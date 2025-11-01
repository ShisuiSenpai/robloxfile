-- King of the Hill Server Script (Fixed - Stable Detection)
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local KING_PART_NAME = "PyramidKing" -- Name of the part in workspace
local TIME_TO_WIN = 5 -- Seconds on the king part to win
local ROUND_INTERMISSION = 8 -- Seconds between rounds
local DEBUG = false -- Set to true for debug messages

-- Game state
local currentKing = nil
local kingTimer = 0
local roundInProgress = true

-- Debug print
local function debugPrint(...)
	if DEBUG then
		print("[KING SERVER]", ...)
	end
end

debugPrint("King of the Hill server starting...")

-- Create RemoteEvents
local updateKingEvent = Instance.new("RemoteEvent")
updateKingEvent.Name = "UpdateKing"
updateKingEvent.Parent = ReplicatedStorage

local roundStatusEvent = Instance.new("RemoteEvent")
roundStatusEvent.Name = "RoundStatus"
roundStatusEvent.Parent = ReplicatedStorage

local winnerEvent = Instance.new("RemoteEvent")
winnerEvent.Name = "Winner"
winnerEvent.Parent = ReplicatedStorage

debugPrint("RemoteEvents created")

-- Find the king part
local kingPart = workspace:FindFirstChild(KING_PART_NAME)
if not kingPart then
	warn("[KING SERVER] Could not find part named '" .. KING_PART_NAME .. "' in workspace!")
	warn("Please create a part named 'PyramidKing' at the top of your pyramid!")
	return
end

debugPrint("Found king part:", kingPart.Name)

-- Create an invisible detection zone (box volume) above the king part
local detectionZone = Instance.new("Part")
detectionZone.Name = "KingDetectionZone"
detectionZone.Size = Vector3.new(kingPart.Size.X, 12, kingPart.Size.Z) -- Tall box (12 studs high)
detectionZone.Position = kingPart.Position + Vector3.new(0, 6, 0) -- Center it above the part
detectionZone.Anchored = true
detectionZone.CanCollide = false -- Don't interfere with player movement
detectionZone.Transparency = 1 -- Invisible
detectionZone.Parent = workspace

debugPrint("Detection zone created")

-- Find the crown accessory
local crownAccessory = nil
if ReplicatedStorage:FindFirstChild("Assets") then
	crownAccessory = ReplicatedStorage.Assets:FindFirstChild("Crown")
	if crownAccessory then
		debugPrint("Crown accessory found!")
	else
		warn("[KING SERVER] Crown accessory not found in Assets folder!")
	end
else
	warn("[KING SERVER] Assets folder not found in ReplicatedStorage!")
end

-- Function to give crown to player
local function giveCrown(player)
	if not crownAccessory then return end
	
	local character = player.Character
	if not character then return end
	
	-- Check if player already has the crown
	if character:FindFirstChild("KingCrown") then
		return
	end
	
	-- Clone and add crown to character
	local crown = crownAccessory:Clone()
	crown.Name = "KingCrown"
	crown.Parent = character
	
	debugPrint("Gave crown to", player.Name)
end

-- Function to remove crown from player
local function removeCrown(player)
	if not player or not player.Character then return end
	
	local character = player.Character
	local crown = character:FindFirstChild("KingCrown")
	
	if crown then
		crown:Destroy()
		debugPrint("Removed crown from", player.Name)
	end
end

-- Update the current king to all clients
local function updateKingDisplay(player, timeRemaining)
	if player then
		debugPrint("King:", player.Name, "Time:", string.format("%.1f", timeRemaining))
		updateKingEvent:FireAllClients(player, timeRemaining, TIME_TO_WIN)
	else
		debugPrint("No king")
		updateKingEvent:FireAllClients(nil, 0, TIME_TO_WIN)
	end
end

-- Handle player winning
local function playerWins(player)
	print("========================================")
	print("WINNER:", player.Name)
	print("========================================")
	
	roundInProgress = false
	
	-- Remove crown from winner
	removeCrown(player)
	
	-- Announce winner to all clients
	winnerEvent:FireAllClients(player)
	
	-- Clear king display
	currentKing = nil
	kingTimer = 0
	updateKingDisplay(nil, 0)
	
	-- Wait for intermission
	task.wait(ROUND_INTERMISSION)
	
	-- Reset the round
	debugPrint("New round starting...")
	roundInProgress = true
	roundStatusEvent:FireAllClients("newRound")
end

-- Check if a player's HumanoidRootPart is inside the detection zone
local function isPlayerInZone(player)
	if not player.Character then return false end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end
	
	-- Calculate if root part is within the zone bounds
	local zonePos = detectionZone.Position
	local zoneSize = detectionZone.Size / 2
	local rootPos = rootPart.Position
	
	local inX = math.abs(rootPos.X - zonePos.X) <= zoneSize.X
	local inY = math.abs(rootPos.Y - zonePos.Y) <= zoneSize.Y
	local inZ = math.abs(rootPos.Z - zonePos.Z) <= zoneSize.Z
	
	return inX and inY and inZ
end

-- Main game loop with stable detection
task.spawn(function()
	debugPrint("Game loop started")
	
	while true do
		task.wait(0.1) -- Check every 0.1 seconds
		
		if roundInProgress then
			-- Find who's in the zone
			local playerInZone = nil
			
			for _, player in pairs(Players:GetPlayers()) do
				if isPlayerInZone(player) then
					playerInZone = player
					break -- Only one king at a time
				end
			end
			
			if playerInZone then
				-- Someone is in the zone
				if currentKing == playerInZone then
					-- Same king, increment timer
					kingTimer = kingTimer + 0.1
					local timeRemaining = TIME_TO_WIN - kingTimer
					
					-- Update UI
					updateKingDisplay(currentKing, timeRemaining)
					
					-- Check if they won
					if kingTimer >= TIME_TO_WIN then
						playerWins(currentKing)
					end
				else
					-- New king
					if currentKing then
						removeCrown(currentKing)
					end
					
					debugPrint("New king:", playerInZone.Name)
					currentKing = playerInZone
					kingTimer = 0
					updateKingDisplay(currentKing, TIME_TO_WIN)
					giveCrown(currentKing)
				end
			else
				-- No one in the zone
				if currentKing then
					debugPrint("King left the zone:", currentKing.Name)
					removeCrown(currentKing)
					currentKing = nil
					kingTimer = 0
					updateKingDisplay(nil, 0)
				end
			end
		end
	end
end)

-- Handle player death
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		
		humanoid.Died:Connect(function()
			if currentKing == player then
				debugPrint("Current king died:", player.Name)
				removeCrown(player)
				currentKing = nil
				kingTimer = 0
				updateKingDisplay(nil, 0)
			end
		end)
	end)
end)

-- Handle player leaving game
Players.PlayerRemoving:Connect(function(player)
	if currentKing == player then
		debugPrint("Current king left the game:", player.Name)
		removeCrown(player)
		currentKing = nil
		kingTimer = 0
		updateKingDisplay(nil, 0)
	end
end)

print("========================================")
print("King of the Hill Ready!")
print("Climb to the pyramid top to become king!")
print("========================================")
