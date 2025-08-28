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

-- Function to set camera to the table view with cinematic pan
local function setTableCamera(player)
	local camera = workspace.CurrentCamera
	
	-- Store the original camera type if not already stored
	if not originalCameraTypes[player] then
		originalCameraTypes[player] = camera.CameraType
	end
	
	-- Set camera to scriptable mode
	camera.CameraType = Enum.CameraType.Scriptable
	
	-- Calculate starting position (above and slightly back from the target)
	local targetCFrame = cameraPart.CFrame
	local startOffset = CFrame.new(0, 10, 5) -- 10 studs up, 5 studs back
	local lookDownAngle = CFrame.Angles(math.rad(-15), 0, 0) -- Look down 15 degrees
	local startCFrame = targetCFrame * startOffset * lookDownAngle
	
	-- Set camera to starting position instantly
	camera.CFrame = startCFrame
	
	-- Create a two-part animation for more cinematic feel
	-- Part 1: Quick move to intermediate position
	local tweenInfo1 = TweenInfo.new(
		0.8, -- Duration
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	)
	
	-- Intermediate position (slightly above final position)
	local intermediateCFrame = targetCFrame * CFrame.new(0, 2, 1) * CFrame.Angles(math.rad(-5), 0, 0)
	
	local tween1 = TweenService:Create(camera, tweenInfo1, {
		CFrame = intermediateCFrame
	})
	
	-- Part 2: Slow settle to final position
	local tweenInfo2 = TweenInfo.new(
		0.6, -- Duration
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)
	
	local tween2 = TweenService:Create(camera, tweenInfo2, {
		CFrame = targetCFrame
	})
	
	-- Play the animation sequence
	tween1:Play()
	tween1.Completed:Connect(function()
		tween2:Play()
	end)
end

-- Function to reset camera to default with smooth transition
local function resetCamera(player)
	local camera = workspace.CurrentCamera
	local character = player.Character
	
	if character and character:FindFirstChild("HumanoidRootPart") then
		-- Create a smooth transition back to the player
		local targetCFrame = camera.CFrame
		local playerPosition = character.HumanoidRootPart.Position
		local transitionCFrame = CFrame.lookAt(
			playerPosition + Vector3.new(5, 8, 8), -- Camera position relative to player
			playerPosition -- Look at player
		)
		
		local tweenInfo = TweenInfo.new(
			0.5, -- Duration
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.InOut
		)
		
		local tween = TweenService:Create(camera, tweenInfo, {
			CFrame = transitionCFrame
		})
		
		tween:Play()
		tween.Completed:Connect(function()
			-- Restore original camera type after transition
			if originalCameraTypes[player] then
				camera.CameraType = originalCameraTypes[player]
				originalCameraTypes[player] = nil
			else
				-- Default to Custom if original type wasn't stored
				camera.CameraType = Enum.CameraType.Custom
			end
		end)
	else
		-- If no character, just reset immediately
		if originalCameraTypes[player] then
			camera.CameraType = originalCameraTypes[player]
			originalCameraTypes[player] = nil
		else
			camera.CameraType = Enum.CameraType.Custom
		end
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