-- GameManager.lua
-- Core game state management for Step to Victory

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConstants"))

local GameManager = {}
GameManager.__index = GameManager

function GameManager.new()
    local self = setmetatable({}, GameManager)
    
    self.currentState = GameConstants.GameState.WAITING
    self.activePlayers = {}
    self.playerSpawnMap = {} -- Maps player to spawn location index
    self.isGameRunning = false
    
    return self
end

function GameManager:GetState()
    return self.currentState
end

function GameManager:SetState(newState)
    self.currentState = newState
    print("[GameManager] State changed to:", newState)
end

function GameManager:AddPlayer(player)
    if #self.activePlayers >= GameConstants.MAX_PLAYERS then
        warn("[GameManager] Maximum players reached!")
        return false
    end
    
    table.insert(self.activePlayers, player)
    print("[GameManager] Player added:", player.Name, "Total players:", #self.activePlayers)
    return true
end

function GameManager:RemovePlayer(player)
    for i, activePlayer in ipairs(self.activePlayers) do
        if activePlayer == player then
            table.remove(self.activePlayers, i)
            self.playerSpawnMap[player] = nil
            print("[GameManager] Player removed:", player.Name, "Total players:", #self.activePlayers)
            break
        end
    end
end

function GameManager:GetPlayerCount()
    return #self.activePlayers
end

function GameManager:GetActivePlayers()
    return self.activePlayers
end

function GameManager:AssignPlayerToSpawn(player, spawnIndex)
    self.playerSpawnMap[player] = spawnIndex
end

function GameManager:GetPlayerSpawnIndex(player)
    return self.playerSpawnMap[player]
end

function GameManager:CanStartGame()
    -- For now, we'll allow starting with any number of players
    -- You can change this to require a minimum number
    return #self.activePlayers > 0 and self.currentState == GameConstants.GameState.WAITING
end

function GameManager:ResetGame()
    self.currentState = GameConstants.GameState.WAITING
    self.activePlayers = {}
    self.playerSpawnMap = {}
    self.isGameRunning = false
    print("[GameManager] Game reset")
end

return GameManager