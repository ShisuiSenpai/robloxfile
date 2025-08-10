-- Main.server.lua
-- Server-side main game controller

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Module references
local Modules = ServerScriptService:WaitForChild("Modules")
local GameManager = require(Modules:WaitForChild("GameManager"))
local SpawnManager = require(Modules:WaitForChild("SpawnManager"))
local IntermissionManager = require(Modules:WaitForChild("IntermissionManager"))
local PathManager = require(Modules:WaitForChild("PathManager"))
local QuizController = require(Modules:WaitForChild("QuizController"))
local MovementController = require(Modules:WaitForChild("MovementController"))
local DarkLightingSystem = require(Modules:WaitForChild("DarkLightingSystem"))

-- Remote Events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Game variables
local MIN_PLAYERS = 1 -- Minimum players to start a round

-- Initialize the dark lighting system
local darkLighting = DarkLightingSystem.new()
darkLighting:CreateEnvironmentalLights()
print("[Main] Dark lighting system initialized")

-- Player management
local function onPlayerAdded(player)
	print("[Main] Player joined:", player.Name)
	
	-- Handle character spawning
	player.CharacterAdded:Connect(function(character)
		-- Give time for character to fully load
		task.wait(0.5)
		
		-- Check if game is in progress
		if GameManager:GetGameState() == "InGame" then
			-- Player joined mid-game, add as spectator
			print("[Main] Player joined mid-game, setting as spectator")
			-- Could implement spectator functionality here
		end
	end)
end

local function onPlayerRemoving(player)
	print("[Main] Player leaving:", player.Name)
	
	-- Remove from active players if in game
	if GameManager:IsPlayerActive(player) then
		GameManager:RemoveActivePlayer(player)
		
		-- Check if not enough players remain
		local activePlayers = GameManager:GetActivePlayers()
		if #activePlayers < MIN_PLAYERS and GameManager:GetGameState() == "InGame" then
			print("[Main] Not enough players, ending round")
			-- End the round early
			GameManager:SetGameState("RoundEnd")
		end
	end
end

-- Main game loop
local function runGameLoop()
	while true do
		-- Wait for enough players
		GameManager:SetGameState("Waiting")
		print("[Main] Waiting for players...")
		
		while #Players:GetPlayers() < MIN_PLAYERS do
			task.wait(1)
		end
		
		-- Start intermission
		print("[Main] Starting intermission")
		GameManager:SetGameState("Intermission")
		IntermissionManager:StartIntermission()
		
		-- Reset active players and spawn them
		GameManager:ResetActivePlayers()
		
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				-- Add as active player
				GameManager:AddActivePlayer(player)
				
				-- Spawn player at available spawn
				local spawn = SpawnManager:GetAvailableSpawn()
				if spawn then
					SpawnManager:SpawnPlayer(player, spawn)
					-- Initialize path for player
					PathManager:InitializePlayerPath(player, spawn)
				else
					warn("[Main] No available spawn for player:", player.Name)
				end
			end
		end
		
		-- Start the game
		print("[Main] Starting game round")
		GameManager:SetGameState("InGame")
		
		-- Wait a moment for all players to be positioned
		task.wait(1)
		
		-- Start the quiz controller
		QuizController:StartQuizRound()
		
		-- Wait for round to end (QuizController will change state when done)
		while GameManager:GetGameState() == "InGame" do
			task.wait(0.5)
		end
		
		-- Round ended
		print("[Main] Round ended")
		
		-- Clean up
		SpawnManager:ResetSpawns()
		PathManager:ResetAllPaths()
		GameManager:ResetActivePlayers()
		
		-- Wait before starting new round
		task.wait(5)
	end
end

-- Initialize
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in game
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Start game loop
print("[Main] Starting game loop")
task.spawn(runGameLoop)