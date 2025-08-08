-- LockOnClient LocalScript
-- Place in: StarterPlayer > StarterPlayerScripts > LockOnClient

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Wait for modules and remotes
local LockOnModules = ReplicatedStorage:WaitForChild("LockOnModules")
local LockOnConfig = require(LockOnModules:WaitForChild("LockOnConfig"))

-- State variables
local isLockedOn = false
local currentTarget = nil
local targetMarker = nil
local lockConnection = nil
local scanConnection = nil
local lastScanTime = 0
local defaultFOV = camera.FieldOfView
local currentFOVTween = nil

-- Utility Functions
local function lerp(a, b, t)
	return a + (b - a) * t
end

local function getAngleBetweenVectors(v1, v2)
	local dot = v1:Dot(v2)
	return math.deg(math.acos(math.clamp(dot / (v1.Magnitude * v2.Magnitude), -1, 1)))
end

local function isTargetValid(target)
	if not target or not target.Parent then return false end
	
	local humanoid = target.Parent:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	
	local rootPart = target.Parent:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end
	
	-- Don't target yourself
	if target.Parent == player.Character then return false end
	
	-- Check size threshold
	if rootPart.Size.Magnitude < LockOnConfig.MIN_TARGET_SIZE then return false end
	
	return true, humanoid, rootPart
end

local function createTargetMarker()
	if targetMarker then
		targetMarker:Destroy()
	end
	
	local marker = Instance.new("Part")
	marker.Name = "LockOnTargetMarker"
	marker.Anchored = true
	marker.CanCollide = false
	marker.Size = LockOnConfig.TARGET_MARKER_SIZE
	marker.Transparency = LockOnConfig.TARGET_MARKER_TRANSPARENCY
	marker.Material = Enum.Material.Neon
	marker.Color = LockOnConfig.TARGET_MARKER_COLOR
	marker.Parent = Workspace
	
	-- Create decal on both sides
	local frontDecal = Instance.new("Decal")
	frontDecal.Texture = LockOnConfig.TARGET_DECAL_ID
	frontDecal.Face = Enum.NormalId.Front
	frontDecal.Transparency = 0
	frontDecal.Parent = marker
	
	local backDecal = Instance.new("Decal")
	backDecal.Texture = LockOnConfig.TARGET_DECAL_ID
	backDecal.Face = Enum.NormalId.Back
	backDecal.Transparency = 0
	backDecal.Parent = marker
	
	-- Add rotation effect
	local rotation = Instance.new("NumberValue")
	rotation.Value = 0
	rotation.Parent = marker
	
	RunService.Heartbeat:Connect(function(dt)
		if marker and marker.Parent then
			rotation.Value = rotation.Value + dt * 45 -- 45 degrees per second
			marker.CFrame = marker.CFrame * CFrame.Angles(0, 0, math.rad(dt * 45))
		end
	end)
	
	targetMarker = marker
	return marker
end

local function removeTargetMarker()
	if targetMarker then
		targetMarker:Destroy()
		targetMarker = nil
	end
end

local function findBestTarget()
	local character = player.Character
	if not character then return nil end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return nil end
	
	local candidates = {}
	local cameraLookVector = camera.CFrame.LookVector
	local characterPosition = humanoidRootPart.Position
	
	-- Scan all characters in workspace
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
			local isValid, humanoid, rootPart = isTargetValid(obj)
			if isValid then
				local distance = (rootPart.Position - characterPosition).Magnitude
				
				if distance <= LockOnConfig.MAX_LOCK_DISTANCE then
					local toTarget = (rootPart.Position - camera.CFrame.Position).Unit
					local angle = getAngleBetweenVectors(cameraLookVector, toTarget)
					
					-- Calculate priority score
					local angleFactor = 1 - (angle / 180) -- 0 to 1, higher is better
					local distanceFactor = 1 - (distance / LockOnConfig.MAX_LOCK_DISTANCE) -- 0 to 1, higher is better
					local inView = angle <= LockOnConfig.LOCK_ANGLE_THRESHOLD
					
					local score = distanceFactor
					if inView then
						score = score + angleFactor * LockOnConfig.PRIORITY_VIEW_WEIGHT
					end
					
					table.insert(candidates, {
						target = obj,
						rootPart = rootPart,
						score = score,
						distance = distance,
						angle = angle
					})
				end
			end
		end
	end
	
	-- Sort by score (highest first)
	table.sort(candidates, function(a, b)
		return a.score > b.score
	end)
	
	return candidates[1] and candidates[1].target or nil
end

local function updateCameraLock()
	if not isLockedOn or not currentTarget then return end
	
	local isValid, humanoid, rootPart = isTargetValid(currentTarget)
	if not isValid then
		cancelLockOn()
		return
	end
	
	-- Update target marker position
	if targetMarker then
		targetMarker.CFrame = CFrame.lookAt(
			rootPart.Position + Vector3.new(0, 0, -2),
			camera.CFrame.Position
		)
	end
	
	-- Smooth camera follow
	local targetLookAt = CFrame.lookAt(camera.CFrame.Position, rootPart.Position)
	camera.CFrame = camera.CFrame:Lerp(targetLookAt, LockOnConfig.CAMERA_FOLLOW_SPEED)
end

local function startLockOn(target)
	if not target then return false end
	
	currentTarget = target
	isLockedOn = true
	
	-- Create target marker
	createTargetMarker()
	
	-- Zoom camera
	if currentFOVTween then
		currentFOVTween:Cancel()
	end
	
	currentFOVTween = TweenService:Create(
		camera,
		TweenInfo.new(LockOnConfig.CAMERA_ZOOM_SPEED, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{FieldOfView = LockOnConfig.CAMERA_ZOOM_FOV}
	)
	currentFOVTween:Play()
	
	-- Start update loop
	if lockConnection then
		lockConnection:Disconnect()
	end
	lockConnection = RunService.RenderStepped:Connect(updateCameraLock)
	
	return true
end

local function cancelLockOn()
	isLockedOn = false
	currentTarget = nil
	
	-- Remove target marker
	removeTargetMarker()
	
	-- Reset camera zoom
	if currentFOVTween then
		currentFOVTween:Cancel()
	end
	
	currentFOVTween = TweenService:Create(
		camera,
		TweenInfo.new(LockOnConfig.CAMERA_ZOOM_SPEED, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{FieldOfView = defaultFOV}
	)
	currentFOVTween:Play()
	
	-- Stop update loop
	if lockConnection then
		lockConnection:Disconnect()
		lockConnection = nil
	end
end

local function toggleLockOn()
	if isLockedOn then
		cancelLockOn()
	else
		local target = findBestTarget()
		if target then
			startLockOn(target)
		end
	end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == LockOnConfig.LOCK_ON_KEY then
		toggleLockOn()
	end
end)

-- Cleanup on character death/removal
player.CharacterRemoving:Connect(function()
	cancelLockOn()
end)

-- Handle target leaving
Workspace.DescendantRemoving:Connect(function(descendant)
	if currentTarget and (descendant == currentTarget or descendant:IsDescendantOf(currentTarget)) then
		cancelLockOn()
	end
end)

print("Lock-On System initialized! Press Left Ctrl to lock onto targets.")