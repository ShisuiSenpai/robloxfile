--[[
	SmashVFXController (LocalScript)
	Location: StarterPlayerScripts/SmashVFXController
	
	Handles mouse input and spawns the SmashVfx on left-click
	when clicking on the ground within 20 studs.
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Player references
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Configuration
local MAX_DISTANCE = 20 -- Maximum distance in studs
local VFX_LIFETIME = 2 -- How long the VFX stays before fading
local TWEEN_IN_TIME = 0.15 -- Time to scale in
local TWEEN_OUT_TIME = 0.4 -- Time to fade out
local COOLDOWN = 0.3 -- Prevent spam clicking

-- VFX Reference
local VFXFolder = ReplicatedStorage:WaitForChild("VFX")
local SmashVfxTemplate = VFXFolder:WaitForChild("SmashVfx")

-- State
local lastClickTime = 0
local isOnCooldown = false

-- Raycast parameters (ignore player character and other VFX)
local function createRaycastParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character, camera}
	params.IgnoreWater = true
	return params
end

-- Get all ParticleEmitters recursively from a part/model
local function getAllParticleEmitters(parent)
	local emitters = {}
	
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			table.insert(emitters, descendant)
		end
	end
	
	return emitters
end

-- Emit all particles in the VFX
local function emitAllParticles(vfxPart, emitCount)
	local emitters = getAllParticleEmitters(vfxPart)
	
	for _, emitter in ipairs(emitters) do
		-- Store original enabled state
		emitter.Enabled = false
		-- Emit a burst of particles
		emitter:Emit(emitCount or emitter:GetAttribute("EmitCount") or 15)
	end
end

-- Tween the VFX in (scale up from 0)
local function tweenIn(vfxPart, originalSize)
	-- Start from small size
	vfxPart.Size = Vector3.new(0.1, 0.1, 0.1)
	vfxPart.Transparency = 1 -- Keep part invisible, we only want particles
	
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

-- Tween the VFX out and cleanup
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

-- Spawn the VFX at the given position
local function spawnVFX(position, normal)
	-- Clone the VFX template
	local vfxClone = SmashVfxTemplate:Clone()
	
	-- Store original size for tweening
	local originalSize = vfxClone.Size
	
	-- Position the VFX at the hit point, slightly above ground
	-- Orient it flat on the ground (90, 0, 0 rotation)
	vfxClone.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(math.rad(90), 0, 0)
	
	-- Make the part non-collidable and anchored
	vfxClone.Anchored = true
	vfxClone.CanCollide = false
	vfxClone.CanQuery = false
	vfxClone.CanTouch = false
	vfxClone.Transparency = 1 -- Invisible part, only particles visible
	
	-- Parent to workspace (or a dedicated VFX folder if you have one)
	vfxClone.Parent = workspace
	
	-- Tween in
	local tweenInObj = tweenIn(vfxClone, originalSize)
	
	-- Wait for tween to complete, then emit particles
	tweenInObj.Completed:Wait()
	
	-- Emit all particles
	emitAllParticles(vfxClone)
	
	-- Schedule fade out and cleanup
	task.delay(VFX_LIFETIME, function()
		if vfxClone and vfxClone.Parent then
			tweenOutAndDestroy(vfxClone)
		end
	end)
	
	-- Safety cleanup with Debris (backup in case something goes wrong)
	Debris:AddItem(vfxClone, VFX_LIFETIME + TWEEN_OUT_TIME + 1)
end

-- Perform raycast from mouse position to find ground
local function getGroundPosition()
	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	
	local raycastParams = createRaycastParams()
	
	-- Cast a ray from camera through mouse position
	local raycastResult = workspace:Raycast(
		ray.Origin,
		ray.Direction * 500, -- Long ray to hit distant surfaces
		raycastParams
	)
	
	if raycastResult then
		return raycastResult.Position, raycastResult.Normal, raycastResult.Instance
	end
	
	return nil, nil, nil
end

-- Check if position is within max distance from player
local function isWithinRange(position)
	local character = player.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	local distance = (position - humanoidRootPart.Position).Magnitude
	return distance <= MAX_DISTANCE
end

-- Handle mouse click
local function onInputBegan(input, gameProcessedEvent)
	-- Ignore if the game already processed this input (e.g., clicking on GUI)
	if gameProcessedEvent then return end
	
	-- Check for left mouse button
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	
	-- Check cooldown
	if isOnCooldown then return end
	
	local currentTime = tick()
	if currentTime - lastClickTime < COOLDOWN then return end
	
	-- Get ground position
	local position, normal, hitPart = getGroundPosition()
	
	if not position then
		-- No ground hit
		return
	end
	
	-- Check if within range
	if not isWithinRange(position) then
		-- Optional: You could add a visual/audio feedback here for "out of range"
		return
	end
	
	-- Set cooldown
	isOnCooldown = true
	lastClickTime = currentTime
	
	-- Spawn the VFX
	spawnVFX(position, normal)
	
	-- Reset cooldown after delay
	task.delay(COOLDOWN, function()
		isOnCooldown = false
	end)
end

-- Wait for character to load
local function onCharacterAdded(character)
	-- Update raycast params when character changes
	-- Character is automatically excluded in createRaycastParams()
end

-- Initialize
local function init()
	-- Connect input handler
	UserInputService.InputBegan:Connect(onInputBegan)
	
	-- Handle character respawning
	player.CharacterAdded:Connect(onCharacterAdded)
	
	if player.Character then
		onCharacterAdded(player.Character)
	end
	
	print("[SmashVFX] Controller initialized! Left-click on ground within " .. MAX_DISTANCE .. " studs to spawn VFX.")
end

-- Start the system
init()
