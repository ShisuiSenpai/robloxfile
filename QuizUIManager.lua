-- Quiz UI Manager Module
-- Provides helper functions for managing the Who Wants to Be a Millionaire UI

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local QuizUIManager = {}

-- Color schemes
local Colors = {
    Correct = Color3.fromRGB(0, 255, 100),
    Incorrect = Color3.fromRGB(255, 50, 50),
    Selected = Color3.fromRGB(255, 180, 0),
    Default = Color3.fromRGB(30, 40, 70),
    Hover = Color3.fromRGB(50, 60, 100),
    Gold = Color3.fromRGB(255, 215, 0),
    White = Color3.fromRGB(255, 255, 255)
}

-- Update question display
function QuizUIManager.SetQuestion(questionFrame, questionText)
    local textLabel = questionFrame:FindFirstChild("QuestionText")
    if not textLabel then return end
    
    -- Fade out animation
    local fadeOut = TweenService:Create(textLabel, TweenInfo.new(0.3), {
        TextTransparency = 1
    })
    
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        textLabel.Text = questionText
        
        -- Fade in animation
        local fadeIn = TweenService:Create(textLabel, TweenInfo.new(0.3), {
            TextTransparency = 0
        })
        fadeIn:Play()
    end)
end

-- Update answer options
function QuizUIManager.SetAnswers(answersContainer, answers)
    local letters = {"A", "B", "C", "D"}
    local positions = {
        UDim2.new(0, 0, 0, 0),
        UDim2.new(0.52, 0, 0, 0),
        UDim2.new(0, 0, 0.55, 0),
        UDim2.new(0.52, 0, 0.55, 0)
    }
    
    for i, answer in ipairs(answers) do
        if i > 4 then break end
        
        local answerFrame = answersContainer:FindFirstChild("Answer" .. letters[i])
        if answerFrame then
            local answerText = answerFrame:FindFirstChild("AnswerText")
            if answerText then
                -- Animate text change
                local fadeTween = TweenService:Create(answerText, TweenInfo.new(0.2), {
                    TextTransparency = 1
                })
                
                fadeTween:Play()
                fadeTween.Completed:Connect(function()
                    answerText.Text = answer
                    TweenService:Create(answerText, TweenInfo.new(0.2), {
                        TextTransparency = 0
                    }):Play()
                end)
            end
        end
    end
end

-- Highlight selected answer
function QuizUIManager.SelectAnswer(answerFrame, callback)
    -- Flash animation
    local originalColor = answerFrame.BackgroundColor3
    
    -- Selection flash
    local flash1 = TweenService:Create(answerFrame, TweenInfo.new(0.15), {
        BackgroundColor3 = Colors.Selected
    })
    
    local flash2 = TweenService:Create(answerFrame, TweenInfo.new(0.15), {
        BackgroundColor3 = originalColor
    })
    
    -- Create pulsing effect
    for i = 1, 3 do
        flash1:Play()
        wait(0.15)
        flash2:Play()
        wait(0.15)
    end
    
    if callback then
        callback()
    end
end

-- Show correct answer
function QuizUIManager.RevealAnswer(answerFrame, isCorrect)
    local targetColor = isCorrect and Colors.Correct or Colors.Incorrect
    
    -- Glow effect
    local glow = Instance.new("PointLight")
    glow.Brightness = 2
    glow.Color = targetColor
    glow.Range = 10
    glow.Parent = answerFrame
    
    -- Color change animation
    local colorTween = TweenService:Create(answerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), {
        BackgroundColor3 = targetColor
    })
    
    colorTween:Play()
    
    -- Pulse effect
    local pulseSize = answerFrame.Size
    local pulseTween = TweenService:Create(answerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(pulseSize.X.Scale * 1.05, 0, pulseSize.Y.Scale * 1.05, 0)
    })
    
    pulseTween:Play()
    pulseTween.Completed:Connect(function()
        TweenService:Create(answerFrame, TweenInfo.new(0.3), {
            Size = pulseSize
        }):Play()
    end)
    
    -- Clean up glow after animation
    wait(1)
    if glow then
        glow:Destroy()
    end
end

-- Update prize ladder
function QuizUIManager.UpdatePrizeLadder(prizeList, currentQuestion)
    local prizeItems = {}
    for _, child in pairs(prizeList:GetChildren()) do
        if child:IsA("TextLabel") and child.Name:match("Prize") then
            table.insert(prizeItems, child)
        end
    end
    
    -- Sort by layout order
    table.sort(prizeItems, function(a, b)
        return a.LayoutOrder < b.LayoutOrder
    end)
    
    -- Update highlighting
    for i, prizeItem in ipairs(prizeItems) do
        local questionNumber = 16 - i
        
        if questionNumber == currentQuestion then
            -- Current question highlight
            prizeItem.BackgroundColor3 = Colors.Selected
            prizeItem.TextColor3 = Color3.fromRGB(0, 0, 0)
            
            -- Add glow effect
            local selectionBox = Instance.new("SelectionBox")
            selectionBox.Adornee = prizeItem
            selectionBox.Color3 = Colors.Gold
            selectionBox.LineThickness = 0.1
            selectionBox.Parent = prizeItem
            
        elseif questionNumber < currentQuestion then
            -- Completed questions
            prizeItem.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
            prizeItem.TextColor3 = Colors.White
            
        else
            -- Future questions
            prizeItem.BackgroundColor3 = Color3.fromRGB(30, 40, 70)
            prizeItem.TextColor3 = Colors.White
        end
    end
end

-- Lifeline animations
function QuizUIManager.UseLifeline(lifelineFrame, lifelineType)
    -- Disable lifeline
    lifelineFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    
    -- Cross out effect
    local cross = Instance.new("Frame")
    cross.Size = UDim2.new(1.2, 0, 0.05, 0)
    cross.Position = UDim2.new(-0.1, 0, 0.475, 0)
    cross.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    cross.Rotation = 45
    cross.Parent = lifelineFrame
    
    -- Fade animation
    local fadeTween = TweenService:Create(lifelineFrame, TweenInfo.new(0.5), {
        BackgroundTransparency = 0.7
    })
    fadeTween:Play()
    
    -- Special effects based on lifeline type
    if lifelineType == "FiftyFifty" then
        QuizUIManager.AnimateFiftyFifty()
    elseif lifelineType == "PhoneFriend" then
        QuizUIManager.AnimatePhoneFriend()
    elseif lifelineType == "AskAudience" then
        QuizUIManager.AnimateAskAudience()
    end
end

-- 50:50 animation
function QuizUIManager.AnimateFiftyFifty()
    -- This would remove two incorrect answers
    -- Implementation depends on game logic
end

-- Phone a Friend animation
function QuizUIManager.AnimatePhoneFriend()
    -- Create phone ringing effect
    -- Implementation can include visual/audio effects
end

-- Ask the Audience animation  
function QuizUIManager.AnimateAskAudience()
    -- Create audience poll visualization
    -- Implementation can include bar graphs
end

-- Timer management
function QuizUIManager.UpdateTimer(timerFrame, timeLeft)
    local timerText = timerFrame:FindFirstChild("TimerText")
    if not timerText then return end
    
    timerText.Text = tostring(timeLeft)
    
    -- Color based on time remaining
    if timeLeft <= 10 then
        timerText.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        -- Pulse effect for urgency
        if timeLeft <= 5 then
            local pulseTween = TweenService:Create(timerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                Size = UDim2.new(0.17, 0, 0.09, 0)
            })
            pulseTween:Play()
        end
    else
        timerText.TextColor3 = Colors.White
    end
end

-- Create particle effects
function QuizUIManager.CreateConfetti(parent)
    local colors = {
        Colors.Gold,
        Color3.fromRGB(255, 100, 255),
        Color3.fromRGB(100, 255, 255),
        Color3.fromRGB(255, 255, 100)
    }
    
    for i = 1, 50 do
        local confetti = Instance.new("Frame")
        confetti.Size = UDim2.new(0, math.random(5, 15), 0, math.random(5, 15))
        confetti.Position = UDim2.new(math.random(), 0, -0.1, 0)
        confetti.BackgroundColor3 = colors[math.random(1, #colors)]
        confetti.Rotation = math.random(0, 360)
        confetti.Parent = parent
        
        -- Falling animation
        local fallTween = TweenService:Create(confetti, TweenInfo.new(math.random(2, 4), Enum.EasingStyle.Linear), {
            Position = UDim2.new(confetti.Position.X.Scale + math.random(-0.1, 0.1), 0, 1.1, 0),
            Rotation = confetti.Rotation + math.random(180, 720)
        })
        
        fallTween:Play()
        fallTween.Completed:Connect(function()
            confetti:Destroy()
        end)
    end
end

-- Transition effects
function QuizUIManager.TransitionToNextQuestion(ui, callback)
    local mainContainer = ui:FindFirstChild("BG"):FindFirstChild("MainContainer")
    if not mainContainer then return end
    
    -- Fade out current question
    local fadeOut = TweenService:Create(mainContainer, TweenInfo.new(0.5), {
        BackgroundTransparency = 1
    })
    
    -- Slide effect
    local originalPos = mainContainer.Position
    local slideOut = TweenService:Create(mainContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Position = UDim2.new(-1, 0, originalPos.Y.Scale, 0)
    })
    
    fadeOut:Play()
    slideOut:Play()
    
    slideOut.Completed:Connect(function()
        if callback then callback() end
        
        -- Reset position for slide in
        mainContainer.Position = UDim2.new(1, 0, originalPos.Y.Scale, 0)
        
        -- Slide in
        local slideIn = TweenService:Create(mainContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
            Position = originalPos,
            BackgroundTransparency = 0
        })
        
        slideIn:Play()
    end)
end

-- Final answer confirmation
function QuizUIManager.ShowFinalAnswerPrompt(parent, callback)
    local promptFrame = Instance.new("Frame")
    promptFrame.Size = UDim2.new(0.4, 0, 0.2, 0)
    promptFrame.Position = UDim2.new(0.3, 0, 0.4, 0)
    promptFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 60)
    promptFrame.BorderSizePixel = 0
    promptFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = promptFrame
    
    local promptText = Instance.new("TextLabel")
    promptText.Size = UDim2.new(1, 0, 0.6, 0)
    promptText.Position = UDim2.new(0, 0, 0, 0)
    promptText.BackgroundTransparency = 1
    promptText.Text = "Is that your final answer?"
    promptText.TextColor3 = Colors.White
    promptText.TextScaled = true
    promptText.Font = Enum.Font.SourceSansBold
    promptText.Parent = promptFrame
    
    -- Yes/No buttons
    local yesButton = Instance.new("TextButton")
    yesButton.Size = UDim2.new(0.4, 0, 0.3, 0)
    yesButton.Position = UDim2.new(0.05, 0, 0.65, 0)
    yesButton.BackgroundColor3 = Colors.Correct
    yesButton.Text = "YES"
    yesButton.TextColor3 = Colors.White
    yesButton.TextScaled = true
    yesButton.Font = Enum.Font.SourceSansBold
    yesButton.Parent = promptFrame
    
    local noButton = Instance.new("TextButton")
    noButton.Size = UDim2.new(0.4, 0, 0.3, 0)
    noButton.Position = UDim2.new(0.55, 0, 0.65, 0)
    noButton.BackgroundColor3 = Colors.Incorrect
    noButton.Text = "NO"
    noButton.TextColor3 = Colors.White
    noButton.TextScaled = true
    noButton.Font = Enum.Font.SourceSansBold
    noButton.Parent = promptFrame
    
    -- Button corners
    Instance.new("UICorner", yesButton).CornerRadius = UDim.new(0, 8)
    Instance.new("UICorner", noButton).CornerRadius = UDim.new(0, 8)
    
    -- Animate in
    promptFrame.Position = UDim2.new(0.3, 0, -0.3, 0)
    local slideIn = TweenService:Create(promptFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.3, 0, 0.4, 0)
    })
    slideIn:Play()
    
    -- Button connections
    yesButton.MouseButton1Click:Connect(function()
        callback(true)
        promptFrame:Destroy()
    end)
    
    noButton.MouseButton1Click:Connect(function()
        callback(false)
        promptFrame:Destroy()
    end)
end

return QuizUIManager