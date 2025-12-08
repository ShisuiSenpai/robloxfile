--[[
	SmashVFXController_WithAnimation (LocalScript)
	Location: StarterPlayerScripts/SmashVFXController
	
	INTEGRATED VERSION - Animation + VFX + Sound
	- Hold E to preview
	- Press R to play animation AND spawn VFX at preview location
	- Or Left-click to spawn VFX without animation
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Player references
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ============================================
-- CONFIGURATION
-- ============================================

-- VFX Settings
local MAX_DISTANCE = 40
local VFX_LIFETIME = 2
local TWEEN_IN_TIME = 0.15
local TWEEN_OUT_TIME = 0.4
local COOLDOWN = 1.5

-- Preview Settings
local PREVIEW_SIZE = 7
local PREVIEW_COLOR_VALID = Color3.fromRGB(100, 255, 100)
local PREVIEW_COLOR_INVALID = Color3.fromRGB(255, 100, 100)
local PREVIEW_TRANSPARENCY = 0.5

-- Hitbox Settings (visual debug)
local HITBOX_SIZE = Vector3.new(7, 8, 7)
local HITBOX_COLOR = Color3.fromRGB(255, 0, 0)
local HITBOX_TRANSPARENCY = 0.7
local HITBOX_DURATION = 0.3
local DEBUG_HITBOX = true

-- Ground Detection
local MIN_GROUND_NORMAL_Y = 0.7

-- Sound Settings
local SOUND_SPAWN_ID = "rbxassetid://9125402735"
local SOUND_SPAWN_VOLUME = 1
local SOUND_HIT_ID = "rbxassetid://9125514708"
local SOUND_HIT_VOLUME = 0.8
local SOUND_PREVIEW_SHOW_ID = "rbxassetid://9113869830"
local SOUND_PREVIEW_SHOW_VOLUME = 0.3
local SOUND_PREVIEW_LOOP_ID = "rbxassetid://9112854440"
local SOUND_PREVIEW_LOOP_VOLUME = 0.2

-- Animation Settings
local ANIMATION_ID = "rbxassetid://YOUR_ANIMATION_ID_HERE" -- Replace with your animation!
local ANIMATION_PRIORITY = Enum.AnimationPriority.Action4
local ANIMATION_FADE_IN = 0.1
local ANIMATION_FADE_OUT = 0.15
local ANIMATION_SPEED = 1
local VFX_TRIGGER_TIME = 0.3 -- When to spawn VFX during animation (seconds from start)

-- ============================================
-- REFERENCES
-- ============================================

local VFXFolder = ReplicatedStorage:WaitForChild("VFX")
local SmashVfxTemplate = VFXFolder:WaitForChild("SmashVfx")
local smashVFXEvent = ReplicatedStorage:WaitForChild("SmashVFXEvent")

-- ============================================
-- STATE
-- ============================================

local lastClickTime = 0
local isOnCooldown = false
local isPreviewActive = false
local previewPart = nil
local previewConnection = nil
local previewLoopSound = nil

-- Animation state
local currentAnimation = nil
local animationTrack = nil
local isPlayingAnimation = false

-- Store preview position for R key activation
local lastValidPreviewPosition = nil
local lastValidPreviewNormal = nil

-- ============================================
-- SOUND SYSTEM
-- ============================================

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

local function playLocalSound(soundId, volume, pitch)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	
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

local function createLoopingSound(soundId, volume)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return nil end
	
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.Looped = true
	sound.Parent = playerGui
	
	return sound
end

-- ============================================
-- ANIMATION SYSTEM
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
	
	local animation = Instance.new("Animation")
	animation.AnimationId = ANIMATION_ID
	
	local track = animator:LoadAnimation(animation)
	track.Priority = ANIMATION_PRIORITY
	
	currentAnimation = animation
	animationTrack = track
	
	return track
end

local function unloadAnimation()
	if animationTrack then
		animationTrack:Stop(0)
		animationTrack:Destroy()
		animationTrack = nil
	end
	
	if currentAnimation then
		currentAnimation:Destroy()
		currentAnimation = nil
	end
end

local function canPlayAnimation()
	local character = player.Character
	if not character then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	
	if humanoid.Health <= 0 then return false end
	
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Seated then
		return false
	end
	
	return true
end

-- Play animation and trigger VFX at the right moment
local function playAnimationWithVFX(position, normal)
	local character = player.Character
	if not character then return false end
	
	if not canPlayAnimation() then return false end
	
	-- Load animation if needed
	if not animationTrack then
		loadAnimation(character)
	end
	
	if not animationTrack then
		-- If animation fails, just spawn VFX without animation
		smashVFXEvent:FireServer(position, normal)
		return true
	end
	
	isPlayingAnimation = true
	
	-- Play animation
	animationTrack:Play(ANIMATION_FADE_IN, ANIMATION_SPEED, ANIMATION_SPEED)
	
	-- Spawn VFX after a delay (at the "impact" moment of the animation)
	task.delay(VFX_TRIGGER_TIME, function()
		if isPlayingAnimation then
			smashVFXEvent:FireServer(position, normal)
		end
	end)
	
	-- Track when animation ends
	local connection
	connection = animationTrack.Stopped:Connect(function()
		isPlayingAnimation = false
		connection:Disconnect()
	end)
	
	-- Safety timeout
	task.delay(animationTrack.Length + 0.5, function()
		isPlayingAnimation = false
	end)
	
	return true
end

-- ============================================
-- VISUAL HITBOX
-- ============================================

local function createVisualHitbox(position)
	if not DEBUG_HITBOX then return end
	
	local hitbox = Instance.new("Part")
	hitbox.Name = "SmashVFX_Hitbox_Visual"
	hitbox.Shape = Enum.PartType.Block
	hitbox.Size = HITBOX_SIZE
	hitbox.Color = HITBOX_COLOR
	hitbox.Material = Enum.Material.ForceField
	hitbox.Transparency = HITBOX_TRANSPARENCY
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanQuery = false
	hitbox.CanTouch = false
	hitbox.CastShadow = false
	
	hitbox.CFrame = CFrame.new(position + Vector3.new(0, HITBOX_SIZE.Y / 2, 0))
	
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Adornee = hitbox
	selectionBox.Color3 = HITBOX_COLOR
	selectionBox.LineThickness = 0.05
	selectionBox.Transparency = 0.3
	selectionBox.Parent = hitbox
	
	hitbox.Parent = workspace
	
	local originalSize = hitbox.Size
	hitbox.Size = Vector3.new(HITBOX_SIZE.X, 0.5, HITBOX_SIZE.Z)
	hitbox.CFrame = CFrame.new(position + Vector3.new(0, 0.25, 0))
	
	local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(hitbox, tweenInfo, {
		Size = originalSize,
		CFrame = CFrame.new(position + Vector3.new(0, HITBOX_SIZE.Y / 2, 0))
	})
	tween:Play()
	
	task.delay(HITBOX_DURATION, function()
		if hitbox and hitbox.Parent then
			local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			local fadeTween = TweenService:Create(hitbox, fadeInfo, {
				Transparency = 1,
				Size = Vector3.new(HITBOX_SIZE.X, 0.5, HITBOX_SIZE.Z)
			})
			fadeTween:Play()
			fadeTween.Completed:Connect(function()
				hitbox:Destroy()
			end)
		end
	end)
	
	Debris:AddItem(hitbox, HITBOX_DURATION + 1)
end

-- ============================================
-- PREVIEW SYSTEM
-- ============================================

local function createPreviewPart()
	local part = Instance.new("Part")
	part.Name = "SmashVFX_Preview"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.2, PREVIEW_SIZE, PREVIEW_SIZE)
	part.Color = PREVIEW_COLOR_VALID
	part.Material = Enum.Material.Neon
	part.Transparency = PREVIEW_TRANSPARENCY
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	
	local highlight = Instance.new("Highlight")
	highlight.FillColor = PREVIEW_COLOR_VALID
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0.3
	highlight.Parent = part
	
	return part
end

local function showPreview()
	if isPreviewActive then return end
	isPreviewActive = true
	
	previewPart = createPreviewPart()
	previewPart.Parent = workspace
	
	playLocalSound(SOUND_PREVIEW_SHOW_ID, SOUND_PREVIEW_SHOW_VOLUME, 1.2)
	
	previewLoopSound = createLoopingSound(SOUND_PREVIEW_LOOP_ID, SOUND_PREVIEW_LOOP_VOLUME)
	if previewLoopSound then
		previewLoopSound:Play()
	end
	
	previewPart.Size = Vector3.new(0.2, 0.5, 0.5)
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(previewPart, tweenInfo, {
		Size = Vector3.new(0.2, PREVIEW_SIZE, PREVIEW_SIZE)
	})
	tween:Play()
	
	previewConnection = RunService.RenderStepped:Connect(function()
		if not previewPart or not previewPart.Parent then return end
		
		local position, normal, hitPart, isValidGround = getGroundPosition()
		
		if position and isValidGround then
			previewPart.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
			
			local inRange = isWithinRange(position)
			local targetColor = inRange and PREVIEW_COLOR_VALID or PREVIEW_COLOR_INVALID
			
			previewPart.Color = targetColor
			previewPart.Transparency = PREVIEW_TRANSPARENCY
			
			local highlight = previewPart:FindFirstChild("Highlight")
			if highlight then
				highlight.FillColor = targetColor
			end
			
			-- Store valid position for R key
			if inRange then
				lastValidPreviewPosition = position
				lastValidPreviewNormal = normal
			else
				lastValidPreviewPosition = nil
				lastValidPreviewNormal = nil
			end
		else
			previewPart.Color = Color3.fromRGB(100, 100, 100)
			previewPart.Transparency = 0.8
			
			local highlight = previewPart:FindFirstChild("Highlight")
			if highlight then
				highlight.FillColor = Color3.fromRGB(100, 100, 100)
			end
			
			lastValidPreviewPosition = nil
			lastValidPreviewNormal = nil
		end
	end)
end

local function hidePreview()
	if not isPreviewActive then return end
	isPreviewActive = false
	
	-- Clear stored position
	lastValidPreviewPosition = nil
	lastValidPreviewNormal = nil
	
	if previewLoopSound then
		previewLoopSound:Stop()
		previewLoopSound:Destroy()
		previewLoopSound = nil
	end
	
	if previewConnection then
		previewConnection:Disconnect()
		previewConnection = nil
	end
	
	if previewPart and previewPart.Parent then
		local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local tween = TweenService:Create(previewPart, tweenInfo, {
			Size = Vector3.new(0.2, 0.5, 0.5),
			Transparency = 1
		})
		tween:Play()
		tween.Completed:Connect(function()
			if previewPart then
				previewPart:Destroy()
				previewPart = nil
			end
		end)
	end
end

-- ============================================
-- VFX SYSTEM
-- ============================================

local function createRaycastParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	
	local filterList = {camera}
	
	if previewPart then
		table.insert(filterList, previewPart)
	end
	
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(filterList, p.Character)
		end
	end
	
	for _, child in ipairs(workspace:GetChildren()) do
		if child:FindFirstChildOfClass("Humanoid") then
			table.insert(filterList, child)
		end
	end
	
	params.FilterDescendantsInstances = filterList
	params.IgnoreWater = true
	return params
end

local function isValidGroundSurface(normal)
	return normal.Y >= MIN_GROUND_NORMAL_Y
end

function getGroundPosition()
	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	local raycastParams = createRaycastParams()
	
	local raycastResult = workspace:Raycast(
		ray.Origin,
		ray.Direction * 500,
		raycastParams
	)
	
	if raycastResult then
		local isValidGround = isValidGroundSurface(raycastResult.Normal)
		return raycastResult.Position, raycastResult.Normal, raycastResult.Instance, isValidGround
	end
	
	return nil, nil, nil, false
end

function isWithinRange(position)
	local character = player.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	return (position - humanoidRootPart.Position).Magnitude <= MAX_DISTANCE
end

local function getAllParticleEmitters(parent)
	local emitters = {}
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			table.insert(emitters, descendant)
		end
	end
	return emitters
end

local function emitAllParticles(vfxPart, emitCount)
	local emitters = getAllParticleEmitters(vfxPart)
	for _, emitter in ipairs(emitters) do
		emitter.Enabled = false
		emitter:Emit(emitCount or emitter:GetAttribute("EmitCount") or 15)
	end
end

local function tweenIn(vfxPart, originalSize)
	vfxPart.Size = Vector3.new(0.1, 0.1, 0.1)
	vfxPart.Transparency = 1
	
	local tweenInfo = TweenInfo.new(
		TWEEN_IN_TIME,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	)
	
	local tween = TweenService:Create(vfxPart, tweenInfo, {
		Size = originalSize
	})
	
	tween:Play()
	return tween
end

local function tweenOutAndDestroy(vfxPart)
	local tweenInfo = TweenInfo.new(
		TWEEN_OUT_TIME,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In
	)
	
	local tween = TweenService:Create(vfxPart, tweenInfo, {
		Size = Vector3.new(0.1, 0.1, 0.1)
	})
	
	tween:Play()
	tween.Completed:Connect(function()
		vfxPart:Destroy()
	end)
end

local function spawnVFX(position, normal)
	local vfxClone = SmashVfxTemplate:Clone()
	local originalSize = vfxClone.Size
	
	vfxClone.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(math.rad(90), 0, 0)
	
	vfxClone.Anchored = true
	vfxClone.CanCollide = false
	vfxClone.CanQuery = false
	vfxClone.CanTouch = false
	vfxClone.Transparency = 1
	vfxClone.Parent = workspace
	
	playSoundAtPosition(SOUND_SPAWN_ID, position, SOUND_SPAWN_VOLUME, math.random(90, 110) / 100)
	
	createVisualHitbox(position)
	
	local tweenInObj = tweenIn(vfxClone, originalSize)
	tweenInObj.Completed:Wait()
	emitAllParticles(vfxClone)
	
	task.delay(VFX_LIFETIME, function()
		if vfxClone and vfxClone.Parent then
			tweenOutAndDestroy(vfxClone)
		end
	end)
	
	Debris:AddItem(vfxClone, VFX_LIFETIME + TWEEN_OUT_TIME + 1)
end

-- ============================================
-- INPUT HANDLING
-- ============================================

local function onInputBegan(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	
	-- E for preview
	if input.KeyCode == Enum.KeyCode.E then
		showPreview()
		return
	end
	
	-- R to play animation + VFX (while previewing)
	if input.KeyCode == Enum.KeyCode.R then
		if isOnCooldown then return end
		
		-- Use stored preview position if available, otherwise get current mouse position
		local position, normal
		
		if lastValidPreviewPosition and lastValidPreviewNormal then
			position = lastValidPreviewPosition
			normal = lastValidPreviewNormal
		else
			local hitPart, isValidGround
			position, normal, hitPart, isValidGround = getGroundPosition()
			
			if not position or not isValidGround then return end
			if not isWithinRange(position) then return end
		end
		
		local currentTime = tick()
		if currentTime - lastClickTime < COOLDOWN then return end
		
		isOnCooldown = true
		lastClickTime = currentTime
		
		-- Play animation with VFX
		playAnimationWithVFX(position, normal)
		
		task.delay(COOLDOWN, function()
			isOnCooldown = false
		end)
		
		return
	end
	
	-- Left click for VFX only (no animation)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isOnCooldown then return end
		
		local currentTime = tick()
		if currentTime - lastClickTime < COOLDOWN then return end
		
		local position, normal, hitPart, isValidGround = getGroundPosition()
		
		if not position or not isValidGround then return end
		if not isWithinRange(position) then return end
		
		isOnCooldown = true
		lastClickTime = currentTime
		
		smashVFXEvent:FireServer(position, normal)
		
		task.delay(COOLDOWN, function()
			isOnCooldown = false
		end)
	end
end

local function onInputEnded(input, gameProcessedEvent)
	if input.KeyCode == Enum.KeyCode.E then
		hidePreview()
	end
end

-- Receive VFX from server
local function onVFXReceived(sourcePlayer, position, normal, hitPositions)
	print("[SmashVFX] VFX from " .. sourcePlayer.Name)
	spawnVFX(position, normal)
	
	if hitPositions and #hitPositions > 0 then
		for i, hitPos in ipairs(hitPositions) do
			task.delay((i - 1) * 0.05, function()
				playSoundAtPosition(SOUND_HIT_ID, hitPos, SOUND_HIT_VOLUME, math.random(85, 115) / 100)
			end)
		end
	end
end

-- ============================================
-- CHARACTER HANDLING
-- ============================================

local function onCharacterAdded(character)
	hidePreview()
	unloadAnimation()
	
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		task.wait(0.5)
		loadAnimation(character)
	end
end

local function onCharacterRemoving(character)
	hidePreview()
	unloadAnimation()
end

-- ============================================
-- INITIALIZATION
-- ============================================

local function init()
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
	smashVFXEvent.OnClientEvent:Connect(onVFXReceived)
	
	player.CharacterAdded:Connect(onCharacterAdded)
	player.CharacterRemoving:Connect(onCharacterRemoving)
	
	if player.Character then
		onCharacterAdded(player.Character)
	end
	
	print("[SmashVFX] Controller with Animation initialized!")
	print("  - Hold E to preview")
	print("  - Press R to play animation + spawn VFX")
	print("  - Left-click for VFX only")
	print("  - Max Distance: " .. MAX_DISTANCE .. " studs")
	print("  - Cooldown: " .. COOLDOWN .. " seconds")
end

init()
