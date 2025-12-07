--[[
	SmashVFXController_Multiplayer (LocalScript)
	Location: StarterPlayerScripts/SmashVFXController
	
	MULTIPLAYER VERSION - Use this if you want other players to see the VFX.
	Works with SmashVFXHandler on the server.
	
	Handles mouse input and VFX spawning with server replication.
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
local MAX_DISTANCE = 20
local VFX_LIFETIME = 2
local TWEEN_IN_TIME = 0.15
local TWEEN_OUT_TIME = 0.4
local COOLDOWN = 0.3

-- References
local VFXFolder = ReplicatedStorage:WaitForChild("VFX")
local SmashVfxTemplate = VFXFolder:WaitForChild("SmashVfx")
local smashVFXEvent = ReplicatedStorage:WaitForChild("SmashVFXEvent")

-- State
local lastClickTime = 0
local isOnCooldown = false

-- Raycast parameters
local function createRaycastParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character, camera}
	params.IgnoreWater = true
	return params
end

-- Get all ParticleEmitters recursively
local function getAllParticleEmitters(parent)
	local emitters = {}
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			table.insert(emitters, descendant)
		end
	end
	return emitters
end

-- Emit all particles
local function emitAllParticles(vfxPart, emitCount)
	local emitters = getAllParticleEmitters(vfxPart)
	for _, emitter in ipairs(emitters) do
		emitter.Enabled = false
		emitter:Emit(emitCount or emitter:GetAttribute("EmitCount") or 15)
	end
end

-- Tween in effect
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

-- Tween out and destroy
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

-- Spawn VFX at position (called for all players)
local function spawnVFX(position, normal)
	local vfxClone = SmashVfxTemplate:Clone()
	local originalSize = vfxClone.Size
	
	-- Orient flat on the ground (90, 0, 0 rotation)
	vfxClone.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(math.rad(90), 0, 0)
	
	vfxClone.Anchored = true
	vfxClone.CanCollide = false
	vfxClone.CanQuery = false
	vfxClone.CanTouch = false
	vfxClone.Transparency = 1
	vfxClone.Parent = workspace
	
	-- Animate
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

-- Get ground position from mouse
local function getGroundPosition()
	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	local raycastParams = createRaycastParams()
	
	local raycastResult = workspace:Raycast(
		ray.Origin,
		ray.Direction * 500,
		raycastParams
	)
	
	if raycastResult then
		return raycastResult.Position, raycastResult.Normal, raycastResult.Instance
	end
	
	return nil, nil, nil
end

-- Check distance
local function isWithinRange(position)
	local character = player.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	return (position - humanoidRootPart.Position).Magnitude <= MAX_DISTANCE
end

-- Handle click input
local function onInputBegan(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if isOnCooldown then return end
	
	local currentTime = tick()
	if currentTime - lastClickTime < COOLDOWN then return end
	
	local position, normal, hitPart = getGroundPosition()
	if not position then return end
	if not isWithinRange(position) then return end
	
	isOnCooldown = true
	lastClickTime = currentTime
	
	-- Send request to server
	smashVFXEvent:FireServer(position, normal)
	
	task.delay(COOLDOWN, function()
		isOnCooldown = false
	end)
end

-- Receive VFX event from server (for all players)
local function onVFXReceived(sourcePlayer, position, normal)
	spawnVFX(position, normal)
end

-- Initialize
local function init()
	UserInputService.InputBegan:Connect(onInputBegan)
	smashVFXEvent.OnClientEvent:Connect(onVFXReceived)
	
	print("[SmashVFX] Multiplayer controller initialized!")
end

init()
