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

-- Spawn JumpWind VFX with TRUE SINGLE SIMULTANEOUS emission
local function spawnJumpWindVFX(position)
	print("🌪️ Starting INSTANT JumpWind VFX...")

	-- Create or get FX folder in workspace
	local fxFolder = workspace:FindFirstChild("FX")
	if not fxFolder then
		fxFolder = Instance.new("Folder")
		fxFolder.Name = "FX"
		fxFolder.Parent = workspace
	end

	-- Navigate to VFX folder
	local assetsFolder = ReplicatedStorage:WaitForChild("Assets", 5)
	if not assetsFolder then return end
	local abilitiesFolder = assetsFolder:WaitForChild("Abilities", 5)
	if not abilitiesFolder then return end
	local vfxFolder = abilitiesFolder:WaitForChild("VFX", 5)
	if not vfxFolder then return end
	local upSlashFolder = vfxFolder:WaitForChild("UpSlashAbility", 5)
	if not upSlashFolder then return end
	local jumpWindVFX = upSlashFolder:WaitForChild("jumpwind", 5)
	if not jumpWindVFX then return end

	-- Clone VFX INSTANTLY
	local vfxClone = jumpWindVFX:Clone()
	vfxClone.Name = "JumpWindEffect_" .. tick()
	vfxClone.Anchored = true
	vfxClone.CanCollide = false
	vfxClone.Transparency = 1  -- Keep invisible (remove debug)
	vfxClone.Position = position
	vfxClone.Parent = fxFolder
	vfxClone.CFrame = CFrame.new(position)

	print("🎯 VFX positioned at:", position)

	-- COLLECT ALL EMITTERS FIRST (no emitting yet!)
	local allEmitters = {}
	local function collectEmitters(parent)
		for _, child in pairs(parent:GetChildren()) do
			if child:IsA("ParticleEmitter") then
				table.insert(allEmitters, child)
			elseif child:IsA("Attachment") or #child:GetChildren() > 0 then
				collectEmitters(child)
			end
		end
	end
	
	collectEmitters(vfxClone)
	print("📊 Found", #allEmitters, "total emitters")

	-- NOW EMIT ALL AT EXACTLY THE SAME TIME
	for _, emitter in pairs(allEmitters) do
		emitter.Enabled = false  -- Ensure burst only
		local emitCount = math.min(50, math.max(15, math.floor(emitter.Rate * 1.0)))
		emitter:Emit(emitCount)
	end
	
	print("💥 ALL PARTICLES EMITTED SIMULTANEOUSLY!")
	
	-- Clean up
	Debris:AddItem(vfxClone, 6)
end

-- Perform the upair slash attack
local function performUpairSlash(player)
	print("\n========== UPAIR SLASH START ==========")
	print("👤 Player:", player.Name)
	print("🕒 Time:", tick())

	local character = player.Character
	if not character then 
		warn("❌ No character found for player")
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
		warn("⏰ Ability on cooldown. Time left:", string.format("%.1f", timeLeft), "seconds")
		return
	end

	-- Update cooldown
	COOLDOWNS[player] = tick()
	print("✅ Cooldown updated")

	-- GET CURRENT POSITION IMMEDIATELY (before any delays)
	local currentPosition = rootPart.Position
	print("📍 Player position captured:", currentPosition)

	-- Calculate ground position IMMEDIATELY
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {character}

	local groundRay = workspace:Raycast(
		currentPosition,
		Vector3.new(0, -50, 0),
		rayParams
	)

	local groundPos
	if groundRay then
		groundPos = groundRay.Position + Vector3.new(0, 0.5, 0)
	else
		groundPos = currentPosition - Vector3.new(0, 3, 0)
	end
	print("🎯 Ground position:", groundPos)

	-- START EVERYTHING SIMULTANEOUSLY
	print("🚀 STARTING ALL EFFECTS SIMULTANEOUSLY!")
	
	-- 1. Freeze player
	freezePlayer(character, true)
	
	-- 2. Spawn VFX INSTANTLY (no waiting)
	spawnJumpWindVFX(groundPos)
	
	-- 3. Start animation INSTANTLY
	local animTrack = animationCache[player]
	if not animTrack then
		animTrack = preloadAnimation(player)
	end
	if animTrack then
		animTrack.Priority = Enum.AnimationPriority.Action
		animTrack:Play()
		print("▶️ Animation playing SIMULTANEOUSLY")
	end

	-- Unanchor for jump but keep movement frozen
	rootPart.Anchored = false

	-- Make player jump up
	print("🚀 Applying jump force:", JUMP_POWER)
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
	bodyVelocity.Velocity = Vector3.new(0, JUMP_POWER, 0)
	bodyVelocity.Parent = rootPart

	-- Handle hover effect
	task.spawn(function()
		-- Wait for the right moment in animation
		print("⏳ Waiting", HOVER_DELAY, "seconds before hover...")
		task.wait(HOVER_DELAY)

		-- Remove upward velocity
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
			print("🛑 Removed upward velocity")
		end

		-- Create hover effect using BodyPosition
		print("🎈 Creating hover effect for", HOVER_DURATION, "seconds")
		local bodyPosition = Instance.new("BodyPosition")
		bodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
		bodyPosition.Position = rootPart.Position
		bodyPosition.D = 2000
		bodyPosition.P = 10000
		bodyPosition.Parent = rootPart

		-- Hold position during slash
		task.wait(HOVER_DURATION)

		-- Remove hover to let player fall
		if bodyPosition and bodyPosition.Parent then
			bodyPosition:Destroy()
			print("🎈 Hover removed - player falling")
		end

		-- Unfreeze player after ability completes
		freezePlayer(character, false)

		print("========== UPAIR SLASH COMPLETE ==========\n")
	end)

	-- Backup velocity removal
	task.spawn(function()
		task.wait(0.2)
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
	end)
end

-- Preload animation when character spawns
local function onCharacterAdded(player, character)
	print("🎭 Character added for", player.Name, "- preloading animation...")
	task.wait(0.5)
	preloadAnimation(player)
end

-- Handle remote event
upairSlashRemote.OnServerEvent:Connect(function(player)
	print("\n📨 Upair slash request received from", player.Name)
	print("🔍 Current attributes:")
	print("   - CanUseCombat:", player:GetAttribute("CanUseCombat"))
	print("   - RoundState:", player:GetAttribute("RoundState"))

	-- Verify player can use combat
	local canUseCombat = player:GetAttribute("CanUseCombat")
	if not canUseCombat then
		warn("❌ Player tried to use upair slash without combat permission:", player.Name)
		warn("   - Make sure player is in a round, not in lobby!")
		return
	end

	print("✅ Combat permission verified")
	performUpairSlash(player)
end)

-- Handle player connections
Players.PlayerAdded:Connect(function(player)
	print("👋 Player joined:", player.Name)

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	print("👋 Player leaving:", player.Name, "- cleaning up...")
	COOLDOWNS[player] = nil
	animationCache[player] = nil
end)

print("✅ UpairSlashServer loaded and ready!")
print("⚠️ Remember: Players need CanUseCombat = true to use abilities!")
print("📁 VFX will now show controlled wind bursts, not explosions!")