-- ClientController.lua
-- Main client-side controller for Step to Victory

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local GameConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConstants"))

-- Wait for RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local freezePlayerRemote = remoteEvents:WaitForChild("FreezePlayer")
local moveToFootstepRemote = remoteEvents:WaitForChild("MoveToFootstep")
local setMovementStateRemote = remoteEvents:WaitForChild("SetMovementState")

-- Player state
local isFrozen = false
local isMoving = false -- New state to track when we're moving between footsteps
local currentPath = nil
local currentFootstep = nil

-- Handle freeze/unfreeze
freezePlayerRemote.OnClientEvent:Connect(function(freeze)
    isFrozen = freeze
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Always keep controls disabled in this game
    local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    local controls = playerModule:GetControls()
    controls:Disable()
    
    if freeze then
        print("[Client] Player frozen - controls remain disabled")
    else
        print("[Client] Player unfrozen - but controls still disabled for this game")
    end
end)

-- Handle footstep movement updates
moveToFootstepRemote.OnClientEvent:Connect(function(pathIndex, footstepIndex)
    currentPath = pathIndex
    currentFootstep = footstepIndex
    
    print("[Client] Moved to footstep", footstepIndex, "on path", pathIndex)
    
    -- You can add visual effects here
    -- For example, highlighting the current footstep
end)

-- Handle movement state changes
setMovementStateRemote.OnClientEvent:Connect(function(state)
    if state == "moving" then
        isMoving = true
        print("[Client] Movement state: moving - stopping freeze enforcement")
        
        -- DON'T enable controls - player should never control movement
    elseif state == "frozen" then
        isMoving = false
        print("[Client] Movement state: frozen - resuming freeze enforcement")
        
        -- Keep controls disabled
    end
end)

-- Optional: Add camera smoothing during movement
local function setupCameraSmoothing()
    local camera = workspace.CurrentCamera
    local character = player.Character or player.CharacterAdded:Wait()
    
    -- You can implement custom camera behavior here if needed
end

-- Character spawned handler
player.CharacterAdded:Connect(function(character)
    -- Reset state
    isFrozen = true -- Start frozen!
    isMoving = false
    currentPath = nil
    currentFootstep = nil
    
    -- Immediately disable controls when character spawns
    task.spawn(function()
        task.wait(0.1) -- Small wait to ensure PlayerModule is ready
        local success, err = pcall(function()
            local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
            local controls = playerModule:GetControls()
            controls:Disable()
        end)
        
        if not success then
            warn("[Client] Failed to disable controls:", err)
        else
            print("[Client] Successfully disabled controls on spawn")
        end
    end)
    
    -- Setup camera if needed
    setupCameraSmoothing()
    
    print("[Client] Character spawned - initializing freeze")
end)

-- Control disable counter
local controlDisableAttempts = 0

-- Continuously enforce freeze state and control disable
RunService.Heartbeat:Connect(function()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid and humanoidRootPart then
            -- Always enforce movement restrictions
            if not isMoving then
                -- Player should never be able to move unless server is moving them
                if humanoid.WalkSpeed > 0 then
                    humanoid.WalkSpeed = 0
                end
                if humanoid.JumpPower > 0 then
                    humanoid.JumpPower = 0
                end
            end
        end
    end
    
    -- Try to disable controls periodically if they somehow get re-enabled
    controlDisableAttempts = controlDisableAttempts + 1
    if controlDisableAttempts >= 60 then -- Every ~1 second at 60 FPS
        controlDisableAttempts = 0
        pcall(function()
            local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
            local controls = playerModule:GetControls()
            controls:Disable()
        end)
    end
end)

-- Initialize
-- Immediately try to disable controls on script start
task.spawn(function()
    local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    local controls = playerModule:GetControls()
    controls:Disable()
    print("[Client] Initial control disable complete")
end)

if player.Character then
    setupCameraSmoothing()
    -- Also disable for existing character
    pcall(function()
        local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
        local controls = playerModule:GetControls()
        controls:Disable()
    end)
end

print("[Client] ClientController initialized - controls disabled")