-- IntermissionManager.lua
-- Handles intermission countdown and player freezing for Step to Victory

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local GameConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConstants"))

local IntermissionManager = {}
IntermissionManager.__index = IntermissionManager

function IntermissionManager.new()
    local self = setmetatable({}, IntermissionManager)
    
    self.intermissionActive = false
    self.currentTime = 0
    self.frozenPlayers = {}
    
    -- Create RemoteEvents
    self:CreateRemoteEvents()
    
    return self
end

function IntermissionManager:CreateRemoteEvents()
    -- Use existing RemoteEvents from the folder
    local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
    
    -- Get existing RemoteEvents
    self.updateIntermissionRemote = remoteEvents:WaitForChild("UpdateIntermission")
    self.freezePlayerRemote = remoteEvents:WaitForChild("FreezePlayer")
    
    print("[IntermissionManager] Connected to existing RemoteEvents")
end

function IntermissionManager:StartIntermission(players, callback)
    if self.intermissionActive then
        warn("[IntermissionManager] Intermission already active!")
        return
    end
    
    self.intermissionActive = true
    self.currentTime = GameConstants.INTERMISSION_TIME
    
    -- Freeze all players
    for _, player in ipairs(players) do
        self:FreezePlayer(player, true)
    end
    
    -- Update all clients with initial countdown
    self.updateIntermissionRemote:FireAllClients(true, self.currentTime)
    
    -- Start countdown
    local connection
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        self.currentTime = self.currentTime - deltaTime
        
        -- Update clients every second
        local roundedTime = math.ceil(self.currentTime)
        if roundedTime ~= math.ceil(self.currentTime + deltaTime) then
            self.updateIntermissionRemote:FireAllClients(true, roundedTime)
        end
        
        -- Check if intermission is over
        if self.currentTime <= 0 then
            connection:Disconnect()
            self:EndIntermission(players)
            
            if callback then
                callback()
            end
        end
    end)
    
    print("[IntermissionManager] Started intermission")
end

function IntermissionManager:EndIntermission(players)
    self.intermissionActive = false
    
    -- Don't unfreeze players - they stay frozen during gameplay
    -- Just hide the intermission UI
    self.updateIntermissionRemote:FireAllClients(false, 0)
    
    print("[IntermissionManager] Ended intermission (players remain frozen)")
end

function IntermissionManager:UnfreezeAllPlayers(players)
    -- Separate method to unfreeze players when needed (e.g., round end)
    for _, player in ipairs(players) do
        self:FreezePlayer(player, false)
    end
    print("[IntermissionManager] Unfroze all players")
end

function IntermissionManager:FreezePlayer(player, freeze)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not humanoidRootPart then return end
    
    if freeze then
        -- Store original walkspeed and jumppower
        if not self.frozenPlayers[player] then
            self.frozenPlayers[player] = {
                walkSpeed = humanoid.WalkSpeed,
                jumpPower = humanoid.JumpPower
            }
        end
        
        -- Freeze player
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        
        -- Anchor the root part for R6 compatibility
        humanoidRootPart.Anchored = true
    else
        -- Restore original values
        if self.frozenPlayers[player] then
            humanoid.WalkSpeed = self.frozenPlayers[player].walkSpeed
            humanoid.JumpPower = self.frozenPlayers[player].jumpPower
            self.frozenPlayers[player] = nil
        else
            -- Default values if not stored
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
        end
        
        -- Unanchor
        humanoidRootPart.Anchored = false
    end
    
    -- Notify client
    self.freezePlayerRemote:FireClient(player, freeze)
    
    print("[IntermissionManager]", freeze and "Froze" or "Unfroze", "player", player.Name)
end

function IntermissionManager:CleanupPlayer(player)
    self.frozenPlayers[player] = nil
end

return IntermissionManager