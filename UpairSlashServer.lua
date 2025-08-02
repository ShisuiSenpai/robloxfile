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
		print("❄️ Freezing player movement")
		-- Store original walk speed
		humanoid:SetAttribute("StoredWalkSpeed", humanoid.WalkSpeed)
		humanoid:SetAttribute("StoredJumpPower", humanoid.JumpPower)

		-- Freeze movement
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false

		-- Anchor for complete freeze during ability
		rootPart.Anchored = true
	else
		print("🔥 Unfreezing player movement")
		-- Restore movement
		local storedSpeed = humanoid:GetAttribute("StoredWalkSpeed") or 16
		local storedJump = humanoid:GetAttribute("StoredJumpPower") or 50

		humanoid.WalkSpeed = storedSpeed
		humanoid.JumpPower = storedJump
		humanoid.AutoRotate = true

		-- Unanchor
		rootPart.Anchored = false
	end
end

-- Setup particle emitter for proper visibility
local function setupParticleEmitter(emitter)
	-- Ensure the emitter will be visible
	emitter.Enabled = false -- We'll use Emit() for burst
	
	-- Force visibility settings
	if emitter:FindFirstChild("Brightness") then
		emitter.Brightness = math.max(emitter.Brightness, 1)
	end
	
	-- Ensure lifetime is reasonable
	local lifetime = emitter.Lifetime
	if typeof(lifetime) == "NumberRange" then
		if lifetime.Max < 0.1 then
			emitter.Lifetime = NumberRange.new(0.5, 1.5)
		end
	end
	
	-- Ensure size is visible
	local size = emitter.Size
	if typeof(size) == "NumberSequence" then
		local keypoints = size.Keypoints
		local allZero = true
		for _, kp in pairs(keypoints) do
			if kp.Value > 0 then
				allZero = false
				break
			end
		end
		if allZero then
			emitter.Size = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0)
			}
		end
	end
	
	-- Ensure transparency allows visibility
	local transparency = emitter.Transparency
	if typeof(transparency) == "NumberSequence" then
		local keypoints = transparency.Keypoints
		local allInvisible = true
		for _, kp in pairs(keypoints) do
			if kp.Value < 1 then
				allInvisible = false
				break
			end
		end
		if allInvisible then
			emitter.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1)
			}
		end
	end
end

-- Spawn JumpWind VFX with proper visibility and positioning
local function spawnJumpWindVFX(character)
	print("🌪️ Starting JumpWind VFX spawn...")
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		warn("❌ No HumanoidRootPart found!")
		return
	end

	-- Create or get FX folder in workspace
	local fxFolder = workspace:FindFirstChild("FX")
	if not fxFolder then
		fxFolder = Instance.new("Folder")
		fxFolder.Name = "FX"
		fxFolder.Parent = workspace
	end

	-- Navigate to VFX
	local jumpWindVFX = ReplicatedStorage:WaitForChild("Assets")
		:WaitForChild("Abilities")
		:WaitForChild("VFX")
		:WaitForChild("UpSlashAbility")
		:WaitForChild("jumpwind")

	if not jumpWindVFX then
		warn("❌ jumpwind VFX not found!")
		return
	end

	-- Clone VFX
	local vfxClone = jumpWindVFX:Clone()
	vfxClone.Name = "JumpWindEffect_" .. tick()
	vfxClone.Anchored = false -- Make it follow the player
	vfxClone.CanCollide = false
	vfxClone.Massless = true
	vfxClone.Transparency = 1
	
	-- Parent to character for proper following
	vfxClone.Parent = character
	
	-- Create a weld to attach VFX to player
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = vfxClone
	weld.Parent = vfxClone
	
	-- Position below player
	vfxClone.CFrame = rootPart.CFrame * CFrame.new(0, -3, 0)

	print("🎯 VFX attached to player")

	-- Collect ALL emitters recursively
	local allEmitters = {}
	local function collectEmitters(parent, path)
		path = path or parent.Name
		
		for _, child in pairs(parent:GetChildren()) do
			if child:IsA("ParticleEmitter") then
				setupParticleEmitter(child) -- Fix visibility settings
				table.insert(allEmitters, {emitter = child, path = path})
				print("✅ Found emitter:", child.Name, "in", path)
			elseif child:IsA("Attachment") or child:IsA("BasePart") then
				collectEmitters(child, path .. "." .. child.Name)
			end
		end
	end

	collectEmitters(vfxClone)
	print("📊 Total emitters found:", #allEmitters)

	-- Emit from all emitters simultaneously
	if #allEmitters > 0 then
		print("💥 EMITTING ALL PARTICLES NOW!")
		
		for _, data in pairs(allEmitters) do
			local emitter = data.emitter
			-- Calculate appropriate emit count
			local rate = emitter.Rate
			local emitCount = math.clamp(math.floor(rate * 0.5), 10, 50)
			
			-- Make sure emitter is enabled for emission
			emitter.Enabled = false -- Burst only
			emitter:Emit(emitCount)
			
			print("  ✨ Emitted", emitCount, "from", emitter.Name)
		end
		
		-- Also make the VFX visible by adding a light
		local pointLight = Instance.new("PointLight")
		pointLight.Brightness = 2
		pointLight.Color = Color3.new(0.5, 0.8, 1)
		pointLight.Range = 20
		pointLight.Parent = vfxClone
		
		-- Fade out the light
		TweenService:Create(pointLight, TweenInfo.new(2), {
			Brightness = 0,
			Range = 5
		}):Play()
	else
		warn("❌ No emitters found in VFX!")
	end

	-- Clean up after delay
	Debris:AddItem(vfxClone, 5)
	
	return vfxClone
end

-- Perform the upair slash attack
local function performUpairSlash(player)
	print("\n========== UPAIR SLASH START ==========")
	print("👤 Player:", player.Name)

	local character = player.Character
	if not character then 
		warn("❌ No character found")
		return 
	end

	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then 
		warn("❌ Missing humanoid or rootpart")
		return 
	end

	if humanoid.Health <= 0 then
		warn("❌ Player is dead")
		return
	end

	-- Check cooldown
	local lastUse = COOLDOWNS[player]
	if lastUse and tick() - lastUse < COOLDOWN_TIME then
		local timeLeft = COOLDOWN_TIME - (tick() - lastUse)
		warn("⏰ Ability on cooldown:", string.format("%.1f", timeLeft), "seconds")
		return
	end

	-- Update cooldown
	COOLDOWNS[player] = tick()

	-- START EVERYTHING SIMULTANEOUSLY
	print("🚀 STARTING ALL EFFECTS SIMULTANEOUSLY!")

	-- 1. Freeze player
	freezePlayer(character, true)

	-- 2. Spawn VFX attached to player (so it follows them)
	local vfx = spawnJumpWindVFX(character)

	-- 3. Start animation IMMEDIATELY
	local animTrack = animationCache[player]
	if not animTrack then
		animTrack = preloadAnimation(player)
	end
	if animTrack then
		animTrack.Priority = Enum.AnimationPriority.Action
		animTrack:Play()
		print("▶️ Animation started")
	end

	-- 4. Unanchor for jump immediately after starting effects
	rootPart.Anchored = false

	-- 5. Apply jump force
	print("🚀 Applying jump force:", JUMP_POWER)
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
	bodyVelocity.Velocity = Vector3.new(0, JUMP_POWER, 0)
	bodyVelocity.Parent = rootPart

	-- Handle hover effect
	task.spawn(function()
		-- Wait for hover timing
		task.wait(HOVER_DELAY)

		-- Remove upward velocity
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end

		-- Create hover effect
		print("🎈 Creating hover effect")
		local bodyPosition = Instance.new("BodyPosition")
		bodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
		bodyPosition.Position = rootPart.Position
		bodyPosition.D = 2000
		bodyPosition.P = 10000
		bodyPosition.Parent = rootPart

		-- Hold position
		task.wait(HOVER_DURATION)

		-- Remove hover
		if bodyPosition and bodyPosition.Parent then
			bodyPosition:Destroy()
		end

		-- Unfreeze player
		freezePlayer(character, false)

		print("========== UPAIR SLASH COMPLETE ==========\n")
	end)
end

-- Handle character spawning
local function onCharacterAdded(player, character)
	print("🎭 Character added for", player.Name)
	task.wait(0.5)
	preloadAnimation(player)
end

-- Handle remote event
upairSlashRemote.OnServerEvent:Connect(function(player)
	print("\n📨 Upair slash request from", player.Name)

	-- Verify combat permission
	local canUseCombat = player:GetAttribute("CanUseCombat")
	if not canUseCombat then
		warn("❌ Player cannot use combat abilities")
		return
	end

	performUpairSlash(player)
end)

-- Player connections
Players.PlayerAdded:Connect(function(player)
	print("👋 Player joined:", player.Name)

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

print("✅ UpairSlashServer loaded!")