-- Who Wants to Be a Millionaire Quiz UI
-- This script creates a beautiful quiz interface with animations and effects

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuizUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Create BG Frame (as requested)
local BG = Instance.new("Frame")
BG.Name = "BG"
BG.Size = UDim2.new(1, 0, 1, 0)
BG.Position = UDim2.new(0, 0, 0, 0)
BG.BackgroundColor3 = Color3.fromRGB(15, 20, 40) -- Dark blue background
BG.BorderSizePixel = 0
BG.Parent = screenGui

-- Create gradient background
local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 30, 60)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 40, 80)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 20, 40))
})
bgGradient.Rotation = 45
bgGradient.Parent = BG

-- Main container for quiz elements
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(0.95, 0, 0.9, 0)
mainContainer.Position = UDim2.new(0.025, 0, 0.05, 0)
mainContainer.BackgroundTransparency = 1
mainContainer.Parent = BG

-- Title/Logo area
local titleFrame = Instance.new("Frame")
titleFrame.Name = "TitleFrame"
titleFrame.Size = UDim2.new(1, 0, 0.15, 0)
titleFrame.Position = UDim2.new(0, 0, 0, 0)
titleFrame.BackgroundTransparency = 1
titleFrame.Parent = mainContainer

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "WHO WANTS TO BE A MILLIONAIRE?"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = titleFrame

-- Add text stroke for better visibility
local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(139, 90, 0)
titleStroke.Thickness = 2
titleStroke.Parent = titleLabel

-- Question display area
local questionFrame = Instance.new("Frame")
questionFrame.Name = "QuestionFrame"
questionFrame.Size = UDim2.new(0.7, 0, 0.2, 0)
questionFrame.Position = UDim2.new(0.15, 0, 0.2, 0)
questionFrame.BackgroundColor3 = Color3.fromRGB(25, 35, 65)
questionFrame.BorderSizePixel = 0
questionFrame.Parent = mainContainer

-- Add rounded corners
local questionCorner = Instance.new("UICorner")
questionCorner.CornerRadius = UDim.new(0, 12)
questionCorner.Parent = questionFrame

-- Question gradient
local questionGradient = Instance.new("UIGradient")
questionGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 50, 90)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 35, 65))
})
questionGradient.Rotation = 90
questionGradient.Parent = questionFrame

-- Question text
local questionText = Instance.new("TextLabel")
questionText.Name = "QuestionText"
questionText.Size = UDim2.new(0.95, 0, 0.9, 0)
questionText.Position = UDim2.new(0.025, 0, 0.05, 0)
questionText.BackgroundTransparency = 1
questionText.Text = "What is the capital of France?"
questionText.TextColor3 = Color3.fromRGB(255, 255, 255)
questionText.TextScaled = true
questionText.Font = Enum.Font.SourceSans
questionText.TextWrapped = true
questionText.Parent = questionFrame

-- Create answer buttons container
local answersContainer = Instance.new("Frame")
answersContainer.Name = "AnswersContainer"
answersContainer.Size = UDim2.new(0.7, 0, 0.35, 0)
answersContainer.Position = UDim2.new(0.15, 0, 0.45, 0)
answersContainer.BackgroundTransparency = 1
answersContainer.Parent = mainContainer

-- Function to create answer button
local function createAnswerButton(position, letter, text)
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "Answer" .. letter
    buttonFrame.Size = UDim2.new(0.48, 0, 0.45, 0)
    buttonFrame.Position = position
    buttonFrame.BackgroundColor3 = Color3.fromRGB(30, 40, 70)
    buttonFrame.BorderSizePixel = 0
    buttonFrame.Parent = answersContainer
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = buttonFrame
    
    local buttonGradient = Instance.new("UIGradient")
    buttonGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 60, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 40, 70))
    })
    buttonGradient.Rotation = 90
    buttonGradient.Parent = buttonFrame
    
    -- Letter indicator
    local letterLabel = Instance.new("TextLabel")
    letterLabel.Name = "Letter"
    letterLabel.Size = UDim2.new(0.15, 0, 1, 0)
    letterLabel.Position = UDim2.new(0, 0, 0, 0)
    letterLabel.BackgroundTransparency = 1
    letterLabel.Text = letter .. ":"
    letterLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    letterLabel.TextScaled = true
    letterLabel.Font = Enum.Font.SourceSansBold
    letterLabel.Parent = buttonFrame
    
    -- Answer text
    local answerLabel = Instance.new("TextLabel")
    answerLabel.Name = "AnswerText"
    answerLabel.Size = UDim2.new(0.8, 0, 1, 0)
    answerLabel.Position = UDim2.new(0.15, 0, 0, 0)
    answerLabel.BackgroundTransparency = 1
    answerLabel.Text = text
    answerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    answerLabel.TextScaled = true
    answerLabel.Font = Enum.Font.SourceSans
    answerLabel.TextXAlignment = Enum.TextXAlignment.Left
    answerLabel.Parent = buttonFrame
    
    -- Button functionality
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Position = UDim2.new(0, 0, 0, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = buttonFrame
    
    -- Hover effect
    local hoverTween
    button.MouseEnter:Connect(function()
        if hoverTween then hoverTween:Cancel() end
        hoverTween = TweenService:Create(buttonFrame, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(50, 60, 100)
        })
        hoverTween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        if hoverTween then hoverTween:Cancel() end
        hoverTween = TweenService:Create(buttonFrame, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(30, 40, 70)
        })
        hoverTween:Play()
    end)
    
    return buttonFrame
end

-- Create answer buttons
createAnswerButton(UDim2.new(0, 0, 0, 0), "A", "Paris")
createAnswerButton(UDim2.new(0.52, 0, 0, 0), "B", "London")
createAnswerButton(UDim2.new(0, 0, 0.55, 0), "C", "Berlin")
createAnswerButton(UDim2.new(0.52, 0, 0.55, 0), "D", "Madrid")

-- Prize ladder frame
local prizeFrame = Instance.new("Frame")
prizeFrame.Name = "PrizeFrame"
prizeFrame.Size = UDim2.new(0.25, 0, 0.7, 0)
prizeFrame.Position = UDim2.new(0.72, 0, 0.15, 0)
prizeFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 60)
prizeFrame.BorderSizePixel = 0
prizeFrame.Parent = mainContainer

local prizeCorner = Instance.new("UICorner")
prizeCorner.CornerRadius = UDim.new(0, 10)
prizeCorner.Parent = prizeFrame

-- Prize list
local prizeList = Instance.new("ScrollingFrame")
prizeList.Name = "PrizeList"
prizeList.Size = UDim2.new(0.95, 0, 0.95, 0)
prizeList.Position = UDim2.new(0.025, 0, 0.025, 0)
prizeList.BackgroundTransparency = 1
prizeList.ScrollBarThickness = 6
prizeList.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
prizeList.Parent = prizeFrame

local prizeLayout = Instance.new("UIListLayout")
prizeLayout.SortOrder = Enum.SortOrder.LayoutOrder
prizeLayout.Padding = UDim.new(0, 2)
prizeLayout.Parent = prizeList

-- Prize amounts
local prizes = {
    "$1,000,000", "$500,000", "$250,000", "$125,000", "$64,000",
    "$32,000", "$16,000", "$8,000", "$4,000", "$2,000",
    "$1,000", "$500", "$300", "$200", "$100"
}

for i, amount in ipairs(prizes) do
    local prizeItem = Instance.new("TextLabel")
    prizeItem.Name = "Prize" .. i
    prizeItem.Size = UDim2.new(1, 0, 0, 30)
    prizeItem.BackgroundColor3 = Color3.fromRGB(30, 40, 70)
    prizeItem.BorderSizePixel = 0
    prizeItem.Text = tostring(16 - i) .. " - " .. amount
    prizeItem.TextColor3 = Color3.fromRGB(255, 255, 255)
    prizeItem.TextScaled = true
    prizeItem.Font = Enum.Font.SourceSans
    prizeItem.LayoutOrder = i
    prizeItem.Parent = prizeList
    
    if i == 10 or i == 5 then -- Safe havens
        prizeItem.TextColor3 = Color3.fromRGB(255, 215, 0)
        prizeItem.Font = Enum.Font.SourceSansBold
    end
end

-- Lifelines container
local lifelinesFrame = Instance.new("Frame")
lifelinesFrame.Name = "LifelinesFrame"
lifelinesFrame.Size = UDim2.new(0.5, 0, 0.08, 0)
lifelinesFrame.Position = UDim2.new(0.25, 0, 0.88, 0)
lifelinesFrame.BackgroundTransparency = 1
lifelinesFrame.Parent = mainContainer

-- Function to create lifeline button
local function createLifeline(position, icon, name)
    local lifelineButton = Instance.new("Frame")
    lifelineButton.Name = name
    lifelineButton.Size = UDim2.new(0.3, 0, 1, 0)
    lifelineButton.Position = position
    lifelineButton.BackgroundColor3 = Color3.fromRGB(40, 50, 80)
    lifelineButton.BorderSizePixel = 0
    lifelineButton.Parent = lifelinesFrame
    
    local lifelineCorner = Instance.new("UICorner")
    lifelineCorner.CornerRadius = UDim.new(0.5, 0)
    lifelineCorner.Parent = lifelineButton
    
    local lifelineText = Instance.new("TextLabel")
    lifelineText.Size = UDim2.new(1, 0, 1, 0)
    lifelineText.BackgroundTransparency = 1
    lifelineText.Text = icon
    lifelineText.TextColor3 = Color3.fromRGB(255, 255, 255)
    lifelineText.TextScaled = true
    lifelineText.Font = Enum.Font.SourceSansBold
    lifelineText.Parent = lifelineButton
    
    local lifelineButton = Instance.new("TextButton")
    lifelineButton.Size = UDim2.new(1, 0, 1, 0)
    lifelineButton.BackgroundTransparency = 1
    lifelineButton.Text = ""
    lifelineButton.Parent = lifelineButton
    
    return lifelineButton
end

-- Create lifelines
createLifeline(UDim2.new(0, 0, 0, 0), "50:50", "FiftyFifty")
createLifeline(UDim2.new(0.35, 0, 0, 0), "📞", "PhoneFriend")
createLifeline(UDim2.new(0.7, 0, 0, 0), "👥", "AskAudience")

-- Timer display
local timerFrame = Instance.new("Frame")
timerFrame.Name = "TimerFrame"
timerFrame.Size = UDim2.new(0.15, 0, 0.08, 0)
timerFrame.Position = UDim2.new(0.025, 0, 0.2, 0)
timerFrame.BackgroundColor3 = Color3.fromRGB(30, 40, 70)
timerFrame.BorderSizePixel = 0
timerFrame.Parent = mainContainer

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 8)
timerCorner.Parent = timerFrame

local timerText = Instance.new("TextLabel")
timerText.Name = "TimerText"
timerText.Size = UDim2.new(1, 0, 1, 0)
timerText.BackgroundTransparency = 1
timerText.Text = "30"
timerText.TextColor3 = Color3.fromRGB(255, 255, 255)
timerText.TextScaled = true
timerText.Font = Enum.Font.SourceSansBold
timerText.Parent = timerFrame

-- Add some visual polish with animations
local function animateIn()
    -- Animate title
    titleLabel.TextTransparency = 1
    local titleTween = TweenService:Create(titleLabel, TweenInfo.new(1, Enum.EasingStyle.Quad), {
        TextTransparency = 0
    })
    titleTween:Play()
    
    -- Animate question frame
    questionFrame.Position = UDim2.new(0.15, 0, -0.3, 0)
    local questionTween = TweenService:Create(questionFrame, TweenInfo.new(0.8, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.15, 0, 0.2, 0)
    })
    wait(0.3)
    questionTween:Play()
    
    -- Animate answer buttons
    for _, child in pairs(answersContainer:GetChildren()) do
        if child:IsA("Frame") then
            child.BackgroundTransparency = 1
            local answerTween = TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 0
            })
            wait(0.1)
            answerTween:Play()
        end
    end
end

-- Start animations
animateIn()

print("Quiz UI loaded successfully!")