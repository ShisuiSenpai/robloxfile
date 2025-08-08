-- MovementController Module
-- Provides complete server-side control over player movement

local MovementController = {}
MovementController.__index = MovementController

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

function MovementController.new()
    local self = setmetatable({}, MovementController)
    self.connections = {}
    self:Initialize()
    return self
end

function MovementController:Initialize()
    -- Connect to all current and future players
    Players.PlayerAdded:Connect(function(player)
        self:SetupPlayer(player)
    end)
    
    -- Handle already connected players
    for _, player in ipairs(Players:GetPlayers()) do
        self:SetupPlayer(player)
    end
end

function MovementController:SetupPlayer(player)
    player.CharacterAdded:Connect(function(character)
        self:LockCharacterMovement(character)
    end)
    
    -- Handle existing character
    if player.Character then
        self:LockCharacterMovement(player.Character)
    end
end

function MovementController:LockCharacterMovement(character)
    local humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Create a unique key for this character
    local key = character:GetDebugId()
    
    -- Clear any existing connection
    if self.connections[key] then
        self.connections[key]:Disconnect()
    end
    
    print("[MovementController] Locking movement for", character.Name)
    
    -- Initial lock
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.JumpHeight = 0
    humanoid.AutoRotate = false
    
    -- DON'T use BodyVelocity as it interferes with MoveTo()
    -- Let the PathManager handle movement
    
    -- Store humanoid reference for checking
    self.connections[key] = {
        humanoid = humanoid,
        character = character
    }
    
    -- Continuous enforcement with a check for MoveTo
    local heartbeatConnection = RunService.Heartbeat:Connect(function()
        if character.Parent and humanoid.Parent then
            -- Check if MoveTo is active
            local isMoving = humanoid.MoveToFinished:Wait(0) == false
            
            if not isMoving then
                -- Only enforce lock when not using MoveTo
                if humanoid.WalkSpeed > 0 then
                    humanoid.WalkSpeed = 0
                end
                if humanoid.JumpPower > 0 then
                    humanoid.JumpPower = 0
                end
                if humanoid.JumpHeight > 0 then
                    humanoid.JumpHeight = 0
                end
            end
        else
            -- Character removed, clean up
            heartbeatConnection:Disconnect()
            self.connections[key] = nil
        end
    end)
    
    -- Store the actual connection
    self.connections[key].connection = heartbeatConnection
    
    -- Clean up when character is removed
    character.AncestryChanged:Connect(function()
        if not character.Parent then
            if self.connections[key] then
                self.connections[key]:Disconnect()
                self.connections[key] = nil
            end
            if bodyVelocity then
                bodyVelocity:Destroy()
            end
        end
    end)
end

function MovementController:Destroy()
    -- Clean up all connections
    for key, connection in pairs(self.connections) do
        connection:Disconnect()
    end
    self.connections = {}
end

return MovementController