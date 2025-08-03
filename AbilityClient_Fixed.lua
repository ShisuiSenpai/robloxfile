-- AbilityClient: Client-side ability handling with improved timing and synchronization
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Modules
local AbilityConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("AbilityConfig"))

-- Remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Abilities")
local executeAbilityRemote = remotes:WaitForChild("ExecuteAbility")
local abilitySyncRemote = remotes:WaitForChild("AbilitySync")

-- VFX assets (with safe loading)
local abilityVFX = ReplicatedStorage:WaitForChild("AbilityVFX", 10)
local jumpWindVFX = abilityVFX and abilityVFX:FindFirstChild("jumpwind")
local slashEffects = abilityVFX and abilityVFX:FindFirstChild("SlashEffects")
local slash1VFX = slashEffects and slashEffects:FindFirstChild("Slash1")
local attachmentVFX = slashEffects and slashEffects:FindFirstChild("Attachment")
local slash2VFX = slashEffects and slashEffects:FindFirstChild("Slash2")

-- Create FX folder
local fxFolder = workspace:FindFirstChild("Fx") or Instance.new("Folder")
fxFolder.Name = "Fx"
fxFolder.Parent = workspace

-- State
local abilityActive = false
local activeSyncs = {}
local cooldowns = {}

-- Debug function
local function debug(...)
	AbilityConfig.Debug("[CLIENT]", player.Name, ...)
end

-- VFX functions with error handling
local function emitParticles(attachment)
	if not attachment then return end
	
	for _, child in pairs(attachment:GetDescendants()) do
		if child:IsA("ParticleEmitter") then
			local emitCount = child:GetAttribute("EmitCount") or 30
			child:Emit(emitCount)
		end
	end
end

local function playJumpWindVFX(position)
	if not jumpWindVFX then
		debug("Warning: jumpwind VFX not found")
		return
	end
	
	local effect = jumpWindVFX:Clone()
	if effect:IsA("BasePart") then
		effect.CanCollide = false
		effect.CanTouch = false
		effect.CanQuery = false
		effect.Anchored = true
		effect.Transparency = 1
	end

	effect.CFrame = CFrame.new(position) * CFrame.new(0, -3, 0)
	effect.Parent = fxFolder

	-- Emit particles
	for _, emitter in pairs(effect:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			local count = emitter:GetAttribute("EmitCount") or 30
			emitter:Emit(count)
		end
	end

	Debris:AddItem(effect, 5)
	debug("Played jump wind VFX")
end

local function playSlashVFX(rootPart, config)
	if not rootPart or not rootPart.Parent then return end
	
	-- Play Slash1 and Attachment
	if slash1VFX then
		local slash1 = slash1VFX:Clone()
		slash1.Parent = rootPart
		emitParticles(slash1)
		Debris:AddItem(slash1, 4)
	end
	
	if attachmentVFX then
		local attachment = attachmentVFX:Clone()
		attachment.Parent = rootPart
		emitParticles(attachment)
		Debris:AddItem(attachment, 3)
	end

	-- Schedule Slash2 using config timing
	local slash2Delay = config.vfxTiming.slash2 - config.vfxTiming.slash1
	task.delay(slash2Delay, function()
		if rootPart and rootPart.Parent and slash2VFX then
			local slash2 = slash2VFX:Clone()
			slash2.Parent = rootPart
			emitParticles(slash2)
			Debris:AddItem(slash2, 3)
			debug("Played Slash2 VFX")
		end
	end)

	debug("Played slash VFX")
end

-- Improved movement sync with proper cleanup
local function handleMovementSync(data)
	local config = AbilityConfig.Abilities[data.ability]
	if not config then
		debug("Error: Config not found for ability:", data.ability)
		return
	end

	local attacker = data.attacker
	local enemy = data.enemy

	if not attacker or not attacker.Character then return end

	local attackerRoot = attacker.Character:FindFirstChild("HumanoidRootPart")
	if not attackerRoot then return end

	-- Initialize sync data first
	activeSyncs[attacker] = {
		connection = nil,
		animationTrack = nil,
		attackerStartPos = attackerRoot.Position,
		enemyStartPos = nil,
		enemyBodyPos = nil,
		enemyBodyGyro = nil
	}

	-- Play animation immediately
	local attackerHumanoid = attacker.Character:FindFirstChild("Humanoid")
	local animationTrack

	if attackerHumanoid then
		local animator = attackerHumanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = attackerHumanoid
		end
		
		local animation = Instance.new("Animation")
		animation.AnimationId = config.animationId

		animationTrack = animator:LoadAnimation(animation)
		animationTrack.Priority = config.animationPriority
		
		-- Apply animation timing
		task.wait(config.animationTiming.windup)
		animationTrack:Play()
		
		activeSyncs[attacker].animationTrack = animationTrack
		debug("Playing animation for", attacker.Name)
	end

	-- Play VFX with config timing
	if config.vfxTiming.jumpWind == 0 then
		playJumpWindVFX(attackerRoot.Position)
	else
		task.delay(config.vfxTiming.jumpWind, function()
			if attackerRoot and attackerRoot.Parent then
				playJumpWindVFX(attackerRoot.Position)
			end
		end)
	end

	-- Schedule slash VFX with config timing
	task.delay(config.vfxTiming.slash1, function()
		if attackerRoot and attackerRoot.Parent then
			playSlashVFX(attackerRoot, config)
		end
	end)

	-- Small delay for smooth start
	task.wait(config.animationTiming.startDelay)

	-- Store original positions
	local attackerStartPos = attackerRoot.Position
	local enemyStartPos = nil

	-- Handle enemy movement
	if enemy and enemy.Character and config.enemyMovement.useTween then
		local enemyRoot = enemy.Character:FindFirstChild("HumanoidRootPart")
		if enemyRoot then
			enemyStartPos = enemyRoot.Position
			activeSyncs[attacker].enemyStartPos = enemyStartPos
			
			-- Calculate peak position
			local peakHeight = attackerStartPos.Y + config.enemyMovement.peakHeight
			local attackerCFrame = CFrame.new(attackerStartPos, attackerStartPos + attackerRoot.CFrame.LookVector)
			local enemyPeakPos = (attackerCFrame * CFrame.new(config.enemyOffset)).Position
			enemyPeakPos = Vector3.new(enemyPeakPos.X, peakHeight, enemyPeakPos.Z)

			-- Tween enemy to peak
			local tweenInfo = TweenInfo.new(
				config.enemyMovement.tweenDuration,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			)

			local enemyTween = TweenService:Create(enemyRoot, tweenInfo, {
				CFrame = CFrame.new(enemyPeakPos)
			})
			enemyTween:Play()

			-- Make enemy face attacker continuously
			local lookDirection = (attackerStartPos - enemyPeakPos) * Vector3.new(1, 0, 1)
			if lookDirection.Magnitude > 0 then
				-- Initial rotation
				local rotationTween = TweenService:Create(enemyRoot, tweenInfo, {
					CFrame = CFrame.lookAt(enemyPeakPos, enemyPeakPos + lookDirection)
				})
				rotationTween:Play()
			end

			-- Hold enemy at peak if configured
			if config.enemyMovement.stayAtPeak then
				task.delay(config.enemyMovement.tweenDuration, function()
					if enemyRoot and enemyRoot.Parent and activeSyncs[attacker] then
						local enemyBodyPos = Instance.new("BodyPosition")
						enemyBodyPos.MaxForce = Vector3.new(1e6, 1e6, 1e6)
						enemyBodyPos.P = 50000
						enemyBodyPos.D = 5000
						enemyBodyPos.Position = enemyPeakPos
						enemyBodyPos.Parent = enemyRoot

						-- Store for cleanup
						activeSyncs[attacker].enemyBodyPos = enemyBodyPos
						
						-- Add BodyGyro to maintain facing direction
						local bodyGyro = Instance.new("BodyGyro")
						bodyGyro.MaxTorque = Vector3.new(0, 1e6, 0) -- Only Y-axis rotation
						bodyGyro.P = 10000
						bodyGyro.D = 500
						bodyGyro.CFrame = CFrame.lookAt(enemyPeakPos, enemyPeakPos + lookDirection)
						bodyGyro.Parent = enemyRoot
						
						activeSyncs[attacker].enemyBodyGyro = bodyGyro
						debug("Holding enemy at peak with facing lock")
					end
				end)
			end
		end
	end

	-- Get phase timings
	local phaseEndTimes = AbilityConfig.GetPhaseEndTimes(data.ability)
	if not phaseEndTimes.rise then
		debug("Error: Invalid phase configuration")
		return
	end

	-- Movement sequence for attacker
	local startTime = workspace:GetServerTimeNow() - config.animationTiming.startDelay

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not attackerRoot or not attackerRoot.Parent then
			connection:Disconnect()
			return
		end
		
		local elapsed = workspace:GetServerTimeNow() - startTime

		if elapsed <= phaseEndTimes.rise then
			-- Rising phase
			local progress = elapsed / config.phases.rise.duration
			local eased = 1 - (1 - progress) ^ 2
			local height = attackerStartPos.Y + (config.phases.rise.height * eased)
			attackerRoot.CFrame = CFrame.new(attackerStartPos.X, height, attackerStartPos.Z) 
			                      * attackerRoot.CFrame.Rotation

		elseif elapsed <= phaseEndTimes.hover then
			-- Hovering phase
			local peakHeight = attackerStartPos.Y + config.phases.rise.height
			attackerRoot.CFrame = CFrame.new(attackerStartPos.X, peakHeight, attackerStartPos.Z)
			                      * attackerRoot.CFrame.Rotation

		elseif elapsed <= phaseEndTimes.fall then
			-- Falling phase
			local fallProgress = (elapsed - phaseEndTimes.hover) / config.phases.fall.duration
			local fallEased = fallProgress ^ 2
			local peakHeight = attackerStartPos.Y + config.phases.rise.height
			local fallHeight = peakHeight - (config.phases.rise.height * fallEased)
			attackerRoot.CFrame = CFrame.new(attackerStartPos.X, fallHeight, attackerStartPos.Z)
			                      * attackerRoot.CFrame.Rotation

		else
			-- Ability complete
			connection:Disconnect()
			if activeSyncs[attacker] then
				activeSyncs[attacker].connection = nil
			end
		end
	end)

	-- Store connection
	if activeSyncs[attacker] then
		activeSyncs[attacker].connection = connection
	end

	debug("Started movement sync for", attacker.Name)
end

-- Handle damage phase
local function handleDamagePhase(data)
	local sync = activeSyncs[data.attacker]
	if sync then
		-- Remove physics constraints
		if sync.enemyBodyPos and sync.enemyBodyPos.Parent then
			sync.enemyBodyPos:Destroy()
			sync.enemyBodyPos = nil
		end
		if sync.enemyBodyGyro and sync.enemyBodyGyro.Parent then
			sync.enemyBodyGyro:Destroy()
			sync.enemyBodyGyro = nil
		end
		debug("Released enemy for knockback")
	end
end

-- Cleanup sync with proper error handling
local function cleanupSync(data)
	local sync = activeSyncs[data.attacker]
	if not sync then return end

	-- Disconnect movement
	if sync.connection then
		sync.connection:Disconnect()
	end

	-- Stop animation
	if sync.animationTrack then
		sync.animationTrack:Stop()
	end

	-- Clean up enemy physics
	if sync.enemyBodyPos and sync.enemyBodyPos.Parent then
		sync.enemyBodyPos:Destroy()
	end
	if sync.enemyBodyGyro and sync.enemyBodyGyro.Parent then
		sync.enemyBodyGyro:Destroy()
	end

	activeSyncs[data.attacker] = nil
	debug("Cleaned up sync for", data.attacker.Name)
end

-- Handle sync events
abilitySyncRemote.OnClientEvent:Connect(function(action, data)
	-- Validate data
	if type(action) ~= "string" or type(data) ~= "table" then
		debug("Invalid sync data received")
		return
	end
	
	debug("Sync event:", action, "for ability:", data.ability)

	if action == "start" then
		handleMovementSync(data)
	elseif action == "damage" then
		handleDamagePhase(data)
	elseif action == "end" then
		cleanupSync(data)
	end
end)

-- Input handling with debounce
local lastAbilityTime = 0
local INPUT_DEBOUNCE = 0.1

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- Debounce rapid inputs
	if tick() - lastAbilityTime < INPUT_DEBOUNCE then return end

	-- Check for ability keys
	for abilityName, config in pairs(AbilityConfig.Abilities) do
		if input.KeyCode == config.key then
			lastAbilityTime = tick()
			debug("Key pressed for", abilityName)

			-- Check if ability is on cooldown
			if cooldowns[abilityName] and tick() < cooldowns[abilityName] then
				local remaining = cooldowns[abilityName] - tick()
				debug("Ability on cooldown:", string.format("%.1f", remaining), "seconds")
				return
			end

			-- Check if already using ability
			if abilityActive then
				debug("Already using ability")
				return
			end

			-- Set active state
			abilityActive = true

			-- Request ability from server
			task.spawn(function()
				local success, result = pcall(function()
					return executeAbilityRemote:InvokeServer(abilityName)
				end)
				
				if success and result then
					debug("Ability executed successfully")
					-- Set cooldown
					cooldowns[abilityName] = tick() + config.cooldown

					-- Reset active state after duration
					local duration = AbilityConfig.GetAbilityDuration(abilityName)
					task.delay(duration, function()
						abilityActive = false
					end)
				else
					debug("Ability failed:", result or "Unknown error")
					abilityActive = false
				end
			end)
		end
	end
end)

-- Handle character respawn
local function onCharacterAdded(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")

	-- Clean up any active syncs
	for attacker, sync in pairs(activeSyncs) do
		if sync.connection then
			sync.connection:Disconnect()
		end
		if sync.animationTrack then
			sync.animationTrack:Stop()
		end
		if sync.enemyBodyPos and sync.enemyBodyPos.Parent then
			sync.enemyBodyPos:Destroy()
		end
		if sync.enemyBodyGyro and sync.enemyBodyGyro.Parent then
			sync.enemyBodyGyro:Destroy()
		end
	end
	activeSyncs = {}

	-- Reset ability state
	abilityActive = false
	cooldowns = {}

	debug("Character respawned, reset ability state")
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Clean up on player leaving
game.Players.PlayerRemoving:Connect(function(leavingPlayer)
	-- Clean up syncs for leaving player
	local sync = activeSyncs[leavingPlayer]
	if sync then
		if sync.connection then
			sync.connection:Disconnect()
		end
		if sync.animationTrack then
			sync.animationTrack:Stop()
		end
		if sync.enemyBodyPos and sync.enemyBodyPos.Parent then
			sync.enemyBodyPos:Destroy()
		end
		if sync.enemyBodyGyro and sync.enemyBodyGyro.Parent then
			sync.enemyBodyGyro:Destroy()
		end
		activeSyncs[leavingPlayer] = nil
	end
end)

debug("AbilityClient loaded!")