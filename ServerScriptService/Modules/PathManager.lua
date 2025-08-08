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

function PathManager:MovePlayerToFootstep(player, pathIndex, footstepIndex, callback)
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
    
    -- Calculate target position (on the footstep surface, accounting for character height)
    local targetPosition = Vector3.new(
        footstep.Position.X,
        footstep.Position.Y + footstep.Size.Y/2 + (humanoidRootPart.Size.Y/2) + 0.1,
        footstep.Position.Z
    )
    
    -- Make player face the footstep before walking
    local lookDirection = (targetPosition - humanoidRootPart.Position)
    lookDirection = Vector3.new(lookDirection.X, 0, lookDirection.Z).Unit
    -- Don't set CFrame directly as it might interfere with walking animation
    -- humanoidRootPart.CFrame = CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart.Position + lookDirection)
    
    -- Temporarily unanchor and restore walkspeed for movement
    humanoidRootPart.Anchored = false
    humanoid.WalkSpeed = 16 -- Standard walking speed
    humanoid.JumpPower = 0 -- Still no jumping
    
    -- Use Humanoid:MoveTo() to make the player walk
    humanoid:MoveTo(targetPosition)
    
    -- Monitor movement using MoveToFinished event
    local moveConnection
    local timeoutConnection
    
    local function onMoveFinished()
        -- Clean up connections
        if moveConnection then
            moveConnection:Disconnect()
        end
        if timeoutConnection then
            timeoutConnection:Disconnect()
        end
        
        -- Re-freeze the player
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoidRootPart.Anchored = true
        
        -- Notify client
        self.moveToFootstepRemote:FireClient(player, pathIndex, footstepIndex)
        
        print("[PathManager] Player", player.Name, "walked to footstep", footstepIndex, "on path", pathIndex)
        
        -- Call the callback if provided
        if callback then
            callback()
        end
    end
    
    -- Connect to MoveToFinished event
    moveConnection = humanoid.MoveToFinished:Connect(onMoveFinished)
    
    -- Add timeout in case something goes wrong
    timeoutConnection = task.delay(10, function()
        if moveConnection then
            moveConnection:Disconnect()
        end
        -- Force position if timeout
        humanoidRootPart.CFrame = CFrame.new(targetPosition, targetPosition + lookDirection)
        onMoveFinished()
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