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
    isFrozen = false
    currentPath = nil
    currentFootstep = nil
    
    -- Immediately disable controls when character spawns
    wait(0.1) -- Small wait to ensure PlayerModule is ready
    local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    local controls = playerModule:GetControls()
    controls:Disable()
    
    -- Setup camera if needed
    setupCameraSmoothing()
    
    print("[Client] Character spawned - controls disabled")
end)

-- Continuously enforce freeze state
RunService.Heartbeat:Connect(function()
    -- Always enforce freeze when frozen, regardless of movement state
    if isFrozen then
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            
            if humanoid and humanoidRootPart then
                -- Ensure player stays frozen
                if humanoid.WalkSpeed > 0 and not isMoving then
                    -- Only override WalkSpeed when not in server-controlled movement
                    humanoid.WalkSpeed = 0
                end
                if humanoid.JumpPower > 0 then
                    humanoid.JumpPower = 0
                end
                -- Note: Don't anchor on client side as it can cause issues
            end
        end
    end
end)

-- Initialize
if player.Character then
    setupCameraSmoothing()
    -- Disable controls on initialization
    local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    local controls = playerModule:GetControls()
    controls:Disable()
end

print("[Client] ClientController initialized - controls disabled")