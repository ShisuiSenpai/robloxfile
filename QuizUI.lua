-- Quiz UI - Clean White & Blue Theme
-- Floating elements design with no background frame

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

-- Create BG Frame (transparent container as requested)
local BG = Instance.new("Frame")
BG.Name = "BG"
BG.Size = UDim2.new(1, 0, 1, 0)
BG.Position = UDim2.new(0, 0, 0, 0)
BG.BackgroundTransparency = 1 -- Fully transparent
BG.BorderSizePixel = 0
BG.Parent = screenGui

-- Question Frame (floating) - Bigger and lower
local questionFrame = Instance.new("Frame")
questionFrame.Name = "QuestionFrame"
questionFrame.Size = UDim2.new(0, 800, 0, 120)
questionFrame.Position = UDim2.new(0.5, -400, 0.55, 0)  -- Moved even lower
questionFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
questionFrame.BorderSizePixel = 0
questionFrame.Parent = BG

local questionCorner = Instance.new("UICorner")
questionCorner.CornerRadius = UDim.new(0, 15)
questionCorner.Parent = questionFrame

-- Question border
local questionBorder = Instance.new("UIStroke")
questionBorder.Color = Color3.fromRGB(100, 150, 250)
questionBorder.Thickness = 3
questionBorder.Parent = questionFrame

-- Question text
local questionText = Instance.new("TextLabel")
questionText.Name = "QuestionText"
questionText.Size = UDim2.new(0.95, 0, 0.9, 0)
questionText.Position = UDim2.new(0.025, 0, 0.05, 0)
questionText.BackgroundTransparency = 1
questionText.Text = "What is the capital of France?"
questionText.TextColor3 = Color3.fromRGB(100, 150, 250) -- Blue text
questionText.TextScaled = false
questionText.TextSize = 28  -- Even bigger text
questionText.Font = Enum.Font.Gotham
questionText.TextWrapped = true
questionText.TextXAlignment = Enum.TextXAlignment.Center
questionText.TextYAlignment = Enum.TextYAlignment.Center
questionText.Parent = questionFrame

-- Function to create answer button (Who Wants to Be a Millionaire style)
local function createAnswerButton(position, letter, text)
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "Answer" .. letter
    buttonFrame.Size = UDim2.new(0, 380, 0, 70)  -- Bigger buttons
    buttonFrame.Position = position
    buttonFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    buttonFrame.BorderSizePixel = 0
    buttonFrame.Parent = BG
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 35) -- Pill shape like the show
    buttonCorner.Parent = buttonFrame
    
    -- Button border
    local buttonBorder = Instance.new("UIStroke")
    buttonBorder.Color = Color3.fromRGB(100, 150, 250)
    buttonBorder.Thickness = 2
    buttonBorder.Parent = buttonFrame
    
    -- Container for letter and answer
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = buttonFrame
    
    -- Letter indicator (circular like the show)
    local letterCircle = Instance.new("Frame")
    letterCircle.Name = "LetterCircle"
    letterCircle.Size = UDim2.new(0, 50, 0, 50)  -- Bigger circle
    letterCircle.Position = UDim2.new(0, 10, 0.5, -25)
    letterCircle.BackgroundColor3 = Color3.fromRGB(100, 150, 250)
    letterCircle.BorderSizePixel = 0
    letterCircle.Parent = contentFrame
    
    local letterCorner = Instance.new("UICorner")
    letterCorner.CornerRadius = UDim.new(0.5, 0)
    letterCorner.Parent = letterCircle
    
    local letterLabel = Instance.new("TextLabel")
    letterLabel.Name = "Letter"
    letterLabel.Size = UDim2.new(1, 0, 1, 0)
    letterLabel.BackgroundTransparency = 1
    letterLabel.Text = letter
    letterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    letterLabel.TextScaled = false
    letterLabel.TextSize = 24  -- Bigger letter
    letterLabel.Font = Enum.Font.GothamBold
    letterLabel.Parent = letterCircle
    
    -- Answer text
    local answerLabel = Instance.new("TextLabel")
    answerLabel.Name = "AnswerText"
    answerLabel.Size = UDim2.new(1, -80, 1, 0)
    answerLabel.Position = UDim2.new(0, 70, 0, 0)
    answerLabel.BackgroundTransparency = 1
    answerLabel.Text = text
    answerLabel.TextColor3 = Color3.fromRGB(100, 150, 250)
    answerLabel.TextScaled = false
    answerLabel.TextSize = 20  -- Bigger text
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
            BackgroundColor3 = Color3.fromRGB(100, 150, 250)
        }):Play()
        TweenService:Create(buttonBorder, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 3
        }):Play()
        TweenService:Create(letterCircle, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        TweenService:Create(letterLabel, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(100, 150, 250)
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
        TweenService:Create(buttonBorder, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(100, 150, 250),
            Thickness = 2
        }):Play()
        TweenService:Create(letterCircle, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(100, 150, 250)
        }):Play()
        TweenService:Create(letterLabel, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        TweenService:Create(answerLabel, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(100, 150, 250)
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

-- Create answer buttons - Much closer to question and lower
-- Top row (A and B)
createAnswerButton(UDim2.new(0.5, -390, 0.72, 0), "A", "Paris")   -- Much closer to question
createAnswerButton(UDim2.new(0.5, 10, 0.72, 0), "B", "London")

-- Bottom row (C and D) - Less gap between rows
createAnswerButton(UDim2.new(0.5, -390, 0.72, 85), "C", "Berlin")
createAnswerButton(UDim2.new(0.5, 10, 0.72, 85), "D", "Madrid")

-- Entrance animations for floating effect
local function animateIn()
    -- Animate question
    questionFrame.Position = UDim2.new(0.5, -400, -0.3, 0)
    local questionTween = TweenService:Create(questionFrame, TweenInfo.new(0.8, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -400, 0.55, 0)
    })
    questionTween:Play()
    
    -- Animate answer buttons
    wait(0.2)
    for _, child in pairs(BG:GetChildren()) do
        if child.Name:match("Answer") then
            local originalPos = child.Position
            child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, 1.2, 0)
            local answerTween = TweenService:Create(child, TweenInfo.new(0.6, Enum.EasingStyle.Back), {
                Position = originalPos
            })
            wait(0.1)
            answerTween:Play()
        end
    end
end

-- Add subtle floating animation
local function addFloatingEffect(element, delay, amplitude)
    spawn(function()
        wait(delay)
        local originalY = element.Position.Y.Offset
        while element.Parent do
            local time = tick()
            local offset = math.sin(time * 0.5) * amplitude
            element.Position = UDim2.new(
                element.Position.X.Scale,
                element.Position.X.Offset,
                element.Position.Y.Scale,
                originalY + offset
            )
            RunService.Heartbeat:Wait()
        end
    end)
end

-- Apply floating effect to elements
local RunService = game:GetService("RunService")
spawn(function()
    wait(2) -- Wait for entrance animations
    addFloatingEffect(questionFrame, 0.5, 4)
    for _, child in pairs(BG:GetChildren()) do
        if child.Name:match("Answer") then
            addFloatingEffect(child, math.random() * 0.5, 2)
        end
    end
end)

-- Start animations
animateIn()

print("Quiz UI loaded!")