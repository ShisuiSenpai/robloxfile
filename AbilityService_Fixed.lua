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

-- Security: Track ability requests to prevent spam
local requestTracker = {}
local MAX_REQUESTS_PER_SECOND = 5

-- Debug function
local function debug(...)
	AbilityConfig.Debug("[SERVER]", ...)
end

-- Initialize player
local function initializePlayer(player)
	playerCooldowns[player] = {}
	requestTracker[player] = {requests = 0, lastReset = tick()}
	player:SetAttribute("UsingAbility", false)
	debug("Initialized player:", player.Name)
end

-- Clean up player
local function cleanupPlayer(player)
	-- Clean up any active abilities
	if activeAbilities[player] then
		-- Force cleanup if ability is still active
		local abilityData = activeAbilities[player]
		if abilityData.cleanupConnection then
			abilityData.cleanupConnection:Disconnect()
		end
		activeAbilities[player] = nil
	end
	
	playerCooldowns[player] = nil
	requestTracker[player] = nil
	debug("Cleaned up player:", player.Name)
end

-- Security: Check request rate
local function checkRequestRate(player)
	local tracker = requestTracker[player]
	if not tracker then return false end
	
	local currentTime = tick()
	if currentTime - tracker.lastReset > 1 then
		tracker.requests = 0
		tracker.lastReset = currentTime
	end
	
	tracker.requests = tracker.requests + 1
	return tracker.requests <= MAX_REQUESTS_PER_SECOND
end

-- Validate ability usage
local function canUseAbility(player, abilityName)
	-- Security check
	if not checkRequestRate(player) then
		return false, "Too many requests"
	end
	
	-- Check if ability exists
	local abilityConfig = AbilityConfig.Abilities[abilityName]
	if not abilityConfig then
		return false, "Invalid ability"
	end
	
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

	-- Check round state (optional - remove if not using round system)
	local canUseCombat = player:GetAttribute("CanUseCombat")
	if canUseCombat == false then -- Explicitly check for false
		return false, "Combat disabled"
	end

	-- Check freeze state
	if player:GetAttribute("Freeze") then
		return false, "Player frozen"
	end

	-- Check weapon equipped (optional - customize based on your weapon system)
	local hasWeapon = false
	for _, tool in pairs(player.Character:GetChildren()) do
		if tool:IsA("Tool") then
			hasWeapon = true
			break
		end
	end

	if not hasWeapon then
		-- Optional: Remove this check if abilities don't require weapons
		return false, "No weapon equipped"
	end

	return true, "Can use ability"
end

-- Find nearest enemy with improved validation
local function findNearestEnemy(attacker, range)
	local attackerRoot = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
	if not attackerRoot then return nil end

	local nearestEnemy = nil
	local nearestDistance = range

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= attacker and player.Character then
			local enemyRoot = player.Character:FindFirstChild("HumanoidRootPart")
			local enemyHumanoid = player.Character:FindFirstChild("Humanoid")

			if enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 then
				-- Optional round state check - customize based on your game
				local inRound = player:GetAttribute("RoundState") == "InRound"
				local notFrozen = not player:GetAttribute("Freeze")
				local notBeingGrabbed = not player:GetAttribute("BeingGrabbed")
				
				-- Remove round check if not using round system
				if notFrozen and notBeingGrabbed then
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

-- Store enemy state for restoration
local function storeEnemyState(enemy)
	if not enemy or not enemy.Character then return end
	
	local humanoid = enemy.Character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	enemy:SetAttribute("OriginalWalkSpeed", humanoid.WalkSpeed)
	enemy:SetAttribute("OriginalJumpPower", humanoid.JumpPower)
	enemy:SetAttribute("OriginalJumpHeight", humanoid.JumpHeight)
	enemy:SetAttribute("OriginalAutoRotate", humanoid.AutoRotate)
	enemy:SetAttribute("OriginalPlatformStand", humanoid.PlatformStand)
end

-- Restore enemy state
local function restoreEnemyState(enemy)
	if not enemy or not enemy.Character then return end
	
	local humanoid = enemy.Character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	-- Use stored values or defaults
	humanoid.WalkSpeed = enemy:GetAttribute("OriginalWalkSpeed") or 16
	humanoid.JumpPower = enemy:GetAttribute("OriginalJumpPower") or 50
	humanoid.JumpHeight = enemy:GetAttribute("OriginalJumpHeight") or 7.2
	
	local autoRotate = enemy:GetAttribute("OriginalAutoRotate")
	humanoid.AutoRotate = autoRotate ~= false -- Default to true if nil
	
	local platformStand = enemy:GetAttribute("OriginalPlatformStand")
	humanoid.PlatformStand = platformStand == true -- Default to false if nil
	
	-- Re-enable Movement script if we disabled it
	if enemy:GetAttribute("MovementScriptDisabled") then
		local movementScript = enemy.Character and enemy.Character:FindFirstChild("Movement")
		if movementScript then
			movementScript.Enabled = true
		end
		enemy:SetAttribute("MovementScriptDisabled", nil)
	end
	
	-- Clear idle animation disable flag
	enemy:SetAttribute("DisableIdleAnimations", nil)
	
	-- Clear attributes
	enemy:SetAttribute("BeingGrabbed", false)
	enemy:SetAttribute("OriginalWalkSpeed", nil)
	enemy:SetAttribute("OriginalJumpPower", nil)
	enemy:SetAttribute("OriginalJumpHeight", nil)
	enemy:SetAttribute("OriginalAutoRotate", nil)
	enemy:SetAttribute("OriginalPlatformStand", nil)
end

-- Execute Upward Slash with improved safety
local function executeUpwardSlash(player)
	local config = AbilityConfig.Abilities.UpwardSlash
	local character = player.Character
	if not character then return false, "No character" end
	
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

	-- Set cooldown immediately
	playerCooldowns[player].UpwardSlash = tick() + config.cooldown

	-- Store original attacker values
	local originalWalkSpeed = humanoid.WalkSpeed
	local originalJumpPower = humanoid.JumpPower
	local originalJumpHeight = humanoid.JumpHeight
	local originalAutoRotate = humanoid.AutoRotate

	-- Disable attacker movement and rotation
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false -- Lock orientation

	-- Create ability data with cleanup function
	local abilityData = {
		ability = "UpwardSlash",
		enemy = enemy,
		startTime = tick(),
		originalWalkSpeed = originalWalkSpeed,
		originalJumpPower = originalJumpPower,
		originalJumpHeight = originalJumpHeight,
		originalAutoRotate = originalAutoRotate
	}

	-- Handle enemy state
	if enemy and enemy.Character then
		local enemyHumanoid = enemy.Character:FindFirstChild("Humanoid")
		local enemyRoot = enemy.Character:FindFirstChild("HumanoidRootPart")
		
		if enemyHumanoid and enemyRoot then
			enemy:SetAttribute("BeingGrabbed", true)
			
			-- Store original values
			storeEnemyState(enemy)

			-- Freeze enemy completely
			enemyHumanoid.WalkSpeed = 0
			enemyHumanoid.JumpPower = 0
			enemyHumanoid.JumpHeight = 0
			enemyHumanoid.AutoRotate = false

						-- Stop all animations using your animation system
			local animationHandler = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("AnimationHandler"))
			
			-- Stop all animations on the enemy using your AnimationHandler
			if animationHandler and animationHandler.StopAll then
				animationHandler.StopAll(enemy.Character)
			end
			
			-- Also stop any remaining tracks the traditional way as backup
			local animator = enemyHumanoid:FindFirstChildOfClass("Animator")
			if animator then
				for _, track in pairs(animator:GetPlayingAnimationTracks()) do
					track:Stop(0) -- Stop immediately with 0 fade time
				end
			end
			
			-- Set PlatformStand to prevent movement
			enemyHumanoid.PlatformStand = true
			
			-- Disable the movement framework for this character
			-- Find and disable the Movement script in the enemy's character
			local movementScript = enemy.Character:FindFirstChild("Movement")
			if movementScript then
				movementScript.Enabled = false
				enemy:SetAttribute("MovementScriptDisabled", true)
			end
			
			-- Set attribute to signal IdleScript to stop (since it's in PlayerScripts)
			enemy:SetAttribute("DisableIdleAnimations", true)
			
			-- Clear physics bodies
			for _, child in pairs(enemyRoot:GetChildren()) do
				if child:IsA("BodyVelocity") or child:IsA("BodyPosition") or child:IsA("BodyGyro") then
					child:Destroy()
				end
			end
			
			-- SERVER-SIDE ENEMY MOVEMENT
			-- Calculate target position
			local attackerStartPos = rootPart.Position
			local peakHeight = attackerStartPos.Y + config.enemyMovement.peakHeight
			local attackerCFrame = CFrame.new(attackerStartPos, attackerStartPos + rootPart.CFrame.LookVector)
			local enemyPeakPos = (attackerCFrame * CFrame.new(config.enemyOffset)).Position
			enemyPeakPos = Vector3.new(enemyPeakPos.X, peakHeight, enemyPeakPos.Z)
			
			-- Apply BodyPosition to move enemy
			local bodyPosition = Instance.new("BodyPosition")
			bodyPosition.MaxForce = Vector3.new(4e4, 4e4, 4e4)
			bodyPosition.P = 20000
			bodyPosition.D = 1000
			bodyPosition.Position = enemyPeakPos
			bodyPosition.Parent = enemyRoot
			
			-- Apply BodyGyro to face attacker
			local lookDirection = (attackerStartPos - enemyPeakPos) * Vector3.new(1, 0, 1)
			if lookDirection.Magnitude > 0 then
				local bodyGyro = Instance.new("BodyGyro")
				bodyGyro.MaxTorque = Vector3.new(0, 4e4, 0)
				bodyGyro.P = 10000
				bodyGyro.D = 500
				bodyGyro.CFrame = CFrame.lookAt(enemyPeakPos, enemyPeakPos + lookDirection)
				bodyGyro.Parent = enemyRoot
				
				-- Store for cleanup
				abilityData.enemyBodyGyro = bodyGyro
			end
			
			-- Store for cleanup
			abilityData.enemyBodyPosition = bodyPosition
			abilityData.enemyRoot = enemyRoot
		end
	end

	-- Store ability data
	activeAbilities[player] = abilityData

	-- Prepare sync data
	local syncData = {
		ability = "UpwardSlash",
		attacker = player,
		enemy = enemy,
		startPosition = rootPart.Position,
		startTime = workspace:GetServerTimeNow()
	}

	-- Notify all clients
	abilitySyncRemote:FireAllClients("start", syncData)

	-- Schedule damage at config timing
	local damageConnection
	damageConnection = task.delay(config.vfxTiming.damagePoint, function()
		if not activeAbilities[player] then return end -- Ability was cancelled
		
		if enemy and enemy.Character then
			local enemyHumanoid = enemy.Character:FindFirstChild("Humanoid")
			local enemyRoot = enemy.Character:FindFirstChild("HumanoidRootPart")

			if enemyHumanoid and enemyRoot and enemyHumanoid.Health > 0 then
				-- Calculate damage
				local damage = math.random(config.damage.min, config.damage.max)
				
				-- Use your combat system's HealthValue instead of Humanoid health
				local healthValue = enemy.Character:FindFirstChild("HealthValue")
				local percentValue = enemy.Character:FindFirstChild("PercentValue")
				
				if healthValue and percentValue then
					-- Apply damage to HealthValue (your system)
					healthValue.Value = math.max(0, healthValue.Value - damage)
					
					-- Get current percentage for knockback scaling
					local percentageManager = require(script.Parent.ServerCombat:FindFirstChild("PercentageManager"))
					local currentPercent = percentageManager and percentageManager.GetPercentFromHealth(enemy.Character) or 0
					
					debug("Applied", damage, "damage to", enemy.Name, "- now at", currentPercent, "%")
				else
					-- Fallback to default damage if combat system not initialized
					enemyHumanoid:TakeDamage(damage)
					debug("Applied", damage, "damage to", enemy.Name, "(fallback method)")
				end

				-- Remove physics constraints before applying knockback
				if abilityData.enemyBodyPosition and abilityData.enemyBodyPosition.Parent then
					abilityData.enemyBodyPosition:Destroy()
					abilityData.enemyBodyPosition = nil
				end
				if abilityData.enemyBodyGyro and abilityData.enemyBodyGyro.Parent then
					abilityData.enemyBodyGyro:Destroy()
					abilityData.enemyBodyGyro = nil
				end
				
				-- Use your RagdollModule for knockback instead of BodyVelocity
				local ragdollModule = require(script.Parent.ServerCombat:FindFirstChild("RagdollModule"))
				if ragdollModule then
					-- Calculate knockback force with your system's scaling
					local percentForKnockback = percentValue and percentValue.Value or 0
					local scaledPercent = math.clamp(percentForKnockback, 0, 400)
					
					-- Scale knockback based on percentage (similar to your combat system)
					local baseForce = config.knockback.force
					local scaledForce = baseForce * (1 + (scaledPercent / 200)) -- Scale up to 3x at 400%
					
					local knockbackDirection = (enemyRoot.Position - rootPart.Position).Unit
					if knockbackDirection.Magnitude == 0 then
						knockbackDirection = rootPart.CFrame.LookVector
					end
					
					local knockbackVector = (knockbackDirection * scaledForce) + 
					                       Vector3.new(0, config.knockback.upwardBoost, 0)
					
					-- Use your knockback system
					ragdollModule.Knockback(enemy, knockbackVector, true, config.knockback.duration, player)
					
					debug("Applied knockback with force:", scaledForce, "to", enemy.Name)
				else
					-- Fallback to simple knockback
					local knockback = Instance.new("BodyVelocity")
					knockback.MaxForce = Vector3.new(4e4, 4e4, 4e4)
					knockback.Velocity = (knockbackDirection * config.knockback.force) + 
					                    Vector3.new(0, config.knockback.upwardBoost, 0)
					knockback.Parent = enemyRoot
					Debris:AddItem(knockback, config.knockback.duration)
				end

				debug("Applied", damage, "damage to", enemy.Name)

				-- Release enemy if configured
				if config.enemyMovement.releaseAfterDamage then
					restoreEnemyState(enemy)
					debug("Released enemy after damage:", enemy.Name)
				end

				-- Play hit animation directly with the specific animation ID
				local animator = enemyHumanoid:FindFirstChildOfClass("Animator")
				if not animator then
					animator = Instance.new("Animator")
					animator.Parent = enemyHumanoid
				end
				
				-- Create and load the hit animation
				local hitAnimation = Instance.new("Animation")
				hitAnimation.AnimationId = "rbxassetid://121509032866215"
				
				local hitAnimTrack = animator:LoadAnimation(hitAnimation)
				hitAnimTrack.Priority = Enum.AnimationPriority.Action4 -- High priority to override other animations
				hitAnimTrack:Play()
				
				debug("Playing ability hit animation on", enemy.Name)
				
				-- Stop animation after it completes (or after 2 seconds)
				task.delay(2, function()
					if hitAnimTrack.IsPlaying then
						hitAnimTrack:Stop()
					end
				end)
				
				-- Notify clients
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
	local cleanupConnection
	cleanupConnection = task.delay(totalDuration, function()
		-- Ensure this player's ability is still active
		if activeAbilities[player] ~= abilityData then return end
		
		-- Restore attacker state
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = abilityData.originalWalkSpeed
			humanoid.JumpPower = abilityData.originalJumpPower
			humanoid.JumpHeight = abilityData.originalJumpHeight
			humanoid.AutoRotate = abilityData.originalAutoRotate
		end

		-- Clean up physics objects if they still exist
		if abilityData.enemyBodyPosition and abilityData.enemyBodyPosition.Parent then
			abilityData.enemyBodyPosition:Destroy()
		end
		if abilityData.enemyBodyGyro and abilityData.enemyBodyGyro.Parent then
			abilityData.enemyBodyGyro:Destroy()
		end
		
		-- Restore enemy state if not already released
		if enemy and enemy.Character and enemy:GetAttribute("BeingGrabbed") then
			restoreEnemyState(enemy)
		end

		-- Clear ability state
		player:SetAttribute("UsingAbility", false)
		activeAbilities[player] = nil

		-- Notify clients
		abilitySyncRemote:FireAllClients("end", {
			ability = "UpwardSlash",
			attacker = player
		})

		debug("UpwardSlash completed for:", player.Name)
	end)
	
	-- Store cleanup connection for emergency cleanup
	abilityData.cleanupConnection = cleanupConnection

	return true, "Success"
end

-- Handle ability execution request
executeAbilityRemote.OnServerInvoke = function(player, abilityName)
	-- Validate input
	if type(abilityName) ~= "string" then
		return false, "Invalid ability name"
	end
	
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

-- Clean up on server shutdown
game:BindToClose(function()
	-- Clean up all active abilities
	for player, abilityData in pairs(activeAbilities) do
		if abilityData.cleanupConnection then
			abilityData.cleanupConnection:Disconnect()
		end
		
		-- Restore states
		if player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = abilityData.originalWalkSpeed or 16
				humanoid.JumpPower = abilityData.originalJumpPower or 50
			end
		end
		
		-- Restore enemy if applicable
		if abilityData.enemy and abilityData.enemy.Character then
			restoreEnemyState(abilityData.enemy)
		end
	end
end)

debug("AbilityService loaded!")