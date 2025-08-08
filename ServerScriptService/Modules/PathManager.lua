-- PathManager.lua
-- Manages footstep paths and player movement for Step to Victory

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local GameConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConstants"))

local PathManager = {}
PathManager.__index = PathManager

function PathManager.new()
    local self = setmetatable({}, PathManager)
    
    self.footstepPaths = {}
    self.playerPositions = {} -- Track which footstep each player is on
    
    -- Create RemoteEvent for movement
    self:CreateRemoteEvents()
    self:Initialize()
    
    return self
end

function PathManager:CreateRemoteEvents()
    local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
    if not remoteEvents then
        remoteEvents = Instance.new("Folder")
        remoteEvents.Name = "RemoteEvents"
        remoteEvents.Parent = ReplicatedStorage
    end
    
    local moveToFootstep = remoteEvents:FindFirstChild("MoveToFootstep")
    if not moveToFootstep then
        moveToFootstep = Instance.new("RemoteEvent")
        moveToFootstep.Name = "MoveToFootstep"
        moveToFootstep.Parent = remoteEvents
    end
    
    self.moveToFootstepRemote = moveToFootstep
end

function PathManager:Initialize()
    -- Load all footstep paths
    for i, folderName in ipairs(GameConstants.FOOTSTEP_FOLDERS) do
        local footstepFolder = Workspace:FindFirstChild(folderName)
        
        if footstepFolder then
            local path = {}
            
            -- Collect all footsteps in order
            for j = 1, GameConstants.FOOTSTEPS_PER_PATH do
                local footstepName = "Footstep" .. j
                local footstep = footstepFolder:FindFirstChild(footstepName)
                
                if footstep then
                    path[j] = footstep
                    print("[PathManager] Found", footstepName, "in", folderName)
                else
                    warn("[PathManager] Missing", footstepName, "in", folderName)
                end
            end
            
            self.footstepPaths[i] = path
        else
            warn("[PathManager] Footstep folder not found:", folderName)
        end
    end
end

function PathManager:MovePlayerToFirstFootstep(player, pathIndex)
    if not self.footstepPaths[pathIndex] then
        warn("[PathManager] Invalid path index:", pathIndex)
        return false
    end
    
    local firstFootstep = self.footstepPaths[pathIndex][1]
    if not firstFootstep then
        warn("[PathManager] No first footstep in path", pathIndex)
        return false
    end
    
    -- Move player to first footstep
    self:MovePlayerToFootstep(player, pathIndex, 1)
    
    -- Track player position
    self.playerPositions[player] = {
        pathIndex = pathIndex,
        footstepIndex = 1
    }
    
    return true
end

function PathManager:MovePlayerToFootstep(player, pathIndex, footstepIndex)
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not humanoidRootPart then return false end
    
    local footstep = self.footstepPaths[pathIndex][footstepIndex]
    if not footstep then
        warn("[PathManager] Invalid footstep", footstepIndex, "in path", pathIndex)
        return false
    end
    
    -- Calculate target position (on the footstep surface)
    local targetPosition = footstep.Position + Vector3.new(0, footstep.Size.Y/2 + 3, 0)
    
    -- Make player face the footstep before walking
    local lookDirection = (footstep.Position - humanoidRootPart.Position)
    lookDirection = Vector3.new(lookDirection.X, 0, lookDirection.Z).Unit
    humanoidRootPart.CFrame = CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart.Position + lookDirection)
    
    -- Temporarily unanchor and restore walkspeed for movement
    humanoidRootPart.Anchored = false
    local originalWalkSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = 16 -- Standard walking speed
    humanoid.JumpPower = 0 -- Still no jumping
    
    -- Use Humanoid:MoveTo() to make the player walk
    humanoid:MoveTo(targetPosition)
    
    -- Wait for the player to reach the destination
    local startTime = tick()
    local timeout = 10 -- Maximum 10 seconds to reach destination
    
    spawn(function()
        while (humanoidRootPart.Position - targetPosition).Magnitude > 4 and 
              tick() - startTime < timeout do
            wait(0.1)
        end
        
        -- Ensure player is exactly on the footstep
        humanoidRootPart.CFrame = CFrame.new(targetPosition, targetPosition + lookDirection)
        
        -- Stop any residual movement
        humanoid:MoveTo(humanoidRootPart.Position)
        
        -- Re-freeze the player
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoidRootPart.Anchored = true
        
        -- Notify client
        self.moveToFootstepRemote:FireClient(player, pathIndex, footstepIndex)
        
        print("[PathManager] Player", player.Name, "walked to footstep", footstepIndex, "on path", pathIndex)
    end)
    
    return true
end

function PathManager:AdvancePlayer(player)
    local position = self.playerPositions[player]
    if not position then
        warn("[PathManager] Player position not tracked:", player.Name)
        return false
    end
    
    local nextIndex = position.footstepIndex + 1
    
    -- Check if player has reached the end
    if nextIndex > GameConstants.FOOTSTEPS_PER_PATH then
        print("[PathManager] Player", player.Name, "has reached the end!")
        return false
    end
    
    -- Move to next footstep
    if self:MovePlayerToFootstep(player, position.pathIndex, nextIndex) then
        position.footstepIndex = nextIndex
        return true
    end
    
    return false
end

function PathManager:GetPlayerPosition(player)
    return self.playerPositions[player]
end

function PathManager:ResetPlayerPosition(player)
    self.playerPositions[player] = nil
end

function PathManager:ResetAllPositions()
    self.playerPositions = {}
    print("[PathManager] All player positions reset")
end

return PathManager