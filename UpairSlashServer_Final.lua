-- ServerScriptService.UpairSlashServer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Get RemoteEvent
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local upairSlashRemote = remotes:WaitForChild("UpairSlashRemote")

-- Animation ID
local UPAIR_ANIMATION_ID = "rbxassetid://126685859180940"

-- Attack settings
local JUMP_POWER = 65
local COOLDOWNS = {} -- Track player cooldowns
local COOLDOWN_TIME = 1.5
local HOVER_DURATION = 1.19
local HOVER_DELAY = 0.6

-- Cache for preloaded animations per player
local animationCache = {}

print("🎮 UpairSlashServer starting...")

-- Preload animation for a player
local function preloadAnimation(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = UPAIR_ANIMATION_ID

	local animTrack = animator:LoadAnimation(animation)
	animationCache[player] = animTrack

	return animTrack
end

-- Freeze/Unfreeze player movement
local function freezePlayer(character, freeze)
	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then return end

	if freeze then
		-- Store original values
		humanoid:SetAttribute("StoredWalkSpeed", humanoid.WalkSpeed)
		humanoid:SetAttribute("StoredJumpPower", humanoid.JumpPower)

		-- Freeze movement
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false

		-- Brief anchor
		rootPart.Anchored = true
		task.wait(0.05)
		rootPart.Anchored = false
	else
		-- Restore movement
		local storedSpeed = humanoid:GetAttribute("StoredWalkSpeed") or 16
		local storedJump = humanoid:GetAttribute("StoredJumpPower") or 50

		humanoid.WalkSpeed = storedSpeed
		humanoid.JumpPower = storedJump
		humanoid.AutoRotate = true
	end
end

-- Create custom wind VFX that WILL work
local function createCustomWindVFX(character)
	print("🌪️ Creating custom wind VFX...")
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	-- Create a model to hold all VFX
	local vfxModel = Instance.new("Model")
	vfxModel.Name = "UpSlashVFX"
	vfxModel.Parent = workspace
	
	-- Create central part
	local centerPart = Instance.new("Part")
	centerPart.Name = "VFXCenter"
	centerPart.Size = Vector3.new(1, 1, 1)
	centerPart.Transparency = 1
	centerPart.Anchored = true
	centerPart.CanCollide = false
	centerPart.Position = rootPart.Position + Vector3.new(0, -3, 0)
	centerPart.Parent = vfxModel
	
	-- Update position to follow player
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if centerPart and centerPart.Parent and rootPart and rootPart.Parent then
			centerPart.Position = rootPart.Position + Vector3.new(0, -3, 0)
		else
			connection:Disconnect()
		end
	end)
	
	-- Create multiple attachments for different effects
	local attachments = {}
	
	-- Ground burst attachment
	local groundAttachment = Instance.new("Attachment")
	groundAttachment.Name = "GroundBurst"
	groundAttachment.Parent = centerPart
	table.insert(attachments, groundAttachment)
	
	-- Ring attachments at different heights
	for i = 1, 3 do
		local ringAttachment = Instance.new("Attachment")
		ringAttachment.Name = "Ring" .. i
		ringAttachment.Position = Vector3.new(0, i * 0.5, 0)
		ringAttachment.Parent = centerPart
		table.insert(attachments, ringAttachment)
	end
	
	-- EFFECT 1: Ground dust burst
	local dustBurst = Instance.new("ParticleEmitter")
	dustBurst.Name = "DustBurst"
	dustBurst.Parent = groundAttachment
	
	dustBurst.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dustBurst.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(0.8, 0.7, 0.6)),
		ColorSequenceKeypoint.new(1, Color3.new(0.9, 0.85, 0.8))
	}
	dustBurst.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(0.5, 5),
		NumberSequenceKeypoint.new(1, 8)
	}
	dustBurst.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	}
	dustBurst.Lifetime = NumberRange.new(0.5, 1)
	dustBurst.Rate = 0
	dustBurst.Speed = NumberRange.new(15, 25)
	dustBurst.SpreadAngle = Vector2.new(360, 20)
	dustBurst.VelocityInheritance = 0
	dustBurst.EmissionDirection = Enum.NormalId.Top
	dustBurst.LightEmission = 0.2
	dustBurst.LightInfluence = 0.5
	dustBurst.Enabled = false
	
	-- EFFECT 2: Wind spirals
	for i, attachment in ipairs(attachments) do
		local windSpiral = Instance.new("ParticleEmitter")
		windSpiral.Name = "WindSpiral" .. i
		windSpiral.Parent = attachment
		
		windSpiral.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		windSpiral.Color = ColorSequence.new(Color3.new(0.7, 0.85, 1))
		windSpiral.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 2),
			NumberSequenceKeypoint.new(1, 0.5)
		}
		windSpiral.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.3),
			NumberSequenceKeypoint.new(1, 1)
		}
		windSpiral.Lifetime = NumberRange.new(0.3, 0.8)
		windSpiral.Rate = 0
		windSpiral.Speed = NumberRange.new(10 + i * 5, 20 + i * 5)
		windSpiral.SpreadAngle = Vector2.new(360, 0)
		windSpiral.VelocityInheritance = 0
		windSpiral.EmissionDirection = Enum.NormalId.Top
		windSpiral.LightEmission = 0.5
		windSpiral.LightInfluence = 0.3
		windSpiral.Enabled = false
		windSpiral.RotSpeed = NumberRange.new(50, 100)
		windSpiral.Rotation = NumberRange.new(0, 360)
	end
	
	-- EFFECT 3: Energy burst
	local energyBurst = Instance.new("ParticleEmitter")
	energyBurst.Name = "EnergyBurst"
	energyBurst.Parent = groundAttachment
	
	energyBurst.Texture = "rbxasset://textures/particles/explosion.dds"
	energyBurst.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(0.5, 0.8, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.new(0.7, 0.9, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
	}
	energyBurst.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(0.2, 6),
		NumberSequenceKeypoint.new(1, 10)
	}
	energyBurst.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	}
	energyBurst.Lifetime = NumberRange.new(0.3, 0.5)
	energyBurst.Rate = 0
	energyBurst.Speed = NumberRange.new(5, 10)
	energyBurst.SpreadAngle = Vector2.new(360, 360)
	energyBurst.VelocityInheritance = 0
	energyBurst.LightEmission = 1
	energyBurst.LightInfluence = 0
	energyBurst.Enabled = false
	energyBurst.ZOffset = -1
	
	-- Create visual shockwave ring
	local shockwaveRing = Instance.new("Part")
	shockwaveRing.Name = "ShockwaveRing"
	shockwaveRing.Size = Vector3.new(4, 0.1, 4)
	shockwaveRing.Shape = Enum.PartType.Cylinder
	shockwaveRing.Material = Enum.Material.ForceField
	shockwaveRing.BrickColor = BrickColor.new("Cyan")
	shockwaveRing.Transparency = 0.3
	shockwaveRing.Anchored = true
	shockwaveRing.CanCollide = false
	shockwaveRing.CFrame = CFrame.new(centerPart.Position) * CFrame.Angles(0, 0, math.rad(90))
	shockwaveRing.Parent = vfxModel
	
	-- Add glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 3
	pointLight.Color = Color3.new(0.5, 0.8, 1)
	pointLight.Range = 20
	pointLight.Parent = centerPart
	
	-- EMIT ALL PARTICLES
	print("💥 Emitting custom VFX particles...")
	
	-- Ground dust
	dustBurst:Emit(50)
	
	-- Wind spirals (staggered)
	for i, attachment in ipairs(attachments) do
		local emitter = attachment:FindFirstChildOfClass("ParticleEmitter")
		if emitter and emitter.Name:match("WindSpiral") then
			task.wait(0.05 * (i - 1))
			emitter:Emit(30)
		end
	end
	
	-- Energy burst
	energyBurst:Emit(20)
	
	-- Animate shockwave
	local shockwaveTween = TweenService:Create(shockwaveRing,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(20, 0.05, 20),
			Transparency = 1
		}
	)
	shockwaveTween:Play()
	
	-- Fade out light
	local lightTween = TweenService:Create(pointLight,
		TweenInfo.new(1, Enum.EasingStyle.Quad),
		{
			Brightness = 0,
			Range = 5
		}
	)
	lightTween:Play()
	
	-- Cleanup
	task.delay(3, function()
		if connection then
			connection:Disconnect()
		end
		if vfxModel and vfxModel.Parent then
			vfxModel:Destroy()
		end
	end)
	
	print("✅ Custom VFX created and emitted!")
	return vfxModel
end

-- Try to extract textures from original VFX (bonus feature)
local function tryOriginalVFXTextures(character)
	local success, result = pcall(function()
		local vfxOriginal = ReplicatedStorage
			:WaitForChild("Assets", 1)
			:WaitForChild("Abilities", 1)
			:WaitForChild("VFX", 1)
			:WaitForChild("UpSlashAbility", 1)
			:WaitForChild("jumpwind", 1)
		
		if vfxOriginal then
			print("📋 Found original VFX, extracting textures...")
			
			local textures = {}
			for _, desc in pairs(vfxOriginal:GetDescendants()) do
				if desc:IsA("ParticleEmitter") and desc.Texture then
					table.insert(textures, desc.Texture)
				end
			end
			
			if #textures > 0 then
				print("✅ Extracted", #textures, "textures from original VFX")
				-- Could use these textures in our custom VFX if desired
			end
		end
	end)
	
	-- Always create our custom VFX regardless
	return createCustomWindVFX(character)
end

-- Perform the upair slash attack
local function performUpairSlash(player)
	print("\n========== UPAIR SLASH START ==========")
	
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then return end
	if humanoid.Health <= 0 then return end

	-- Check cooldown
	local lastUse = COOLDOWNS[player]
	if lastUse and tick() - lastUse < COOLDOWN_TIME then
		return
	end

	-- Update cooldown
	COOLDOWNS[player] = tick()

	-- ALL EFFECTS START SIMULTANEOUSLY
	print("🚀 Starting all effects...")

	-- 1. Freeze player movement
	freezePlayer(character, true)

	-- 2. Create custom VFX (guaranteed to work)
	local vfx = tryOriginalVFXTextures(character)

	-- 3. Play animation
	local animTrack = animationCache[player]
	if not animTrack then
		animTrack = preloadAnimation(player)
	end
	if animTrack then
		animTrack.Priority = Enum.AnimationPriority.Action
		animTrack:Play()
		print("▶️ Animation playing")
	end

	-- 4. Apply jump force
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
	bodyVelocity.Velocity = Vector3.new(0, JUMP_POWER, 0)
	bodyVelocity.Parent = rootPart

	-- Handle hover timing
	task.spawn(function()
		-- Remove upward force
		task.wait(HOVER_DELAY)
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end

		-- Create hover
		local bodyPosition = Instance.new("BodyPosition")
		bodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
		bodyPosition.Position = rootPart.Position
		bodyPosition.D = 2000
		bodyPosition.P = 10000
		bodyPosition.Parent = rootPart

		-- Hold position
		task.wait(HOVER_DURATION)

		-- Clean up
		if bodyPosition and bodyPosition.Parent then
			bodyPosition:Destroy()
		end

		-- Restore movement
		freezePlayer(character, false)
		
		print("========== UPAIR SLASH COMPLETE ==========\n")
	end)
end

-- Character added handler
local function onCharacterAdded(player, character)
	task.wait(0.5)
	preloadAnimation(player)
end

-- Remote event handler
upairSlashRemote.OnServerEvent:Connect(function(player)
	print("\n📨 Upair slash request from", player.Name)

	-- Check combat permission
	local canUseCombat = player:GetAttribute("CanUseCombat")
	if not canUseCombat then
		warn("❌ Player cannot use abilities - not in combat")
		return
	end

	performUpairSlash(player)
end)

-- Player connections
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
	COOLDOWNS[player] = nil
	animationCache[player] = nil
end)

print("✅ UpairSlashServer ready!")
print("🌪️ Using custom VFX system for guaranteed visibility")