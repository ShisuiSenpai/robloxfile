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
		
		-- Clean up stored attributes
		humanoid:SetAttribute("StoredWalkSpeed", nil)
		humanoid:SetAttribute("StoredJumpPower", nil)
	end
end

-- Spawn JumpWind VFX with FIXED particle emission
local function spawnJumpWindVFX(position)
	print("🌪️ Starting JumpWind VFX spawn process...")

	-- Navigate to VFX folder
	local assetsFolder = ReplicatedStorage:WaitForChild("Assets", 5)
	if not assetsFolder then 
		warn("❌ Assets folder not found!") 
		return 
	end

	local abilitiesFolder = assetsFolder:WaitForChild("Abilities", 5)
	if not abilitiesFolder then 
		warn("❌ Abilities folder not found!") 
		return 
	end

	local vfxFolder = abilitiesFolder:WaitForChild("VFX", 5)
	if not vfxFolder then 
		warn("❌ VFX folder not found!") 
		return 
	end

	local upSlashFolder = vfxFolder:WaitForChild("UpSlashAbility", 5)
	if not upSlashFolder then 
		warn("❌ UpSlashAbility folder not found!") 
		return 
	end

	local jumpWindVFX = upSlashFolder:WaitForChild("jumpwind", 5)
	if not jumpWindVFX then
		warn("❌ jumpwind part not found in UpSlashAbility!")
		return
	end

	print("✅ Found jumpwind VFX part")

	-- Clone VFX
	local vfxClone = jumpWindVFX:Clone()
	vfxClone.Name = "JumpWindEffect_" .. tick()
	vfxClone.Anchored = true
	vfxClone.CanCollide = false
	vfxClone.Transparency = 1
	vfxClone.Position = position
	vfxClone.Parent = workspace

	print("📍 VFX cloned to workspace at position:", position)

	-- FIXED: Disable all particle emitters FIRST, then emit once
	local function disableAllEmitters(parent)
		for _, child in pairs(parent:GetDescendants()) do
			if child:IsA("ParticleEmitter") then
				child.Enabled = false -- Ensure no continuous emission
				print("🔇 Disabled ParticleEmitter:", child:GetFullName())
			end
		end
	end

	-- First, disable all emitters to prevent spam
	disableAllEmitters(vfxClone)
	
	-- Wait a frame to ensure all emitters are properly disabled
	RunService.Heartbeat:Wait()

	-- Find and emit ALL ParticleEmitters ONCE
	local totalEmitters = 0
	local emittedParticles = 0

	local function findAndEmitParticles(parent, path)
		path = path or parent.Name

		for _, child in pairs(parent:GetChildren()) do
			local childPath = path .. " > " .. child.Name

			if child:IsA("ParticleEmitter") then
				totalEmitters = totalEmitters + 1

				print("🎨 Found ParticleEmitter:", childPath)
				print("   - Enabled:", child.Enabled)
				print("   - Rate:", child.Rate)
				print("   - Lifetime:", tostring(child.Lifetime))

				-- Emit particles ONCE
				local emitCount = 15 -- Good burst amount
				child:Emit(emitCount)
				emittedParticles = emittedParticles + emitCount

				print("   ✅ Emitted", emitCount, "particles")

			elseif child:IsA("Attachment") then
				print("📎 Found Attachment:", childPath)
				-- Recursively check inside attachments
				findAndEmitParticles(child, childPath)

			elseif #child:GetChildren() > 0 then
				print("📦 Checking container:", childPath, "(" .. child.ClassName .. ")")
				-- Check any other containers
				findAndEmitParticles(child, childPath)
			end
		end
	end

	-- Start the search
	print("\n🔍 Searching for ParticleEmitters...")
	findAndEmitParticles(vfxClone)

	print("\n📊 VFX Summary:")
	print("   - Total ParticleEmitters found:", totalEmitters)
	print("   - Total particles emitted:", emittedParticles)

	if totalEmitters == 0 then
		warn("⚠️ No ParticleEmitters found in the VFX! Check your VFX structure.")
	end

	-- Clean up after particles fade
	Debris:AddItem(vfxClone, 5)
	print("🗑️ VFX will be cleaned up in 5 seconds\n")
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

	-- Get ground position for VFX BEFORE freezing player
	print("🎯 Calculating ground position...")
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {character}

	local groundRay = workspace:Raycast(
		rootPart.Position,
		Vector3.new(0, -50, 0),
		rayParams
	)

	local groundPos
	if groundRay then
		groundPos = groundRay.Position + Vector3.new(0, 0.5, 0)
		print("✅ Ground found at:", groundPos)
	else
		groundPos = rootPart.Position - Vector3.new(0, 3, 0)
		print("⚠️ No ground found, using offset position:", groundPos)
	end

	-- Spawn VFX at ground ONCE
	spawnJumpWindVFX(groundPos)

	-- Freeze player movement
	freezePlayer(character, true)

	-- Get or create animation
	local animTrack = animationCache[player]
	if not animTrack then
		print("📹 Loading animation for first time...")
		animTrack = preloadAnimation(player)
	end

	if animTrack then
		animTrack.Priority = Enum.AnimationPriority.Action
		animTrack:Play()
		print("▶️ Animation playing")
	else
		warn("❌ Failed to load animation")
	end

	-- FIXED: Unanchor for jump but keep movement frozen
	rootPart.Anchored = false

	-- Make player jump up
	print("🚀 Applying jump force:", JUMP_POWER)
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
	bodyVelocity.Velocity = Vector3.new(0, JUMP_POWER, 0)
	bodyVelocity.Parent = rootPart

	-- FIXED: Better hover and cleanup logic
	local cleanupConnection
	cleanupConnection = task.spawn(function()
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

		-- FIXED: Properly unfreeze player after ability completes
		print("🔓 Unfreezing player movement...")
		freezePlayer(character, false)

		print("========== UPAIR SLASH COMPLETE ==========\n")
	end)

	-- Backup cleanup in case anything goes wrong
	task.spawn(function()
		task.wait(3) -- Total ability duration
		
		-- Clean up any remaining body movers
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
		
		local bodyPosition = rootPart:FindFirstChild("BodyPosition")
		if bodyPosition then
			bodyPosition:Destroy()
		end
		
		-- Ensure player is unfrozen
		freezePlayer(character, false)
		print("🔧 Backup cleanup completed")
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