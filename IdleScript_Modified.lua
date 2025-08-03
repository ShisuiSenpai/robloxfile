-- This should be a LOCALSCRIPT in StarterPlayer > StarterPlayerScripts
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Get RemoteEvent for communication with movement framework
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local katanaStateRemote = remotes:WaitForChild("KatanaStateRemote")

-- Idle system variables
local isKatanaEquipped = false
local idleTime = 0
local LONG_IDLE_THRESHOLD = 5
local currentIdleAnimation = nil
local idleAnimationTracks = {}

-- Find katana tool
local function findKatanaTool()
	-- Check backpack
	local katana = Player.Backpack:FindFirstChild("Katana")
	if katana then return katana end

	-- Check character (if equipped)
	katana = Character:FindFirstChild("Katana")
	if katana then return katana end

	return nil
end

-- Load idle animations
local function loadIdleAnimations()
	local modules = ReplicatedStorage:WaitForChild("Modules")
	local animationHandler = modules:WaitForChild("AnimationHandler")
	local idleAnimationsFolder = animationHandler:WaitForChild("IdleAnimations")

	local animator = Humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Humanoid:WaitForChild("Animator")
	end

	for _, idleAnim in idleAnimationsFolder:GetChildren() do
		if idleAnim:IsA("Animation") then
			idleAnimationTracks[idleAnim.Name] = animator:LoadAnimation(idleAnim)

			if idleAnim.Name == "LongKatanaIdle" then
				idleAnimationTracks[idleAnim.Name].Priority = Enum.AnimationPriority.Action2
			else
				idleAnimationTracks[idleAnim.Name].Priority = Enum.AnimationPriority.Idle
			end
		end
	end
end

-- Play idle animation
local function playIdleAnimation(animName)
	-- CHECK IF ANIMATIONS ARE DISABLED
	if Player:GetAttribute("DisableIdleAnimations") or Player:GetAttribute("BeingGrabbed") then
		stopAllIdleAnimations()
		return
	end
	
	if idleAnimationTracks[animName] then
		-- Stop all other idle animations
		for name, track in pairs(idleAnimationTracks) do
			if track.IsPlaying then
				track:Stop(0)
			end
		end

		-- Play the requested animation
		idleAnimationTracks[animName]:Play()
		currentIdleAnimation = animName
	else
		warn("Animation not found:", animName)
	end
end

-- Stop all idle animations
local function stopAllIdleAnimations()
	for name, track in pairs(idleAnimationTracks) do
		if track.IsPlaying then
			track:Stop(0)
		end
	end
	currentIdleAnimation = nil
end

-- Handle idle animations based on state
local function handleIdleAnimations()
	-- CHECK IF ANIMATIONS ARE DISABLED
	if Player:GetAttribute("DisableIdleAnimations") or Player:GetAttribute("BeingGrabbed") then
		stopAllIdleAnimations()
		return
	end
	
	if not isKatanaEquipped then
		-- No katana - play default idle, reset timer
		idleTime = 0
		if currentIdleAnimation ~= "DefaultIdle" then
			playIdleAnimation("DefaultIdle")
		end
		return
	end

	-- Katana equipped
	if idleTime >= LONG_IDLE_THRESHOLD then
		-- Long idle
		if currentIdleAnimation ~= "LongKatanaIdle" then
			playIdleAnimation("LongKatanaIdle")
		end
	else
		-- Short idle
		if currentIdleAnimation ~= "KatanaIdle" then
			playIdleAnimation("KatanaIdle")
		end
	end
end

-- Check if katana is currently equipped
local function updateKatanaState()
	local katanaInCharacter = Character:FindFirstChild("Katana")
	local newState = katanaInCharacter ~= nil

	if newState ~= isKatanaEquipped then
		isKatanaEquipped = newState
		idleTime = 0 -- Reset timer on state change

		-- Tell movement framework
		if isKatanaEquipped then
			katanaStateRemote:FireServer("equipped")
		else
			katanaStateRemote:FireServer("unequipped")
			stopAllIdleAnimations()
		end
	end
end

-- Heartbeat loop for idle detection and katana state
local function onHeartbeat(deltaTime)
	-- CHECK IF DISABLED FIRST
	if Player:GetAttribute("DisableIdleAnimations") or Player:GetAttribute("BeingGrabbed") then
		stopAllIdleAnimations()
		return
	end
	
	-- Update katana equipped state
	updateKatanaState()

	local isMoving = Humanoid.MoveDirection.Magnitude > 0

	if isMoving then
		-- Reset when moving
		idleTime = 0
		stopAllIdleAnimations()
	else
		-- Increment idle time only if katana equipped, otherwise keep at 0
		if isKatanaEquipped then
			idleTime = idleTime + deltaTime
		else
			idleTime = 0
		end

		-- Handle idle animations
		handleIdleAnimations()
	end
end

-- Listen for attribute changes to stop animations immediately
Player:GetAttributeChangedSignal("DisableIdleAnimations"):Connect(function()
	if Player:GetAttribute("DisableIdleAnimations") then
		stopAllIdleAnimations()
	end
end)

Player:GetAttributeChangedSignal("BeingGrabbed"):Connect(function()
	if Player:GetAttribute("BeingGrabbed") then
		stopAllIdleAnimations()
	end
end)

-- Handle character respawning
Player.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
	Humanoid = Character:WaitForChild("Humanoid")

	-- Reset state
	isKatanaEquipped = false
	idleTime = 0
	currentIdleAnimation = nil

	-- Clear old animation tracks
	for name, track in pairs(idleAnimationTracks) do
		if track then
			track:Stop()
			track:Destroy()
		end
	end
	idleAnimationTracks = {}

	-- Reload animations
	loadIdleAnimations()

	-- Start with default idle
	task.wait(1) -- Wait for everything to load
	if Humanoid.MoveDirection.Magnitude == 0 and not Player:GetAttribute("DisableIdleAnimations") then
		playIdleAnimation("DefaultIdle")
	end
end)

-- Initialize
loadIdleAnimations()
RunService.Heartbeat:Connect(onHeartbeat)

-- Start with default idle
task.wait(1) -- Wait for everything to load
if Humanoid.MoveDirection.Magnitude == 0 and not Player:GetAttribute("DisableIdleAnimations") then
	playIdleAnimation("DefaultIdle")
end