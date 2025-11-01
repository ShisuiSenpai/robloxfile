-- Round System & King of the Hill Server Script
-- Place this in ServerScriptService (REPLACES KingOfTheHillServer.lua)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local KING_PART_NAME = "PyramidKing"
local TIME_TO_WIN = 5
local INTERMISSION_TIME = 8
local MINIMUM_PLAYERS = 2
local DEBUG = false

-- Game state
local gameState = "Intermission" -- Intermission, WaitingForPlayers, InProgress
local currentKing = nil
local kingTimer = 0
local playersAlive = {}

-- Debug print
local function debugPrint(...)
	if DEBUG then
		print("[ROUND SYSTEM]", ...)
	end
end

print("[ROUND SYSTEM] Starting...")

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

-- Find spawn locations
local lobbySpawns = workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("LobbySpawns")
local pyramidSpawns = workspace:FindFirstChild("Pyramid") and workspace.Pyramid:FindFirstChild("PyramidSpawns")

if not lobbySpawns then
	warn("[ROUND SYSTEM] LobbySpawns not found! Looking for: Lobby > LobbySpawns")
end

if not pyramidSpawns then
	warn("[ROUND SYSTEM] PyramidSpawns not found! Looking for: Pyramid > PyramidSpawns")
end

-- Find the king part
local kingPart = workspace:FindFirstChild(KING_PART_NAME)
if not kingPart then
	warn("[ROUND SYSTEM] Could not find part named '" .. KING_PART_NAME .. "'")
	return
end

-- Create detection zone
local detectionZone = Instance.new("Part")
detectionZone.Name = "KingDetectionZone"
detectionZone.Size = Vector3.new(kingPart.Size.X, 12, kingPart.Size.Z)
detectionZone.Position = kingPart.Position + Vector3.new(0, 6, 0)
detectionZone.Anchored = true
detectionZone.CanCollide = false
detectionZone.Transparency = 1
detectionZone.Parent = workspace

-- Find crown accessory
local crownAccessory = nil
if ReplicatedStorage:FindFirstChild("Assets") then
	crownAccessory = ReplicatedStorage.Assets:FindFirstChild("Crown")
	if crownAccessory then
		debugPrint("Crown found!")
	end
end

-- Helper: Get random spawn from folder
local function getRandomSpawn(spawnFolder)
	if not spawnFolder then return nil end
	
	local spawns = spawnFolder:GetChildren()
	if #spawns == 0 then return nil end
	
	return spawns[math.random(1, #spawns)]
end

-- Helper: Spawn player at location
local function spawnPlayerAt(player, spawnFolder)
	if not player.Character then return end
	
	local spawn = getRandomSpawn(spawnFolder)
	if not spawn then
		warn("[ROUND SYSTEM] No spawn found in folder!")
		return
	end
	
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		-- Teleport with slight offset to prevent clipping
		rootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
		rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		debugPrint("Spawned", player.Name, "at", spawn.Name)
	end
end

-- Crown management
local function giveCrown(player)
	if not crownAccessory or not player.Character then return end
	if player.Character:FindFirstChild("KingCrown") then return end
	
	local crown = crownAccessory:Clone()
	crown.Name = "KingCrown"
	crown.Parent = player.Character
end

local function removeCrown(player)
	if not player or not player.Character then return end
	local crown = player.Character:FindFirstChild("KingCrown")
	if crown then crown:Destroy() end
end

-- Update king display
local function updateKingDisplay(player, timeRemaining)
	if player then
		updateKingEvent:FireAllClients(player, timeRemaining, TIME_TO_WIN)
	else
		updateKingEvent:FireAllClients(nil, 0, TIME_TO_WIN)
	end
end

-- Check if player is in the king zone
local function isPlayerInZone(player)
	if not player.Character then return false end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end
	
	-- Check if position is within zone bounds
	local zonePos = detectionZone.Position
	local zoneSize = detectionZone.Size / 2
	local rootPos = rootPart.Position
	
	local inX = math.abs(rootPos.X - zonePos.X) <= zoneSize.X
	local inY = math.abs(rootPos.Y - zonePos.Y) <= zoneSize.Y
	local inZ = math.abs(rootPos.Z - zonePos.Z) <= zoneSize.Z
	
	return inX and inY and inZ
end

-- Handle player winning
local function onPlayerWin(player)
	print("========================================")
	print(player.Name, "CONQUERED THE PYRAMID!")
	print("========================================")
	
	gameState = "GameOver"
	removeCrown(player)
	
	-- Announce winner
	winnerEvent:FireAllClients(player)
	
	-- Clear king
	currentKing = nil
	kingTimer = 0
	updateKingDisplay(nil, 0)
	
	-- Wait for victory screen (5 seconds total before new round)
	task.wait(5)
	
	-- Start intermission
	gameState = "Intermission"
	roundStatusEvent:FireAllClients("intermission", INTERMISSION_TIME)
	
	-- Send all players to lobby
	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Character then
			spawnPlayerAt(plr, lobbySpawns)
			playersAlive[plr] = false
		end
	end
	
	-- Intermission countdown
	for i = INTERMISSION_TIME, 1, -1 do
		debugPrint("Intermission:", i)
		task.wait(1)
	end
	
	-- Check if enough players
	if #Players:GetPlayers() < MINIMUM_PLAYERS then
		gameState = "WaitingForPlayers"
	else
		startNewRound()
	end
end

-- Freeze player
local function freezePlayer(player)
	if not player.Character then return end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	end
end

-- Unfreeze player
local function unfreezePlayer(player)
	if not player.Character then return end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.JumpHeight = 7.2
	end
end

-- Start a new round
function startNewRound()
	print("========================================")
	print("NEW ROUND STARTING!")
	print("========================================")
	
	gameState = "InProgress"
	currentKing = nil
	kingTimer = 0
	playersAlive = {}
	
	-- Spawn all players at pyramid spawns and freeze them
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			spawnPlayerAt(player, pyramidSpawns)
			playersAlive[player] = true
			freezePlayer(player)
		end
	end
	
	-- Start countdown
	roundStatusEvent:FireAllClients("countdown", 3)
	
	-- Countdown: 3, 2, 1
	for i = 3, 1, -1 do
		debugPrint("Countdown:", i)
		task.wait(1)
		if i > 1 then
			roundStatusEvent:FireAllClients("countdown", i - 1)
		end
	end
	
	-- GO! Unfreeze all players
	roundStatusEvent:FireAllClients("roundStart", 0)
	for _, player in pairs(Players:GetPlayers()) do
		if playersAlive[player] then
			unfreezePlayer(player)
		end
	end
	
	debugPrint("Round started with", #Players:GetPlayers(), "players")
end

-- Handle player death during round
local function onPlayerDeath(player)
	if gameState ~= "InProgress" then return end
	
	debugPrint(player.Name, "died")
	
	-- Remove from alive list
	playersAlive[player] = false
	
	-- Remove crown if they were king
	if currentKing == player then
		removeCrown(player)
		currentKing = nil
		kingTimer = 0
		updateKingDisplay(nil, 0)
	end
	
	-- Send them to lobby
	task.wait(2) -- Wait for death animation
	if player.Character then
		spawnPlayerAt(player, lobbySpawns)
	end
end

-- Setup player character events
local function setupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		
		-- Handle death
		humanoid.Died:Connect(function()
			onPlayerDeath(player)
		end)
		
		-- Spawn in correct location based on game state
		task.wait(0.5)
		if gameState == "InProgress" and playersAlive[player] then
			-- Respawn in pyramid if they're alive in round
			spawnPlayerAt(player, pyramidSpawns)
		else
			-- Otherwise spawn in lobby
			spawnPlayerAt(player, lobbySpawns)
		end
	end)
end

-- Handle players joining
Players.PlayerAdded:Connect(function(player)
	setupPlayer(player)
	
	-- Spawn in lobby initially
	player.CharacterAdded:Wait()
	task.wait(1)
	spawnPlayerAt(player, lobbySpawns)
	
	-- Send current game state to new player
	if gameState == "WaitingForPlayers" then
		roundStatusEvent:FireClient(player, "waitingForPlayers", 0)
	elseif gameState == "Intermission" then
		roundStatusEvent:FireClient(player, "intermission", INTERMISSION_TIME)
	end
	
	-- Check if we have enough players to start
	if gameState == "WaitingForPlayers" and #Players:GetPlayers() >= MINIMUM_PLAYERS then
		gameState = "Intermission"
		roundStatusEvent:FireAllClients("intermission", 5)
		task.wait(5)
		startNewRound()
	end
end)

-- Handle players leaving
Players.PlayerRemoving:Connect(function(player)
	playersAlive[player] = nil
	
	if currentKing == player then
		removeCrown(player)
		currentKing = nil
		kingTimer = 0
		updateKingDisplay(nil, 0)
	end
	
	-- Check if not enough players
	if gameState == "InProgress" and #Players:GetPlayers() - 1 < MINIMUM_PLAYERS then
		print("[ROUND SYSTEM] Not enough players, ending round")
		gameState = "WaitingForPlayers"
		roundStatusEvent:FireAllClients("waitingForPlayers", 0)
	end
end)

-- Setup existing players
for _, player in pairs(Players:GetPlayers()) do
	setupPlayer(player)
end

-- Main game loop
task.spawn(function()
	debugPrint("Main game loop started")
	
	-- Initial state check
	if #Players:GetPlayers() < MINIMUM_PLAYERS then
		gameState = "WaitingForPlayers"
		roundStatusEvent:FireAllClients("waitingForPlayers", 0)
		
		-- Wait for enough players
		while #Players:GetPlayers() < MINIMUM_PLAYERS do
			task.wait(1)
		end
		
		-- Start intermission
		gameState = "Intermission"
		roundStatusEvent:FireAllClients("intermission", 5)
		task.wait(5)
		startNewRound()
	else
		-- Enough players, start first round after intermission
		gameState = "Intermission"
		roundStatusEvent:FireAllClients("intermission", 5)
		task.wait(5)
		startNewRound()
	end
	
	-- Main loop
	while true do
		task.wait(0.1)
		
		if gameState == "InProgress" then
			-- Find who's in the king zone
			local playerInZone = nil
			
			for _, player in pairs(Players:GetPlayers()) do
				if playersAlive[player] and isPlayerInZone(player) then
					playerInZone = player
					break
				end
			end
			
			if playerInZone then
				if currentKing == playerInZone then
					-- Same king, increment timer
					kingTimer = kingTimer + 0.1
					local timeRemaining = TIME_TO_WIN - kingTimer
					
					updateKingDisplay(currentKing, timeRemaining)
					
					-- Check if they won
					if kingTimer >= TIME_TO_WIN then
						onPlayerWin(currentKing)
					end
				else
					-- New king
					if currentKing then
						removeCrown(currentKing)
					end
					
					print(playerInZone.Name, "is now the King!")
					currentKing = playerInZone
					kingTimer = 0
					updateKingDisplay(currentKing, TIME_TO_WIN)
					giveCrown(currentKing)
				end
			else
				-- No one in zone
				if currentKing then
					debugPrint(currentKing.Name, "left the king zone")
					removeCrown(currentKing)
					currentKing = nil
					kingTimer = 0
					updateKingDisplay(nil, 0)
				end
			end
		elseif gameState == "WaitingForPlayers" then
			-- Check if we have enough players now
			if #Players:GetPlayers() >= MINIMUM_PLAYERS then
				gameState = "Intermission"
				roundStatusEvent:FireAllClients("intermission", 5)
				task.wait(5)
				startNewRound()
			end
		end
	end
end)

print("========================================")
print("Round System Ready!")
print("Minimum players:", MINIMUM_PLAYERS)
print("========================================")
