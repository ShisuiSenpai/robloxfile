-- LockOnClientEnhanced LocalScript (Alternative with more features)
-- Use this instead of LockOnClient if you want additional features
-- Place in: StarterPlayer > StarterPlayerScripts > LockOnClient

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Wait for modules
local LockOnModules = ReplicatedStorage:WaitForChild("LockOnModules")
local LockOnConfig = require(LockOnModules:WaitForChild("LockOnConfig"))

-- State variables
local isLockedOn = false
local currentTarget = nil
local targetMarker = nil
local lockConnection = nil
local defaultFOV = camera.FieldOfView
local currentFOVTween = nil
local targetList = {}
local currentTargetIndex = 1

-- Visual effect parts
local outerRing = nil
local innerCross = nil
local particles = {}

-- Enhanced configuration
local SWITCH_TARGET_KEY = Enum.KeyCode.Tab
local PARTICLE_COUNT = 8
local RING_SPIN_SPEED = 90 -- degrees per second

-- Utility Functions
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
	
	if target.Parent == player.Character then return false end
	
	if rootPart.Size.Magnitude < LockOnConfig.MIN_TARGET_SIZE then return false end
	
	return true, humanoid, rootPart
end

local function createEnhancedTargetMarker()
	if targetMarker then
		targetMarker:Destroy()
	end
	
	-- Main container
	local container = Instance.new("Model")
	container.Name = "LockOnTargetMarker"
	container.Parent = Workspace
	
	-- Base part (invisible anchor)
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Anchored = true
	base.CanCollide = false
	base.Size = Vector3.new(0.1, 0.1, 0.1)
	base.Transparency = 1
	base.Parent = container
	
	-- Outer spinning ring
	outerRing = Instance.new("Part")
	outerRing.Name = "OuterRing"
	outerRing.Anchored = true
	outerRing.CanCollide = false
	outerRing.Size = Vector3.new(5, 5, 0.2)
	outerRing.Material = Enum.Material.Neon
	outerRing.Color = LockOnConfig.TARGET_MARKER_COLOR
	outerRing.Transparency = 0.5
	outerRing.Parent = container
	
	-- Ring mesh
	local ringMesh = Instance.new("SpecialMesh")
	ringMesh.MeshType = Enum.MeshType.Cylinder
	ringMesh.Parent = outerRing
	
	-- Inner crosshair
	innerCross = Instance.new("Part")
	innerCross.Name = "InnerCross"
	innerCross.Anchored = true
	innerCross.CanCollide = false
	innerCross.Size = Vector3.new(3, 3, 0.1)
	innerCross.Transparency = LockOnConfig.TARGET_MARKER_TRANSPARENCY
	innerCross.Material = Enum.Material.Neon
	innerCross.Color = LockOnConfig.TARGET_MARKER_COLOR
	innerCross.Parent = container
	
	-- Add decals
	local frontDecal = Instance.new("Decal")
	frontDecal.Texture = LockOnConfig.TARGET_DECAL_ID
	frontDecal.Face = Enum.NormalId.Front
	frontDecal.Transparency = 0
	frontDecal.Parent = innerCross
	
	local backDecal = Instance.new("Decal")
	backDecal.Texture = LockOnConfig.TARGET_DECAL_ID
	backDecal.Face = Enum.NormalId.Back
	backDecal.Transparency = 0
	backDecal.Parent = innerCross
	
	-- Create orbiting particles
	particles = {}
	for i = 1, PARTICLE_COUNT do
		local particle = Instance.new("Part")
		particle.Name = "Particle" .. i
		particle.Anchored = true
		particle.CanCollide = false
		particle.Size = Vector3.new(0.3, 0.3, 0.3)
		particle.Material = Enum.Material.Neon
		particle.Color = LockOnConfig.TARGET_MARKER_COLOR
		particle.Parent = container
		
		-- Add glow
		local pointLight = Instance.new("PointLight")
		pointLight.Brightness = 2
		pointLight.Color = LockOnConfig.TARGET_MARKER_COLOR
		pointLight.Range = 5
		pointLight.Parent = particle
		
		table.insert(particles, particle)
	end
	
	-- Lock-on animation
	local lockOnAnim = TweenService:Create(
		innerCross,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = Vector3.new(4, 4, 0.1)}
	)
	lockOnAnim:Play()
	
	targetMarker = container
	return container
end

local function updateEnhancedMarker(deltaTime)
	if not targetMarker or not outerRing or not innerCross then return end
	
	local base = targetMarker:FindFirstChild("Base")
	if not base then return end
	
	-- Rotate outer ring
	outerRing.CFrame = outerRing.CFrame * CFrame.Angles(0, 0, math.rad(RING_SPIN_SPEED * deltaTime))
	
	-- Rotate inner cross opposite direction
	innerCross.CFrame = innerCross.CFrame * CFrame.Angles(0, 0, math.rad(-RING_SPIN_SPEED * 0.5 * deltaTime))
	
	-- Update particle orbits
	local time = tick()
	for i, particle in ipairs(particles) do
		local angle = (i / PARTICLE_COUNT) * math.pi * 2 + time
		local radius = 2.5 + math.sin(time * 2 + i) * 0.5
		local x = math.cos(angle) * radius
		local y = math.sin(angle) * radius
		
		particle.CFrame = base.CFrame * CFrame.new(x, y, 0)
		particle.Transparency = 0.3 + math.sin(time * 3 + i) * 0.2
	end
end

local function removeEnhancedTargetMarker()
	if targetMarker then
		-- Fade out animation
		for _, desc in ipairs(targetMarker:GetDescendants()) do
			if desc:IsA("BasePart") and desc.Transparency < 1 then
				TweenService:Create(
					desc,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{Transparency = 1}
				):Play()
			end
		end
		
		Debris:AddItem(targetMarker, 0.3)
		targetMarker = nil
		outerRing = nil
		innerCross = nil
		particles = {}
	end
end

local function getAllValidTargets()
	local character = player.Character
	if not character then return {} end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return {} end
	
	local candidates = {}
	local cameraLookVector = camera.CFrame.LookVector
	local characterPosition = humanoidRootPart.Position
	
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
			local isValid, humanoid, rootPart = isTargetValid(obj)
			if isValid then
				local distance = (rootPart.Position - characterPosition).Magnitude
				
				if distance <= LockOnConfig.MAX_LOCK_DISTANCE then
					local toTarget = (rootPart.Position - camera.CFrame.Position).Unit
					local angle = getAngleBetweenVectors(cameraLookVector, toTarget)
					
					local angleFactor = 1 - (angle / 180)
					local distanceFactor = 1 - (distance / LockOnConfig.MAX_LOCK_DISTANCE)
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
	
	table.sort(candidates, function(a, b)
		return a.score > b.score
	end)
	
	return candidates
end

local function updateCameraLock(deltaTime)
	if not isLockedOn or not currentTarget then return end
	
	local isValid, humanoid, rootPart = isTargetValid(currentTarget)
	if not isValid then
		cancelLockOn()
		return
	end
	
	-- Update target marker position
	if targetMarker then
		local base = targetMarker:FindFirstChild("Base")
		if base then
			local targetPosition = rootPart.Position
			local lookAtPosition = camera.CFrame.Position
			
			base.CFrame = CFrame.lookAt(targetPosition, lookAtPosition)
			
			if outerRing then
				outerRing.CFrame = base.CFrame * CFrame.Angles(0, math.rad(90), 0)
			end
			
			if innerCross then
				innerCross.CFrame = base.CFrame
			end
		end
		
		updateEnhancedMarker(deltaTime)
	end
	
	-- Smooth camera follow with prediction
	local humanoid = rootPart.Parent:FindFirstChildOfClass("Humanoid")
	local velocity = rootPart.AssemblyLinearVelocity
	local predictedPosition = rootPart.Position + velocity * 0.1
	
	local targetLookAt = CFrame.lookAt(camera.CFrame.Position, predictedPosition)
	camera.CFrame = camera.CFrame:Lerp(targetLookAt, LockOnConfig.CAMERA_FOLLOW_SPEED)
end

local function startLockOn(target)
	if not target then return false end
	
	currentTarget = target
	isLockedOn = true
	
	createEnhancedTargetMarker()
	
	if currentFOVTween then
		currentFOVTween:Cancel()
	end
	
	currentFOVTween = TweenService:Create(
		camera,
		TweenInfo.new(LockOnConfig.CAMERA_ZOOM_SPEED, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{FieldOfView = LockOnConfig.CAMERA_ZOOM_FOV}
	)
	currentFOVTween:Play()
	
	if lockConnection then
		lockConnection:Disconnect()
	end
	lockConnection = RunService.RenderStepped:Connect(updateCameraLock)
	
	-- Get all targets for switching
	targetList = getAllValidTargets()
	for i, candidate in ipairs(targetList) do
		if candidate.target == target then
			currentTargetIndex = i
			break
		end
	end
	
	return true
end

local function cancelLockOn()
	isLockedOn = false
	currentTarget = nil
	targetList = {}
	currentTargetIndex = 1
	
	removeEnhancedTargetMarker()
	
	if currentFOVTween then
		currentFOVTween:Cancel()
	end
	
	currentFOVTween = TweenService:Create(
		camera,
		TweenInfo.new(LockOnConfig.CAMERA_ZOOM_SPEED, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{FieldOfView = defaultFOV}
	)
	currentFOVTween:Play()
	
	if lockConnection then
		lockConnection:Disconnect()
		lockConnection = nil
	end
end

local function switchTarget()
	if not isLockedOn or #targetList <= 1 then return end
	
	currentTargetIndex = currentTargetIndex % #targetList + 1
	local newTarget = targetList[currentTargetIndex].target
	
	if isTargetValid(newTarget) then
		currentTarget = newTarget
		
		-- Visual feedback for switch
		if innerCross then
			local switchAnim = TweenService:Create(
				innerCross,
				TweenInfo.new(0.1, Enum.EasingStyle.Quad),
				{Size = Vector3.new(5, 5, 0.1)}
			)
			switchAnim:Play()
			switchAnim.Completed:Connect(function()
				TweenService:Create(
					innerCross,
					TweenInfo.new(0.1, Enum.EasingStyle.Quad),
					{Size = Vector3.new(4, 4, 0.1)}
				):Play()
			end)
		end
	else
		-- Remove invalid target and try next
		table.remove(targetList, currentTargetIndex)
		if #targetList > 0 then
			currentTargetIndex = math.min(currentTargetIndex, #targetList)
			switchTarget()
		else
			cancelLockOn()
		end
	end
end

local function toggleLockOn()
	if isLockedOn then
		cancelLockOn()
	else
		local candidates = getAllValidTargets()
		if #candidates > 0 then
			startLockOn(candidates[1].target)
		end
	end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == LockOnConfig.LOCK_ON_KEY then
		toggleLockOn()
	elseif input.KeyCode == SWITCH_TARGET_KEY and isLockedOn then
		switchTarget()
	end
end)

-- Cleanup handlers
player.CharacterRemoving:Connect(function()
	cancelLockOn()
end)

Workspace.DescendantRemoving:Connect(function(descendant)
	if currentTarget and (descendant == currentTarget or descendant:IsDescendantOf(currentTarget)) then
		cancelLockOn()
	end
end)

print("Enhanced Lock-On System initialized!")
print("Controls: Left Ctrl = Toggle Lock | Tab = Switch Target (while locked)")