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

-- VFX assets
local abilityVFX = ReplicatedStorage:WaitForChild("AbilityVFX")
local jumpWindVFX = abilityVFX:WaitForChild("jumpwind")
local slashEffects = abilityVFX:WaitForChild("SlashEffects")
local slash1VFX = slashEffects:WaitForChild("Slash1")
local attachmentVFX = slashEffects:WaitForChild("Attachment")
local slash2VFX = slashEffects:WaitForChild("Slash2")

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

-- VFX functions
local function emitParticles(attachment)
	for _, child in pairs(attachment:GetDescendants()) do
		if child:IsA("ParticleEmitter") then
			local emitCount = child:GetAttribute("EmitCount") or 30
			child:Emit(emitCount)
		end
	end
end

local function playJumpWindVFX(position)
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

local function playSlashVFX(rootPart)
	-- Play Slash1 and Attachment
	local slash1 = slash1VFX:Clone()
	local attachment = attachmentVFX:Clone()

	slash1.Parent = rootPart
	attachment.Parent = rootPart

	emitParticles(slash1)
	emitParticles(attachment)

	Debris:AddItem(slash1, 4)
	Debris:AddItem(attachment, 3)

	-- Schedule Slash2
	task.delay(1, function()
		if rootPart and rootPart.Parent then
			local slash2 = slash2VFX:Clone()
			slash2.Parent = rootPart
			emitParticles(slash2)
			Debris:AddItem(slash2, 3)
			debug("Played Slash2 VFX")
		end
	end)

	debug("Played slash VFX")
end

-- COMPLETELY NEW: Direct CFrame movement handler for instant, snappy movement
local function handleMovementSync(data)
	local config = AbilityConfig.Abilities[data.ability]
	if not config then return end

	local attacker = data.attacker
	local enemy = data.enemy

	if not attacker or not attacker.Character then return end

	local attackerRoot = attacker.Character:FindFirstChild("HumanoidRootPart")
	if not attackerRoot then return end

	-- Play animation immediately
	local attackerHumanoid = attacker.Character:FindFirstChild("Humanoid")
	local animationTrack

	if attackerHumanoid then
		local animator = attackerHumanoid:FindFirstChildOfClass("Animator")
		if animator then
			local animation = Instance.new("Animation")
			animation.AnimationId = config.animationId

			animationTrack = animator:LoadAnimation(animation)
			animationTrack.Priority = config.animationPriority
			animationTrack:Play()

			debug("Playing animation for", attacker.Name)
		end
	end

	-- Play VFX immediately
	playJumpWindVFX(attackerRoot.Position)

	-- Schedule slash VFX
	task.delay(config.vfxTiming.slash1, function()
		if attackerRoot and attackerRoot.Parent then
			playSlashVFX(attackerRoot)
		end
	end)

	-- Minimal delay for instant response
	task.wait(config.animationTiming.startDelay)

	-- STORE ORIGINAL POSITIONS
	local attackerStartPos = attackerRoot.Position
	local enemyStartPos = enemy and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") and enemy.Character.HumanoidRootPart.Position or nil

	-- TELEPORT ENEMY TO PEAK HEIGHT IMMEDIATELY
	if enemy and enemy.Character and config.movementSettings.teleportEnemy then
		local enemyRoot = enemy.Character:FindFirstChild("HumanoidRootPart")
		if enemyRoot then
			-- Calculate peak position for enemy
			local peakHeight = attackerStartPos.Y + config.phases.rise.height
			local attackerCFrame = CFrame.new(attackerStartPos, attackerStartPos + attackerRoot.CFrame.LookVector)
			local enemyPeakPos = (attackerCFrame * CFrame.new(config.enemyOffset)).Position
			enemyPeakPos = Vector3.new(enemyPeakPos.X, peakHeight, enemyPeakPos.Z)
			
			-- TELEPORT ENEMY TO PEAK HEIGHT
			enemyRoot.CFrame = CFrame.new(enemyPeakPos)
			
			-- Make enemy face attacker instantly
			local lookDirection = (attackerStartPos - enemyPeakPos) * Vector3.new(1, 0, 1)
			if lookDirection.Magnitude > 0 then
				enemyRoot.CFrame = CFrame.lookAt(enemyPeakPos, enemyPeakPos + lookDirection)
			end
			
			debug("TELEPORTED enemy to peak height:", enemy.Name)
		end
	end

	-- Movement sequence using direct CFrame manipulation
	local startTime = workspace:GetServerTimeNow() - config.animationTiming.startDelay

	local connection
	connection = RunService.Heartbeat:Connect(function()
		local elapsed = workspace:GetServerTimeNow() - startTime

		-- Calculate current phase
		local riseEnd = config.phases.rise.duration
		local hoverEnd = riseEnd + config.phases.hover.duration

		if elapsed <= riseEnd then
			-- Rising phase - direct CFrame movement
			local progress = elapsed / config.phases.rise.duration
			local height = attackerStartPos.Y + (config.phases.rise.height * progress)
			
			-- Move attacker directly
			attackerRoot.CFrame = CFrame.new(attackerStartPos.X, height, attackerStartPos.Z)

		elseif elapsed <= hoverEnd then
			-- Hovering phase - maintain peak height
			local peakHeight = attackerStartPos.Y + config.phases.rise.height
			attackerRoot.CFrame = CFrame.new(attackerStartPos.X, peakHeight, attackerStartPos.Z)

		else
			-- Falling - cleanup
			connection:Disconnect()
			
			-- Clear from activeSyncs
			if activeSyncs[attacker] then
				activeSyncs[attacker].connection = nil
			end
		end
	end)

	-- Store sync data (no BodyPosition objects needed)
	activeSyncs[attacker] = {
		connection = connection,
		animationTrack = animationTrack,
		attackerStartPos = attackerStartPos,
		enemyStartPos = enemyStartPos
	}

	debug("Started DIRECT CFrame movement for", attacker.Name)
end

-- Handle damage phase - enemy is already at peak height
local function handleDamagePhase(data)
	local sync = activeSyncs[data.attacker]
	if sync then
		-- Enemy is already teleported to peak height, no need to remove physics
		-- The knockback from server will handle the enemy movement
		debug("Damage applied - enemy at peak height")
	end
end

-- Cleanup sync - simplified since we use direct CFrame
local function cleanupSync(data)
	local sync = activeSyncs[data.attacker]
	if not sync then return end

	if sync.connection then
		sync.connection:Disconnect()
	end

	if sync.animationTrack then
		sync.animationTrack:Stop()
	end

	activeSyncs[data.attacker] = nil
	debug("Cleaned up sync for", data.attacker.Name)
end

-- Handle sync events
abilitySyncRemote.OnClientEvent:Connect(function(action, data)
	debug("Sync event:", action, "for ability:", data.ability)

	if action == "start" then
		handleMovementSync(data)
	elseif action == "damage" then
		handleDamagePhase(data)
	elseif action == "end" then
		cleanupSync(data)
	end
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Check for ability keys
	for abilityName, config in pairs(AbilityConfig.Abilities) do
		if input.KeyCode == config.key then
			debug("Key pressed for", abilityName)

			-- Check if ability is on cooldown
			if cooldowns[abilityName] and tick() < cooldowns[abilityName] then
				local remaining = cooldowns[abilityName] - tick()
				debug("Ability on cooldown:", remaining, "seconds")
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
			local success, result = executeAbilityRemote:InvokeServer(abilityName)

			if success then
				debug("Ability executed successfully")
				-- Set cooldown
				cooldowns[abilityName] = tick() + config.cooldown

				-- Reset active state after duration
				local duration = AbilityConfig.GetAbilityDuration(abilityName)
				task.delay(duration, function()
					abilityActive = false
				end)
			else
				debug("Ability failed:", result)
				abilityActive = false
			end
		end
	end
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")

	-- Clean up any active syncs
	for _, sync in pairs(activeSyncs) do
		if sync.connection then
			sync.connection:Disconnect()
		end
	end
	activeSyncs = {}

	-- Reset ability state
	abilityActive = false
	cooldowns = {}

	debug("Character respawned, reset ability state")
end)

debug("AbilityClient loaded!")