-- Round System Main Script
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configuration
local MIN_PLAYERS = 2 -- Minimum players to start
local INTERMISSION_TIME = 10 -- Seconds for intermission
local FREEZE_TIME = 3 -- Seconds players are frozen at round start
local RESPAWN_DELAY = 1 -- Delay before respawning to lobby

-- Game States
local GameState = {
	WAITING = "WAITING",
	INTERMISSION = "INTERMISSION",
	STARTING = "STARTING",
	IN_PROGRESS = "IN_PROGRESS",
	ENDING = "ENDING"
}

-- Current state
local currentState = GameState.WAITING
local playersInRound = {}
local roundActive = false
local freezePlayers = false

-- Get spawn locations
local spawnMap = workspace:WaitForChild("SpawnMap")
local gameMap = workspace:WaitForChild("Map")
local lobbySpawns = {}
local gameSpawns = {}

-- Collect spawn points
local function collectSpawnPoints()
	lobbySpawns = {}
	gameSpawns = {}

	-- Collect lobby spawns
	for _, spawn in pairs(spawnMap:GetDescendants()) do
		if spawn:IsA("SpawnLocation") then
			table.insert(lobbySpawns, spawn)
			spawn.Enabled = true -- Enable lobby spawns
		end
	end

	-- Collect game spawns
	for _, spawn in pairs(gameMap:GetDescendants()) do
		if spawn:IsA("SpawnLocation") then
			table.insert(gameSpawns, spawn)
			spawn.Enabled = false -- Disable game spawns initially
		end
	end

	print("[ROUND SYSTEM] Found", #lobbySpawns, "lobby spawns and", #gameSpawns, "game spawns")
end

-- Create RemoteEvents for UI
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "RoundEvents"
remoteEvents.Parent = ReplicatedStorage

local stateChangeRemote = Instance.new("RemoteEvent")
stateChangeRemote.Name = "StateChange"
stateChangeRemote.Parent = remoteEvents

local timerRemote = Instance.new("RemoteEvent")
timerRemote.Name = "TimerUpdate"
timerRemote.Parent = remoteEvents

-- Global hazards flag for gating map hazards
local hazardsEnabled = Instance.new("BoolValue")
hazardsEnabled.Name = "HazardsEnabled"
hazardsEnabled.Value = false
hazardsEnabled.Parent = ReplicatedStorage

-- Broadcast state to all clients
local function broadcastState(state, message)
	stateChangeRemote:FireAllClients(state, message)
	print("[ROUND SYSTEM] State:", state, "-", message or "")
end

-- Broadcast timer to all clients with total time and phase
local function broadcastTimer(timeLeft, totalTime, phase)
	timerRemote:FireAllClients(timeLeft, totalTime, phase)
end

-- Teleport player to spawn
local function teleportToSpawn(player, spawnList)
	if not player.Character then return end

	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	if #spawnList > 0 then
		local randomSpawn = spawnList[math.random(1, #spawnList)]
		humanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
	end
end

-- Freeze/Unfreeze player
local function setPlayerFreeze(player, frozen)
	if not player.Character then return end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")

	if humanoid and rootPart then
		if frozen then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
			rootPart.Anchored = true
		else
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.JumpHeight = 7.2
			rootPart.Anchored = false
		end
	end
end

-- Control kill brick
local function setKillBrickActive(active)
	-- Find the rotating kill part
	local killPart = workspace:FindFirstChild("SpinKiller")
	if killPart then
		local script = killPart:FindFirstChildOfClass("Script")
		if script then
			script.Enabled = active
			print("[ROUND SYSTEM] Kill brick", active and "activated" or "deactivated")
		end
	end
end

-- Handle player death
local function onPlayerDied(player)
	-- Remove from round
	for i, p in ipairs(playersInRound) do
		if p == player then
			table.remove(playersInRound, i)
			break
		end
	end

	print("[ROUND SYSTEM]", player.Name, "died. Players remaining:", #playersInRound)

	-- Respawn to lobby after delay
	task.wait(RESPAWN_DELAY)
	if player.Character then
		player:LoadCharacter()
		task.wait(0.5)
		teleportToSpawn(player, lobbySpawns)
	end

	-- Check for winner
	if roundActive and #playersInRound == 1 then
		-- We have a winner!
		local winner = playersInRound[1]
		endRound(winner)
	elseif roundActive and #playersInRound == 0 then
		-- No winner (shouldn't happen but safety check)
		endRound(nil)
	end
end

-- Start round
local function startRound()
	currentState = GameState.STARTING
	roundActive = true
	playersInRound = {}

	print("[ROUND SYSTEM] Starting round...")
	broadcastState("STARTING", "Round starting!")

	-- Disable hazards during freeze
	hazardsEnabled.Value = false
	setKillBrickActive(false)

	-- Disable lobby spawns, enable game spawns
	for _, spawn in pairs(lobbySpawns) do
		spawn.Enabled = false
	end
	for _, spawn in pairs(gameSpawns) do
		spawn.Enabled = true
	end

	-- Teleport all players to game map
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(playersInRound, player)
			teleportToSpawn(player, gameSpawns)
			setPlayerFreeze(player, true) -- Freeze players
		end
	end

	-- Countdown freeze time
	for i = FREEZE_TIME, 1, -1 do
		broadcastState("STARTING", "Get ready! " .. i)
		broadcastTimer(i, FREEZE_TIME, "FREEZE")
		task.wait(1)
	end

	-- Unfreeze players and start the round
	currentState = GameState.IN_PROGRESS
	broadcastState("IN_PROGRESS", "GO!")

	for _, player in pairs(playersInRound) do
		setPlayerFreeze(player, false)
	end

	-- Activate hazards after freeze
	hazardsEnabled.Value = true
	setKillBrickActive(true)

	print("[ROUND SYSTEM] Round is now active with", #playersInRound, "players")
end

-- End round
function endRound(winner)
	if not roundActive then return end

	currentState = GameState.ENDING
	roundActive = false

	-- Deactivate hazards immediately
	hazardsEnabled.Value = false
	setKillBrickActive(false)

	if winner then
		broadcastState("ENDING", winner.Name .. " wins!")
		print("[ROUND SYSTEM]", winner.Name, "won the round!")

		-- Give reward here if needed
		-- winner.leaderstats.Wins.Value += 1
	else
		broadcastState("ENDING", "Round ended - no winner")
		print("[ROUND SYSTEM] Round ended with no winner")
	end

	-- Wait a bit to show winner
	task.wait(3)

	-- Teleport all players back to lobby
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			player:LoadCharacter()
			task.wait(0.1)
			teleportToSpawn(player, lobbySpawns)
		end
	end

	-- Re-enable lobby spawns, disable game spawns
	for _, spawn in pairs(lobbySpawns) do
		spawn.Enabled = true
	end
	for _, spawn in pairs(gameSpawns) do
		spawn.Enabled = false
	end

	-- Reset to waiting state
	currentState = GameState.WAITING
	playersInRound = {}

	print("[ROUND SYSTEM] Returned to lobby, waiting for players...")
end

-- Main game loop
local function gameLoop()
	while true do
		local playerCount = #Players:GetPlayers()

		if currentState == GameState.WAITING then
			if playerCount >= MIN_PLAYERS then
				-- Start intermission
				currentState = GameState.INTERMISSION
				broadcastState("INTERMISSION", "Starting intermission...")

				for i = INTERMISSION_TIME, 1, -1 do
					broadcastTimer(i, INTERMISSION_TIME, "INTERMISSION")
					broadcastState("INTERMISSION", "Round starts in " .. i .. " seconds")
					task.wait(1)

					-- Check if enough players still
					if #Players:GetPlayers() < MIN_PLAYERS then
						currentState = GameState.WAITING
						broadcastState("WAITING", "Not enough players")
						break
					end
				end

				-- Start round if still enough players
				if currentState == GameState.INTERMISSION and #Players:GetPlayers() >= MIN_PLAYERS then
					startRound()
				end
			else
				broadcastState("WAITING", "Waiting for players... (" .. playerCount .. "/" .. MIN_PLAYERS .. ")")
			end
		end

		task.wait(1)
	end
end

-- Player joined
Players.PlayerAdded:Connect(function(player)
	print("[ROUND SYSTEM]", player.Name, "joined. Total players:", #Players:GetPlayers())

	-- Set up character spawning
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- Handle death
		humanoid.Died:Connect(function()
			if roundActive then
				onPlayerDied(player)
			end
		end)

		-- Spawn in lobby if not in round
		if not roundActive then
			task.wait(0.5)
			teleportToSpawn(player, lobbySpawns)
		end
	end)

	-- Initial spawn
	player:LoadCharacter()
end)

-- Player left
Players.PlayerRemoving:Connect(function(player)
	print("[ROUND SYSTEM]", player.Name, "left. Total players:", #Players:GetPlayers() - 1)

	-- Remove from round if in it
	for i, p in ipairs(playersInRound) do
		if p == player then
			table.remove(playersInRound, i)
			break
		end
	end

	-- Check if round should end
	if roundActive and #playersInRound <= 1 then
		if #playersInRound == 1 then
			endRound(playersInRound[1])
		else
			endRound(nil)
		end
	end
end)

-- Initialize
collectSpawnPoints()

-- Ensure hazards are disabled at startup
hazardsEnabled.Value = false
setKillBrickActive(false)

print("[ROUND SYSTEM] Initialized and waiting for players...")

-- Start game loop
task.spawn(gameLoop)

