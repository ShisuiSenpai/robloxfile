--[[
	SmashVFXHandler (Script)
	Location: ServerScriptService/SmashVFXHandler
	
	Server-side handler for SmashVFX system.
	- Validates client requests
	- Handles hit detection
	- Applies knockback & ragdoll
	- Broadcasts VFX to all clients
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Configuration
local MAX_DISTANCE = 20
local COOLDOWN = 0.3

-- Hitbox Configuration
local HITBOX_SIZE = Vector3.new(7, 8, 7)
local HITBOX_DURATION = 0.3

-- Knockback & Ragdoll Configuration
local KNOCKBACK_FORCE_UP = 35
local KNOCKBACK_FORCE_BACK = 25
local RAGDOLL_DURATION = 1.5

-- Player cooldowns
local playerCooldowns = {}

-- Track ragdolled characters
local ragdolledCharacters = {}

-- Create RemoteEvents
local smashVFXEvent = Instance.new("RemoteEvent")
smashVFXEvent.Name = "SmashVFXEvent"
smashVFXEvent.Parent = ReplicatedStorage

-- ============================================
-- RAGDOLL SYSTEM (Server-Side)
-- ============================================

local function getMotor6Ds(character)
	local motors = {}
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			table.insert(motors, descendant)
		end
	end
	return motors
end

local function createRagdollConstraint(motor)
	local socket = Instance.new("BallSocketConstraint")
	socket.Name = "RagdollSocket_" .. motor.Name
	socket.LimitsEnabled = true
	socket.TwistLimitsEnabled = true
	socket.UpperAngle = 45
	socket.TwistLowerAngle = -45
	socket.TwistUpperAngle = 45
	
	local att0 = Instance.new("Attachment")
	att0.Name = "RagdollAtt0"
	att0.CFrame = motor.C0
	att0.Parent = motor.Part0
	
	local att1 = Instance.new("Attachment")
	att1.Name = "RagdollAtt1"
	att1.CFrame = motor.C1
	att1.Parent = motor.Part1
	
	socket.Attachment0 = att0
	socket.Attachment1 = att1
	socket.Parent = motor.Part0
	
	return socket, att0, att1
end

local function enableRagdoll(character)
	if ragdolledCharacters[character] then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	
	local ragdollData = {
		motors = {},
		sockets = {},
		attachments = {}
	}
	
	-- Disable humanoid states
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	-- Process motors
	local motors = getMotor6Ds(character)
	
	for _, motor in ipairs(motors) do
		if motor.Name ~= "RootJoint" and motor.Name ~= "Root" then
			table.insert(ragdollData.motors, {
				motor = motor,
				enabled = motor.Enabled
			})
			
			local socket, att0, att1 = createRagdollConstraint(motor)
			table.insert(ragdollData.sockets, socket)
			table.insert(ragdollData.attachments, att0)
			table.insert(ragdollData.attachments, att1)
			
			motor.Enabled = false
		end
	end
	
	-- Enable collision on parts
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end
	
	ragdolledCharacters[character] = ragdollData
	return true
end

local function disableRagdoll(character)
	local ragdollData = ragdolledCharacters[character]
	if not ragdollData then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
	-- Clean up constraints
	for _, socket in ipairs(ragdollData.sockets) do
		if socket and socket.Parent then
			socket:Destroy()
		end
	end
	
	for _, att in ipairs(ragdollData.attachments) do
		if att and att.Parent then
			att:Destroy()
		end
	end
	
	-- Re-enable motors
	for _, motorData in ipairs(ragdollData.motors) do
		if motorData.motor and motorData.motor.Parent then
			motorData.motor.Enabled = true
		end
	end
	
	-- Re-enable humanoid states
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	
	-- Reset collision
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = false
		end
	end
	
	ragdolledCharacters[character] = nil
end

local function applyKnockback(character, hitPosition)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	-- Direction away from hit
	local direction = (rootPart.Position - hitPosition).Unit
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude > 0 then
		direction = direction.Unit
	else
		direction = Vector3.new(1, 0, 0)
	end
	
	-- Apply velocity
	local knockbackVelocity = Vector3.new(
		direction.X * KNOCKBACK_FORCE_BACK,
		KNOCKBACK_FORCE_UP,
		direction.Z * KNOCKBACK_FORCE_BACK
	)
	
	rootPart.AssemblyLinearVelocity = knockbackVelocity
	rootPart.AssemblyAngularVelocity = Vector3.new(
		math.random(-5, 5),
		math.random(-3, 3),
		math.random(-5, 5)
	)
end

local function knockbackAndRagdoll(character, hitPosition)
	if ragdolledCharacters[character] then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	local success = enableRagdoll(character)
	if not success then return end
	
	applyKnockback(character, hitPosition)
	
	-- Schedule recovery
	task.delay(RAGDOLL_DURATION, function()
		if character and character.Parent then
			disableRagdoll(character)
		end
	end)
end

-- ============================================
-- HITBOX SYSTEM (Server-Side)
-- ============================================

local function getCharactersInHitbox(position, sourceCharacter)
	local charactersHit = {}
	local charactersChecked = {}
	
	-- Create a temporary hitbox for detection
	local hitboxCFrame = CFrame.new(position + Vector3.new(0, HITBOX_SIZE.Y / 2, 0))
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {sourceCharacter}
	
	local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, HITBOX_SIZE, overlapParams)
	
	for _, part in ipairs(partsInBox) do
		local character = part.Parent
		
		if character and not charactersChecked[character] then
			charactersChecked[character] = true
			
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				table.insert(charactersHit, character)
			end
		end
	end
	
	return charactersHit
end

local function processHits(position, sourcePlayer)
	local sourceCharacter = sourcePlayer.Character
	if not sourceCharacter then return end
	
	local charactersHit = getCharactersInHitbox(position, sourceCharacter)
	
	for _, character in ipairs(charactersHit) do
		local targetPlayer = Players:GetPlayerFromCharacter(character)
		local name = targetPlayer and targetPlayer.Name or character.Name
		print("[SmashVFX Server] HIT: " .. name .. " by " .. sourcePlayer.Name)
		
		-- Apply knockback and ragdoll on server
		knockbackAndRagdoll(character, position)
	end
	
	if #charactersHit > 0 then
		print("[SmashVFX Server] Total hit by " .. sourcePlayer.Name .. ": " .. #charactersHit)
	end
end

-- ============================================
-- REQUEST VALIDATION
-- ============================================

local function validateRequest(player, position, normal)
	-- Check player has character
	local character = player.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	-- Validate types
	if typeof(position) ~= "Vector3" then return false end
	if typeof(normal) ~= "Vector3" then return false end
	
	-- Check distance (with small buffer for latency)
	local distance = (position - humanoidRootPart.Position).Magnitude
	if distance > MAX_DISTANCE + 5 then
		return false
	end
	
	-- Check cooldown
	local lastTime = playerCooldowns[player.UserId] or 0
	if tick() - lastTime < COOLDOWN then
		return false
	end
	
	-- Check if normal is ground-like
	if normal.Y < 0.7 then
		return false
	end
	
	return true
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

local function onSmashVFXRequested(player, position, normal)
	-- Validate request
	if not validateRequest(player, position, normal) then
		return
	end
	
	-- Set cooldown
	playerCooldowns[player.UserId] = tick()
	
	-- Process hits on server
	processHits(position, player)
	
	-- Broadcast VFX to all clients
	smashVFXEvent:FireAllClients(player, position, normal)
	
	print("[SmashVFX Server] VFX spawned by " .. player.Name .. " at " .. tostring(position))
end

local function onPlayerRemoving(player)
	playerCooldowns[player.UserId] = nil
end

-- Handle character removal (cleanup ragdoll data)
local function onCharacterRemoving(character)
	if ragdolledCharacters[character] then
		ragdolledCharacters[character] = nil
	end
end

local function onPlayerAdded(player)
	player.CharacterRemoving:Connect(onCharacterRemoving)
end

-- ============================================
-- INITIALIZATION
-- ============================================

smashVFXEvent.OnServerEvent:Connect(onSmashVFXRequested)
Players.PlayerRemoving:Connect(onPlayerRemoving)
Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("[SmashVFX] Server handler initialized!")
print("  - Hit detection: SERVER-SIDE")
print("  - Knockback & Ragdoll: SERVER-SIDE")
print("  - VFX broadcast: ALL CLIENTS")
