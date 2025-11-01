-- King of the Hill Server Script (Fixed)
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local KING_PART_NAME = "PyramidKing" -- Name of the part in workspace
local TIME_TO_WIN = 5 -- Seconds on the king part to win
local ROUND_INTERMISSION = 8 -- Seconds between rounds
local DEBUG = true

-- Game state
local currentKing = nil
local kingTimer = 0
local roundInProgress = true
local playersOnPart = {} -- Track who's currently on the part

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

debugPrint("Found king part:", kingPart.Name, "| Position:", kingPart.Position)

-- Create an invisible detection zone (box volume) above the king part
-- This way jumping doesn't make you lose king status
local detectionZone = Instance.new("Part")
detectionZone.Name = "KingDetectionZone"
detectionZone.Size = Vector3.new(kingPart.Size.X, 12, kingPart.Size.Z) -- Tall box (12 studs high)
detectionZone.Position = kingPart.Position + Vector3.new(0, 6, 0) -- Center it above the part
detectionZone.Anchored = true
detectionZone.CanCollide = false -- Don't interfere with player movement
detectionZone.Transparency = 1 -- Invisible
detectionZone.Parent = workspace

-- Optional: Add a visible outline for testing (comment out in production)
if DEBUG then
	detectionZone.Transparency = 0.8
	detectionZone.BrickColor = BrickColor.new("Bright blue")
	detectionZone.Material = Enum.Material.ForceField
end

debugPrint("Detection zone created | Size:", detectionZone.Size, "| Position:", detectionZone.Position)

-- Update the current king to all clients
local function updateKingDisplay(player, timeRemaining)
	if player then
		debugPrint("Sending king update:", player.Name, "Time remaining:", string.format("%.1f", timeRemaining))
		updateKingEvent:FireAllClients(player, timeRemaining, TIME_TO_WIN)
	else
		debugPrint("Sending clear king signal")
		updateKingEvent:FireAllClients(nil, 0, TIME_TO_WIN)
	end
end

-- Handle player winning
local function playerWins(player)
	debugPrint("========================================")
	debugPrint("WINNER:", player.Name)
	debugPrint("========================================")
	
	roundInProgress = false
	
	-- Announce winner to all clients
	winnerEvent:FireAllClients(player)
	
	-- Clear king display
	currentKing = nil
	kingTimer = 0
	playersOnPart = {}
	updateKingDisplay(nil, 0)
	
	-- Wait for intermission
	debugPrint("Intermission started:", ROUND_INTERMISSION, "seconds")
	task.wait(ROUND_INTERMISSION)
	
	-- Reset the round
	debugPrint("New round starting...")
	roundInProgress = true
	roundStatusEvent:FireAllClients("newRound")
	debugPrint("Game active again!")
end

-- Handle player entering the detection zone (the invisible box)
detectionZone.Touched:Connect(function(hit)
	if not roundInProgress then return end
	
	-- Check if it's a player's character part
	local character = hit.Parent
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end
	
	-- Check if player is already tracked
	if playersOnPart[player] then return end
	
	debugPrint("Player entered king part:", player.Name)
	playersOnPart[player] = true
	
	-- If no current king, make this player the king
	if not currentKing then
		debugPrint("New king set:", player.Name)
		currentKing = player
		kingTimer = 0
		updateKingDisplay(currentKing, TIME_TO_WIN)
	end
end)

-- Handle player leaving the detection zone
detectionZone.TouchEnded:Connect(function(hit)
	-- Check if it's a player's character part
	local character = hit.Parent
	if not character then return end
	
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end
	
	-- Remove player from tracking
	if playersOnPart[player] then
		debugPrint("Player left king part:", player.Name)
		playersOnPart[player] = nil
		
		-- If the current king left, clear everything
		if currentKing == player then
			debugPrint("Current king left! Clearing king status")
			currentKing = nil
			kingTimer = 0
			updateKingDisplay(nil, 0)
			
			-- Check if there's another player on the part to become king
			for otherPlayer, _ in pairs(playersOnPart) do
				if otherPlayer and otherPlayer.Character then
					local otherHumanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
					if otherHumanoid and otherHumanoid.Health > 0 then
						debugPrint("New king from remaining players:", otherPlayer.Name)
						currentKing = otherPlayer
						kingTimer = 0
						updateKingDisplay(currentKing, TIME_TO_WIN)
						break
					end
				end
			end
		end
	end
end)

-- Main timer loop
task.spawn(function()
	debugPrint("Timer loop started")
	
	while true do
		task.wait(0.1) -- Update every 0.1 seconds for smooth timer
		
		if roundInProgress and currentKing then
			-- Verify king is still valid
			local kingValid = false
			if currentKing.Character then
				local humanoid = currentKing.Character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 and playersOnPart[currentKing] then
					kingValid = true
				end
			end
			
			if kingValid then
				-- Increment timer
				kingTimer = kingTimer + 0.1
				local timeRemaining = TIME_TO_WIN - kingTimer
				
				-- Update UI
				updateKingDisplay(currentKing, timeRemaining)
				
				-- Check if they won
				if kingTimer >= TIME_TO_WIN then
					playerWins(currentKing)
				end
			else
				-- King is no longer valid
				debugPrint("King became invalid (died or left)")
				currentKing = nil
				kingTimer = 0
				updateKingDisplay(nil, 0)
			end
		end
	end
end)

-- Handle player death
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		
		humanoid.Died:Connect(function()
			-- Remove from tracking
			playersOnPart[player] = nil
			
			if currentKing == player then
				debugPrint("Current king died:", player.Name)
				currentKing = nil
				kingTimer = 0
				updateKingDisplay(nil, 0)
			end
		end)
	end)
end)

-- Handle player leaving game
Players.PlayerRemoving:Connect(function(player)
	playersOnPart[player] = nil
	
	if currentKing == player then
		debugPrint("Current king left the game:", player.Name)
		currentKing = nil
		kingTimer = 0
		updateKingDisplay(nil, 0)
	end
end)

debugPrint("==========================================")
debugPrint("King of the Hill Ready!")
debugPrint("Waiting for players to reach the pyramid top...")
debugPrint("==========================================")
