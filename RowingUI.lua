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

-- Create the main UI
local function createRowingUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RowingUI"
    screenGui.ResetOnSpawn = false
    
    -- Main container frame
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0.8, 0, 0.15, 0)
    container.Position = UDim2.new(0.1, 0, 0.7, 0)
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
    speedBarBg.Size = UDim2.new(0.9, 0, 0.1, 0)
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
    
    -- Keys container
    local keysContainer = Instance.new("Frame")
    keysContainer.Name = "KeysContainer"
    keysContainer.Size = UDim2.new(1, 0, 0.7, 0)
    keysContainer.Position = UDim2.new(0, 0, 0.25, 0)
    keysContainer.BackgroundTransparency = 1
    keysContainer.Parent = container
    
    -- Instructions label
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(1, 0, 0.15, 0)
    instructions.Position = UDim2.new(0, 0, 0.08, 0)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Press the keys as they appear!"
    instructions.TextColor3 = Color3.new(1, 1, 1)
    instructions.TextScaled = true
    instructions.Font = Enum.Font.SourceSansBold
    instructions.Parent = container
    
    screenGui.Parent = playerGui
    return screenGui
end

-- Create a key prompt
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
    
    -- Add glow effect
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.new(0.4, 0.7, 1)
    uiStroke.Thickness = 2
    uiStroke.Transparency = 0.5
    uiStroke.Parent = keyFrame
    
    return keyFrame
end

-- Spawn a new key
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
    
    -- Animate key moving from right to left
    local targetPosition = UDim2.new(-0.1, 0, 0.1, 0)
    local tween = TweenService:Create(
        keyPrompt,
        TweenInfo.new(KEY_LIFETIME, Enum.EasingStyle.Linear),
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
        
        -- Visual feedback - flash green
        oldestMatch.frame.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
        
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
        wait(0.1)
        container.BackgroundColor3 = originalColor
    end
end

-- Start rowing
local function startRowing(boat)
    if isRowing then return end
    
    isRowing = true
    currentBoat = boat
    
    -- Create UI if it doesn't exist
    if not gui then
        gui = createRowingUI()
    end
    
    gui.Enabled = true
    
    -- Clear any existing keys
    for _, keyData in ipairs(activeKeys) do
        keyData.frame:Destroy()
    end
    activeKeys = {}
    
    -- Start spawning keys
    spawn(function()
        while isRowing do
            spawnKey()
            wait(KEY_SPAWN_INTERVAL)
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

-- Update speed bar
local function updateSpeedBar(speed)
    if not gui or not gui.Enabled then return end
    
    currentSpeed = speed or currentSpeed
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
    end
end)

-- Cleanup on character removal
player.CharacterRemoving:Connect(function()
    stopRowing()
end)