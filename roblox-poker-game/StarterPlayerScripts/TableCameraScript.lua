-- TableCameraScriptMulti.lua
-- This script handles camera changes when players sit at any poker table
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Table configurations
local TABLE_CONFIGS = {
	Table1Folder = {
		cameraPart = "CameraPartTable1",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table2Folder = {
		cameraPart = "CameraPartTable2",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table3Folder = {
		cameraPart = "CameraPartTable3",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table4Folder = {
		cameraPart = "CameraPartTable4",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table5Folder = {
		cameraPart = "CameraPartTable5",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table6Folder = {
		cameraPart = "CameraPartTable6",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table7Folder = {
		cameraPart = "CameraPartTable7",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table8Folder = {
		cameraPart = "CameraPartTable8",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table9Folder = {
		cameraPart = "CameraPartTable9",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table10Folder = {
		cameraPart = "CameraPartTable10",
		seats = {"Player1Chair", "Player2Chair"}
	}
}

-- Store all seats and their corresponding camera parts
local seatToCameraPart = {}
local allSeats = {}

-- Initialize seats
for folderName, config in pairs(TABLE_CONFIGS) do
	local folder = workspace:WaitForChild(folderName)
	local cameraPart = folder:WaitForChild(config.cameraPart)

	for _, chairName in ipairs(config.seats) do
		local chair = folder:FindFirstChild(chairName)
		if chair then
			local seat = chair:FindFirstChild("Seat")
			if seat then
				table.insert(allSeats, seat)
				seatToCameraPart[seat] = cameraPart
			end
		end
	end
end

-- Camera animation settings
local CAMERA_ANIMATION_TIME = 1.8
local originalCameraType = nil
local currentCameraConnection = nil
local isTransitioning = false

-- Set table camera for a specific camera part
local function setTableCamera(targetCameraPart)
	if not player.Character then return end

	-- Store original camera type
	if not originalCameraType then
		originalCameraType = camera.CameraType
	end

	camera.CameraType = Enum.CameraType.Scriptable

	-- Calculate positions
	local startCFrame = camera.CFrame
	local targetCFrame = targetCameraPart.CFrame

	-- Create intermediate position (higher up)
	local midPoint = targetCFrame.Position + Vector3.new(0, 10, -5)
	local intermediateCFrame = CFrame.lookAt(midPoint, targetCFrame.Position)

	-- Disconnect any existing animation
	if currentCameraConnection then
		currentCameraConnection:Disconnect()
		currentCameraConnection = nil
	end

	-- Animate camera
	local startTime = tick()
	isTransitioning = true

	currentCameraConnection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		local progress = math.min(elapsed / CAMERA_ANIMATION_TIME, 1)

		if progress < 0.5 then
			-- First phase: move to intermediate position
			local alpha = progress * 2
			alpha = 1 - (1 - alpha)^3 -- Ease out
			camera.CFrame = startCFrame:Lerp(intermediateCFrame, alpha)
		else
			-- Second phase: move to final position
			local alpha = (progress - 0.5) * 2
			alpha = alpha * alpha * alpha -- Ease in
			camera.CFrame = intermediateCFrame:Lerp(targetCFrame, alpha)
		end

		if progress >= 1 then
			camera.CFrame = targetCFrame
			currentCameraConnection:Disconnect()
			currentCameraConnection = nil
			isTransitioning = false
		end
	end)
end

-- Reset camera to default
local function resetCamera()
	if currentCameraConnection then
		currentCameraConnection:Disconnect()
		currentCameraConnection = nil
	end

	if originalCameraType then
		camera.CameraType = originalCameraType
		originalCameraType = nil
	end

	isTransitioning = false
end

-- Check if player is seated at any table
local function checkSeating()
	if not player.Character then return end
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local currentSeat = humanoid.SeatPart

	-- Check if seated at any poker table
	if currentSeat and seatToCameraPart[currentSeat] then
		-- Set camera to the appropriate table
		setTableCamera(seatToCameraPart[currentSeat])
	else
		-- Not seated at a poker table
		resetCamera()
	end
end

-- Monitor character and seating
local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Connect to seated event
	humanoid.Seated:Connect(function()
		wait(0.1) -- Small delay for seat registration
		checkSeating()
	end)

	-- Also monitor seat part changes
	humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		checkSeating()
	end)
end

-- Clean up on character removal
player.CharacterRemoving:Connect(function()
	resetCamera()
end)

-- Connect to existing character
if player.Character then
	onCharacterAdded(player.Character)
end

-- Connect to future characters
player.CharacterAdded:Connect(onCharacterAdded)

print("[TableCamera] Multi-table camera script loaded")