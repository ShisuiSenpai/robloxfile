-- Round System & King of the Hill Server Script [OPTIMIZED]
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local KING_PART_NAME = "PyramidKing"
local TIME_TO_WIN = 5
local INTERMISSION_TIME = 8
local MINIMUM_PLAYERS = 2
local DEBUG = false

-- Game state
local gameState = "Intermission"
local currentKing = nil
local kingTimer = 0
local playersAlive = {}
local lastKingUpdate = 0 -- Track last update time for optimization

-- State lock to prevent race conditions
local stateLock = false

-- Debug print
local function debugPrint(...)
	if DEBUG then
		print("[ROUND SYSTEM]", ...)
	end
end

print("[ROUND SYSTEM] Starting...")

-- Create RemoteEvents (or reuse existing)
local updateKingEvent = ReplicatedStorage:FindFirstChild("UpdateKing") or Instance.new("RemoteEvent")
updateKingEvent.Name = "UpdateKing"
updateKingEvent.Parent = ReplicatedStorage

local roundStatusEvent = ReplicatedStorage:FindFirstChild("RoundStatus") or Instance.new("RemoteEvent")
roundStatusEvent.Name = "RoundStatus"
roundStatusEvent.Parent = ReplicatedStorage

local winnerEvent = ReplicatedStorage:FindFirstChild("Winner") or Instance.new("RemoteEvent")
winnerEvent.Name = "Winner"
winnerEvent.Parent = ReplicatedStorage

local playSoundEvent = ReplicatedStorage:FindFirstChild("PlaySound") or Instance.new("RemoteEvent")
playSoundEvent.Name = "PlaySound"
playSoundEvent.Parent = ReplicatedStorage

debugPrint("RemoteEvents ready")

-- Find spawn locations with error handling
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

-- Find assets
local crownAccessory = nil
local pushTool = nil

if ReplicatedStorage:FindFirstChild("Assets") then
	crownAccessory = ReplicatedStorage.Assets:FindFirstChild("Crown")
	if crownAccessory then
		debugPrint("Crown found!")
	end

	pushTool = ReplicatedStorage.Assets:FindFirstChild("Push")
	if pushTool and pushTool:IsA("Tool") then
		debugPrint("Push tool found!")
	else
		warn("[ROUND SYSTEM] Push tool not found in ReplicatedStorage > Assets > Push")
	end
end

-- OPTIMIZED: Cache spawn list to avoid repeated GetChildren calls
local cachedLobbySpawns = lobbySpawns and lobbySpawns:GetChildren() or {}
local cachedPyramidSpawns = pyramidSpawns and pyramidSpawns:GetChildren() or {}

-- Helper: Get random spawn from cached list
local function getRandomSpawn(spawnCache)
	if #spawnCache == 0 then return nil end
	return spawnCache[math.random(1, #spawnCache)]
end

-- Helper: Spawn player at location
-- Track which spawns are currently in use (to avoid duplicate spawns)
local usedSpawns = {}

local function spawnPlayerAt(player, spawnCache)
	if not player or not player.Character then return end

	-- For pyramid spawns, ensure unique spawn per player
	local isPyramidSpawn = (spawnCache == cachedPyramidSpawns)
	local spawn = nil

	if isPyramidSpawn then
		-- Find an unused spawn point
		local availableSpawns = {}
		for _, spawnPoint in ipairs(spawnCache) do
			if not usedSpawns[spawnPoint] then
				table.insert(availableSpawns, spawnPoint)
			end
		end

		-- If all spawns are used, use any spawn (shouldn't happen with 12 spawns and 12 max players)
		if #availableSpawns == 0 then
			warn("[ROUND] All pyramid spawns in use, reusing spawn point")
			spawn = getRandomSpawn(spawnCache)
		else
			-- Pick random spawn from available spawns
			spawn = availableSpawns[math.random(1, #availableSpawns)]
			-- Mark this spawn as used
			usedSpawns[spawn] = player
			debugPrint("Assigned unique spawn to", player.Name, "- Remaining spawns:", #availableSpawns - 1)
		end
	else
		-- For lobby spawns, just use random (doesn't matter if they overlap)
		spawn = getRandomSpawn(spawnCache)
	end

	if not spawn then
		warn("[ROUND SYSTEM] No spawn found!")
		return
	end

	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		-- Teleport with offset and clear velocity
		rootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		debugPrint("Spawned", player.Name, "at", spawn.Name)
	end
end

-- Crown management
local function giveCrown(player)
	if not crownAccessory or not player or not player.Character then return end
	if player.Character:FindFirstChild("KingCrown") then return end

	local success, crown = pcall(function()
		local c = crownAccessory:Clone()
		c.Name = "KingCrown"
		c.Parent = player.Character
		return c
	end)

	if not success then
		warn("[ROUND SYSTEM] Failed to give crown to", player.Name)
	end
end

local function removeCrown(player)
	if not player or not player.Character then return end
	local crown = player.Character:FindFirstChild("KingCrown")
	if crown then pcall(function() crown:Destroy() end) end
end

-- Push tool management
local function givePushTool(player)
	if not pushTool or not player then return end

	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end

	-- Check if already has tool
	if backpack:FindFirstChild("Push") or (player.Character and player.Character:FindFirstChild("Push")) then
		return
	end

	-- Clone and give tool
	local success = pcall(function()
		local toolClone = pushTool:Clone()
		toolClone.Parent = backpack
	end)

	if success then
		debugPrint("Gave push tool to", player.Name)
	end
end

local function removePushTool(player)
	if not player then return end

	-- Remove from backpack and character
	pcall(function()
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			local tool = backpack:FindFirstChild("Push")
			if tool then tool:Destroy() end
		end
	end)

	pcall(function()
		if player.Character then
			local tool = player.Character:FindFirstChild("Push")
			if tool then tool:Destroy() end
		end
	end)
end

-- OPTIMIZED: Only update king display when value actually changes
local lastTimeRemaining = -1
local function updateKingDisplay(player, timeRemaining)
	-- Round to 1 decimal to reduce network spam
	local roundedTime = math.floor(timeRemaining * 10) / 10

	-- Only fire if changed or new king
	if player and (roundedTime ~= lastTimeRemaining or currentKing ~= player) then
		updateKingEvent:FireAllClients(player, roundedTime, TIME_TO_WIN)
		lastTimeRemaining = roundedTime
	elseif not player and lastTimeRemaining ~= -1 then
		updateKingEvent:FireAllClients(nil, 0, TIME_TO_WIN)
		lastTimeRemaining = -1
	end
end

-- Check if player is in the king zone
local function isPlayerInZone(player)
	if not player or not player.Character then return false end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	-- Optimized bounds check
	local zonePos = detectionZone.Position
	local zoneSize = detectionZone.Size / 2
	local rootPos = rootPart.Position

	return math.abs(rootPos.X - zonePos.X) <= zoneSize.X
		and math.abs(rootPos.Y - zonePos.Y) <= zoneSize.Y
		and math.abs(rootPos.Z - zonePos.Z) <= zoneSize.Z
end

-- Freeze/Unfreeze players
local function freezePlayer(player)
	if not player or not player.Character then return end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	end
end

local function unfreezePlayer(player)
	if not player or not player.Character then return end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Base speeds
		local baseWalkSpeed = 16
		local baseJumpPower = 50

		-- Check for speed boost gamepass
		local speedMultiplier = 1
		if _G.GamepassManager then
			speedMultiplier = _G.GamepassManager.getSpeedMultiplier(player)
		end

		humanoid.WalkSpeed = baseWalkSpeed * speedMultiplier
		humanoid.JumpPower = baseJumpPower
		humanoid.JumpHeight = 7.2

		if speedMultiplier > 1 then
			print("[ROUND]", player.Name, "unfrozen with speed boost:", speedMultiplier, "x")
		end
	end
end

-- Handle player winning
local function onPlayerWin(player)
	if stateLock then return end -- Prevent double-wins
	stateLock = true

	print("========================================")
	print(player.Name, "CONQUERED THE PYRAMID!")
	print("========================================")

	gameState = "GameOver"
	removeCrown(player)

	-- Award win to player
	if _G.StatsManager then
		_G.StatsManager.addWin(player)
	end

	-- Increment win streak
	if _G.StreakManager then
		_G.StreakManager.incrementStreak(player)
	end

	-- Reset other players' streaks
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player and _G.StreakManager then
			_G.StreakManager.resetStreak(otherPlayer)
		end
	end

	-- Announce winner
	winnerEvent:FireAllClients(player)
	playSoundEvent:FireAllClients("player_wins")

	-- Clear king
	currentKing = nil
	kingTimer = 0
	updateKingDisplay(nil, 0)

	-- Wait for victory screen
	task.wait(5)

	-- Start intermission
	gameState = "Intermission"

	-- Reset lava IMMEDIATELY
	if _G.LavaRisingControl then
		print("[ROUND] Resetting lava for intermission")
		_G.LavaRisingControl.resetLava()
	else
		warn("[ROUND] LavaRisingControl not found!")
	end

	roundStatusEvent:FireAllClients("intermission", INTERMISSION_TIME)

	-- Send all players to lobby
	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Character then
			spawnPlayerAt(plr, cachedLobbySpawns)
			playersAlive[plr] = false
			removePushTool(plr)
		end
	end

	-- Intermission countdown
	for i = INTERMISSION_TIME, 1, -1 do
		task.wait(1)
	end

	stateLock = false

	-- Check if enough players
	if #Players:GetPlayers() < MINIMUM_PLAYERS then
		gameState = "WaitingForPlayers"
		roundStatusEvent:FireAllClients("waitingForPlayers", 0)
	else
		startNewRound()
	end
end

-- Start a new round
function startNewRound()
	if stateLock then return end -- Prevent overlapping rounds
	stateLock = true

	print("========================================")
	print("NEW ROUND STARTING!")
	print("========================================")

	gameState = "InProgress"
	currentKing = nil
	kingTimer = 0
	lastTimeRemaining = -1
	playersAlive = {}

	-- Clear used spawns for new round
	usedSpawns = {}

	-- Ensure lava is reset before starting (double-check)
	if _G.LavaRisingControl then
		_G.LavaRisingControl.resetLava()
	end

	-- Spawn and freeze all players
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			spawnPlayerAt(player, cachedPyramidSpawns)
			playersAlive[player] = true
			freezePlayer(player)
			givePushTool(player)
		end
	end

	-- Start countdown
	roundStatusEvent:FireAllClients("countdown", 3)

	-- Countdown: 3, 2, 1
	for i = 3, 1, -1 do
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

	stateLock = false
	debugPrint("Round started with", #Players:GetPlayers(), "players")

	-- Start lava rising
	if _G.LavaRisingControl then
		task.delay(1, function()
			_G.LavaRisingControl.startRising()
		end)
	end
end

-- Handle player death
local function onPlayerDeath(player)
	if gameState ~= "InProgress" then return end

	debugPrint(player.Name, "died")

	playersAlive[player] = false

	if currentKing == player then
		removeCrown(player)
		currentKing = nil
		kingTimer = 0
		updateKingDisplay(nil, 0)
	end

	removePushTool(player)

	-- Clear this player's spawn usage (they're going to lobby now)
	for spawn, usedByPlayer in pairs(usedSpawns) do
		if usedByPlayer == player then
			usedSpawns[spawn] = nil
		end
	end

	task.wait(2)
	if player and player.Character then
		spawnPlayerAt(player, cachedLobbySpawns)
	end

	-- Check if all players are dead
	local aliveCount = 0
	for _, isAlive in pairs(playersAlive) do
		if isAlive then
			aliveCount = aliveCount + 1
		end
	end

	if aliveCount == 0 then
		print("========================================")
		print("[ROUND] ALL PLAYERS DIED - No winner!")
		print("[ROUND] Resetting round...")
		print("========================================")

		-- Clear the current king if any
		if currentKing then
			removeCrown(currentKing)
			currentKing = nil
		end
		kingTimer = 0
		updateKingDisplay(nil, 0)

		-- Reset lava
		if _G.LavaRisingControl then
			print("[ROUND] Resetting lava due to all players dead")
			_G.LavaRisingControl.resetLava()
		end

		-- Start intermission
		gameState = "Intermission"
		roundStatusEvent:FireAllClients("intermission", INTERMISSION_TIME)
		playSoundEvent:FireAllClients("intermission")

		task.wait(INTERMISSION_TIME)

		-- Check if we still have enough players
		local playerCount = #Players:GetPlayers()
		if playerCount >= MINIMUM_PLAYERS then
			startNewRound()
		else
			gameState = "WaitingForPlayers"
			roundStatusEvent:FireAllClients("waitingForPlayers")
		end
	end
end

-- Setup player
local function setupPlayer(player)
	if not player then return end

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if not humanoid then return end

		-- Handle death
		humanoid.Died:Connect(function()
			onPlayerDeath(player)
		end)

		-- Spawn in correct location
		task.wait(0.5)
		if gameState == "InProgress" and playersAlive[player] then
			spawnPlayerAt(player, cachedPyramidSpawns)
			givePushTool(player)
		else
			spawnPlayerAt(player, cachedLobbySpawns)
			removePushTool(player)
		end
	end)
end

-- Handle players joining
Players.PlayerAdded:Connect(function(player)
	setupPlayer(player)

	-- Initial spawn
	if player.Character or player.CharacterAdded:Wait() then
		task.wait(1)
		spawnPlayerAt(player, cachedLobbySpawns)
		removePushTool(player)

		-- Send current game state
		if gameState == "WaitingForPlayers" then
			roundStatusEvent:FireClient(player, "waitingForPlayers", 0)
		elseif gameState == "Intermission" then
			roundStatusEvent:FireClient(player, "intermission", INTERMISSION_TIME)
		end

		-- Check if can start
		if gameState == "WaitingForPlayers" and #Players:GetPlayers() >= MINIMUM_PLAYERS then
			gameState = "Intermission"
			roundStatusEvent:FireAllClients("intermission", 5)
			task.wait(5)
			startNewRound()
		end
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

	-- Check player count
	task.wait(0.1) -- Small delay for accurate count
	if gameState == "InProgress" and #Players:GetPlayers() < MINIMUM_PLAYERS then
		print("[ROUND SYSTEM] Not enough players, ending round")
		gameState = "WaitingForPlayers"
		roundStatusEvent:FireAllClients("waitingForPlayers", 0)
	end
end)

-- Setup existing players
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		setupPlayer(player)
	end)
end

-- OPTIMIZED Main game loop
task.spawn(function()
	debugPrint("Main game loop started")

	-- Initial state check
	if #Players:GetPlayers() < MINIMUM_PLAYERS then
		gameState = "WaitingForPlayers"
		roundStatusEvent:FireAllClients("waitingForPlayers", 0)

		while #Players:GetPlayers() < MINIMUM_PLAYERS do
			task.wait(1)
		end

		gameState = "Intermission"
		roundStatusEvent:FireAllClients("intermission", 5)
		task.wait(5)
		startNewRound()
	else
		gameState = "Intermission"
		roundStatusEvent:FireAllClients("intermission", 5)
		task.wait(5)
		startNewRound()
	end

	-- Main loop
	while true do
		task.wait(0.1)

		if gameState == "InProgress" then
			local playerInZone = nil

			-- Find player in zone
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

					-- Play tick sound every second
					if math.floor(kingTimer * 10) % 10 == 0 then
						playSoundEvent:FireClient(currentKing, "king_tick")
					end

					-- Check victory
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
					playSoundEvent:FireClient(playerInZone, "become_king")
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
print("Round System Ready! [OPTIMIZED]")
print("Minimum players:", MINIMUM_PLAYERS)
print("========================================")
