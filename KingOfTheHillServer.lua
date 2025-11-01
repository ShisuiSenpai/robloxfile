-- King of the Hill Server Script
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Configuration
local KING_PART_NAME = "PyramidKing" -- Name of the part in workspace
local TIME_TO_WIN = 5 -- Seconds on the king part to win
local ROUND_INTERMISSION = 8 -- Seconds between rounds
local DEBUG = true

-- Game state
local currentKing = nil
local kingTimer = 0
local gameActive = false
local roundInProgress = false

-- Debug print
local function debugPrint(...)
	if DEBUG then
		print("[KING OF THE HILL]", ...)
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
	warn("[KING OF THE HILL] Could not find part named '" .. KING_PART_NAME .. "' in workspace!")
	warn("Please create a part named 'PyramidKing' at the top of your pyramid!")
	return
end

debugPrint("Found king part:", kingPart.Name)

-- Get all players currently touching the king part
local function getPlayersOnKingPart()
	local playersOnPart = {}
	local touchingParts = kingPart:GetTouchingParts()
	
	for _, part in pairs(touchingParts) do
		if part.Parent and part.Parent:FindFirstChildOfClass("Humanoid") then
			local player = Players:GetPlayerFromCharacter(part.Parent)
			if player then
				local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					table.insert(playersOnPart, player)
				end
			end
		end
	end
	
	return playersOnPart
end

-- Update the current king to all clients
local function updateKingDisplay(player, timeRemaining)
	if player then
		debugPrint("Updating king display:", player.Name, "Time:", timeRemaining)
		updateKingEvent:FireAllClients(player, timeRemaining, TIME_TO_WIN)
	else
		debugPrint("Clearing king display")
		updateKingEvent:FireAllClients(nil, 0, TIME_TO_WIN)
	end
end

-- Handle player winning
local function playerWins(player)
	debugPrint("===== PLAYER WINS =====")
	debugPrint("Winner:", player.Name)
	
	roundInProgress = false
	gameActive = false
	
	-- Announce winner to all clients
	winnerEvent:FireAllClients(player)
	
	-- Clear king display
	updateKingDisplay(nil, 0)
	
	-- Wait for intermission
	debugPrint("Starting intermission for", ROUND_INTERMISSION, "seconds")
	task.wait(ROUND_INTERMISSION)
	
	-- Reset the round
	debugPrint("Resetting round...")
	currentKing = nil
	kingTimer = 0
	roundInProgress = true
	gameActive = true
	
	-- Announce new round
	roundStatusEvent:FireAllClients("newRound")
	
	debugPrint("New round started!")
end

-- Main game loop
local function gameLoop()
	debugPrint("Game loop started")
	gameActive = true
	roundInProgress = true
	
	while true do
		task.wait(0.1) -- Check every 0.1 seconds for smooth timer
		
		if not roundInProgress then
			task.wait(1)
			continue
		end
		
		-- Get all players on the king part
		local playersOnPart = getPlayersOnKingPart()
		
		if #playersOnPart > 0 then
			-- At least one player is on the part
			local newKing = playersOnPart[1] -- Take the first player (or could randomize)
			
			if currentKing == newKing then
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
				-- New king, reset timer
				debugPrint("New king:", newKing.Name)
				currentKing = newKing
				kingTimer = 0
				updateKingDisplay(currentKing, TIME_TO_WIN)
			end
		else
			-- No one on the part
			if currentKing then
				debugPrint("King left the part:", currentKing.Name)
			end
			currentKing = nil
			kingTimer = 0
			updateKingDisplay(nil, 0)
		end
	end
end

-- Handle player respawn (clear them as king if they die)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		
		humanoid.Died:Connect(function()
			if currentKing == player then
				debugPrint("Current king died:", player.Name)
				currentKing = nil
				kingTimer = 0
				updateKingDisplay(nil, 0)
			end
		end)
	end)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	if currentKing == player then
		debugPrint("Current king left the game:", player.Name)
		currentKing = nil
		kingTimer = 0
		updateKingDisplay(nil, 0)
	end
end)

-- Start the game
debugPrint("==========================================")
debugPrint("King of the Hill Game Ready!")
debugPrint("King Part:", KING_PART_NAME)
debugPrint("Time to Win:", TIME_TO_WIN, "seconds")
debugPrint("Starting game loop...")
debugPrint("==========================================")

-- Start game loop
task.spawn(gameLoop)
