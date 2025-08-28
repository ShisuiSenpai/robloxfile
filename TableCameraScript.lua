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
local cameraTweenConnection = nil
local currentTween = nil

-- Debug mode
local DEBUG_MODE = true

local function debugPrint(...)
	if DEBUG_MODE then
		print("[TableCamera]", ...)
	end
end

-- Function to set camera to the table view with cinematic pan
local function setTableCamera(player)
	local camera = workspace.CurrentCamera
	
	debugPrint("Setting table camera for player:", player.Name)
	debugPrint("Camera Part Position:", cameraPart.Position)
	debugPrint("Camera Part CFrame:", cameraPart.CFrame)
	
	-- Store the original camera type if not already stored
	if not originalCameraTypes[player] then
		originalCameraTypes[player] = camera.CameraType
		debugPrint("Stored original camera type:", camera.CameraType.Name)
	end
	
	-- Set camera to scriptable mode
	camera.CameraType = Enum.CameraType.Scriptable
	
	-- Cancel any existing camera animation
	if cameraTweenConnection then
		cameraTweenConnection:Disconnect()
		cameraTweenConnection = nil
	end
	
	-- Calculate positions for the animation
	local targetCFrame = cameraPart.CFrame
	local startOffset = CFrame.new(0, 15, 10) -- Start higher and further back
	local startCFrame = targetCFrame * startOffset * CFrame.Angles(math.rad(-25), 0, 0)
	
	-- Intermediate position
	local intermediateCFrame = targetCFrame * CFrame.new(0, 3, 2) * CFrame.Angles(math.rad(-10), 0, 0)
	
	debugPrint("Start CFrame:", startCFrame.Position)
	debugPrint("Intermediate CFrame:", intermediateCFrame.Position)
	debugPrint("Target CFrame:", targetCFrame.Position)
	
	-- Manual animation using RenderStepped
	local startTime = tick()
	local phase1Duration = 1.0  -- First phase duration
	local phase2Duration = 0.8  -- Second phase duration
	local totalDuration = phase1Duration + phase2Duration
	
	-- Set initial camera position
	camera.CFrame = startCFrame
	
	cameraTweenConnection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		local camera = workspace.CurrentCamera
		
		-- Ensure camera stays in scriptable mode
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Scriptable
		end
		
		if elapsed < phase1Duration then
			-- Phase 1: Start to intermediate
			local alpha = elapsed / phase1Duration
			-- Apply easing (Quart Out)
			alpha = 1 - math.pow(1 - alpha, 4)
			
			camera.CFrame = startCFrame:Lerp(intermediateCFrame, alpha)
			
			if elapsed < 0.1 then -- Debug first few frames
				debugPrint("Phase 1 - Alpha:", alpha, "Camera Pos:", camera.CFrame.Position)
			end
			
		elseif elapsed < totalDuration then
			-- Phase 2: Intermediate to final
			local phase2Elapsed = elapsed - phase1Duration
			local alpha = phase2Elapsed / phase2Duration
			-- Apply easing (Quad InOut)
			if alpha < 0.5 then
				alpha = 2 * alpha * alpha
			else
				alpha = 1 - math.pow(-2 * alpha + 2, 2) / 2
			end
			
			camera.CFrame = intermediateCFrame:Lerp(targetCFrame, alpha)
			
		else
			-- Animation complete
			camera.CFrame = targetCFrame
			cameraTweenConnection:Disconnect()
			cameraTweenConnection = nil
			debugPrint("Camera animation complete")
		end
	end)
end

-- Function to reset camera to default with smooth transition
local function resetCamera(player)
	local camera = workspace.CurrentCamera
	local character = player.Character
	
	debugPrint("Resetting camera for player:", player.Name)
	
	-- Cancel any existing camera animation
	if cameraTweenConnection then
		cameraTweenConnection:Disconnect()
		cameraTweenConnection = nil
	end
	
	if character and character:FindFirstChild("HumanoidRootPart") then
		-- Manual transition back to player
		local startCFrame = camera.CFrame
		local playerPosition = character.HumanoidRootPart.Position
		local endCFrame = CFrame.lookAt(
			playerPosition + Vector3.new(5, 8, 8), -- Camera position relative to player
			playerPosition -- Look at player
		)
		
		local startTime = tick()
		local duration = 0.5
		
		cameraTweenConnection = RunService.RenderStepped:Connect(function()
			local elapsed = tick() - startTime
			local alpha = math.min(elapsed / duration, 1)
			
			-- Apply easing
			alpha = 1 - math.pow(1 - alpha, 2) -- Quad Out
			
			camera.CFrame = startCFrame:Lerp(endCFrame, alpha)
			
			if alpha >= 1 then
				-- Animation complete
				cameraTweenConnection:Disconnect()
				cameraTweenConnection = nil
				
				-- Restore original camera type
				if originalCameraTypes[player] then
					camera.CameraType = originalCameraTypes[player]
					originalCameraTypes[player] = nil
				else
					camera.CameraType = Enum.CameraType.Custom
				end
				
				debugPrint("Camera reset complete")
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
		debugPrint("Camera reset immediate (no character)")
	end
end

-- Function to handle when a humanoid sits down
local function onSeatOccupantChanged(seat, property)
	if property ~= "Occupant" then return end
	
	local seatName = seat.Parent.Name
	debugPrint("Seat occupancy changed for:", seatName)
	
	local humanoid = seat.Occupant
	
	if humanoid then
		-- Someone sat down
		local character = humanoid.Parent
		local player = Players:GetPlayerFromCharacter(character)
		
		debugPrint("Player detected:", player and player.Name or "Unknown")
		debugPrint("Is local player:", player == Players.LocalPlayer)
		
		if player and player == Players.LocalPlayer then
			-- This is the local player, change their camera
			debugPrint("Activating table camera for local player")
			setTableCamera(player)
			
			-- Store connection to reset camera when they get up
			if playerConnections[player] then
				playerConnections[player]:Disconnect()
			end
			
			playerConnections[player] = humanoid.Seated:Connect(function(isSeated, currentSeat)
				debugPrint("Seated changed - isSeated:", isSeated, "currentSeat:", currentSeat and currentSeat.Name or "None")
				
				if not isSeated or (currentSeat ~= player1Chair and currentSeat ~= player2Chair) then
					-- Player got up or sat somewhere else
					debugPrint("Player leaving seat, resetting camera")
					resetCamera(player)
					if playerConnections[player] then
						playerConnections[player]:Disconnect()
						playerConnections[player] = nil
					end
				end
			end)
		end
	else
		debugPrint("Seat is now empty")
	end
end

-- Connect seat occupancy changes
debugPrint("Connecting seat listeners...")
player1Chair:GetPropertyChangedSignal("Occupant"):Connect(function()
	onSeatOccupantChanged(player1Chair, "Occupant")
end)

player2Chair:GetPropertyChangedSignal("Occupant"):Connect(function()
	onSeatOccupantChanged(player2Chair, "Occupant")
end)

-- Clean up connections when player leaves
Players.LocalPlayer.CharacterRemoving:Connect(function()
	debugPrint("Character removing, cleaning up...")
	local player = Players.LocalPlayer
	
	-- Cancel any ongoing camera animation
	if cameraTweenConnection then
		cameraTweenConnection:Disconnect()
		cameraTweenConnection = nil
	end
	
	if playerConnections[player] then
		playerConnections[player]:Disconnect()
		playerConnections[player] = nil
	end
	originalCameraTypes[player] = nil
end)

-- Verify script is running
debugPrint("TableCamera script loaded successfully!")
debugPrint("Player1Chair found:", player1Chair and "Yes" or "No")
debugPrint("Player2Chair found:", player2Chair and "Yes" or "No")
debugPrint("CameraPartTable1 found:", cameraPart and "Yes" or "No")