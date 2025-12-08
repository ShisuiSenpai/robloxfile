--[[
	AnimationController (LocalScript)
	Location: StarterPlayerScripts/AnimationController
	
	Standalone animation system.
	Press R to play animation smoothly.
	
	Completely separate from VFX system.
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Player references
local player = Players.LocalPlayer

-- ============================================
-- CONFIGURATION
-- ============================================

local ANIMATION_ID = "rbxassetid://YOUR_ANIMATION_ID_HERE" -- ⚠️ Replace with your animation ID!

local ACTIVATION_KEY = Enum.KeyCode.R -- Key to play animation
local COOLDOWN = 1.5 -- Seconds between plays

local ANIMATION_PRIORITY = Enum.AnimationPriority.Action4 -- High priority
local ANIMATION_FADE_IN = 0.1 -- Smooth fade in (seconds)
local ANIMATION_FADE_OUT = 0.15 -- Smooth fade out (seconds)
local ANIMATION_SPEED = 1 -- Playback speed (1 = normal)

local ALLOW_WHILE_JUMPING = false
local ALLOW_WHILE_FALLING = false
local ALLOW_WHILE_SEATED = false

-- ============================================
-- STATE
-- ============================================

local animationTrack = nil
local animationInstance = nil
local isOnCooldown = false
local lastPlayTime = 0

-- ============================================
-- ANIMATION FUNCTIONS
-- ============================================

-- Get or create the Animator from character
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

-- Load the animation onto the character
local function loadAnimation(character)
	local animator = getAnimator(character)
	if not animator then return nil end
	
	-- Create animation instance
	animationInstance = Instance.new("Animation")
	animationInstance.AnimationId = ANIMATION_ID
	
	-- Load animation track
	animationTrack = animator:LoadAnimation(animationInstance)
	animationTrack.Priority = ANIMATION_PRIORITY
	
	print("[Animation] Loaded successfully")
	return animationTrack
end

-- Unload and cleanup animation
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

-- Check if player can play animation right now
local function canPlayAnimation()
	local character = player.Character
	if not character then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	
	-- Check if alive
	if humanoid.Health <= 0 then
		return false
	end
	
	-- Check movement states
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

-- Play the animation smoothly
local function playAnimation()
	-- Check if can play
	if not canPlayAnimation() then
		return false
	end
	
	-- Check cooldown
	if isOnCooldown then
		return false
	end
	
	local currentTime = tick()
	if currentTime - lastPlayTime < COOLDOWN then
		return false
	end
	
	-- Make sure animation is loaded
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
	
	-- If already playing, let it finish or restart
	if animationTrack.IsPlaying then
		animationTrack:Stop(ANIMATION_FADE_OUT)
		task.wait(ANIMATION_FADE_OUT)
	end
	
	-- Set cooldown
	isOnCooldown = true
	lastPlayTime = currentTime
	
	-- Play with smooth fade
	animationTrack:Play(ANIMATION_FADE_IN, ANIMATION_SPEED)
	
	print("[Animation] Playing!")
	
	-- Reset cooldown
	task.delay(COOLDOWN, function()
		isOnCooldown = false
	end)
	
	return true
end

-- Stop animation early
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
	-- Ignore if typing in chat, etc.
	if gameProcessedEvent then return end
	
	-- Check for activation key
	if input.KeyCode == ACTIVATION_KEY then
		playAnimation()
	end
end

-- ============================================
-- CHARACTER HANDLING
-- ============================================

local function onCharacterAdded(character)
	-- Cleanup old animation
	unloadAnimation()
	
	-- Wait for humanoid to be ready
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	
	-- Small delay to ensure everything is loaded
	task.wait(0.5)
	
	-- Pre-load animation for instant playback
	loadAnimation(character)
end

local function onCharacterRemoving(character)
	unloadAnimation()
end

-- ============================================
-- INITIALIZATION
-- ============================================

local function init()
	-- Connect input
	UserInputService.InputBegan:Connect(onInputBegan)
	
	-- Connect character events
	player.CharacterAdded:Connect(onCharacterAdded)
	player.CharacterRemoving:Connect(onCharacterRemoving)
	
	-- Handle existing character
	if player.Character then
		task.spawn(function()
			onCharacterAdded(player.Character)
		end)
	end
	
	print("========================================")
	print("[Animation] Controller initialized!")
	print("  - Press " .. ACTIVATION_KEY.Name .. " to play animation")
	print("  - Cooldown: " .. COOLDOWN .. " seconds")
	print("  - ⚠️ Set your ANIMATION_ID in the script!")
	print("========================================")
end

init()
