-- SpawnManager.lua
-- Handles player spawning and spawn point assignment for Step to Victory

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConstants"))

local SpawnManager = {}
SpawnManager.__index = SpawnManager

function SpawnManager.new()
    local self = setmetatable({}, SpawnManager)
    
    self.spawnFolder = nil
    self.spawnPoints = {}
    self.availableSpawns = {}
    
    self:Initialize()
    
    return self
end

function SpawnManager:Initialize()
    -- Wait for spawn folder to exist
    self.spawnFolder = Workspace:WaitForChild("Spawns", 10)
    
    if not self.spawnFolder then
        warn("[SpawnManager] Spawns folder not found in Workspace!")
        return
    end
    
    -- Collect all spawn points
    for i, spawnName in ipairs(GameConstants.SPAWN_NAMES) do
        local spawnPoint = self.spawnFolder:FindFirstChild(spawnName)
        if spawnPoint then
            self.spawnPoints[i] = spawnPoint
            self.availableSpawns[i] = true
            print("[SpawnManager] Found spawn point:", spawnName)
        else
            warn("[SpawnManager] Spawn point not found:", spawnName)
        end
    end
end

function SpawnManager:GetAvailableSpawnIndex()
    for index, available in pairs(self.availableSpawns) do
        if available then
            return index
        end
    end
    return nil
end

function SpawnManager:AssignSpawn(player)
    local spawnIndex = self:GetAvailableSpawnIndex()
    
    if not spawnIndex then
        warn("[SpawnManager] No available spawn points!")
        return nil
    end
    
    self.availableSpawns[spawnIndex] = false
    print("[SpawnManager] Assigned spawn", spawnIndex, "to player", player.Name)
    
    return spawnIndex
end

function SpawnManager:ReleaseSpawn(spawnIndex)
    if spawnIndex and self.availableSpawns[spawnIndex] ~= nil then
        self.availableSpawns[spawnIndex] = true
        print("[SpawnManager] Released spawn", spawnIndex)
    end
end

function SpawnManager:SpawnPlayer(player, spawnIndex)
    local character = player.Character
    if not character then
        warn("[SpawnManager] Player has no character!")
        return false
    end
    
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
    if not humanoidRootPart then
        warn("[SpawnManager] Character has no HumanoidRootPart!")
        return false
    end
    
    local spawnPoint = self.spawnPoints[spawnIndex]
    if not spawnPoint then
        warn("[SpawnManager] Invalid spawn index:", spawnIndex)
        return false
    end
    
    -- Teleport player to spawn point
    humanoidRootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 3, 0) -- Spawn slightly above
    
    -- Make player face their path
    self:OrientPlayerToPath(player, spawnIndex)
    
    print("[SpawnManager] Spawned player", player.Name, "at", spawnPoint.Name)
    return true
end

function SpawnManager:OrientPlayerToPath(player, spawnIndex)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Get the corresponding footstep folder
    local footstepFolderName = GameConstants.FOOTSTEP_FOLDERS[spawnIndex]
    local footstepFolder = Workspace:FindFirstChild(footstepFolderName)
    
    if not footstepFolder then
        warn("[SpawnManager] Footstep folder not found:", footstepFolderName)
        return
    end
    
    -- Get first footstep
    local firstFootstep = footstepFolder:FindFirstChild("Footstep1")
    if not firstFootstep then
        warn("[SpawnManager] First footstep not found in", footstepFolderName)
        return
    end
    
    -- Calculate direction from spawn to first footstep
    local direction = (firstFootstep.Position - humanoidRootPart.Position).Unit
    local lookAtCFrame = CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart.Position + direction)
    
    -- Apply rotation
    humanoidRootPart.CFrame = lookAtCFrame
    print("[SpawnManager] Oriented player", player.Name, "toward their path")
end

function SpawnManager:ResetSpawns()
    for i = 1, #self.spawnPoints do
        self.availableSpawns[i] = true
    end
    print("[SpawnManager] All spawns reset")
end

return SpawnManager