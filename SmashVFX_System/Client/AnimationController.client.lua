--[[
	AnimationController (LocalScript)
	Location: StarterPlayerScripts/AnimationController
	
	Standalone animation system.
	Press R to play animation with:
	- Smooth camera zoom in
	- Kanji VFX above head
	- Camera shake effect
	- Smooth zoom out
	
	Press R again to cancel and return to normal.
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Player references
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ============================================
-- CONFIGURATION
-- ============================================

-- Animation Settings
local ANIMATION_ID = "rbxassetid://YOUR_ANIMATION_ID_HERE" -- ⚠️ Replace with your animation ID!

local ACTIVATION_KEY = Enum.KeyCode.R
local COOLDOWN = 1.5

local ANIMATION_PRIORITY = Enum.AnimationPriority.Action4
local ANIMATION_FADE_IN = 0.1
local ANIMATION_FADE_OUT = 0.15
local ANIMATION_SPEED = 1

local ALLOW_WHILE_JUMPING = false
local ALLOW_WHILE_FALLING = false
local ALLOW_WHILE_SEATED = false

-- Kanji VFX Settings
local KANJI_OFFSET = Vector3.new(1.5, 2.5, 0)
local KANJI_LIFETIME = 1.5
local KANJI_FADE_IN_TIME = 0.15
local KANJI_FADE_OUT_TIME = 0.3
local KANJI_DELAY_AFTER_ANIM = 0.1

-- Camera Zoom Settings
local ZOOM_IN_FOV = 50
local ZOOM_IN_TIME = 0.2
local ZOOM_OUT_TIME = 0.4
local ZOOM_HOLD_TIME = 0.3
local ZOOM_EASING_IN = Enum.EasingStyle.Back
local ZOOM_EASING_OUT = Enum.EasingStyle.Quad
local CANCEL_ZOOM_TIME = 0.2 -- Fast zoom out when cancelled

-- Camera Shake Settings
local SHAKE_MAGNITUDE = 5
local SHAKE_ROUGHNESS = 12
local SHAKE_FADE_IN = 0
local SHAKE_FADE_OUT = 0.5
local SHAKE_POSITION_INFLUENCE = Vector3.new(0.1, 0.1, 0.1)
local SHAKE_ROTATION_INFLUENCE = Vector3.new(2, 2, 2)

-- Sound Settings
local SOUND_ACTIVATION_ID = "rbxassetid://9125402735" -- Sound when pressing R / animation starts
local SOUND_ACTIVATION_VOLUME = 0.8
local SOUND_ACTIVATION_PITCH = 1

local SOUND_KANJI_ID = "rbxassetid://9113869830" -- Sound when Kanji VFX appears
local SOUND_KANJI_VOLUME = 0.6
local SOUND_KANJI_PITCH = 1.2

local SOUND_CANCEL_ID = "rbxassetid://9112854440" -- Sound when cancelled (optional)
local SOUND_CANCEL_VOLUME = 0.4
local SOUND_CANCEL_PITCH = 0.8

-- ============================================
-- REFERENCES
-- ============================================

local VFXFolder = ReplicatedStorage:WaitForChild("VFX")
local KanjiTemplate = VFXFolder:WaitForChild("kanji")

-- CameraShaker Module
local CameraShaker = nil
local camShake = nil

local function loadCameraShaker()
	local success, result = pcall(function()
		return require(ReplicatedStorage:WaitForChild("CameraShaker", 5))
	end)
	
	if success and result then
		CameraShaker = result
		print("[Animation] CameraShaker module loaded!")
		return true
	else
		warn("[Animation] CameraShaker module not found. Shake disabled.")
		return false
	end
end

-- ============================================
-- STATE
-- ============================================

local animationTrack = nil
local animationInstance = nil
local isOnCooldown = false
local lastPlayTime = 0
local originalFOV = 70
local isZooming = false
local isPlaying = false -- Track if animation sequence is active
local activeKanji = nil -- Track active Kanji VFX for cleanup
local currentZoomTween = nil -- Track current zoom tween for cancellation
local activeSound = nil -- Track active sound for cleanup

-- ============================================
-- SOUND SYSTEM
-- ============================================

-- Play a sound attached to the player (local, always audible)
local function playLocalSound(soundId, volume, pitch)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return nil end
	
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = playerGui
	sound:Play()
	
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	
	return sound
end

-- Play a sound at a position in the world (3D sound)
local function playSoundAtPosition(soundId, position, volume, pitch)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.PlaybackSpeed = pitch or 1
	sound.RollOffMaxDistance = 100
	sound.RollOffMinDistance = 10
	sound.RollOffMode = Enum.RollOffMode.Linear
	
	local soundPart = Instance.new("Part")
	soundPart.Name = "SoundEmitter"
	soundPart.Anchored = true
	soundPart.CanCollide = false
	soundPart.CanQuery = false
	soundPart.CanTouch = false
	soundPart.Transparency = 1
	soundPart.Size = Vector3.new(0.1, 0.1, 0.1)
	soundPart.Position = position
	soundPart.Parent = workspace
	
	sound.Parent = soundPart
	sound:Play()
	
	sound.Ended:Connect(function()
		soundPart:Destroy()
	end)
	
	Debris:AddItem(soundPart, sound.TimeLength + 1)
	
	return sound
end

-- Play activation sound
local function playActivationSound()
	activeSound = playLocalSound(
		SOUND_ACTIVATION_ID, 
		SOUND_ACTIVATION_VOLUME, 
		SOUND_ACTIVATION_PITCH + (math.random(-10, 10) / 100) -- Slight pitch variation
	)
end

-- Play Kanji appear sound
local function playKanjiSound()
	local character = player.Character
	if character then
		local head = character:FindFirstChild("Head")
		if head then
			playSoundAtPosition(
				SOUND_KANJI_ID, 
				head.Position + Vector3.new(0, 2, 0), 
				SOUND_KANJI_VOLUME, 
				SOUND_KANJI_PITCH + (math.random(-10, 10) / 100)
			)
		else
			playLocalSound(SOUND_KANJI_ID, SOUND_KANJI_VOLUME, SOUND_KANJI_PITCH)
		end
	end
end

-- Play cancel sound
local function playCancelSound()
	playLocalSound(
		SOUND_CANCEL_ID, 
		SOUND_CANCEL_VOLUME, 
		SOUND_CANCEL_PITCH
	)
end

-- Stop active sound
local function stopActiveSound()
	if activeSound and activeSound.Parent then
		activeSound:Stop()
		activeSound:Destroy()
		activeSound = nil
	end
end

-- ============================================
-- CAMERA SHAKE SYSTEM
-- ============================================

local function initCameraShaker()
	if not CameraShaker then return false end
	
	camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
		if camera then
			camera.CFrame = camera.CFrame * shakeCFrame
		end
	end)
	
	camShake:Start()
	print("[Animation] Camera shaker initialized!")
	return true
end

local function doShake()
	if not camShake or not CameraShaker then 
		return 
	end
	
	local shakeInstance = CameraShaker.CameraShakeInstance.new(
		SHAKE_MAGNITUDE,
		SHAKE_ROUGHNESS,
		SHAKE_FADE_IN,
		SHAKE_FADE_OUT
	)
	shakeInstance.PositionInfluence = SHAKE_POSITION_INFLUENCE
	shakeInstance.RotationInfluence = SHAKE_ROTATION_INFLUENCE
	
	camShake:Shake(shakeInstance)
end

local function stopShake()
	if camShake then
		camShake:StopSustained(0.1)
	end
end

-- ============================================
-- CAMERA ZOOM SYSTEM
-- ============================================

local function zoomIn()
	if isZooming then return end
	isZooming = true
	
	originalFOV = camera.FieldOfView
	
	local tweenInfo = TweenInfo.new(
		ZOOM_IN_TIME,
		ZOOM_EASING_IN,
		Enum.EasingDirection.Out
	)
	
	currentZoomTween = TweenService:Create(camera, tweenInfo, {
		FieldOfView = ZOOM_IN_FOV
	})
	
	currentZoomTween:Play()
end

local function zoomOut(fast)
	if not isZooming then return end
	
	-- Cancel any current zoom tween
	if currentZoomTween then
		currentZoomTween:Cancel()
	end
	
	local duration = fast and CANCEL_ZOOM_TIME or ZOOM_OUT_TIME
	
	local tweenInfo = TweenInfo.new(
		duration,
		ZOOM_EASING_OUT,
		Enum.EasingDirection.Out
	)
	
	currentZoomTween = TweenService:Create(camera, tweenInfo, {
		FieldOfView = originalFOV
	})
	
	currentZoomTween:Play()
	
	currentZoomTween.Completed:Connect(function()
		isZooming = false
		currentZoomTween = nil
	end)
end

local function doZoomSequence()
	zoomIn()
	
	task.delay(ZOOM_IN_TIME + ZOOM_HOLD_TIME, function()
		-- Only zoom out if still playing (not cancelled)
		if isPlaying then
			zoomOut(false)
		end
	end)
end

-- ============================================
-- KANJI VFX SYSTEM
-- ============================================

local function getAllParticleEmitters(parent)
	local emitters = {}
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			table.insert(emitters, descendant)
		end
	end
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			table.insert(emitters, child)
		end
	end
	return emitters
end

local function emitAllParticles(vfxPart, emitCount)
	local emitters = getAllParticleEmitters(vfxPart)
	for _, emitter in ipairs(emitters) do
		emitter.Enabled = false
		emitter:Emit(emitCount or emitter:GetAttribute("EmitCount") or 10)
	end
end

local function destroyKanji()
	if activeKanji and activeKanji.Parent then
		-- Quick fade out
		if activeKanji:IsA("BasePart") then
			local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			local tween = TweenService:Create(activeKanji, tweenInfo, {
				Size = Vector3.new(0.1, 0.1, 0.1)
			})
			tween:Play()
			tween.Completed:Connect(function()
				if activeKanji then
					activeKanji:Destroy()
					activeKanji = nil
				end
			end)
		else
			activeKanji:Destroy()
			activeKanji = nil
		end
	end
end

local function spawnKanjiVFX()
	local character = player.Character
	if not character then return end
	
	local head = character:FindFirstChild("Head")
	if not head then return end
	
	-- Destroy any existing Kanji first
	destroyKanji()
	
	local kanjiClone = KanjiTemplate:Clone()
	activeKanji = kanjiClone -- Track for cleanup
	
	local headCFrame = head.CFrame
	local offsetPosition = headCFrame.Position + 
		(headCFrame.RightVector * KANJI_OFFSET.X) +
		(Vector3.new(0, KANJI_OFFSET.Y, 0)) +
		(headCFrame.LookVector * KANJI_OFFSET.Z)
	
	if kanjiClone:IsA("BasePart") then
		kanjiClone.CFrame = CFrame.new(offsetPosition)
		kanjiClone.Anchored = true
		kanjiClone.CanCollide = false
		kanjiClone.CanQuery = false
		kanjiClone.CanTouch = false
		kanjiClone.Transparency = 1
	elseif kanjiClone:IsA("Model") then
		if kanjiClone.PrimaryPart then
			kanjiClone:SetPrimaryPartCFrame(CFrame.new(offsetPosition))
		else
			local firstPart = kanjiClone:FindFirstChildWhichIsA("BasePart")
			if firstPart then
				firstPart.CFrame = CFrame.new(offsetPosition)
			end
		end
	end
	
	kanjiClone.Parent = workspace
	
	local originalSize = nil
	if kanjiClone:IsA("BasePart") then
		originalSize = kanjiClone.Size
		kanjiClone.Size = Vector3.new(0.1, 0.1, 0.1)
	end
	
	if kanjiClone:IsA("BasePart") and originalSize then
		local tweenInfo = TweenInfo.new(KANJI_FADE_IN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local tween = TweenService:Create(kanjiClone, tweenInfo, {
			Size = originalSize
		})
		tween:Play()
		tween.Completed:Wait()
	else
		task.wait(KANJI_FADE_IN_TIME)
	end
	
	emitAllParticles(kanjiClone)
	
	task.delay(KANJI_LIFETIME, function()
		if kanjiClone and kanjiClone.Parent and kanjiClone == activeKanji then
			if kanjiClone:IsA("BasePart") then
				local tweenInfo = TweenInfo.new(KANJI_FADE_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local tween = TweenService:Create(kanjiClone, tweenInfo, {
					Size = Vector3.new(0.1, 0.1, 0.1)
				})
				tween:Play()
				tween.Completed:Connect(function()
					if kanjiClone then
						kanjiClone:Destroy()
						if activeKanji == kanjiClone then
							activeKanji = nil
						end
					end
				end)
			else
				kanjiClone:Destroy()
				activeKanji = nil
			end
		end
	end)
	
	Debris:AddItem(kanjiClone, KANJI_LIFETIME + KANJI_FADE_OUT_TIME + 1)
end

-- ============================================
-- ANIMATION FUNCTIONS
-- ============================================

local function getAnimator(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	
	return animator
end

local function loadAnimation(character)
	local animator = getAnimator(character)
	if not animator then return nil end
	
	animationInstance = Instance.new("Animation")
	animationInstance.AnimationId = ANIMATION_ID
	
	animationTrack = animator:LoadAnimation(animationInstance)
	animationTrack.Priority = ANIMATION_PRIORITY
	
	print("[Animation] Loaded successfully")
	return animationTrack
end

local function unloadAnimation()
	if animationTrack then
		animationTrack:Stop(0)
		animationTrack:Destroy()
		animationTrack = nil
	end
	
	if animationInstance then
		animationInstance:Destroy()
		animationInstance = nil
	end
end

local function canPlayAnimation()
	local character = player.Character
	if not character then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	
	if humanoid.Health <= 0 then
		return false
	end
	
	local state = humanoid:GetState()
	
	if not ALLOW_WHILE_JUMPING and state == Enum.HumanoidStateType.Jumping then
		return false
	end
	
	if not ALLOW_WHILE_FALLING and state == Enum.HumanoidStateType.Freefall then
		return false
	end
	
	if not ALLOW_WHILE_SEATED and state == Enum.HumanoidStateType.Seated then
		return false
	end
	
	return true
end

-- Cancel everything and return to normal
local function cancelAnimation()
	if not isPlaying then return end
	
	print("[Animation] Cancelled!")
	
	isPlaying = false
	
	-- Play cancel sound
	playCancelSound()
	
	-- Stop active sound
	stopActiveSound()
	
	-- Stop animation
	if animationTrack and animationTrack.IsPlaying then
		animationTrack:Stop(ANIMATION_FADE_OUT)
	end
	
	-- Fast zoom out
	zoomOut(true)
	
	-- Stop shake
	stopShake()
	
	-- Destroy Kanji VFX
	destroyKanji()
	
	-- Reset cooldown so they can play again
	task.delay(0.3, function()
		isOnCooldown = false
	end)
end

local function playAnimation()
	-- If already playing, cancel instead
	if isPlaying then
		cancelAnimation()
		return true
	end
	
	if not canPlayAnimation() then
		return false
	end
	
	if isOnCooldown then
		return false
	end
	
	local currentTime = tick()
	if currentTime - lastPlayTime < COOLDOWN then
		return false
	end
	
	if not animationTrack then
		local character = player.Character
		if character then
			loadAnimation(character)
		end
	end
	
	if not animationTrack then
		warn("[Animation] No animation track loaded!")
		return false
	end
	
	isOnCooldown = true
	lastPlayTime = currentTime
	isPlaying = true -- Mark as playing
	
	-- === THE COOL EFFECT SEQUENCE ===
	
	-- 1. Play activation sound
	playActivationSound()
	
	-- 2. Start zoom in
	doZoomSequence()
	
	-- 3. Play animation
	animationTrack:Play(ANIMATION_FADE_IN, ANIMATION_SPEED)
	print("[Animation] Playing! (Press R again to cancel)")
	
	-- 4. Spawn Kanji VFX + Camera shake + Kanji sound after delay
	task.delay(KANJI_DELAY_AFTER_ANIM, function()
		if isPlaying then -- Only if not cancelled
			spawnKanjiVFX()
			playKanjiSound() -- Sound when Kanji appears
			doShake()
		end
	end)
	
	-- Track when animation ends naturally
	local connection
	connection = animationTrack.Stopped:Connect(function()
		if isPlaying then
			isPlaying = false
		end
		connection:Disconnect()
	end)
	
	-- Reset cooldown after full sequence
	task.delay(COOLDOWN, function()
		if not isPlaying then -- Only reset if not actively playing
			isOnCooldown = false
		end
	end)
	
	return true
end

-- ============================================
-- INPUT HANDLING
-- ============================================

local function onInputBegan(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	
	if input.KeyCode == ACTIVATION_KEY then
		playAnimation()
	end
end

-- ============================================
-- CHARACTER HANDLING
-- ============================================

local function onCharacterAdded(character)
	-- Cancel any active animation
	cancelAnimation()
	unloadAnimation()
	
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	
	task.wait(0.5)
	loadAnimation(character)
	
	-- Reset state
	isPlaying = false
	isOnCooldown = false
	isZooming = false
end

local function onCharacterRemoving(character)
	cancelAnimation()
	unloadAnimation()
end

-- ============================================
-- INITIALIZATION
-- ============================================

local function init()
	loadCameraShaker()
	
	if CameraShaker then
		initCameraShaker()
	end
	
	UserInputService.InputBegan:Connect(onInputBegan)
	
	player.CharacterAdded:Connect(onCharacterAdded)
	player.CharacterRemoving:Connect(onCharacterRemoving)
	
	if player.Character then
		task.spawn(function()
			onCharacterAdded(player.Character)
		end)
	end
	
	print("========================================")
	print("[Animation] Controller initialized!")
	print("  - Press " .. ACTIVATION_KEY.Name .. " to play")
	print("  - Press " .. ACTIVATION_KEY.Name .. " again to CANCEL")
	print("  - Cooldown: " .. COOLDOWN .. " seconds")
	print("  - ⚠️ Set your ANIMATION_ID!")
	print("  - ⚠️ Put CameraShaker in ReplicatedStorage!")
	print("========================================")
end

init()
