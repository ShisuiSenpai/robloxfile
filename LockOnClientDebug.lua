-- LockOnClientDebug LocalScript with extensive debugging
-- Place in: StarterPlayer > StarterPlayerScripts > LockOnClient

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

print("[LockOn] Starting initialization...")

-- Wait for character to load
local character = player.Character or player.CharacterAdded:Wait()
print("[LockOn] Character loaded:", character)

-- Wait for modules and remotes
local LockOnModules = ReplicatedStorage:WaitForChild("LockOnModules", 5)
if not LockOnModules then
	warn("[LockOn] ERROR: LockOnModules folder not found in ReplicatedStorage!")
	return
end
print("[LockOn] Found LockOnModules folder")

local configModule = LockOnModules:WaitForChild("LockOnConfig", 5)
if not configModule then
	warn("[LockOn] ERROR: LockOnConfig module not found!")
	return
end
print("[LockOn] Found LockOnConfig module")

local LockOnConfig = require(configModule)
print("[LockOn] Config loaded successfully")
print("[LockOn] Lock key set to:", LockOnConfig.LOCK_ON_KEY)

-- State variables
local isLockedOn = false
local currentTarget = nil
local targetMarker = nil
local lockConnection = nil
local defaultFOV = camera.FieldOfView
local currentFOVTween = nil

-- Debug function
local function debugPrint(...)
	if LockOnConfig.DEBUG_MODE then
		print("[LockOn]", ...)
	end
end

-- Utility Functions
local function getAngleBetweenVectors(v1, v2)
	local dot = v1:Dot(v2)
	return math.deg(math.acos(math.clamp(dot / (v1.Magnitude * v2.Magnitude), -1, 1)))
end

local function isTargetValid(target)
	if not target then 
		debugPrint("Target is nil")
		return false 
	end
	
	if not target.Parent then 
		debugPrint("Target has no parent")
		return false 
	end
	
	local humanoid = target.Parent:FindFirstChildOfClass("Humanoid")
	if not humanoid then 
		debugPrint("No humanoid found in", target.Parent.Name)
		return false 
	end
	
	if humanoid.Health <= 0 then 
		debugPrint("Humanoid is dead")
		return false 
	end
	
	local rootPart = target.Parent:FindFirstChild("HumanoidRootPart")
	if not rootPart then 
		debugPrint("No HumanoidRootPart found")
		return false 
	end
	
	-- Don't target yourself
	if target.Parent == player.Character then 
		debugPrint("Can't target yourself")
		return false 
	end
	
	-- Check size threshold
	if rootPart.Size.Magnitude < LockOnConfig.MIN_TARGET_SIZE then 
		debugPrint("Target too small")
		return false 
	end
	
	return true, humanoid, rootPart
end

local function createTargetMarker()
	debugPrint("Creating target marker...")
	
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
	
	-- Create a simple sphere mesh for visibility
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = marker
	
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
	local rotationConnection
	rotationConnection = RunService.Heartbeat:Connect(function(dt)
		if marker and marker.Parent then
			marker.CFrame = marker.CFrame * CFrame.Angles(0, 0, math.rad(dt * 45))
		else
			rotationConnection:Disconnect()
		end
	end)
	
	targetMarker = marker
	debugPrint("Target marker created successfully")
	return marker
end

local function removeTargetMarker()
	debugPrint("Removing target marker...")
	if targetMarker then
		targetMarker:Destroy()
		targetMarker = nil
	end
end

local function findBestTarget()
	debugPrint("Searching for targets...")
	
	local character = player.Character
	if not character then 
		debugPrint("No player character found")
		return nil 
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then 
		debugPrint("No player HumanoidRootPart found")
		return nil 
	end
	
	local candidates = {}
	local cameraLookVector = camera.CFrame.LookVector
	local characterPosition = humanoidRootPart.Position
	
	-- Count all models in workspace
	local modelCount = 0
	local humanoidCount = 0
	
	-- Scan all characters in workspace
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") then
			modelCount = modelCount + 1
			local humanoid = obj:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoidCount = humanoidCount + 1
				debugPrint("Found model with humanoid:", obj.Name)
				
				local isValid, hum, rootPart = isTargetValid(obj)
				if isValid then
					local distance = (rootPart.Position - characterPosition).Magnitude
					debugPrint("  Distance:", distance, "Max allowed:", LockOnConfig.MAX_LOCK_DISTANCE)
					
					if distance <= LockOnConfig.MAX_LOCK_DISTANCE then
						local toTarget = (rootPart.Position - camera.CFrame.Position).Unit
						local angle = getAngleBetweenVectors(cameraLookVector, toTarget)
						debugPrint("  Angle from camera:", angle, "degrees")
						
						-- Calculate priority score
						local angleFactor = 1 - (angle / 180) -- 0 to 1, higher is better
						local distanceFactor = 1 - (distance / LockOnConfig.MAX_LOCK_DISTANCE) -- 0 to 1, higher is better
						local inView = angle <= LockOnConfig.LOCK_ANGLE_THRESHOLD
						
						local score = distanceFactor
						if inView then
							score = score + angleFactor * LockOnConfig.PRIORITY_VIEW_WEIGHT
						end
						
						debugPrint("  Score:", score, "In view:", inView)
						
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
	end
	
	debugPrint("Scan complete. Models:", modelCount, "With humanoids:", humanoidCount, "Valid candidates:", #candidates)
	
	-- Sort by score (highest first)
	table.sort(candidates, function(a, b)
		return a.score > b.score
	end)
	
	if #candidates > 0 then
		debugPrint("Best target:", candidates[1].target.Name, "Score:", candidates[1].score)
		return candidates[1].target
	else
		debugPrint("No valid targets found")
		return nil
	end
end

local function updateCameraLock()
	if not isLockedOn or not currentTarget then return end
	
	local isValid, humanoid, rootPart = isTargetValid(currentTarget)
	if not isValid then
		debugPrint("Target no longer valid, canceling lock")
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
	if not target then 
		debugPrint("Cannot start lock-on: no target provided")
		return false 
	end
	
	debugPrint("Starting lock-on for target:", target.Name)
	
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
	
	debugPrint("Lock-on started successfully")
	return true
end

function cancelLockOn() -- Made global for access
	debugPrint("Canceling lock-on...")
	
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
	
	debugPrint("Lock-on canceled")
end

local function toggleLockOn()
	debugPrint("Toggle lock-on called. Current state:", isLockedOn)
	
	if isLockedOn then
		cancelLockOn()
	else
		local target = findBestTarget()
		if target then
			startLockOn(target)
		else
			debugPrint("No target found to lock onto")
			print("[LockOn] No valid targets in range! Make sure there are other characters with Humanoids nearby.")
		end
	end
end

-- Test function to manually trigger lock-on
local function testLockOn()
	print("[LockOn] Running test...")
	toggleLockOn()
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then 
		debugPrint("Input was game processed, ignoring")
		return 
	end
	
	debugPrint("Key pressed:", input.KeyCode.Name)
	
	if input.KeyCode == LockOnConfig.LOCK_ON_KEY then
		debugPrint("Lock-on key detected!")
		toggleLockOn()
	end
end)

-- Cleanup on character death/removal
player.CharacterRemoving:Connect(function()
	debugPrint("Character removing, cleaning up...")
	cancelLockOn()
end)

-- Handle target leaving
Workspace.DescendantRemoving:Connect(function(descendant)
	if currentTarget and (descendant == currentTarget or descendant:IsDescendantOf(currentTarget)) then
		debugPrint("Current target is being removed")
		cancelLockOn()
	end
end)

print("[LockOn] Lock-On System initialized! Press F to lock onto targets.")
print("[LockOn] Debug mode is ON. Check output for detailed logs.")

-- Add a test command
game:GetService("Players").LocalPlayer.Chatted:Connect(function(msg)
	if msg:lower() == "/testlock" then
		testLockOn()
	end
end)

print("[LockOn] You can also type '/testlock' in chat to test the system.")