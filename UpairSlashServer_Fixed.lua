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

-- Debug mode (set to true to see debug markers)
local DEBUG_MODE = false

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

-- Fix particle emitter properties for visibility
local function fixEmitterProperties(emitter)
	-- Ensure emitter has a texture
	if not emitter.Texture or emitter.Texture == "" then
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		print("  ⚠️ Added missing texture to", emitter.Name)
	end
	
	-- Check and fix size
	local size = emitter.Size
	if typeof(size) == "NumberSequence" then
		local keypoints = size.Keypoints
		local needsFix = false
		
		-- Check if all keypoints are zero or too small
		for _, kp in pairs(keypoints) do
			if kp.Value < 0.1 then
				needsFix = true
				break
			end
		end
		
		if needsFix then
			-- Create a reasonable size sequence
			emitter.Size = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 1.5),
				NumberSequenceKeypoint.new(1, 0.5)
			}
			print("  ⚠️ Fixed zero/small size for", emitter.Name)
		end
	end
	
	-- Check and fix lifetime
	local lifetime = emitter.Lifetime
	if typeof(lifetime) == "NumberRange" then
		if lifetime.Max < 0.5 then
			emitter.Lifetime = NumberRange.new(0.5, 1.5)
			print("  ⚠️ Extended lifetime for", emitter.Name)
		end
	end
	
	-- Ensure some light emission for visibility
	if emitter.LightEmission < 0.2 then
		emitter.LightEmission = 0.3
	end
	
	-- Ensure it's not fully transparent
	local transparency = emitter.Transparency
	if typeof(transparency) == "NumberSequence" then
		local firstKP = transparency.Keypoints[1]
		if firstKP and firstKP.Value >= 0.9 then
			-- Create a fade sequence
			emitter.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.7, 0.3),
				NumberSequenceKeypoint.new(1, 1)
			}
			print("  ⚠️ Fixed transparency for", emitter.Name)
		end
	end
end

-- Spawn JumpWind VFX with fixed visibility
local function spawnJumpWindVFX(character)
	print("🌪️ Spawning VFX...")
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Get VFX from storage
	local vfxOriginal = ReplicatedStorage
		:WaitForChild("Assets")
		:WaitForChild("Abilities")
		:WaitForChild("VFX")
		:WaitForChild("UpSlashAbility")
		:WaitForChild("jumpwind")

	if not vfxOriginal then
		warn("❌ VFX not found!")
		return
	end

	-- Clone VFX
	local vfxClone = vfxOriginal:Clone()
	vfxClone.Name = "JumpWindVFX"
	vfxClone.Transparency = 1 -- Keep part invisible
	vfxClone.CanCollide = false
	vfxClone.Massless = true
	
	-- Parent to workspace for visibility
	vfxClone.Parent = workspace
	
	-- Position at player's feet and update position
	local updateConnection
	updateConnection = RunService.Heartbeat:Connect(function()
		if vfxClone and vfxClone.Parent and rootPart and rootPart.Parent then
			-- Calculate ground position below player
			local groundOffset = Vector3.new(0, -3, 0)
			vfxClone.CFrame = rootPart.CFrame + groundOffset
		else
			updateConnection:Disconnect()
		end
	end)
	
	-- Store connection for cleanup
	vfxClone:SetAttribute("UpdateConnection", true)
	
	-- Initial position
	vfxClone.CFrame = rootPart.CFrame + Vector3.new(0, -3, 0)

	-- Process all emitters with fixes
	local emitterCount = 0
	local emittersToFire = {}
	
	local function processEmitters(parent, depth)
		depth = depth or 0
		for _, child in pairs(parent:GetChildren()) do
			if child:IsA("ParticleEmitter") then
				emitterCount = emitterCount + 1
				
				-- Fix properties BEFORE emitting
				fixEmitterProperties(child)
				
				-- Disable continuous emission
				child.Enabled = false
				
				-- Add to emit list
				table.insert(emittersToFire, child)
				
			elseif child:IsA("Attachment") then
				-- Process attachments recursively
				processEmitters(child, depth + 1)
			end
		end
	end
	
	-- Process all levels of the VFX hierarchy
	processEmitters(vfxClone)
	
	-- Also check the main attachments mentioned
	local attachment1 = vfxClone:FindFirstChild("Attachment")
	if attachment1 then processEmitters(attachment1) end
	
	local attachment2 = vfxClone:FindFirstChild("Attachment2")
	if attachment2 then 
		processEmitters(attachment2)
		
		-- Check Debris inside Attachment2
		local debris = attachment2:FindFirstChild("Debris")
		if debris then
			processEmitters(debris)
			
			-- Check sub-attachments in Debris
			local dust2 = debris:FindFirstChild("Dust2")
			if dust2 then processEmitters(dust2) end
			
			local groundGusts = debris:FindFirstChild("Ground Gusts")
			if groundGusts then processEmitters(groundGusts) end
		end
	end
	
	print("📊 Found", emitterCount, "emitters total")
	
	-- EMIT ALL PARTICLES AT ONCE
	if #emittersToFire > 0 then
		print("💥 Emitting particles from all emitters...")
		
		for i, emitter in pairs(emittersToFire) do
			local emitCount = math.clamp(math.floor(emitter.Rate * 0.75), 15, 40)
			emitter:Emit(emitCount)
			
			if i <= 5 then -- Log first 5 for brevity
				print("  ✨", emitter.Name, "->", emitCount, "particles")
			end
		end
		
		print("✅ All particles emitted!")
	else
		warn("❌ No emitters found to fire!")
	end
	
	-- Add visual indicators if in debug mode
	if DEBUG_MODE then
		local marker = Instance.new("Part")
		marker.Name = "VFX_Position_Marker"
		marker.Size = Vector3.new(4, 0.2, 4)
		marker.Material = Enum.Material.Neon
		marker.BrickColor = BrickColor.new("Lime green")
		marker.Transparency = 0.5
		marker.Anchored = true
		marker.CanCollide = false
		marker.CFrame = vfxClone.CFrame
		marker.Parent = workspace
		Debris:AddItem(marker, 3)
		
		-- Add light for visibility
		local light = Instance.new("PointLight")
		light.Brightness = 3
		light.Color = Color3.new(0.5, 1, 0.5)
		light.Range = 30
		light.Parent = marker
	end
	
	-- Cleanup
	task.delay(4, function()
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
print("📝 Set DEBUG_MODE = true to see position markers")