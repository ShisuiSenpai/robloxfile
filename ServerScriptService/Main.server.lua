-- Main.server.lua
-- Main server script for Step to Victory game

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Load modules
local Modules = ServerScriptService:WaitForChild("Modules")
local GameManager = require(Modules:WaitForChild("GameManager"))
local SpawnManager = require(Modules:WaitForChild("SpawnManager"))
local IntermissionManager = require(Modules:WaitForChild("IntermissionManager"))
local PathManager = require(Modules:WaitForChild("PathManager"))

local GameConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConstants"))

-- Initialize managers
local gameManager = GameManager.new()
local spawnManager = SpawnManager.new()
local intermissionManager = IntermissionManager.new()
local pathManager = PathManager.new()

-- Game flow functions
local function onPlayerAdded(player)
    print("[Main] Player joined:", player.Name)
    
    -- Wait for character to spawn
    player.CharacterAdded:Connect(function(character)
        print("[Main] Character spawned for", player.Name)
        
        -- Add player to game if space available
        if gameManager:AddPlayer(player) then
            -- Assign spawn location
            local spawnIndex = spawnManager:AssignSpawn(player)
            
            if spawnIndex then
                -- Track spawn assignment
                gameManager:AssignPlayerToSpawn(player, spawnIndex)
                
                -- Spawn player at assigned location
                wait(0.1) -- Small delay to ensure character is ready
                spawnManager:SpawnPlayer(player, spawnIndex)
                
                -- Check if we should start the game
                checkGameStart()
            else
                warn("[Main] Could not assign spawn to player", player.Name)
                -- Remove player from game if no spawn available
                gameManager:RemovePlayer(player)
            end
        else
            warn("[Main] Game is full, cannot add player", player.Name)
        end
    end)
end

local function onPlayerRemoving(player)
    print("[Main] Player leaving:", player.Name)
    
    -- Get player's spawn index before removing
    local spawnIndex = gameManager:GetPlayerSpawnIndex(player)
    
    -- Remove from game
    gameManager:RemovePlayer(player)
    
    -- Release spawn
    if spawnIndex then
        spawnManager:ReleaseSpawn(spawnIndex)
    end
    
    -- Clean up from other managers
    intermissionManager:CleanupPlayer(player)
    pathManager:ResetPlayerPosition(player)
end

function checkGameStart()
    -- Auto-start when we have players and game is waiting
    if gameManager:CanStartGame() then
        startGame()
    end
end

function startGame()
    print("[Main] Starting game with", gameManager:GetPlayerCount(), "players")
    
    -- Change game state
    gameManager:SetState(GameConstants.GameState.INTERMISSION)
    
    -- Get all active players
    local activePlayers = gameManager:GetActivePlayers()
    
    -- Start intermission with callback
    intermissionManager:StartIntermission(activePlayers, function()
        -- Intermission ended, start the actual game
        onIntermissionEnd()
    end)
end

function onIntermissionEnd()
    print("[Main] Intermission ended, moving players to first footsteps")
    
    -- Change game state
    gameManager:SetState(GameConstants.GameState.IN_GAME)
    
    -- Small delay to ensure everything is ready
    wait(0.5)
    
    -- Move all players to their first footsteps
    local activePlayers = gameManager:GetActivePlayers()
    
    for _, player in ipairs(activePlayers) do
        local spawnIndex = gameManager:GetPlayerSpawnIndex(player)
        if spawnIndex then
            pathManager:MovePlayerToFirstFootstep(player, spawnIndex)
        end
    end
    
    -- Wait for all players to reach their first footstep
    wait(5) -- Give time for walking animation
    
    -- Game is now ready for questions phase
    print("[Main] Players positioned, ready for game phase")
    
    -- TODO: Start question phase here
    -- For now, we'll just wait a few seconds and advance players as a test
    wait(3)
    
    -- Test advancement
    print("[Main] Testing player advancement...")
    for _, player in ipairs(activePlayers) do
        pathManager:AdvancePlayer(player)
    end
end

function resetGame()
    print("[Main] Resetting game")
    
    -- Reset all managers
    gameManager:ResetGame()
    spawnManager:ResetSpawns()
    pathManager:ResetAllPositions()
    
    -- TODO: Reset any other game state
end

-- Connect player events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle existing players (for studio testing)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

print("[Main] Step to Victory server initialized")

-- Optional: Game loop for managing rounds
RunService.Heartbeat:Connect(function()
    -- You can add game state checks here
    -- For example, checking if all players reached the end
    -- Or managing round timers
end)