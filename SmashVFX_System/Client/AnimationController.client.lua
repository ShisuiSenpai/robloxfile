--[[
	AnimationController (LocalScript)
	Location: StarterPlayerScripts/AnimationController
	
	Standalone animation system.
	Press R to play animation smoothly.
	Spawns Kanji VFX above player's head after animation.
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Player references
local player = Players.LocalPlayer

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
local KANJI_OFFSET = Vector3.new(1.5, 2.5, 0) -- Right (X), Up (Y), Forward (Z) from head
local KANJI_LIFETIME = 1.5 -- How long the VFX stays
local KANJI_FADE_IN_TIME = 0.15 -- Smooth appear
local KANJI_FADE_OUT_TIME = 0.3 -- Smooth disappear
local KANJI_DELAY_AFTER_ANIM = 0.1 -- Delay after animation starts before showing Kanji

-- ============================================
-- REFERENCES
-- ============================================

local VFXFolder = ReplicatedStorage:WaitForChild("VFX")
local KanjiTemplate = VFXFolder:WaitForChild("kanji")

-- ============================================
-- STATE
-- ============================================

local animationTrack = nil
local animationInstance = nil
local isOnCooldown = false
local lastPlayTime = 0

-- ============================================
-- KANJI VFX SYSTEM
-- ============================================

-- Get all ParticleEmitters recursively
local function getAllParticleEmitters(parent)
	local emitters = {}
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			table.insert(emitters, descendant)
		end
	end
	-- Also check the parent itself if it has emitters as direct children
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			table.insert(emitters, child)
		end
	end
	return emitters
end

-- Emit all particles
local function emitAllParticles(vfxPart, emitCount)
	local emitters = getAllParticleEmitters(vfxPart)
	for _, emitter in ipairs(emitters) do
		emitter.Enabled = false
		emitter:Emit(emitCount or emitter:GetAttribute("EmitCount") or 10)
	end
end

-- Spawn Kanji VFX above player's head
local function spawnKanjiVFX()
	local character = player.Character
	if not character then return end
	
	local head = character:FindFirstChild("Head")
	if not head then return end
	
	-- Clone the Kanji VFX
	local kanjiClone = KanjiTemplate:Clone()
	
	-- Calculate position: head position + offset (relative to character's orientation)
	local headCFrame = head.CFrame
	local offsetPosition = headCFrame.Position + 
		(headCFrame.RightVector * KANJI_OFFSET.X) + -- Right of head
		(Vector3.new(0, KANJI_OFFSET.Y, 0)) + -- Above head (world up)
		(headCFrame.LookVector * KANJI_OFFSET.Z) -- Forward/back
	
	-- Position the VFX
	if kanjiClone:IsA("BasePart") then
		kanjiClone.CFrame = CFrame.new(offsetPosition)
		kanjiClone.Anchored = true
		kanjiClone.CanCollide = false
		kanjiClone.CanQuery = false
		kanjiClone.CanTouch = false
		kanjiClone.Transparency = 1 -- Keep part invisible, show particles only
	elseif kanjiClone:IsA("Model") then
		if kanjiClone.PrimaryPart then
			kanjiClone:SetPrimaryPartCFrame(CFrame.new(offsetPosition))
		else
			-- Find first part and position it
			local firstPart = kanjiClone:FindFirstChildWhichIsA("BasePart")
			if firstPart then
				firstPart.CFrame = CFrame.new(offsetPosition)
			end
		end
	end
	
	-- Parent to workspace
	kanjiClone.Parent = workspace
	
	-- Store original size for tweening (if it's a part)
	local originalSize = nil
	if kanjiClone:IsA("BasePart") then
		originalSize = kanjiClone.Size
		kanjiClone.Size = Vector3.new(0.1, 0.1, 0.1)
	end
	
	-- Smooth fade in with scale
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
	
	-- Emit particles
	emitAllParticles(kanjiClone)
	
	-- Smooth fade out after lifetime
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
	
	-- Safety cleanup
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
	
	-- Play animation
	animationTrack:Play(ANIMATION_FADE_IN, ANIMATION_SPEED)
	print("[Animation] Playing!")
	
	-- Spawn Kanji VFX after a short delay
	task.delay(KANJI_DELAY_AFTER_ANIM, function()
		spawnKanjiVFX()
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
	print("  - Press " .. ACTIVATION_KEY.Name .. " to play animation")
	print("  - Kanji VFX spawns above head")
	print("  - Cooldown: " .. COOLDOWN .. " seconds")
	print("  - ⚠️ Set your ANIMATION_ID in the script!")
	print("========================================")
end

init()
