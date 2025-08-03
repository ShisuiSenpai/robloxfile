-- AbilityService: Server-side ability handling
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Modules
local AbilityConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("AbilityConfig"))

-- Remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Abilities")
local executeAbilityRemote = remotes:WaitForChild("ExecuteAbility")
local abilitySyncRemote = remotes:WaitForChild("AbilitySync")

-- Player data
local playerCooldowns = {}
local activeAbilities = {}

-- Debug function
local function debug(...)
	AbilityConfig.Debug("[SERVER]", ...)
end

-- Initialize player
local function initializePlayer(player)
	playerCooldowns[player] = {}
	player:SetAttribute("UsingAbility", false)
	debug("Initialized player:", player.Name)
end

-- Clean up player
local function cleanupPlayer(player)
	playerCooldowns[player] = nil
	if activeAbilities[player] then
		activeAbilities[player] = nil
	end
	debug("Cleaned up player:", player.Name)
end

-- Validate ability usage
local function canUseAbility(player, abilityName)
	-- Check if player exists and has character
	if not player.Character then
		return false, "No character"
	end

	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false, "Invalid humanoid"
	end

	-- Check if already using ability
	if player:GetAttribute("UsingAbility") then
		return false, "Already using ability"
	end

	-- Check cooldown
	local cooldowns = playerCooldowns[player]
	if cooldowns[abilityName] and tick() < cooldowns[abilityName] then
		local remaining = cooldowns[abilityName] - tick()
		return false, string.format("On cooldown (%.1fs)", remaining)
	end

	-- Check round state
	local canUseCombat = player:GetAttribute("CanUseCombat")
	if not canUseCombat then
		return false, "Combat disabled"
	end

	-- Check freeze state
	if player:GetAttribute("Freeze") then
		return false, "Player frozen"
	end

	-- Check weapon equipped (basic check - expand based on your weapon system)
	local hasWeapon = false
	for _, tool in pairs(player.Character:GetChildren()) do
		if tool:IsA("Tool") then
			hasWeapon = true
			break
		end
	end

	if not hasWeapon then
		return false, "No weapon equipped"
	end

	return true, "Can use ability"
end

-- Find nearest enemy
local function findNearestEnemy(attacker, range)
	local attackerRoot = attacker.Character:FindFirstChild("HumanoidRootPart")
	if not attackerRoot then return nil end

	local nearestEnemy = nil
	local nearestDistance = range

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= attacker and player.Character then
			local enemyRoot = player.Character:FindFirstChild("HumanoidRootPart")
			local enemyHumanoid = player.Character:FindFirstChild("Humanoid")

			if enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 then
				-- Check if enemy is in round
				if player:GetAttribute("RoundState") == "InRound" and not player:GetAttribute("Freeze") then
					local distance = (enemyRoot.Position - attackerRoot.Position).Magnitude
					if distance < nearestDistance then
						nearestEnemy = player
						nearestDistance = distance
					end
				end
			end
		end
	end

	debug("Found enemy:", nearestEnemy and nearestEnemy.Name or "none", "at distance:", nearestDistance)
	return nearestEnemy
end

-- Execute Upward Slash
local function executeUpwardSlash(player)
	local config = AbilityConfig.Abilities.UpwardSlash
	local character = player.Character
	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then
		return false, "Invalid character"
	end

	debug("Executing UpwardSlash for:", player.Name)

	-- Find enemy
	local enemy = findNearestEnemy(player, config.detectionRange)

	-- Set ability state
	player:SetAttribute("UsingAbility", true)

	-- Set cooldown
	playerCooldowns[player].UpwardSlash = tick() + config.cooldown

	-- Store ability data
	activeAbilities[player] = {
		ability = "UpwardSlash",
		enemy = enemy,
		startTime = tick()
	}

	-- Prepare sync data
	local syncData = {
		ability = "UpwardSlash",
		attacker = player,
		enemy = enemy,
		startPosition = rootPart.Position,
		startTime = workspace:GetServerTimeNow()
	}

	-- Notify all clients to handle movement and VFX
	abilitySyncRemote:FireAllClients("start", syncData)

	-- Disable movement
	local originalWalkSpeed = humanoid.WalkSpeed
	local originalJumpPower = humanoid.JumpPower
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	-- Handle enemy state - Improved enemy control
	if enemy and enemy.Character then
		local enemyHumanoid = enemy.Character:FindFirstChild("Humanoid")
		if enemyHumanoid then
			enemy:SetAttribute("BeingGrabbed", true)
			-- Store original values for restoration
			enemy:SetAttribute("OriginalWalkSpeed", enemyHumanoid.WalkSpeed)
			enemy:SetAttribute("OriginalJumpPower", enemyHumanoid.JumpPower)
			enemy:SetAttribute("OriginalAutoRotate", enemyHumanoid.AutoRotate)
			
			-- Completely disable enemy movement
			enemyHumanoid.WalkSpeed = 0
			enemyHumanoid.JumpPower = 0
			enemyHumanoid.AutoRotate = false
			
			-- Disable any active animations
			local animator = enemyHumanoid:FindFirstChildOfClass("Animator")
			if animator then
				for _, track in pairs(animator:GetPlayingAnimationTracks()) do
					track:Stop()
				end
			end
		end
	end

	-- Schedule damage at the exact damage point
	task.delay(config.vfxTiming.damagePoint, function()
		if enemy and enemy.Character then
			local enemyHumanoid = enemy.Character:FindFirstChild("Humanoid")
			local enemyRoot = enemy.Character:FindFirstChild("HumanoidRootPart")

			if enemyHumanoid and enemyRoot and enemyHumanoid.Health > 0 then
				-- Apply damage
				local damage = math.random(config.damage.min, config.damage.max)
				enemyHumanoid:TakeDamage(damage)

				-- Apply knockback with improved direction calculation
				local attackerCFrame = CFrame.new(rootPart.Position, rootPart.Position + rootPart.CFrame.LookVector)
				local knockbackDirection = (enemyRoot.Position - rootPart.Position).Unit
				
				local knockback = Instance.new("BodyVelocity")
				knockback.MaxForce = Vector3.new(4e4, 4e4, 4e4)
				knockback.Velocity = (knockbackDirection * config.knockback.force) + Vector3.new(0, config.knockback.upwardBoost, 0)
				knockback.Parent = enemyRoot

				Debris:AddItem(knockback, config.knockback.duration)

				debug("Applied", damage, "damage to", enemy.Name, "with knockback")

				-- Notify clients of damage
				abilitySyncRemote:FireAllClients("damage", {
					ability = "UpwardSlash",
					attacker = player,
					enemy = enemy,
					damage = damage
				})
			end
		end
	end)

	-- Schedule cleanup
	local totalDuration = AbilityConfig.GetAbilityDuration("UpwardSlash")
	task.delay(totalDuration, function()
		-- Restore attacker state
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = originalWalkSpeed
			humanoid.JumpPower = originalJumpPower
		end

		-- Restore enemy state - Improved restoration
		if enemy and enemy.Character then
			local enemyHumanoid = enemy.Character:FindFirstChild("Humanoid")
			if enemyHumanoid then
				enemy:SetAttribute("BeingGrabbed", false)
				local origWalkSpeed = enemy:GetAttribute("OriginalWalkSpeed") or 16
				local origJumpPower = enemy:GetAttribute("OriginalJumpPower") or 50
				local origAutoRotate = enemy:GetAttribute("OriginalAutoRotate")
				if origAutoRotate == nil then origAutoRotate = true end
				
				enemyHumanoid.WalkSpeed = origWalkSpeed
				enemyHumanoid.JumpPower = origJumpPower
				enemyHumanoid.AutoRotate = origAutoRotate
			end
		end

		-- Clear ability state
		player:SetAttribute("UsingAbility", false)
		activeAbilities[player] = nil

		-- Notify clients to end
		abilitySyncRemote:FireAllClients("end", {
			ability = "UpwardSlash",
			attacker = player
		})

		debug("UpwardSlash completed for:", player.Name)
	end)

	return true, "Success"
end

-- Handle ability execution request
executeAbilityRemote.OnServerInvoke = function(player, abilityName)
	debug("Ability request:", abilityName, "from", player.Name)

	-- Validate ability
	local canUse, reason = canUseAbility(player, abilityName)
	if not canUse then
		debug("Ability blocked:", reason)
		return false, reason
	end

	-- Execute ability based on name
	if abilityName == "UpwardSlash" then
		return executeUpwardSlash(player)
	end

	return false, "Unknown ability"
end

-- Player connections
Players.PlayerAdded:Connect(initializePlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)

-- Initialize existing players
for _, player in pairs(Players:GetPlayers()) do
	initializePlayer(player)
end

debug("AbilityService loaded!")