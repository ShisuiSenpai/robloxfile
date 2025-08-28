-- Table Camera Script
-- This script handles camera changes when players sit on chairs at Table1

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- References to game objects
local table1Folder = workspace:WaitForChild("Table1Folder")
local player1Chair = table1Folder:WaitForChild("Player1Chair"):WaitForChild("Seat")
local player2Chair = table1Folder:WaitForChild("Player2Chair"):WaitForChild("Seat")
local cameraPart = table1Folder:WaitForChild("CameraPartTable1")

-- Store connections and camera states for each player
local playerConnections = {}
local originalCameraTypes = {}

-- Function to set camera to the table view
local function setTableCamera(player)
	local camera = workspace.CurrentCamera
	
	-- Store the original camera type if not already stored
	if not originalCameraTypes[player] then
		originalCameraTypes[player] = camera.CameraType
	end
	
	-- Set camera to scriptable mode
	camera.CameraType = Enum.CameraType.Scriptable
	
	-- Smoothly transition to the camera part position
	local tweenInfo = TweenInfo.new(
		0.5, -- Duration
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	
	local tween = TweenService:Create(camera, tweenInfo, {
		CFrame = cameraPart.CFrame
	})
	
	tween:Play()
end

-- Function to reset camera to default
local function resetCamera(player)
	local camera = workspace.CurrentCamera
	
	-- Restore original camera type
	if originalCameraTypes[player] then
		camera.CameraType = originalCameraTypes[player]
		originalCameraTypes[player] = nil
	else
		-- Default to Custom if original type wasn't stored
		camera.CameraType = Enum.CameraType.Custom
	end
end

-- Function to handle when a humanoid sits down
local function onSeatOccupantChanged(seat, property)
	if property ~= "Occupant" then return end
	
	local humanoid = seat.Occupant
	
	if humanoid then
		-- Someone sat down
		local character = humanoid.Parent
		local player = Players:GetPlayerFromCharacter(character)
		
		if player and player == Players.LocalPlayer then
			-- This is the local player, change their camera
			setTableCamera(player)
			
			-- Store connection to reset camera when they get up
			if playerConnections[player] then
				playerConnections[player]:Disconnect()
			end
			
			playerConnections[player] = humanoid.Seated:Connect(function(isSeated, currentSeat)
				if not isSeated or (currentSeat ~= player1Chair and currentSeat ~= player2Chair) then
					-- Player got up or sat somewhere else
					resetCamera(player)
					if playerConnections[player] then
						playerConnections[player]:Disconnect()
						playerConnections[player] = nil
					end
				end
			end)
		end
	end
end

-- Connect seat occupancy changes
player1Chair:GetPropertyChangedSignal("Occupant"):Connect(function()
	onSeatOccupantChanged(player1Chair, "Occupant")
end)

player2Chair:GetPropertyChangedSignal("Occupant"):Connect(function()
	onSeatOccupantChanged(player2Chair, "Occupant")
end)

-- Clean up connections when player leaves
Players.LocalPlayer.CharacterRemoving:Connect(function()
	local player = Players.LocalPlayer
	if playerConnections[player] then
		playerConnections[player]:Disconnect()
		playerConnections[player] = nil
	end
	originalCameraTypes[player] = nil
end)

-- Optional: Add camera controls while seated
local function updateCameraWhileSeated()
	local player = Players.LocalPlayer
	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
	
	if humanoid and humanoid.SeatPart and 
	   (humanoid.SeatPart == player1Chair or humanoid.SeatPart == player2Chair) then
		-- Keep camera locked to the camera part
		local camera = workspace.CurrentCamera
		if camera.CameraType == Enum.CameraType.Scriptable then
			camera.CFrame = cameraPart.CFrame
		end
	end
end

-- Update camera position every frame while seated
RunService.RenderStepped:Connect(updateCameraWhileSeated)