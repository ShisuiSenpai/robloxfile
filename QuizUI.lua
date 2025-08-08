-- Minimal Quiz UI for Roblox
-- Clean, compact design with only questions and answers

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuizUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Create BG Frame (as requested) - Centered and compact
local BG = Instance.new("Frame")
BG.Name = "BG"
BG.Size = UDim2.new(0, 600, 0, 500) -- Fixed size, not fullscreen
BG.Position = UDim2.new(0.5, -300, 0.5, -250) -- Centered
BG.BackgroundColor3 = Color3.fromRGB(245, 245, 250) -- Light gray-white background
BG.BorderSizePixel = 0
BG.Parent = screenGui

-- Add subtle shadow
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Position = UDim2.new(0, -10, 0, -10)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.7
shadow.BorderSizePixel = 0
shadow.ZIndex = -1
shadow.Parent = BG

-- Add rounded corners to main frame
local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(0, 16)
bgCorner.Parent = BG

-- Add rounded corners to shadow
local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 16)
shadowCorner.Parent = shadow

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(0.9, 0, 0, 50)
titleLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "QUIZ TIME"
titleLabel.TextColor3 = Color3.fromRGB(50, 50, 60) -- Dark gray
titleLabel.TextScaled = false
titleLabel.TextSize = 32
titleLabel.Font = Enum.Font.Montserrat -- Modern, clean font
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Parent = BG

-- Question Frame
local questionFrame = Instance.new("Frame")
questionFrame.Name = "QuestionFrame"
questionFrame.Size = UDim2.new(0.9, 0, 0, 120)
questionFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
questionFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Pure white
questionFrame.BorderSizePixel = 0
questionFrame.Parent = BG

local questionCorner = Instance.new("UICorner")
questionCorner.CornerRadius = UDim.new(0, 12)
questionCorner.Parent = questionFrame

-- Question border
local questionBorder = Instance.new("UIStroke")
questionBorder.Color = Color3.fromRGB(220, 220, 230)
questionBorder.Thickness = 2
questionBorder.Parent = questionFrame

-- Question text
local questionText = Instance.new("TextLabel")
questionText.Name = "QuestionText"
questionText.Size = UDim2.new(0.95, 0, 0.9, 0)
questionText.Position = UDim2.new(0.025, 0, 0.05, 0)
questionText.BackgroundTransparency = 1
questionText.Text = "What is the capital of France?"
questionText.TextColor3 = Color3.fromRGB(40, 40, 50) -- Very dark gray
questionText.TextScaled = false
questionText.TextSize = 20
questionText.Font = Enum.Font.Gotham -- Clean, readable font
questionText.TextWrapped = true
questionText.TextXAlignment = Enum.TextXAlignment.Center
questionText.TextYAlignment = Enum.TextYAlignment.Center
questionText.Parent = questionFrame

-- Answer buttons container with spacing
local answersContainer = Instance.new("Frame")
answersContainer.Name = "AnswersContainer"
answersContainer.Size = UDim2.new(0.9, 0, 0, 240)
answersContainer.Position = UDim2.new(0.05, 0, 0.5, 0)
answersContainer.BackgroundTransparency = 1
answersContainer.Parent = BG

-- Function to create answer button
local function createAnswerButton(position, letter, text)
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "Answer" .. letter
    buttonFrame.Size = UDim2.new(1, 0, 0, 50)
    buttonFrame.Position = position
    buttonFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White background
    buttonFrame.BorderSizePixel = 0
    buttonFrame.Parent = answersContainer
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = buttonFrame
    
    -- Button border
    local buttonBorder = Instance.new("UIStroke")
    buttonBorder.Color = Color3.fromRGB(100, 150, 250) -- Light blue border
    buttonBorder.Thickness = 2
    buttonBorder.Parent = buttonFrame
    
    -- Container for letter and answer
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = buttonFrame
    
    -- Letter indicator
    local letterLabel = Instance.new("TextLabel")
    letterLabel.Name = "Letter"
    letterLabel.Size = UDim2.new(0, 40, 1, 0)
    letterLabel.Position = UDim2.new(0, 15, 0, 0)
    letterLabel.BackgroundTransparency = 1
    letterLabel.Text = letter
    letterLabel.TextColor3 = Color3.fromRGB(100, 150, 250) -- Blue
    letterLabel.TextScaled = false
    letterLabel.TextSize = 22
    letterLabel.Font = Enum.Font.GothamBold
    letterLabel.TextXAlignment = Enum.TextXAlignment.Left
    letterLabel.Parent = contentFrame
    
    -- Answer text
    local answerLabel = Instance.new("TextLabel")
    answerLabel.Name = "AnswerText"
    answerLabel.Size = UDim2.new(1, -70, 1, 0)
    answerLabel.Position = UDim2.new(0, 55, 0, 0)
    answerLabel.BackgroundTransparency = 1
    answerLabel.Text = text
    answerLabel.TextColor3 = Color3.fromRGB(60, 60, 70) -- Dark gray
    answerLabel.TextScaled = false
    answerLabel.TextSize = 18
    answerLabel.Font = Enum.Font.Gotham
    answerLabel.TextXAlignment = Enum.TextXAlignment.Left
    answerLabel.Parent = contentFrame
    
    -- Button functionality
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Position = UDim2.new(0, 0, 0, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = buttonFrame
    
    -- Hover effect
    local isHovering = false
    button.MouseEnter:Connect(function()
        isHovering = true
        TweenService:Create(buttonFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Color3.fromRGB(100, 150, 250) -- Blue background on hover
        }):Play()
        TweenService:Create(letterLabel, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        TweenService:Create(answerLabel, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        isHovering = false
        TweenService:Create(buttonFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        TweenService:Create(letterLabel, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(100, 150, 250)
        }):Play()
        TweenService:Create(answerLabel, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(60, 60, 70)
        }):Play()
    end)
    
    -- Click effect
    button.MouseButton1Click:Connect(function()
        -- Flash effect
        TweenService:Create(buttonFrame, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(80, 130, 230)
        }):Play()
        wait(0.1)
        if isHovering then
            TweenService:Create(buttonFrame, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.fromRGB(100, 150, 250)
            }):Play()
        end
    end)
    
    return buttonFrame
end

-- Create answer buttons with proper spacing
createAnswerButton(UDim2.new(0, 0, 0, 0), "A", "Paris")
createAnswerButton(UDim2.new(0, 0, 0, 60), "B", "London")
createAnswerButton(UDim2.new(0, 0, 0, 120), "C", "Berlin")
createAnswerButton(UDim2.new(0, 0, 0, 180), "D", "Madrid")

-- Simple entrance animation
BG.Position = UDim2.new(0.5, -300, 0.5, -300)
BG.Size = UDim2.new(0, 580, 0, 480)
local entranceTween = TweenService:Create(BG, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
    Position = UDim2.new(0.5, -300, 0.5, -250),
    Size = UDim2.new(0, 600, 0, 500)
})
entranceTween:Play()

print("Minimal Quiz UI loaded!")