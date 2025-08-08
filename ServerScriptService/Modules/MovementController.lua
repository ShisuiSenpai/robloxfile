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
    
    -- Create BodyVelocity to override any physics-based movement
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000) -- Only restrict X and Z movement
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = humanoidRootPart
    
    -- Continuous enforcement
    self.connections[key] = RunService.Heartbeat:Connect(function()
        if character.Parent then
            -- Keep enforcing movement lock
            if humanoid.WalkSpeed > 0 then
                humanoid.WalkSpeed = 0
            end
            if humanoid.JumpPower > 0 then
                humanoid.JumpPower = 0
            end
            if humanoid.JumpHeight > 0 then
                humanoid.JumpHeight = 0
            end
            
            -- Reset velocity to prevent any movement
            if bodyVelocity and bodyVelocity.Parent then
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        else
            -- Character removed, clean up
            self.connections[key]:Disconnect()
            self.connections[key] = nil
            if bodyVelocity then
                bodyVelocity:Destroy()
            end
        end
    end)
    
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