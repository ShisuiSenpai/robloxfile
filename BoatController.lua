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

-- Speed Configuration (Balanced for gradual progression)
local SPEED_LEVELS = {
    {streak = 0, speed = 0},      -- No movement without input
    {streak = 1, speed = 2},      -- First correct key
    {streak = 2, speed = 4},      -- Small boost
    {streak = 3, speed = 7},      -- Starting to build momentum
    {streak = 5, speed = 11},     -- Good rhythm
    {streak = 8, speed = 16},     -- Strong rowing
    {streak = 12, speed = 22},    -- Excellent coordination
    {streak = 17, speed = 30},    -- Expert level
    {streak = 23, speed = 40},    -- Master rower
    {streak = 30, speed = 50},    -- Maximum speed
}

-- Balancing Configuration
local SPEED_DECAY_RATE = 0.98         -- Slower decay (2% per frame) to maintain momentum
local WRONG_KEY_SPEED_PENALTY = 5     -- Direct speed reduction for wrong keys
local WRONG_KEY_STREAK_PENALTY = 0.5  -- Streak multiplier on wrong key (halves streak)
local NO_INPUT_DECAY_RATE = 0.95      -- Faster decay when no input (5% per frame)
local STREAK_TIMEOUT = 1.5             -- Seconds before streak resets if no input

-- Boat data storage
local boatData = {}
local lastSpeedUpdate = {}

-- Function to calculate speed based on streak
local function getSpeedFromStreak(streak)
    local speed = 0
    for i = #SPEED_LEVELS, 1, -1 do
        if streak >= SPEED_LEVELS[i].streak then
            speed = SPEED_LEVELS[i].speed
            break
        end
    end
    return speed
end

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
            targetSpeed = 0,
            isOccupied = false,
            occupants = {},
            primaryPart = getBoatPrimaryPart(boat),
            originalCFrame = nil,
            forwardDirection = nil,
            streak = 0,
            lastInputTime = 0,
            totalCorrectInputs = 0,
            totalWrongInputs = 0
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
            data.targetSpeed = 0
            data.streak = 0
            data.totalCorrectInputs = 0
            data.totalWrongInputs = 0
        end
    end
end

-- Handle rowing input from client
local function onRowingInput(player, action, isCorrect, boat)
    if not boat or not boatData[boat] then return end
    
    local data = boatData[boat]
    if not data.occupants[player] then return end
    
    if action == "KeyPress" then
        local currentTime = tick()
        
        if isCorrect then
            -- Correct input
            data.totalCorrectInputs = data.totalCorrectInputs + 1
            
            -- Check if streak should continue or reset
            if currentTime - data.lastInputTime > STREAK_TIMEOUT then
                data.streak = 1
            else
                data.streak = data.streak + 1
            end
            
            data.lastInputTime = currentTime
            
            -- Calculate new target speed based on streak
            data.targetSpeed = getSpeedFromStreak(data.streak)
            
            -- Send streak update to player
            remoteEvent:FireClient(player, "UpdateStreak", data.streak)
            
        else
            -- Wrong input
            data.totalWrongInputs = data.totalWrongInputs + 1
            
            -- Reduce streak (but not to 0 to maintain some momentum)
            data.streak = math.floor(data.streak * WRONG_KEY_STREAK_PENALTY)
            
            -- Apply immediate speed penalty
            data.currentSpeed = math.max(0, data.currentSpeed - WRONG_KEY_SPEED_PENALTY)
            
            -- Recalculate target speed
            data.targetSpeed = getSpeedFromStreak(data.streak)
            
            -- Send streak update to player
            remoteEvent:FireClient(player, "UpdateStreak", data.streak)
        end
    end
end

-- Update boat movement
local function updateBoatMovement()
    for boat, data in pairs(boatData) do
        if data.isOccupied and data.primaryPart and data.forwardDirection then
            local currentTime = tick()
            
            -- Check for streak timeout
            if currentTime - data.lastInputTime > STREAK_TIMEOUT and data.streak > 0 then
                data.streak = 0
                data.targetSpeed = 0
                
                -- Notify all occupants
                for player, _ in pairs(data.occupants) do
                    remoteEvent:FireClient(player, "UpdateStreak", 0)
                end
            end
            
            -- Smooth speed transitions
            if data.currentSpeed < data.targetSpeed then
                -- Accelerate towards target
                data.currentSpeed = math.min(data.targetSpeed, data.currentSpeed + 1)
            elseif data.currentSpeed > data.targetSpeed then
                -- Decelerate towards target
                data.currentSpeed = math.max(data.targetSpeed, data.currentSpeed - 0.5)
            end
            
            -- Apply decay based on input activity
            if currentTime - data.lastInputTime > 0.5 then
                -- No recent input - apply no-input decay
                data.currentSpeed = data.currentSpeed * NO_INPUT_DECAY_RATE
            else
                -- Recent input - apply normal decay
                data.currentSpeed = data.currentSpeed * SPEED_DECAY_RATE
            end
            
            -- Move the boat forward
            if data.currentSpeed > 0.1 then -- Threshold to prevent tiny movements
                local deltaTime = RunService.Heartbeat:Wait()
                local movement = data.forwardDirection * data.currentSpeed * deltaTime
                
                -- Use CFrame for smooth movement
                local newCFrame = data.primaryPart.CFrame + movement
                boat:SetPrimaryPartCFrame(newCFrame)
            end
            
            -- Send speed updates to occupants (throttled to every 0.1 seconds)
            if not lastSpeedUpdate[boat] or currentTime - lastSpeedUpdate[boat] > 0.1 then
                for player, _ in pairs(data.occupants) do
                    remoteEvent:FireClient(player, "UpdateSpeed", {
                        currentSpeed = data.currentSpeed,
                        streak = data.streak,
                        accuracy = data.totalCorrectInputs / math.max(1, data.totalCorrectInputs + data.totalWrongInputs)
                    })
                end
                lastSpeedUpdate[boat] = currentTime
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