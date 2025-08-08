-- SimpleLockOn LocalScript
-- A simplified, guaranteed-to-work lock-on system
-- Place in: StarterPlayer > StarterPlayerScripts > LockOnClient

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Configuration
local LOCK_KEY = Enum.KeyCode.F
local MAX_DISTANCE = 100
local ZOOM_FOV = 50
local MARKER_COLOR = Color3.fromRGB(255, 0, 0)

-- State
local isLockedOn = false
local currentTarget = nil
local targetMarker = nil
local updateConnection = nil
local originalFOV = camera.FieldOfView

print("[SimpleLockOn] System starting...")

-- Create a visible marker
local function createMarker()
	if targetMarker then
		targetMarker:Destroy()
	end
	
	-- Create a glowing sphere
	targetMarker = Instance.new("Part")
	targetMarker.Name = "LockOnMarker"
	targetMarker.Shape = Enum.PartType.Ball
	targetMarker.Material = Enum.Material.Neon
	targetMarker.Size = Vector3.new(4, 4, 4)
	targetMarker.Color = MARKER_COLOR
	targetMarker.Anchored = true
	targetMarker.CanCollide = false
	targetMarker.Transparency = 0.5
	targetMarker.Parent = workspace
	
	-- Add a PointLight for glow effect
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Color = MARKER_COLOR
	light.Range = 10
	light.Parent = targetMarker
	
	print("[SimpleLockOn] Marker created")
end

-- Find closest target
local function findTarget()
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("[SimpleLockOn] No player character found")
		return nil
	end
	
	local myPosition = character.HumanoidRootPart.Position
	local closestTarget = nil
	local closestDistance = MAX_DISTANCE
	
	-- Look for all models with humanoids
	for _, model in pairs(workspace:GetDescendants()) do
		if model:IsA("Model") and model ~= character then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
			
			if humanoid and rootPart and humanoid.Health > 0 then
				local distance = (rootPart.Position - myPosition).Magnitude
				if distance < closestDistance then
					closestDistance = distance
					closestTarget = model
				end
			end
		end
	end
	
	if closestTarget then
		print("[SimpleLockOn] Found target:", closestTarget.Name, "at distance:", closestDistance)
	else
		print("[SimpleLockOn] No targets found within range")
	end
	
	return closestTarget
end

-- Update camera and marker
local function updateLockOn()
	if not isLockedOn or not currentTarget then
		return
	end
	
	local rootPart = currentTarget:FindFirstChild("HumanoidRootPart") or currentTarget:FindFirstChild("Torso") or currentTarget:FindFirstChild("UpperTorso")
	local humanoid = currentTarget:FindFirstChildOfClass("Humanoid")
	
	if not rootPart or not humanoid or humanoid.Health <= 0 then
		print("[SimpleLockOn] Target lost")
		stopLockOn()
		return
	end
	
	-- Update marker position
	if targetMarker then
		targetMarker.Position = rootPart.Position
		-- Spin the marker for visual effect
		targetMarker.CFrame = targetMarker.CFrame * CFrame.Angles(0, math.rad(2), 0)
	end
	
	-- Smoothly rotate camera to look at target
	local lookAtCFrame = CFrame.lookAt(camera.CFrame.Position, rootPart.Position)
	camera.CFrame = camera.CFrame:Lerp(lookAtCFrame, 0.1)
end

-- Start lock-on
function startLockOn()
	local target = findTarget()
	if not target then
		return
	end
	
	currentTarget = target
	isLockedOn = true
	
	-- Create marker
	createMarker()
	
	-- Zoom in
	TweenService:Create(camera, TweenInfo.new(0.3), {FieldOfView = ZOOM_FOV}):Play()
	
	-- Start update loop
	if updateConnection then
		updateConnection:Disconnect()
	end
	updateConnection = RunService.RenderStepped:Connect(updateLockOn)
	
	print("[SimpleLockOn] Locked onto:", target.Name)
end

-- Stop lock-on
function stopLockOn()
	isLockedOn = false
	currentTarget = nil
	
	-- Remove marker
	if targetMarker then
		targetMarker:Destroy()
		targetMarker = nil
	end
	
	-- Reset zoom
	TweenService:Create(camera, TweenInfo.new(0.3), {FieldOfView = originalFOV}):Play()
	
	-- Stop update loop
	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end
	
	print("[SimpleLockOn] Lock released")
end

-- Toggle lock-on
local function toggleLockOn()
	if isLockedOn then
		stopLockOn()
	else
		startLockOn()
	end
end

-- Handle input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == LOCK_KEY then
		print("[SimpleLockOn] F key pressed")
		toggleLockOn()
	end
end)

-- Clean up on character removal
if player.Character then
	player.Character.AncestryChanged:Connect(function()
		if not player.Character.Parent then
			stopLockOn()
		end
	end)
end

player.CharacterAdded:Connect(function(character)
	character.AncestryChanged:Connect(function()
		if not character.Parent then
			stopLockOn()
		end
	end)
end)

print("[SimpleLockOn] System ready! Press F to lock onto targets.")
print("[SimpleLockOn] Make sure there are other characters/NPCs with Humanoids in your game!")