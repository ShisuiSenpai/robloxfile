-- Client Script: RowingUI
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvent
local remoteEvent = ReplicatedStorage:WaitForChild("BoatRowingEvent")

-- Configuration
local KEY_SPAWN_INTERVAL = 0.8 -- Time between key spawns (seconds)
local KEY_LIFETIME = 2.5 -- Time before key disappears (seconds)
local POSSIBLE_KEYS = {"W", "A", "S", "D", "E", "Q", "R", "F", "X", "C", "V", "T", "G"} -- Keys near left side of keyboard
local MAX_SPEED = 50 -- Should match server's MAX_SPEED

-- UI State
local isRowing = false
local currentBoat = nil
local activeKeys = {}
local gui = nil
local currentSpeed = 0
local currentStreak = 0
local currentAccuracy = 1

-- Create the main UI
local function createRowingUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RowingUI"
    screenGui.ResetOnSpawn = false
    
    -- Main container frame
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0.8, 0, 0.2, 0)
    container.Position = UDim2.new(0.1, 0, 0.65, 0)
    container.BackgroundColor3 = Color3.new(0, 0, 0)
    container.BackgroundTransparency = 0.3
    container.BorderSizePixel = 0
    container.Parent = screenGui
    
    -- Add rounded corners
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 12)
    uiCorner.Parent = container
    
    -- Speed indicator bar background
    local speedBarBg = Instance.new("Frame")
    speedBarBg.Name = "SpeedBarBackground"
    speedBarBg.Size = UDim2.new(0.9, 0, 0.08, 0)
    speedBarBg.Position = UDim2.new(0.05, 0, 0.05, 0)
    speedBarBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    speedBarBg.BorderSizePixel = 0
    speedBarBg.Parent = container
    
    local speedBarCorner = Instance.new("UICorner")
    speedBarCorner.CornerRadius = UDim.new(0, 4)
    speedBarCorner.Parent = speedBarBg
    
    -- Speed indicator bar fill
    local speedBar = Instance.new("Frame")
    speedBar.Name = "SpeedBar"
    speedBar.Size = UDim2.new(0, 0, 1, 0)
    speedBar.Position = UDim2.new(0, 0, 0, 0)
    speedBar.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    speedBar.BorderSizePixel = 0
    speedBar.Parent = speedBarBg
    
    local speedBarFillCorner = Instance.new("UICorner")
    speedBarFillCorner.CornerRadius = UDim.new(0, 4)
    speedBarFillCorner.Parent = speedBar
    
    -- Streak display
    local streakFrame = Instance.new("Frame")
    streakFrame.Name = "StreakFrame"
    streakFrame.Size = UDim2.new(0.25, 0, 0.25, 0)
    streakFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
    streakFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    streakFrame.BackgroundTransparency = 0.3
    streakFrame.BorderSizePixel = 0
    streakFrame.Parent = container
    
    local streakCorner = Instance.new("UICorner")
    streakCorner.CornerRadius = UDim.new(0, 8)
    streakCorner.Parent = streakFrame
    
    local streakLabel = Instance.new("TextLabel")
    streakLabel.Name = "StreakLabel"
    streakLabel.Size = UDim2.new(1, 0, 0.4, 0)
    streakLabel.Position = UDim2.new(0, 0, 0, 0)
    streakLabel.BackgroundTransparency = 1
    streakLabel.Text = "STREAK"
    streakLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    streakLabel.TextScaled = true
    streakLabel.Font = Enum.Font.SourceSans
    streakLabel.Parent = streakFrame
    
    local streakNumber = Instance.new("TextLabel")
    streakNumber.Name = "StreakNumber"
    streakNumber.Size = UDim2.new(1, 0, 0.6, 0)
    streakNumber.Position = UDim2.new(0, 0, 0.4, 0)
    streakNumber.BackgroundTransparency = 1
    streakNumber.Text = "0"
    streakNumber.TextColor3 = Color3.new(1, 1, 1)
    streakNumber.TextScaled = true
    streakNumber.Font = Enum.Font.SourceSansBold
    streakNumber.Parent = streakFrame
    
    -- Accuracy display
    local accuracyFrame = Instance.new("Frame")
    accuracyFrame.Name = "AccuracyFrame"
    accuracyFrame.Size = UDim2.new(0.25, 0, 0.25, 0)
    accuracyFrame.Position = UDim2.new(0.7, 0, 0.15, 0)
    accuracyFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    accuracyFrame.BackgroundTransparency = 0.3
    accuracyFrame.BorderSizePixel = 0
    accuracyFrame.Parent = container
    
    local accuracyCorner = Instance.new("UICorner")
    accuracyCorner.CornerRadius = UDim.new(0, 8)
    accuracyCorner.Parent = accuracyFrame
    
    local accuracyLabel = Instance.new("TextLabel")
    accuracyLabel.Name = "AccuracyLabel"
    accuracyLabel.Size = UDim2.new(1, 0, 0.4, 0)
    accuracyLabel.Position = UDim2.new(0, 0, 0, 0)
    accuracyLabel.BackgroundTransparency = 1
    accuracyLabel.Text = "ACCURACY"
    accuracyLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    accuracyLabel.TextScaled = true
    accuracyLabel.Font = Enum.Font.SourceSans
    accuracyLabel.Parent = accuracyFrame
    
    local accuracyNumber = Instance.new("TextLabel")
    accuracyNumber.Name = "AccuracyNumber"
    accuracyNumber.Size = UDim2.new(1, 0, 0.6, 0)
    accuracyNumber.Position = UDim2.new(0, 0, 0.4, 0)
    accuracyNumber.BackgroundTransparency = 1
    accuracyNumber.Text = "100%"
    accuracyNumber.TextColor3 = Color3.new(1, 1, 1)
    accuracyNumber.TextScaled = true
    accuracyNumber.Font = Enum.Font.SourceSansBold
    accuracyNumber.Parent = accuracyFrame
    
    -- Keys container
    local keysContainer = Instance.new("Frame")
    keysContainer.Name = "KeysContainer"
    keysContainer.Size = UDim2.new(1, 0, 0.5, 0)
    keysContainer.Position = UDim2.new(0, 0, 0.45, 0)
    keysContainer.BackgroundTransparency = 1
    keysContainer.Parent = container
    
    -- Instructions label
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(0.4, 0, 0.12, 0)
    instructions.Position = UDim2.new(0.3, 0, 0.15, 0)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Press the keys to row!"
    instructions.TextColor3 = Color3.new(1, 1, 1)
    instructions.TextScaled = true
    instructions.Font = Enum.Font.SourceSansBold
    instructions.Parent = container
    
    screenGui.Parent = playerGui
    return screenGui
end

-- Create a key prompt with enhanced visuals
local function createKeyPrompt(key)
    local keyFrame = Instance.new("Frame")
    keyFrame.Name = "KeyPrompt"
    keyFrame.Size = UDim2.new(0.08, 0, 0.8, 0)
    keyFrame.Position = UDim2.new(1, 0, 0.1, 0) -- Start from right side
    keyFrame.BackgroundColor3 = Color3.new(0.2, 0.5, 0.8)
    keyFrame.BorderSizePixel = 0
    
    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 8)
    keyCorner.Parent = keyFrame
    
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(1, 0, 1, 0)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Text = key
    keyLabel.TextColor3 = Color3.new(1, 1, 1)
    keyLabel.TextScaled = true
    keyLabel.Font = Enum.Font.SourceSansBold
    keyLabel.Parent = keyFrame
    
    -- Add glow effect that intensifies based on streak
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.new(0.4, 0.7, 1)
    uiStroke.Thickness = 2
    uiStroke.Transparency = 0.5
    uiStroke.Parent = keyFrame
    
    -- Pulse effect for high streaks
    if currentStreak > 10 then
        spawn(function()
            local pulseTime = 0
            while keyFrame.Parent do
                pulseTime = pulseTime + RunService.Heartbeat:Wait()
                local scale = 1 + math.sin(pulseTime * 5) * 0.1
                keyLabel.TextScaled = false
                keyLabel.TextSize = 24 * scale
                keyLabel.TextScaled = true
            end
        end)
    end
    
    return keyFrame
end

-- Update streak display with effects
local function updateStreakDisplay(streak)
    if not gui then return end
    
    local streakNumber = gui.Container.StreakFrame.StreakNumber
    streakNumber.Text = tostring(streak)
    
    -- Color and size effects based on streak
    local color = Color3.new(1, 1, 1)
    local frameColor = Color3.new(0.1, 0.1, 0.1)
    
    if streak >= 30 then
        color = Color3.new(1, 0.2, 0.2) -- Red for max streak
        frameColor = Color3.new(0.3, 0.1, 0.1)
    elseif streak >= 20 then
        color = Color3.new(1, 0.5, 0) -- Orange
        frameColor = Color3.new(0.3, 0.2, 0.1)
    elseif streak >= 10 then
        color = Color3.new(1, 0.8, 0) -- Yellow
        frameColor = Color3.new(0.3, 0.3, 0.1)
    elseif streak >= 5 then
        color = Color3.new(0.5, 1, 0.5) -- Light green
        frameColor = Color3.new(0.1, 0.2, 0.1)
    end
    
    streakNumber.TextColor3 = color
    gui.Container.StreakFrame.BackgroundColor3 = frameColor
    
    -- Celebration effect for milestone streaks
    if streak > 0 and streak % 5 == 0 then
        local celebration = TweenService:Create(
            gui.Container.StreakFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
            {Size = UDim2.new(0.3, 0, 0.3, 0)}
        )
        celebration:Play()
        celebration.Completed:Connect(function()
            local shrink = TweenService:Create(
                gui.Container.StreakFrame,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {Size = UDim2.new(0.25, 0, 0.25, 0)}
            )
            shrink:Play()
        end)
    end
end

-- Spawn a new key with speed adjusted by streak
local function spawnKey()
    if not isRowing or not gui then return end
    
    local key = POSSIBLE_KEYS[math.random(1, #POSSIBLE_KEYS)]
    local keyPrompt = createKeyPrompt(key)
    keyPrompt.Parent = gui.Container.KeysContainer
    
    -- Store key data
    local keyData = {
        key = key,
        frame = keyPrompt,
        pressed = false,
        spawnTime = tick()
    }
    table.insert(activeKeys, keyData)
    
    -- Adjust speed based on streak for more challenge
    local speedMultiplier = 1 + math.min(currentStreak / 30, 0.5) -- Up to 50% faster at max streak
    local adjustedLifetime = KEY_LIFETIME / speedMultiplier
    
    -- Animate key moving from right to left
    local targetPosition = UDim2.new(-0.1, 0, 0.1, 0)
    local tween = TweenService:Create(
        keyPrompt,
        TweenInfo.new(adjustedLifetime, Enum.EasingStyle.Linear),
        {Position = targetPosition}
    )
    
    tween:Play()
    
    -- Remove key after lifetime
    tween.Completed:Connect(function()
        if not keyData.pressed then
            -- Missed key - counts as incorrect
            remoteEvent:FireServer("KeyPress", false, currentBoat)
        end
        
        -- Remove from active keys
        for i, data in ipairs(activeKeys) do
            if data == keyData then
                table.remove(activeKeys, i)
                break
            end
        end
        
        keyPrompt:Destroy()
    end)
end

-- Check if a key press matches any active keys
local function checkKeyPress(keyCode)
    if not isRowing then return end
    
    local keyName = keyCode.Name
    if string.len(keyName) == 1 then
        keyName = string.upper(keyName)
    end
    
    -- Find the leftmost (oldest) matching key
    local oldestMatch = nil
    local oldestIndex = nil
    
    for i, keyData in ipairs(activeKeys) do
        if not keyData.pressed and keyData.key == keyName then
            if not oldestMatch or keyData.spawnTime < oldestMatch.spawnTime then
                oldestMatch = keyData
                oldestIndex = i
            end
        end
    end
    
    if oldestMatch then
        -- Correct key press
        oldestMatch.pressed = true
        remoteEvent:FireServer("KeyPress", true, currentBoat)
        
        -- Visual feedback - flash green with streak-based intensity
        local greenIntensity = 0.2 + math.min(currentStreak / 30, 0.6)
        oldestMatch.frame.BackgroundColor3 = Color3.new(0.2, greenIntensity, 0.2)
        
        -- Success particle effect for high streaks
        if currentStreak > 10 then
            local particleFrame = Instance.new("Frame")
            particleFrame.Size = UDim2.new(0.02, 0, 0.02, 0)
            particleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            particleFrame.BackgroundColor3 = Color3.new(0.2, 1, 0.2)
            particleFrame.BorderSizePixel = 0
            particleFrame.Parent = oldestMatch.frame
            
            local particleTween = TweenService:Create(
                particleFrame,
                TweenInfo.new(0.5, Enum.EasingStyle.Quad),
                {
                    Position = UDim2.new(0.5, math.random(-20, 20), -0.5, 0),
                    Size = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1
                }
            )
            particleTween:Play()
            particleTween.Completed:Connect(function()
                particleFrame:Destroy()
            end)
        end
        
        -- Fade out and remove
        local fadeOut = TweenService:Create(
            oldestMatch.frame,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {BackgroundTransparency = 1}
        )
        fadeOut:Play()
        
        fadeOut.Completed:Connect(function()
            oldestMatch.frame:Destroy()
        end)
        
        table.remove(activeKeys, oldestIndex)
    else
        -- Incorrect key press
        remoteEvent:FireServer("KeyPress", false, currentBoat)
        
        -- Visual feedback - flash red on container
        local container = gui.Container
        local originalColor = container.BackgroundColor3
        container.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
        
        -- Screen shake effect for wrong keys
        local originalPosition = container.Position
        for i = 1, 3 do
            container.Position = originalPosition + UDim2.new(0, math.random(-5, 5), 0, math.random(-5, 5))
            wait(0.05)
        end
        container.Position = originalPosition
        container.BackgroundColor3 = originalColor
    end
end

-- Update speed bar
local function updateSpeedBar(data)
    if not gui or not gui.Enabled then return end
    
    if type(data) == "table" then
        currentSpeed = data.currentSpeed or currentSpeed
        currentStreak = data.streak or currentStreak
        currentAccuracy = data.accuracy or currentAccuracy
        
        -- Update accuracy display
        local accuracyPercent = math.floor(currentAccuracy * 100)
        gui.Container.AccuracyFrame.AccuracyNumber.Text = accuracyPercent .. "%"
        
        -- Color code accuracy
        local accuracyColor
        if accuracyPercent >= 90 then
            accuracyColor = Color3.new(0.2, 1, 0.2)
        elseif accuracyPercent >= 70 then
            accuracyColor = Color3.new(1, 1, 0.2)
        else
            accuracyColor = Color3.new(1, 0.2, 0.2)
        end
        gui.Container.AccuracyFrame.AccuracyNumber.TextColor3 = accuracyColor
    else
        currentSpeed = data or currentSpeed
    end
    
    local speedBar = gui.Container.SpeedBarBackground.SpeedBar
    local speedPercent = math.min(currentSpeed / MAX_SPEED, 1)
    
    -- Animate the speed bar
    local targetSize = UDim2.new(speedPercent, 0, 1, 0)
    local tween = TweenService:Create(
        speedBar,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = targetSize}
    )
    tween:Play()
    
    -- Change color based on speed
    local color
    if speedPercent < 0.3 then
        color = Color3.new(0.8, 0.2, 0.2) -- Red for low speed
    elseif speedPercent < 0.7 then
        color = Color3.new(0.8, 0.8, 0.2) -- Yellow for medium speed
    else
        color = Color3.new(0.2, 0.8, 0.2) -- Green for high speed
    end
    
    speedBar.BackgroundColor3 = color
end

-- Start rowing
local function startRowing(boat)
    if isRowing then return end
    
    isRowing = true
    currentBoat = boat
    currentStreak = 0
    currentAccuracy = 1
    
    -- Create UI if it doesn't exist
    if not gui then
        gui = createRowingUI()
    end
    
    gui.Enabled = true
    updateStreakDisplay(0)
    
    -- Clear any existing keys
    for _, keyData in ipairs(activeKeys) do
        keyData.frame:Destroy()
    end
    activeKeys = {}
    
    -- Start spawning keys with dynamic interval
    spawn(function()
        while isRowing do
            spawnKey()
            -- Adjust spawn rate based on streak
            local spawnMultiplier = 1 + math.min(currentStreak / 30, 0.3) -- Up to 30% faster spawning
            wait(KEY_SPAWN_INTERVAL / spawnMultiplier)
        end
    end)
end

-- Stop rowing
local function stopRowing()
    isRowing = false
    currentBoat = nil
    
    if gui then
        gui.Enabled = false
        
        -- Clear all active keys
        for _, keyData in ipairs(activeKeys) do
            keyData.frame:Destroy()
        end
        activeKeys = {}
    end
end

-- Connect input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        checkKeyPress(input.KeyCode)
    end
end)

-- Connect remote events
remoteEvent.OnClientEvent:Connect(function(action, data)
    if action == "StartRowing" then
        startRowing(data)
    elseif action == "StopRowing" then
        stopRowing()
    elseif action == "UpdateSpeed" then
        updateSpeedBar(data)
    elseif action == "UpdateStreak" then
        updateStreakDisplay(data)
    end
end)

-- Cleanup on character removal
player.CharacterRemoving:Connect(function()
    stopRowing()
end)