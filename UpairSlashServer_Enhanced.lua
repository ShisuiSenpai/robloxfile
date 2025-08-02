-- ServerScriptService.UpairSlashServer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

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

-- Debug mode - SET THIS TO TRUE TO SEE DEBUG INFO
local DEBUG_MODE = true

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

		-- Brief anchor for starting position
		rootPart.Anchored = true
		task.wait(0.05) -- Very brief anchor
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

-- Create a simple but visible particle effect
local function createSimpleWindEffect(position)
	print("🌪️ Creating simple wind effect...")
	
	-- Create a part to hold our custom particles
	local windPart = Instance.new("Part")
	windPart.Name = "SimpleWindVFX"
	windPart.Size = Vector3.new(1, 1, 1)
	windPart.Transparency = 1
	windPart.Anchored = true
	windPart.CanCollide = false
	windPart.Position = position
	windPart.Parent = workspace
	
	-- Create attachment for particles
	local attachment = Instance.new("Attachment")
	attachment.Parent = windPart
	
	-- Create main wind particle
	local windParticle = Instance.new("ParticleEmitter")
	windParticle.Name = "WindBurst"
	windParticle.Parent = attachment
	
	-- Configure for visibility
	windParticle.Texture = "rbxasset://textures/particles/smoke_main.dds"
	windParticle.Color = ColorSequence.new(Color3.new(0.8, 0.9, 1)) -- Light blue
	windParticle.LightEmission = 0.5
	windParticle.LightInfluence = 0.5
	
	-- Size that starts big and fades
	windParticle.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(0.5, 4),
		NumberSequenceKeypoint.new(1, 6)
	}
	
	-- Transparency fade
	windParticle.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	}
	
	-- Motion settings
	windParticle.Lifetime = NumberRange.new(0.5, 1)
	windParticle.Rate = 0 -- We'll use Emit
	windParticle.Speed = NumberRange.new(10, 20)
	windParticle.SpreadAngle = Vector2.new(360, 45) -- Spread outward
	windParticle.VelocityInheritance = 0
	windParticle.EmissionDirection = Enum.NormalId.Top
	windParticle.Enabled = false
	
	-- Create dust particles
	local dustParticle = Instance.new("ParticleEmitter")
	dustParticle.Name = "DustBurst"
	dustParticle.Parent = attachment
	
	dustParticle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	dustParticle.Color = ColorSequence.new(Color3.new(0.9, 0.8, 0.6)) -- Dusty color
	dustParticle.LightEmission = 0.3
	
	dustParticle.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0.1)
	}
	
	dustParticle.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	}
	
	dustParticle.Lifetime = NumberRange.new(0.3, 0.8)
	dustParticle.Rate = 0
	dustParticle.Speed = NumberRange.new(5, 15)
	dustParticle.SpreadAngle = Vector2.new(360, 10)
	dustParticle.EmissionDirection = Enum.NormalId.Top
	dustParticle.Enabled = false
	
	-- Emit particles
	windParticle:Emit(30)
	dustParticle:Emit(50)
	
	-- Add a shockwave ring
	local ring = Instance.new("Part")
	ring.Name = "ShockwaveRing"
	ring.Size = Vector3.new(4, 0.2, 4)
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.ForceField
	ring.BrickColor = BrickColor.new("Cyan")
	ring.Transparency = 0.5
	ring.Anchored = true
	ring.CanCollide = false
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	
	-- Animate the ring expanding
	local ringTween = TweenService:Create(ring, 
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(15, 0.1, 15),
			Transparency = 1
		}
	)
	ringTween:Play()
	
	-- Cleanup
	Debris:AddItem(windPart, 2)
	Debris:AddItem(ring, 1)
	
	return windPart
end

-- Attempt to use original VFX with aggressive fixes
local function spawnJumpWindVFX(character)
	print("🌪️ Attempting to spawn original VFX...")
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Try to get original VFX
	local success, vfxOriginal = pcall(function()
		return ReplicatedStorage
			:WaitForChild("Assets", 2)
			:WaitForChild("Abilities", 2)
			:WaitForChild("VFX", 2)
			:WaitForChild("UpSlashAbility", 2)
			:WaitForChild("jumpwind", 2)
	end)

	if not success or not vfxOriginal then
		warn("❌ Original VFX not found, using simple effect")
		return createSimpleWindEffect(rootPart.Position + Vector3.new(0, -3, 0))
	end

	-- Clone VFX
	local vfxClone = vfxOriginal:Clone()
	vfxClone.Name = "JumpWindVFX_Active"
	vfxClone.Transparency = 1
	vfxClone.CanCollide = false
	vfxClone.Massless = true
	vfxClone.Anchored = true -- Keep it anchored for now
	
	-- Position at ground
	local groundPos = rootPart.Position + Vector3.new(0, -3, 0)
	vfxClone.Position = groundPos
	vfxClone.Parent = workspace

	-- AGGRESSIVE VFX FIXING
	local emitterCount = 0
	local fixedCount = 0
	local emittersToFire = {}
	
	local function aggressiveFixEmitter(emitter)
		fixedCount = fixedCount + 1
		
		-- Force a texture if missing
		if not emitter.Texture or emitter.Texture == "" then
			emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		end
		
		-- Force reasonable size
		emitter.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 2),
			NumberSequenceKeypoint.new(0.5, 3),
			NumberSequenceKeypoint.new(1, 1)
		}
		
		-- Force visibility
		emitter.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.8, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		}
		
		-- Force reasonable lifetime
		emitter.Lifetime = NumberRange.new(0.5, 1.5)
		
		-- Add light emission
		emitter.LightEmission = 0.5
		emitter.LightInfluence = 0.5
		
		-- Ensure it's not enabled continuously
		emitter.Enabled = false
		
		-- Make it blue/white for wind effect
		emitter.Color = ColorSequence.new(Color3.new(0.7, 0.85, 1))
		
		-- Boost the speed for dramatic effect
		if emitter.Speed then
			local speed = emitter.Speed
			if typeof(speed) == "NumberRange" then
				emitter.Speed = NumberRange.new(speed.Min * 2, speed.Max * 2)
			end
		else
			emitter.Speed = NumberRange.new(10, 20)
		end
		
		return emitter
	end
	
	local function processAllEmitters(parent, depth)
		depth = depth or 0
		
		for _, child in pairs(parent:GetChildren()) do
			if child:IsA("ParticleEmitter") then
				emitterCount = emitterCount + 1
				
				if DEBUG_MODE and emitterCount <= 3 then
					print("🔧 Fixing emitter:", child.Name)
				end
				
				local fixed = aggressiveFixEmitter(child)
				table.insert(emittersToFire, fixed)
				
			elseif child:IsA("Attachment") or child:IsA("BasePart") then
				processAllEmitters(child, depth + 1)
			end
		end
	end
	
	-- Process everything
	processAllEmitters(vfxClone)
	
	print("📊 Fixed", fixedCount, "out of", emitterCount, "emitters")
	
	-- Fire all emitters
	if #emittersToFire > 0 then
		print("💥 Firing all emitters...")
		
		-- Emit from each
		for _, emitter in pairs(emittersToFire) do
			local emitCount = 25 -- Fixed count for consistency
			emitter:Emit(emitCount)
		end
		
		-- ALSO create our simple effect as backup
		if emitterCount < 5 or fixedCount > emitterCount * 0.8 then
			print("⚠️ Too many fixes needed, adding backup VFX")
			createSimpleWindEffect(groundPos)
		end
	else
		warn("❌ No emitters to fire, using simple effect")
		createSimpleWindEffect(groundPos)
	end
	
	-- Add debug visuals
	if DEBUG_MODE then
		-- Add a bright part to mark position
		local marker = Instance.new("Part")
		marker.Name = "VFX_DEBUG_MARKER"
		marker.Size = Vector3.new(8, 0.5, 8)
		marker.Shape = Enum.PartType.Cylinder
		marker.Material = Enum.Material.Neon
		marker.BrickColor = BrickColor.new("Lime green")
		marker.Transparency = 0.3
		marker.Anchored = true
		marker.CanCollide = false
		marker.CFrame = CFrame.new(groundPos) * CFrame.Angles(0, 0, math.rad(90))
		marker.Parent = workspace
		
		-- Add pointlight
		local light = Instance.new("PointLight")
		light.Brightness = 5
		light.Color = Color3.new(0, 1, 0)
		light.Range = 40
		light.Parent = marker
		
		-- Add surface light
		local surfaceLight = Instance.new("SurfaceLight")
		surfaceLight.Brightness = 10
		surfaceLight.Color = Color3.new(0, 1, 0)
		surfaceLight.Face = Enum.NormalId.Top
		surfaceLight.Parent = marker
		
		Debris:AddItem(marker, 3)
		
		print("🟢 Debug marker added at VFX position")
	end
	
	-- Update position to follow player
	local updateConnection
	updateConnection = RunService.Heartbeat:Connect(function()
		if vfxClone and vfxClone.Parent and rootPart and rootPart.Parent then
			vfxClone.Position = rootPart.Position + Vector3.new(0, -3, 0)
		else
			if updateConnection then
				updateConnection:Disconnect()
			end
		end
	end)
	
	-- Cleanup
	task.delay(3, function()
		if updateConnection then
			updateConnection:Disconnect()
		end
		if vfxClone and vfxClone.Parent then
			vfxClone:Destroy()
		end
	end)
	
	return vfxClone
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

	-- 1. Freeze player movement (but not position)
	freezePlayer(character, true)

	-- 2. Start VFX immediately
	local vfx = spawnJumpWindVFX(character)

	-- 3. Play animation immediately
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
		-- Remove upward force after delay
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
print("🔍 DEBUG_MODE is ON - Green markers will show VFX positions")
print("💡 The script will use backup VFX if original has too many issues")