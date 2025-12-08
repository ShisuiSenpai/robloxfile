--[[
	AnimationController (LocalScript)
	Location: StarterPlayerScripts/AnimationController
	
	Standalone animation system.
	Press R to play animation with:
	- Smooth camera zoom in
	- Kanji VFX above head
	- Camera shake effect
	- Smooth zoom out
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
local ZOOM_IN_FOV = 50 -- Field of view when zoomed in (default is 70)
local ZOOM_IN_TIME = 0.2 -- How fast to zoom in
local ZOOM_OUT_TIME = 0.4 -- How fast to zoom out
local ZOOM_HOLD_TIME = 0.3 -- How long to stay zoomed in
local ZOOM_EASING_IN = Enum.EasingStyle.Back
local ZOOM_EASING_OUT = Enum.EasingStyle.Quad

-- Camera Shake Settings
local SHAKE_MAGNITUDE = 5 -- How strong the shake is
local SHAKE_ROUGHNESS = 12 -- How rough/fast the shake is
local SHAKE_FADE_IN = 0 -- Instant shake
local SHAKE_FADE_OUT = 0.5 -- Smooth fade out
local SHAKE_POSITION_INFLUENCE = Vector3.new(0.1, 0.1, 0.1)
local SHAKE_ROTATION_INFLUENCE = Vector3.new(2, 2, 2)

-- ============================================
-- REFERENCES
-- ============================================

local VFXFolder = ReplicatedStorage:WaitForChild("VFX")
local KanjiTemplate = VFXFolder:WaitForChild("kanji")

-- CameraShaker Module (make sure it's in ReplicatedStorage or adjust path)
local CameraShaker = nil
local camShake = nil

-- Try to load CameraShaker
local function loadCameraShaker()
	local success, result = pcall(function()
		return require(ReplicatedStorage:WaitForChild("CameraShaker", 5))
	end)
	
	if success and result then
		CameraShaker = result
		print("[Animation] CameraShaker module loaded!")
		return true
	else
		warn("[Animation] CameraShaker module not found in ReplicatedStorage. Shake disabled.")
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
local cameraConnection = nil

-- ============================================
-- CAMERA SHAKE SYSTEM
-- ============================================

local function initCameraShaker()
	if not CameraShaker then return false end
	
	-- Create camera shaker instance
	camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
		-- Apply shake to camera
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
		print("[Animation] Shake skipped - CameraShaker not available")
		return 
	end
	
	-- Create custom shake instance
	local shakeInstance = CameraShaker.CameraShakeInstance.new(
		SHAKE_MAGNITUDE,
		SHAKE_ROUGHNESS,
		SHAKE_FADE_IN,
		SHAKE_FADE_OUT
	)
	shakeInstance.PositionInfluence = SHAKE_POSITION_INFLUENCE
	shakeInstance.RotationInfluence = SHAKE_ROTATION_INFLUENCE
	
	camShake:Shake(shakeInstance)
	print("[Animation] Camera shake triggered!")
end

-- ============================================
-- CAMERA ZOOM SYSTEM
-- ============================================

local function zoomIn()
	if isZooming then return end
	isZooming = true
	
	-- Store original FOV
	originalFOV = camera.FieldOfView
	
	-- Tween to zoomed FOV
	local tweenInfo = TweenInfo.new(
		ZOOM_IN_TIME,
		ZOOM_EASING_IN,
		Enum.EasingDirection.Out
	)
	
	local tween = TweenService:Create(camera, tweenInfo, {
		FieldOfView = ZOOM_IN_FOV
	})
	
	tween:Play()
	print("[Animation] Zooming in...")
end

local function zoomOut()
	if not isZooming then return end
	
	-- Tween back to original FOV
	local tweenInfo = TweenInfo.new(
		ZOOM_OUT_TIME,
		ZOOM_EASING_OUT,
		Enum.EasingDirection.Out
	)
	
	local tween = TweenService:Create(camera, tweenInfo, {
		FieldOfView = originalFOV
	})
	
	tween:Play()
	
	tween.Completed:Connect(function()
		isZooming = false
	end)
	
	print("[Animation] Zooming out...")
end

-- Full zoom sequence: zoom in -> hold -> zoom out
local function doZoomSequence()
	-- Zoom in
	zoomIn()
	
	-- Wait for zoom in + hold time, then zoom out
	task.delay(ZOOM_IN_TIME + ZOOM_HOLD_TIME, function()
		zoomOut()
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

local function spawnKanjiVFX()
	local character = player.Character
	if not character then return end
	
	local head = character:FindFirstChild("Head")
	if not head then return end
	
	local kanjiClone = KanjiTemplate:Clone()
	
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
		if kanjiClone and kanjiClone.Parent then
			if kanjiClone:IsA("BasePart") then
				local tweenInfo = TweenInfo.new(KANJI_FADE_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local tween = TweenService:Create(kanjiClone, tweenInfo, {
					Size = Vector3.new(0.1, 0.1, 0.1)
				})
				tween:Play()
				tween.Completed:Connect(function()
					kanjiClone:Destroy()
				end)
			else
				kanjiClone:Destroy()
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

local function playAnimation()
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
	
	if animationTrack.IsPlaying then
		animationTrack:Stop(ANIMATION_FADE_OUT)
		task.wait(ANIMATION_FADE_OUT)
	end
	
	isOnCooldown = true
	lastPlayTime = currentTime
	
	-- === THE COOL EFFECT SEQUENCE ===
	
	-- 1. Start zoom in
	doZoomSequence()
	
	-- 2. Play animation
	animationTrack:Play(ANIMATION_FADE_IN, ANIMATION_SPEED)
	print("[Animation] Playing!")
	
	-- 3. Spawn Kanji VFX + Camera shake after delay
	task.delay(KANJI_DELAY_AFTER_ANIM, function()
		spawnKanjiVFX()
		doShake() -- Shake when Kanji appears!
	end)
	
	-- Reset cooldown
	task.delay(COOLDOWN, function()
		isOnCooldown = false
	end)
	
	return true
end

local function stopAnimation()
	if animationTrack and animationTrack.IsPlaying then
		animationTrack:Stop(ANIMATION_FADE_OUT)
		print("[Animation] Stopped")
	end
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
	unloadAnimation()
	
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	
	task.wait(0.5)
	loadAnimation(character)
end

local function onCharacterRemoving(character)
	unloadAnimation()
end

-- ============================================
-- INITIALIZATION
-- ============================================

local function init()
	-- Load CameraShaker module
	loadCameraShaker()
	
	-- Initialize camera shaker
	if CameraShaker then
		initCameraShaker()
	end
	
	-- Connect input
	UserInputService.InputBegan:Connect(onInputBegan)
	
	-- Connect character events
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
	print("  - Zoom: " .. originalFOV .. " → " .. ZOOM_IN_FOV .. " FOV")
	print("  - Shake: Magnitude=" .. SHAKE_MAGNITUDE)
	print("  - Cooldown: " .. COOLDOWN .. " seconds")
	print("  - ⚠️ Set your ANIMATION_ID!")
	print("  - ⚠️ Put CameraShaker in ReplicatedStorage!")
	print("========================================")
end

init()
