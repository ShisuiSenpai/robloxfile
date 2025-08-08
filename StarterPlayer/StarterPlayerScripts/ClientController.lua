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

-- Player state
local isFrozen = false
local currentPath = nil
local currentFootstep = nil

-- Handle freeze/unfreeze
freezePlayerRemote.OnClientEvent:Connect(function(freeze)
    isFrozen = freeze
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Extra client-side protection against movement
    if freeze then
        -- Disable player controls
        local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
        local controls = playerModule:GetControls()
        controls:Disable()
        
        print("[Client] Player frozen - controls disabled")
    else
        -- Re-enable player controls
        local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
        local controls = playerModule:GetControls()
        controls:Enable()
        
        print("[Client] Player unfrozen - controls enabled")
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
    
    -- Setup camera if needed
    setupCameraSmoothing()
    
    print("[Client] Character spawned")
end)

-- Continuously enforce freeze state
RunService.Heartbeat:Connect(function()
    if isFrozen then
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            
            if humanoid and humanoidRootPart then
                -- Ensure player stays frozen
                if humanoid.WalkSpeed > 0 then
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
end

print("[Client] ClientController initialized")