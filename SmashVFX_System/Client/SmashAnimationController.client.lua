--[[
	SmashAnimationController (LocalScript)
	Location: StarterPlayerScripts/SmashAnimationController
	
	Plays a smooth animation when pressing R.
	Integrates with the SmashVFX system.
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Player references
local player = Players.LocalPlayer

-- ============================================
-- CONFIGURATION
-- ============================================

-- Animation Settings
local ANIMATION_ID = "rbxassetid://YOUR_ANIMATION_ID_HERE" -- Replace with your animation ID!
local ANIMATION_PRIORITY = Enum.AnimationPriority.Action4 -- High priority to override other anims
local ANIMATION_FADE_IN = 0.1 -- Smooth fade in time
local ANIMATION_FADE_OUT = 0.15 -- Smooth fade out time
local ANIMATION_SPEED = 1 -- Playback speed (1 = normal)

-- Input Settings
local ACTIVATION_KEY = Enum.KeyCode.R
local COOLDOWN = 1.5 -- Match with VFX cooldown
local ALLOW_WHILE_JUMPING = false -- Can play while in air?
local ALLOW_WHILE_FALLING = false -- Can play while falling?

-- ============================================
-- STATE
-- ============================================

local currentAnimation = nil
local animationTrack = nil
local isOnCooldown = false
local lastPlayTime = 0

-- ============================================
-- ANIMATION SYSTEM
-- ============================================

-- Get or create the Animator
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

-- Load the animation
local function loadAnimation(character)
	local animator = getAnimator(character)
	if not animator then return nil end
	
	-- Create animation instance
	local animation = Instance.new("Animation")
	animation.AnimationId = ANIMATION_ID
	
	-- Load the animation track
	local track = animator:LoadAnimation(animation)
	track.Priority = ANIMATION_PRIORITY
	
	-- Store reference
	currentAnimation = animation
	animationTrack = track
	
	return track
end

-- Unload animation (cleanup)
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

-- Check if player can play animation
local function canPlayAnimation()
	local character = player.Character
	if not character then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	
	-- Check if alive
	if humanoid.Health <= 0 then return false end
	
	-- Check movement state
	local state = humanoid:GetState()
	
	if not ALLOW_WHILE_JUMPING and state == Enum.HumanoidStateType.Jumping then
		return false
	end
	
	if not ALLOW_WHILE_FALLING and state == Enum.HumanoidStateType.Freefall then
		return false
	end
	
	-- Check if sitting
	if state == Enum.HumanoidStateType.Seated then
		return false
	end
	
	return true
end

-- Play the animation smoothly
local function playAnimation()
	local character = player.Character
	if not character then return false end
	
	-- Check if we can play
	if not canPlayAnimation() then
		return false
	end
	
	-- Check cooldown
	if isOnCooldown then return false end
	
	local currentTime = tick()
	if currentTime - lastPlayTime < COOLDOWN then
		return false
	end
	
	-- Load animation if needed
	if not animationTrack then
		loadAnimation(character)
	end
	
	if not animationTrack then
		warn("[SmashAnimation] Failed to load animation!")
		return false
	end
	
	-- Check if already playing
	if animationTrack.IsPlaying then
		-- Option 1: Restart the animation
		animationTrack:Stop(ANIMATION_FADE_OUT)
		task.wait(ANIMATION_FADE_OUT)
	end
	
	-- Set cooldown
	isOnCooldown = true
	lastPlayTime = currentTime
	
	-- Play with smooth fade in
	animationTrack:Play(ANIMATION_FADE_IN, ANIMATION_SPEED, ANIMATION_SPEED)
	
	print("[SmashAnimation] Playing animation!")
	
	-- Reset cooldown after animation or cooldown time
	local resetTime = math.max(COOLDOWN, animationTrack.Length)
	task.delay(COOLDOWN, function()
		isOnCooldown = false
	end)
	
	return true
end

-- Stop animation early (if needed)
local function stopAnimation()
	if animationTrack and animationTrack.IsPlaying then
		animationTrack:Stop(ANIMATION_FADE_OUT)
		print("[SmashAnimation] Animation stopped")
	end
end

-- ============================================
-- INPUT HANDLING
-- ============================================

local function onInputBegan(input, gameProcessedEvent)
	-- Ignore if game processed (typing in chat, etc.)
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
	-- Wait for humanoid to load
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	
	-- Unload old animation
	unloadAnimation()
	
	-- Pre-load new animation for instant playback
	task.wait(0.5) -- Small delay to ensure character is fully loaded
	loadAnimation(character)
	
	print("[SmashAnimation] Animation pre-loaded for " .. player.Name)
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
		onCharacterAdded(player.Character)
	end
	
	print("[SmashAnimation] Controller initialized!")
	print("  - Press " .. ACTIVATION_KEY.Name .. " to play animation")
	print("  - Cooldown: " .. COOLDOWN .. " seconds")
	print("  - Remember to set your ANIMATION_ID!")
end

init()


-- ============================================
-- PUBLIC API (for other scripts to use)
-- ============================================

local SmashAnimation = {}

function SmashAnimation:Play()
	return playAnimation()
end

function SmashAnimation:Stop()
	stopAnimation()
end

function SmashAnimation:IsPlaying()
	return animationTrack and animationTrack.IsPlaying
end

function SmashAnimation:GetTrack()
	return animationTrack
end

-- Store in ReplicatedStorage for other scripts to access
local existingModule = ReplicatedStorage:FindFirstChild("SmashAnimationAPI")
if existingModule then existingModule:Destroy() end

local apiModule = Instance.new("ModuleScript")
apiModule.Name = "SmashAnimationAPI"
apiModule.Parent = ReplicatedStorage
-- Note: The actual API is stored in the local script, 
-- this is just a reference marker

return SmashAnimation
