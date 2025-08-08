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
    
    -- New remote for movement state
    local setMovementState = remoteEvents:FindFirstChild("SetMovementState")
    if not setMovementState then
        setMovementState = Instance.new("RemoteEvent")
        setMovementState.Name = "SetMovementState"
        setMovementState.Parent = remoteEvents
    end
    
    self.moveToFootstepRemote = moveToFootstep
    self.setMovementStateRemote = setMovementState
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
    
    -- Calculate target position
    -- MoveTo moves the character's feet to the position, so we target the footstep center
    -- The Y coordinate should be the top surface of the footstep
    local targetPosition = footstep.Position  -- Use the exact center of the part
    
    print("[PathManager] Footstep info - Position:", footstep.Position, "Size:", footstep.Size)
    
    -- Debug: Check initial state
    print("[PathManager] Pre-move state - Anchored:", humanoidRootPart.Anchored, "WalkSpeed:", humanoid.WalkSpeed, "PlatformStand:", humanoid.PlatformStand)
    
    -- STEP 1: Tell client we're about to move (stop enforcing freeze)
    self.setMovementStateRemote:FireClient(player, "moving")
    
    -- STEP 2: Fully unfreeze the player on server
    humanoidRootPart.Anchored = false
    humanoid.WalkSpeed = 16 -- Standard walking speed
    humanoid.JumpPower = 0 -- Still no jumping
    humanoid.PlatformStand = false -- Ensure PlatformStand is off
    
    -- STEP 3: Wait for client to process the movement state change
    task.wait(0.1) -- Give client time to stop overriding WalkSpeed
    
    -- Debug: Check state after unfreeze
    print("[PathManager] Post-unfreeze - Anchored:", humanoidRootPart.Anchored, "WalkSpeed:", humanoid.WalkSpeed, "Distance to target:", (targetPosition - humanoidRootPart.Position).Magnitude)
    
    -- STEP 4: Now call MoveTo when both server and client agree on movement
    humanoid:MoveTo(targetPosition)
    
    -- Monitor movement using MoveToFinished event
    local moveConnection
    local timeoutConnection
    local moveStarted = false
    
    local function onMoveFinished(reached)
        print("[PathManager] onMoveFinished called! Reached:", reached)
        
        -- Clean up connections
        if moveConnection then
            moveConnection:Disconnect()
        end
        if timeoutConnection then
            timeoutConnection:Disconnect()
        end
        
        -- First, stop any movement
        humanoid:MoveTo(humanoidRootPart.Position) -- Stop MoveTo
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        
        -- Wait a frame for movement to fully stop
        task.wait()
        
        -- Now anchor BEFORE setting position
        humanoidRootPart.Anchored = true
        
        -- Calculate the proper position for centering on footstep
        local finalPosition = Vector3.new(
            footstep.Position.X,
            footstep.Position.Y + footstep.Size.Y/2 + humanoidRootPart.Size.Y/2 + 0.1,
            footstep.Position.Z
        )
        
        -- Debug before setting
        print("[PathManager] BEFORE SET - Current position:", humanoidRootPart.Position)
        print("[PathManager] BEFORE SET - Target position:", finalPosition)
        print("[PathManager] BEFORE SET - Anchored:", humanoidRootPart.Anchored)
        
        -- Keep the player's current rotation
        local currentLookDirection = humanoidRootPart.CFrame.LookVector
        
        -- Set the final position
        humanoidRootPart.CFrame = CFrame.lookAt(finalPosition, finalPosition + currentLookDirection)
        
        -- Force update with a second method
        humanoidRootPart.Position = finalPosition
        
        -- Wait and check again
        task.wait(0.1)
        
        -- Debug after setting
        print("[PathManager] AFTER SET - Actual position:", humanoidRootPart.Position)
        print("[PathManager] AFTER SET - Distance from target:", (humanoidRootPart.Position - finalPosition).Magnitude)
        
        -- Tell client movement is done (resume freeze enforcement)
        self.setMovementStateRemote:FireClient(player, "frozen")
        
        -- Notify client about position
        self.moveToFootstepRemote:FireClient(player, pathIndex, footstepIndex)
        
        print("[PathManager] Player", player.Name, reached and "walked" or "teleported", "to footstep", footstepIndex, "on path", pathIndex)
        
        -- Call the callback if provided
        if callback then
            callback()
        end
    end
    
    -- Connect to MoveToFinished event
    moveConnection = humanoid.MoveToFinished:Connect(onMoveFinished)
    
    -- Add a check to see if movement actually started
    task.spawn(function()
        task.wait(0.1)
        local startPos = humanoidRootPart.Position
        task.wait(0.5)
        
        -- Check if player has moved at all
        if (humanoidRootPart.Position - startPos).Magnitude < 0.5 then
            -- Movement didn't start, probably still frozen somehow
            print("[PathManager] Movement didn't start, forcing walk")
            
            -- Try again with more aggressive unfreezing
            humanoidRootPart.Anchored = false
            humanoid.WalkSpeed = 16
            humanoid:MoveTo(targetPosition)
        end
    end)
    
    -- Add timeout in case something goes wrong
    timeoutConnection = task.delay(10, function()
        if moveConnection then
            moveConnection:Disconnect()
        end
        onMoveFinished(false)
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