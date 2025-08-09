-- Alternative Freeze System using PlatformStand
-- This script provides a more aggressive approach to disabling player movement

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Wait for character
local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    print("[AlternativeFreeze] Character spawned, applying movement restrictions")
    
    -- Method 1: Use PlatformStand to disable all movement
    humanoid.PlatformStand = true
    
    -- Method 2: Set all movement properties to 0
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.JumpHeight = 0
    humanoid.AutoRotate = false
    
    -- Method 3: Disable controls via PlayerModule
    task.wait(0.2) -- Wait for PlayerModule to load
    pcall(function()
        local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
        local controls = playerModule:GetControls()
        controls:Disable()
    end)
    
    -- Continuous enforcement
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if humanoid and humanoid.Parent then
            -- Keep enforcing restrictions
            if humanoid.PlatformStand == false then
                humanoid.PlatformStand = true
            end
            if humanoid.WalkSpeed > 0 then
                humanoid.WalkSpeed = 0
            end
            if humanoid.JumpPower > 0 then
                humanoid.JumpPower = 0
            end
            if humanoid.JumpHeight > 0 then
                humanoid.JumpHeight = 0
            end
            if humanoid.AutoRotate == true then
                humanoid.AutoRotate = false
            end
        else
            -- Character removed
            connection:Disconnect()
        end
    end)
end

-- Connect to character spawn
if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

print("[AlternativeFreeze] Script initialized")