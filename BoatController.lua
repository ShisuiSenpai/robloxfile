-- Server Script: BoatController
-- Place this in ServerScriptService

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create RemoteEvent for client-server communication
local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "BoatRowingEvent"
remoteEvent.Parent = ReplicatedStorage

-- Configuration
local BOAT_NAME = "RowBoat"
local MAX_SPEED = 50 -- Maximum boat speed
local BASE_SPEED = 5 -- Minimum boat speed
local SPEED_INCREASE_PER_CORRECT = 2 -- Speed increase for correct input
local SPEED_DECREASE_PER_INCORRECT = 3 -- Speed decrease for incorrect input
local SPEED_DECAY_RATE = 0.95 -- Speed decay over time

-- Boat data storage
local boatData = {}
local lastSpeedUpdate = {}

-- Function to find the boat in workspace
local function findBoat()
    return workspace:FindFirstChild(BOAT_NAME)
end

-- Function to get all seats in the boat
local function getBoatSeats(boat)
    local seats = {}
    for _, child in pairs(boat:GetDescendants()) do
        if child:IsA("Seat") and child.Name == "Seat" then
            table.insert(seats, child)
        end
    end
    return seats
end

-- Function to check if any seat is occupied
local function isBoatOccupied(boat)
    local seats = getBoatSeats(boat)
    for _, seat in pairs(seats) do
        if seat.Occupant then
            return true
        end
    end
    return false
end

-- Function to get the primary part of the boat (for movement)
local function getBoatPrimaryPart(boat)
    if boat.PrimaryPart then
        return boat.PrimaryPart
    else
        -- If no PrimaryPart, use the first BasePart found
        for _, child in pairs(boat:GetDescendants()) do
            if child:IsA("BasePart") then
                boat.PrimaryPart = child
                return child
            end
        end
    end
    return nil
end

-- Initialize boat data
local function initializeBoat(boat)
    if not boatData[boat] then
        boatData[boat] = {
            currentSpeed = 0,
            isOccupied = false,
            occupants = {},
            primaryPart = getBoatPrimaryPart(boat),
            originalCFrame = nil,
            forwardDirection = nil
        }
        
        if boatData[boat].primaryPart then
            boatData[boat].originalCFrame = boatData[boat].primaryPart.CFrame
            boatData[boat].forwardDirection = boatData[boat].originalCFrame.LookVector
        end
    end
end

-- Handle player sitting
local function onSeatOccupancyChanged(seat)
    local boat = seat:FindFirstAncestor(BOAT_NAME)
    if not boat then return end
    
    initializeBoat(boat)
    local data = boatData[boat]
    
    if seat.Occupant then
        -- Player sat down
        local humanoid = seat.Occupant
        local character = humanoid.Parent
        local player = Players:GetPlayerFromCharacter(character)
        
        if player and not data.occupants[player] then
            data.occupants[player] = true
            data.isOccupied = true
            
            -- Notify the client to show rowing UI
            remoteEvent:FireClient(player, "StartRowing", boat)
        end
    else
        -- Player stood up - check all seats
        local stillOccupied = isBoatOccupied(boat)
        data.isOccupied = stillOccupied
        
        if not stillOccupied then
            -- Clear all occupants when boat is empty
            for player, _ in pairs(data.occupants) do
                remoteEvent:FireClient(player, "StopRowing")
            end
            data.occupants = {}
            data.currentSpeed = 0
        end
    end
end

-- Handle rowing input from client
local function onRowingInput(player, action, isCorrect, boat)
    if not boat or not boatData[boat] then return end
    
    local data = boatData[boat]
    if not data.occupants[player] then return end
    
    if action == "KeyPress" then
        if isCorrect then
            -- Increase speed for correct input
            data.currentSpeed = math.min(data.currentSpeed + SPEED_INCREASE_PER_CORRECT, MAX_SPEED)
        else
            -- Decrease speed for incorrect input
            data.currentSpeed = math.max(data.currentSpeed - SPEED_DECREASE_PER_INCORRECT, 0)
        end
    end
end

-- Update boat movement
local function updateBoatMovement()
    for boat, data in pairs(boatData) do
        if data.isOccupied and data.primaryPart and data.forwardDirection then
            -- Apply speed decay
            data.currentSpeed = data.currentSpeed * SPEED_DECAY_RATE
            
            -- Ensure minimum speed when occupied
            if data.currentSpeed < BASE_SPEED and data.isOccupied then
                data.currentSpeed = BASE_SPEED
            end
            
            -- Move the boat forward
            if data.currentSpeed > 0 then
                local deltaTime = RunService.Heartbeat:Wait()
                local movement = data.forwardDirection * data.currentSpeed * deltaTime
                
                -- Use CFrame for smooth movement
                local newCFrame = data.primaryPart.CFrame + movement
                boat:SetPrimaryPartCFrame(newCFrame)
            end
            
            -- Send speed updates to occupants (throttled to every 0.1 seconds)
            if not lastSpeedUpdate[boat] or tick() - lastSpeedUpdate[boat] > 0.1 then
                for player, _ in pairs(data.occupants) do
                    remoteEvent:FireClient(player, "UpdateSpeed", data.currentSpeed)
                end
                lastSpeedUpdate[boat] = tick()
            end
        end
    end
end

-- Setup seat monitoring
local function setupBoatSeats()
    local boat = findBoat()
    if not boat then 
        warn("Boat '" .. BOAT_NAME .. "' not found in Workspace!")
        return
    end
    
    initializeBoat(boat)
    local seats = getBoatSeats(boat)
    
    for _, seat in pairs(seats) do
        seat:GetPropertyChangedSignal("Occupant"):Connect(function()
            onSeatOccupancyChanged(seat)
        end)
    end
    
    print("Boat control system initialized with " .. #seats .. " seats")
end

-- Connect remote event
remoteEvent.OnServerEvent:Connect(onRowingInput)

-- Start boat movement loop
RunService.Heartbeat:Connect(updateBoatMovement)

-- Initialize when script runs
setupBoatSeats()

-- Re-initialize if boat is added later
workspace.ChildAdded:Connect(function(child)
    if child.Name == BOAT_NAME then
        wait(0.1) -- Small delay to ensure boat is fully loaded
        setupBoatSeats()
    end
end)