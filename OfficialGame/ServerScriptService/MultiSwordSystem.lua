--[[
	MULTI-SWORD SYSTEM - SERVER (WITH PUSH MECHANICS)
	Place this Script in ServerScriptService
	
	Handles:
	- Server-side sword state management
	- Replicating sword visuals to all players
	- Managing holstered and equipped swords
	- Attack validation and push mechanics (NO DAMAGE - just push + ragdoll!)
	- Kill attribution when pushed players fall into lava
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Load configuration
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local SwordConfig = require(modulesFolder:WaitForChild("SwordConfig"))

-- Wait for InventoryManager to be ready
repeat task.wait() until _G.InventoryManager
local InventoryManager = _G.InventoryManager

-- Get asset folders
local toolSwordsFolder = ReplicatedStorage:WaitForChild("ToolSwords")
local holsteredModelsFolder = ReplicatedStorage:WaitForChild("HolsteredModels")

-- Create RemoteEvents for sword system
local swordRemotes = ReplicatedStorage:FindFirstChild("SwordRemotes")
if not swordRemotes then
	swordRemotes = Instance.new("Folder")
	swordRemotes.Name = "SwordRemotes"
	swordRemotes.Parent = ReplicatedStorage
end

-- Remote Events
local attackRemote = swordRemotes:FindFirstChild("Attack") or Instance.new("RemoteEvent")
attackRemote.Name = "Attack"
attackRemote.Parent = swordRemotes

local switchSwordRemote = swordRemotes:FindFirstChild("SwitchSword") or Instance.new("RemoteEvent")
switchSwordRemote.Name = "SwitchSword"
switchSwordRemote.Parent = swordRemotes

local initializeSwordRemote = swordRemotes:FindFirstChild("InitializeSword") or Instance.new("RemoteEvent")
initializeSwordRemote.Name = "InitializeSword"
initializeSwordRemote.Parent = swordRemotes

-- Player data storage
local playerSwordData = {} -- {[userId] = {currentSword = "SwordName", isAttacking = false, lastAttackTime = tick()}}

-- Push tracking (for kill attribution)
local RECENT_PUSHES = {} -- [victimUserId] = {pusher = Player, time = tick()}
local PUSH_ATTRIBUTION_TIME = 3 -- Seconds to attribute a lava death to a push
local RAGDOLL_DURATION = 2 -- How long the ragdoll effect lasts

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Get attachment part safely
local function getAttachmentPart(character, partName)
	local attachPart = character:FindFirstChild(partName)
	if not attachPart then
		attachPart = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	end
	return attachPart
end

-- Set model transparency
local function setModelTransparency(model, transparency)
	if not model then return end
	for _, descendant in pairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = transparency
		end
	end
end

-- ========================================
-- PUSH + RAGDOLL SYSTEM (from old PushTool)
-- ========================================

-- Create proper ragdoll with constraints
local function createRagdoll(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end

	-- Store original joint data
	local originalJoints = {}
	local createdConstraints = {}

	-- Prevent death from neck break
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false

	-- Make sure root part is unanchored
	rootPart.Anchored = false

	-- Find and replace Motor6D joints with BallSocketConstraints
	for _, descendant in pairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			local joint = descendant
			local part0 = joint.Part0
			local part1 = joint.Part1

			if part0 and part1 then
				-- Store original joint data
				table.insert(originalJoints, {
					Motor6D = joint,
					Part0 = part0,
					Part1 = part1,
					C0 = joint.C0,
					C1 = joint.C1,
					Parent = joint.Parent,
					Name = joint.Name
				})

				-- Make sure parts are unanchored
				part0.Anchored = false
				part1.Anchored = false

				-- Create BallSocketConstraint
				local socket = Instance.new("BallSocketConstraint")
				socket.Name = "RagdollSocket_" .. joint.Name
				socket.Attachment0 = Instance.new("Attachment", part0)
				socket.Attachment1 = Instance.new("Attachment", part1)
				socket.Attachment0.CFrame = joint.C0
				socket.Attachment1.CFrame = joint.C1
				socket.LimitsEnabled = true
				socket.TwistLimitsEnabled = true
				socket.UpperAngle = 45
				socket.TwistLowerAngle = -45
				socket.TwistUpperAngle = 45
				socket.Parent = part0

				table.insert(createdConstraints, socket)
				table.insert(createdConstraints, socket.Attachment0)
				table.insert(createdConstraints, socket.Attachment1)

				-- Disable the Motor6D
				joint.Enabled = false
			end
		end
	end

	-- Set humanoid to ragdoll state
	humanoid.PlatformStand = true
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	-- Enable collision on limbs
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = true
		end
	end

	-- Return cleanup function
	return function()
		if not character.Parent then return end

		-- Clean up any leftover push forces
		for _, descendant in pairs(character:GetDescendants()) do
			if descendant.Name == "PushForce" or descendant.Name == "PushAttachment" then
				descendant:Destroy()
			end
		end

		-- Gradually slow down velocities
		if rootPart and rootPart.Parent then
			local currentVel = rootPart.AssemblyLinearVelocity
			rootPart.AssemblyLinearVelocity = Vector3.new(
				currentVel.X * 0.3,
				math.max(currentVel.Y * 0.5, 0),
				currentVel.Z * 0.3
			)
		end

		-- Ground detection and smooth repositioning
		if rootPart and rootPart.Parent then
			local rayOrigin = rootPart.Position + Vector3.new(0, 3, 0)
			local rayDirection = Vector3.new(0, -50, 0)

			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {character}
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude

			local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

			if rayResult then
				local groundPosition = rayResult.Position
				local targetPosition = groundPosition + Vector3.new(0, 4.5, 0)
				local currentPosition = rootPart.Position

				if currentPosition.Y < targetPosition.Y then
					local targetCFrame = CFrame.new(
						currentPosition.X,
						targetPosition.Y,
						currentPosition.Z
					) * CFrame.Angles(0, math.atan2(rootPart.CFrame.LookVector.X, rootPart.CFrame.LookVector.Z), 0)

					local tween = TweenService:Create(
						rootPart,
						TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{CFrame = targetCFrame}
					)
					tween:Play()
					tween.Completed:Wait()
				else
					local targetCFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.atan2(rootPart.CFrame.LookVector.X, rootPart.CFrame.LookVector.Z), 0)
					local tween = TweenService:Create(
						rootPart,
						TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{CFrame = targetCFrame}
					)
					tween:Play()
					tween.Completed:Wait()
				end
			end
		end

		-- Remove all created constraints
		for _, constraint in pairs(createdConstraints) do
			if constraint and constraint.Parent then
				constraint:Destroy()
			end
		end

		-- Restore original joints
		for _, jointData in pairs(originalJoints) do
			if jointData.Motor6D and jointData.Motor6D.Parent then
				jointData.Motor6D.Enabled = true
			end
		end

		-- Reset collision on limbs
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.CanCollide = false
			end
		end

		-- Reset humanoid state
		if humanoid and humanoid.Parent then
			humanoid.RequiresNeck = true
			humanoid.BreakJointsOnDeath = true
			humanoid.PlatformStand = false
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)

			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

			task.wait(0.05)
			if rootPart and rootPart.Parent then
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 6, 0)
			end
		end
	end
end

-- Apply push force using LinearVelocity constraint
local function applyPushForce(character, direction, force)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	rootPart.Anchored = false

	-- Create attachment for LinearVelocity
	local attachment = Instance.new("Attachment")
	attachment.Name = "PushAttachment"
	attachment.Parent = rootPart

	-- Create LinearVelocity constraint
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "PushForce"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = direction * force
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = rootPart

	-- Remove force after short duration for natural physics
	task.delay(0.25, function()
		if linearVelocity and linearVelocity.Parent then
			linearVelocity:Destroy()
		end
		if attachment and attachment.Parent then
			attachment:Destroy()
		end
	end)
end

-- ========================================
-- HOLSTERED SWORD MANAGEMENT
-- ========================================

-- Create holstered sword on character
local function createHolsteredSword(character, swordName, config)
	-- Check if already exists
	local existingFolder = character:FindFirstChild("HolsteredSwords")
	if existingFolder then
		local existing = existingFolder:FindFirstChild("Holstered_" .. swordName)
		if existing then
			existing:Destroy()
		end
	end

	-- Create folder for holstered swords if doesn't exist
	local holsterFolder = character:FindFirstChild("HolsteredSwords")
	if not holsterFolder then
		holsterFolder = Instance.new("Folder")
		holsterFolder.Name = "HolsteredSwords"
		holsterFolder.Parent = character
	end

	-- Find template
	local holsteredTemplate = holsteredModelsFolder:FindFirstChild(config.HolsteredModelName)
	if not holsteredTemplate then
		warn("[SWORD] Could not find holstered model: " .. config.HolsteredModelName)
		return
	end

	local attachPart = getAttachmentPart(character, config.Holster.AttachmentPart)
	if not attachPart then
		warn("[SWORD] Could not find attachment part: " .. config.Holster.AttachmentPart)
		return
	end

	-- Clone holstered sword
	local holsteredSword = holsteredTemplate:Clone()
	holsteredSword.Name = "Holstered_" .. swordName

	-- Find main sword part
	local swordPart = holsteredSword:FindFirstChild(config.SwordPartName)
	if not swordPart then
		warn("[SWORD] Could not find sword part: " .. config.SwordPartName)
		holsteredSword:Destroy()
		return
	end

	-- Make parts non-collidable and massless
	for _, descendant in pairs(holsteredSword:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.Massless = true
		end
	end

	-- Create weld
	local holsterWeld = Instance.new("Weld")
	holsterWeld.Name = "HolsterWeld"
	holsterWeld.Part0 = attachPart
	holsterWeld.Part1 = swordPart

	-- Apply position and rotation
	local rotationCFrame = CFrame.Angles(
		math.rad(config.Holster.RotationOffset.X),
		math.rad(config.Holster.RotationOffset.Y),
		math.rad(config.Holster.RotationOffset.Z)
	)
	holsterWeld.C0 = CFrame.new(config.Holster.PositionOffset) * rotationCFrame
	holsterWeld.Parent = swordPart

	holsteredSword.Parent = holsterFolder

	return holsteredSword
end

-- Show specific holstered sword
local function showHolster(character, swordName)
	local holsterFolder = character:FindFirstChild("HolsteredSwords")
	if not holsterFolder then return end

	local holsteredSword = holsterFolder:FindFirstChild("Holstered_" .. swordName)
	if holsteredSword then
		local config = SwordConfig.Swords[swordName]
		if config then
			setModelTransparency(holsteredSword, config.Holster.TransparencyValue)
		end
	end
end

-- Hide specific holstered sword
local function hideHolster(character, swordName)
	local holsterFolder = character:FindFirstChild("HolsteredSwords")
	if not holsterFolder then return end

	local holsteredSword = holsterFolder:FindFirstChild("Holstered_" .. swordName)
	if holsteredSword then
		setModelTransparency(holsteredSword, 1)
	end
end

-- ========================================
-- EQUIPPED SWORD MANAGEMENT
-- ========================================

-- Create equipped sword (visible to all)
local function equipSword(character, swordName, config)
	-- Remove any existing equipped sword
	local existingEquipped = character:FindFirstChild("EquippedSword")
	if existingEquipped then
		existingEquipped:Destroy()
	end

	-- Find tool template
	local toolTemplate = toolSwordsFolder:FindFirstChild(config.ToolName)
	if not toolTemplate then
		warn("[SWORD] Could not find tool: " .. config.ToolName)
		return
	end

	-- Clone and parent to character
	local equippedSword = toolTemplate:Clone()
	equippedSword.Name = "EquippedSword"
	equippedSword.Parent = character

	-- Find humanoid
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Equip the tool (attaches to hand)
		humanoid:EquipTool(equippedSword)
	end

	return equippedSword
end

-- Remove equipped sword
local function unequipSword(character)
	local equippedSword = character:FindFirstChild("EquippedSword")
	if equippedSword then
		equippedSword:Destroy()
	end
end

-- ========================================
-- HITBOX DETECTION (finds nearby player to push)
-- ========================================

local function findNearbyTarget(attackerCharacter, range)
	local attackerRoot = attackerCharacter:FindFirstChild("HumanoidRootPart")
	if not attackerRoot then return nil end

	local attackerPos = attackerRoot.Position
	local attackerLook = attackerRoot.CFrame.LookVector

	local closestPlayer = nil
	local closestDistance = range

	for _, otherPlayer in pairs(Players:GetPlayers()) do
		local otherCharacter = otherPlayer.Character
		if otherCharacter and otherCharacter ~= attackerCharacter then
			local otherRoot = otherCharacter:FindFirstChild("HumanoidRootPart")
			local otherHumanoid = otherCharacter:FindFirstChildOfClass("Humanoid")

			if otherRoot and otherHumanoid and otherHumanoid.Health > 0 then
				local distance = (otherRoot.Position - attackerPos).Magnitude
				local toTarget = (otherRoot.Position - attackerPos).Unit
				local dotProduct = toTarget:Dot(attackerLook)

				-- Check if in range and roughly in front
				if distance <= range and dotProduct > 0.4 and distance < closestDistance then
					closestPlayer = otherPlayer
					closestDistance = distance
				end
			end
		end
	end

	return closestPlayer, closestDistance
end

-- ========================================
-- PLAYER INITIALIZATION
-- ========================================

-- Initialize player's sword system
local function initializePlayer(player)
	local character = player.Character
	if not character then return end

	local userId = player.UserId

	-- Initialize player data
	playerSwordData[userId] = {
		currentSword = SwordConfig.DefaultSword,
		isAttacking = false,
		lastAttackTime = 0,
	}

	-- Get player's owned swords from inventory
	local ownedSwords = InventoryManager.GetInventory(player)

	-- Create holstered swords only for owned swords
	for swordName, config in pairs(SwordConfig.Swords) do
		if ownedSwords[swordName] then
			createHolsteredSword(character, swordName, config)
		end
	end

	-- Show only the current sword (or all if ShowAllSwords is true)
	for swordName, config in pairs(SwordConfig.Swords) do
		if ownedSwords[swordName] then
			if SwordConfig.ShowAllSwords or swordName == SwordConfig.DefaultSword then
				showHolster(character, swordName)
			else
				hideHolster(character, swordName)
			end
		end
	end

	-- Tell client initialization is complete
	initializeSwordRemote:FireClient(player, SwordConfig.DefaultSword)
end

-- ========================================
-- ATTACK HANDLING (with PUSH instead of damage!)
-- ========================================

attackRemote.OnServerEvent:Connect(function(attacker)
	local attackerCharacter = attacker.Character
	if not attackerCharacter then return end

	local userId = attacker.UserId
	local playerData = playerSwordData[userId]
	if not playerData then return end

	-- Validate attack (cooldown check)
	local currentTime = tick()
	local config = SwordConfig.Swords[playerData.currentSword]
	if not config then return end

	local totalCooldown = config.Attack.AttackDuration + config.Attack.AttackCooldown
	if currentTime - playerData.lastAttackTime < totalCooldown then
		return -- Still on cooldown
	end

	-- Check if already attacking
	if playerData.isAttacking then return end

	-- Mark as attacking
	playerData.isAttacking = true
	playerData.lastAttackTime = currentTime

	-- Hide holstered sword
	hideHolster(attackerCharacter, playerData.currentSword)

	-- Equip attack sword
	equipSword(attackerCharacter, playerData.currentSword, config)

	-- Tell ALL clients to play animation and VFX for this player
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		initializeSwordRemote:FireClient(otherPlayer, "PlayAttack", attacker, playerData.currentSword)
	end

	-- HITBOX DETECTION: Find target to push
	local targetPlayer, targetDistance = findNearbyTarget(attackerCharacter, config.Attack.AttackRange)

	if targetPlayer and targetPlayer.Character then
		local targetCharacter = targetPlayer.Character
		local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
		local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")

		if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
			print("[SWORD] " .. attacker.Name .. " hit " .. targetPlayer.Name .. " with sword!")

			-- Store original health
			local originalHealth = targetHumanoid.Health

			-- Calculate push direction with upward arc
			local attackerRoot = attackerCharacter:FindFirstChild("HumanoidRootPart")
			if attackerRoot then
				local pushDirection = (targetRoot.Position - attackerRoot.Position).Unit
				pushDirection = (pushDirection + Vector3.new(0, 0.3, 0)).Unit

				-- Get push force from sword config
				local pushForce = config.Attack.PushForce or 50

				-- Check for 2x push boost gamepass
				local pushMultiplier = 1
				if _G.GamepassManager then
					pushMultiplier = _G.GamepassManager.getPushMultiplier(attacker)
				end

				pushForce = pushForce * pushMultiplier

				if pushMultiplier > 1 then
					print("[SWORD] Push boost applied! Force: " .. pushForce)
				end

				-- Apply push and ragdoll
				applyPushForce(targetCharacter, pushDirection, pushForce)
				local removeRagdoll = createRagdoll(targetCharacter)

				-- Track this push for kill attribution
				RECENT_PUSHES[targetPlayer.UserId] = {
					pusher = attacker,
					time = tick()
				}
				print("[SWORD] Tracked push: " .. attacker.Name .. " -> " .. targetPlayer.Name)

				if removeRagdoll then
					-- Health protection during ragdoll
					local healthProtected = true
					task.spawn(function()
						while healthProtected and targetHumanoid and targetHumanoid.Parent do
							if targetHumanoid.Health < originalHealth then
								targetHumanoid.Health = originalHealth
							end
							task.wait(0.2)
						end
					end)

					-- Wait for ragdoll duration
					task.wait(RAGDOLL_DURATION)

					-- Stop health protection
					healthProtected = false

					-- Recover from ragdoll
					removeRagdoll()

					-- Final health restore
					if targetHumanoid and targetHumanoid.Parent then
						targetHumanoid.Health = originalHealth
					end
				end
			end
		end
	end

	-- Wait for attack duration
	task.wait(config.Attack.AttackDuration)

	-- Remove equipped sword
	unequipSword(attackerCharacter)

	-- Show holstered sword again
	showHolster(attackerCharacter, playerData.currentSword)

	-- Mark attack as complete
	playerData.isAttacking = false
end)

-- ========================================
-- SWORD SWITCHING
-- ========================================

switchSwordRemote.OnServerEvent:Connect(function(player, swordName)
	local character = player.Character
	if not character then return end

	local userId = player.UserId
	local playerData = playerSwordData[userId]
	if not playerData then return end

	-- Validate sword exists
	if not SwordConfig.Swords[swordName] then 
		warn("[SWORD] Sword does not exist: " .. tostring(swordName))
		return 
	end

	-- Check if player owns this sword
	if not InventoryManager.PlayerOwnsSword(player, swordName) then
		warn("[SWORD] " .. player.Name .. " tried to equip sword they don't own: " .. swordName)
		return
	end

	-- Don't switch if already on this sword
	if playerData.currentSword == swordName then 
		switchSwordRemote:FireClient(player, swordName)
		return 
	end

	-- Don't switch while attacking
	if playerData.isAttacking then 
		warn("[SWORD] " .. player.Name .. " tried to switch while attacking")
		return 
	end

	-- Hide old sword (unless ShowAllSwords)
	if not SwordConfig.ShowAllSwords then
		hideHolster(character, playerData.currentSword)
	end

	-- Update current sword
	playerData.currentSword = swordName

	-- Show new sword
	showHolster(character, swordName)

	-- Tell client switch was successful
	switchSwordRemote:FireClient(player, swordName)

	print("✅ [SWORD] " .. player.Name .. " equipped: " .. swordName)
end)

-- ========================================
-- DYNAMIC HOLSTER CREATION
-- ========================================

local swordAddedBindable = ReplicatedStorage:WaitForChild("SwordAddedBindable", 10)
if swordAddedBindable then
	swordAddedBindable.Event:Connect(function(player, swordName)
		local character = player.Character
		if not character then return end

		local userId = player.UserId
		local playerData = playerSwordData[userId]
		if not playerData then return end

		-- Check if holster already exists
		local holsterFolder = character:FindFirstChild("HolsteredSwords")
		local holsterExists = holsterFolder and holsterFolder:FindFirstChild("Holstered_" .. swordName)

		if not holsterExists then
			local config = SwordConfig.Swords[swordName]
			if config then
				createHolsteredSword(character, swordName, config)

				if not SwordConfig.ShowAllSwords then
					hideHolster(character, swordName)
				else
					showHolster(character, swordName)
				end

				print("🗡️ [SWORD] Created holster for new sword: " .. swordName)
			end
		end
	end)
end

-- ========================================
-- PLAYER MANAGEMENT
-- ========================================

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		task.wait(0.5)
		initializePlayer(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerSwordData[player.UserId] = nil
	RECENT_PUSHES[player.UserId] = nil

	-- Also clean up if they were the pusher
	for victimId, data in pairs(RECENT_PUSHES) do
		if data.pusher == player then
			RECENT_PUSHES[victimId] = nil
		end
	end
end)

-- Initialize existing players
for _, player in pairs(Players:GetPlayers()) do
	if player.Character then
		task.spawn(function()
			initializePlayer(player)
		end)
	end
end

-- ========================================
-- PUSH TRACKER API (for lava system)
-- ========================================

_G.PushTracker = {
	getRecentPusher = function(victimUserId)
		local pushData = RECENT_PUSHES[victimUserId]
		if pushData then
			local timeSince = tick() - pushData.time
			print("[PUSH TRACKER] Check for", victimUserId, "- Found push from", pushData.pusher.Name, "at", timeSince, "seconds ago")
			if timeSince <= PUSH_ATTRIBUTION_TIME then
				return pushData.pusher
			else
				print("[PUSH TRACKER] Push too old (>3s)")
			end
		else
			print("[PUSH TRACKER] No push data found for", victimUserId)
		end
		return nil
	end,
	clearPushData = function(victimUserId)
		RECENT_PUSHES[victimUserId] = nil
		print("[PUSH TRACKER] Cleared push data for", victimUserId)
	end
}

print("✅ Multi-Sword System Server Loaded! (With Push Mechanics)")
