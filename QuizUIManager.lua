-- Minimal Quiz UI Manager Module
-- Simplified helper functions for the clean quiz UI

local TweenService = game:GetService("TweenService")

local QuizUIManager = {}

-- Color schemes
local Colors = {
    Correct = Color3.fromRGB(100, 200, 100),    -- Green
    Incorrect = Color3.fromRGB(250, 100, 100),  -- Red
    Selected = Color3.fromRGB(100, 150, 250),   -- Blue
    Default = Color3.fromRGB(255, 255, 255),    -- White
    Hover = Color3.fromRGB(100, 150, 250),      -- Blue
    Text = Color3.fromRGB(60, 60, 70),          -- Dark gray
    TextLight = Color3.fromRGB(255, 255, 255)   -- White
}

-- Update question display
function QuizUIManager.SetQuestion(questionFrame, questionText)
    local textLabel = questionFrame:FindFirstChild("QuestionText")
    if not textLabel then return end
    
    -- Fade out animation
    local fadeOut = TweenService:Create(textLabel, TweenInfo.new(0.2), {
        TextTransparency = 1
    })
    
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        textLabel.Text = questionText
        
        -- Fade in animation
        local fadeIn = TweenService:Create(textLabel, TweenInfo.new(0.2), {
            TextTransparency = 0
        })
        fadeIn:Play()
    end)
end

-- Update answer options
function QuizUIManager.SetAnswers(answersContainer, answers)
    local letters = {"A", "B", "C", "D"}
    
    for i, answer in ipairs(answers) do
        if i > 4 then break end
        
        local answerFrame = answersContainer:FindFirstChild("Answer" .. letters[i])
        if answerFrame then
            local contentFrame = answerFrame:FindFirstChild("Frame")
            if contentFrame then
                local answerText = contentFrame:FindFirstChild("AnswerText")
                if answerText then
                    -- Smooth text transition
                    local fadeTween = TweenService:Create(answerText, TweenInfo.new(0.15), {
                        TextTransparency = 1
                    })
                    
                    fadeTween:Play()
                    fadeTween.Completed:Connect(function()
                        answerText.Text = answer
                        TweenService:Create(answerText, TweenInfo.new(0.15), {
                            TextTransparency = 0
                        }):Play()
                    end)
                end
            end
        end
    end
end

-- Highlight selected answer
function QuizUIManager.SelectAnswer(answerFrame, callback)
    -- Pulse animation for selection
    local originalSize = answerFrame.Size
    
    -- First pulse
    local pulse1 = TweenService:Create(answerFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
        Size = UDim2.new(originalSize.X.Scale * 0.98, 0, 0, 48),
        BackgroundColor3 = Colors.Selected
    })
    
    local pulse2 = TweenService:Create(answerFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
        Size = originalSize,
        BackgroundColor3 = Colors.Hover
    })
    
    -- Animate text colors
    local contentFrame = answerFrame:FindFirstChild("Frame")
    if contentFrame then
        local letterLabel = contentFrame:FindFirstChild("Letter")
        local answerText = contentFrame:FindFirstChild("AnswerText")
        
        if letterLabel and answerText then
            TweenService:Create(letterLabel, TweenInfo.new(0.15), {
                TextColor3 = Colors.TextLight
            }):Play()
            
            TweenService:Create(answerText, TweenInfo.new(0.15), {
                TextColor3 = Colors.TextLight
            }):Play()
        end
    end
    
    -- Play pulse animation
    pulse1:Play()
    wait(0.15)
    pulse2:Play()
    wait(0.15)
    pulse1:Play()
    wait(0.15)
    pulse2:Play()
    
    if callback then
        wait(0.3)
        callback()
    end
end

-- Show correct/incorrect answer
function QuizUIManager.RevealAnswer(answerFrame, isCorrect)
    local targetColor = isCorrect and Colors.Correct or Colors.Incorrect
    local border = answerFrame:FindFirstChild("UIStroke")
    
    -- Update border color
    if border then
        TweenService:Create(border, TweenInfo.new(0.3), {
            Color = targetColor,
            Thickness = 3
        }):Play()
    end
    
    -- Animate background
    local bgTween = TweenService:Create(answerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), {
        BackgroundColor3 = targetColor
    })
    
    bgTween:Play()
    
    -- Update text colors to white for visibility
    local contentFrame = answerFrame:FindFirstChild("Frame")
    if contentFrame then
        local letterLabel = contentFrame:FindFirstChild("Letter")
        local answerText = contentFrame:FindFirstChild("AnswerText")
        
        if letterLabel and answerText then
            TweenService:Create(letterLabel, TweenInfo.new(0.2), {
                TextColor3 = Colors.TextLight
            }):Play()
            
            TweenService:Create(answerText, TweenInfo.new(0.2), {
                TextColor3 = Colors.TextLight
            }):Play()
        end
    end
    
    -- Add a subtle shake for incorrect answers
    if not isCorrect then
        local originalPos = answerFrame.Position
        for i = 1, 3 do
            answerFrame.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + 5, originalPos.Y.Scale, originalPos.Y.Offset)
            wait(0.05)
            answerFrame.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset - 5, originalPos.Y.Scale, originalPos.Y.Offset)
            wait(0.05)
        end
        answerFrame.Position = originalPos
    end
end

-- Reset answer buttons to default state
function QuizUIManager.ResetAnswers(answersContainer)
    local letters = {"A", "B", "C", "D"}
    
    for i, letter in ipairs(letters) do
        local answerFrame = answersContainer:FindFirstChild("Answer" .. letter)
        if answerFrame then
            -- Reset background color
            TweenService:Create(answerFrame, TweenInfo.new(0.3), {
                BackgroundColor3 = Colors.Default
            }):Play()
            
            -- Reset border
            local border = answerFrame:FindFirstChild("UIStroke")
            if border then
                TweenService:Create(border, TweenInfo.new(0.3), {
                    Color = Color3.fromRGB(100, 150, 250),
                    Thickness = 2
                }):Play()
            end
            
            -- Reset text colors
            local contentFrame = answerFrame:FindFirstChild("Frame")
            if contentFrame then
                local letterLabel = contentFrame:FindFirstChild("Letter")
                local answerText = contentFrame:FindFirstChild("AnswerText")
                
                if letterLabel then
                    TweenService:Create(letterLabel, TweenInfo.new(0.3), {
                        TextColor3 = Color3.fromRGB(100, 150, 250)
                    }):Play()
                end
                
                if answerText then
                    TweenService:Create(answerText, TweenInfo.new(0.3), {
                        TextColor3 = Colors.Text
                    }):Play()
                end
            end
            
            -- Make sure it's visible
            answerFrame.Visible = true
        end
    end
end

-- Transition to next question
function QuizUIManager.TransitionToNextQuestion(bg, callback)
    -- Slide out animation
    local originalPos = bg.Position
    local slideOut = TweenService:Create(bg, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -300, 0.5, -600)
    })
    
    slideOut:Play()
    slideOut.Completed:Connect(function()
        if callback then callback() end
        
        -- Reset from opposite side
        bg.Position = UDim2.new(0.5, -300, 0.5, 100)
        
        -- Slide back in
        local slideIn = TweenService:Create(bg, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
            Position = originalPos
        })
        slideIn:Play()
    end)
end

-- Show result screen
function QuizUIManager.ShowResult(bg, isWinner, score)
    -- Create result overlay
    local resultFrame = Instance.new("Frame")
    resultFrame.Name = "ResultFrame"
    resultFrame.Size = UDim2.new(0.8, 0, 0.6, 0)
    resultFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
    resultFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    resultFrame.BorderSizePixel = 0
    resultFrame.Parent = bg
    
    local resultCorner = Instance.new("UICorner")
    resultCorner.CornerRadius = UDim.new(0, 12)
    resultCorner.Parent = resultFrame
    
    local resultBorder = Instance.new("UIStroke")
    resultBorder.Color = isWinner and Colors.Correct or Colors.Incorrect
    resultBorder.Thickness = 3
    resultBorder.Parent = resultFrame
    
    -- Result text
    local resultText = Instance.new("TextLabel")
    resultText.Size = UDim2.new(1, 0, 0.4, 0)
    resultText.Position = UDim2.new(0, 0, 0.1, 0)
    resultText.BackgroundTransparency = 1
    resultText.Text = isWinner and "CONGRATULATIONS!" or "GAME OVER"
    resultText.TextColor3 = isWinner and Colors.Correct or Colors.Incorrect
    resultText.TextScaled = false
    resultText.TextSize = 36
    resultText.Font = Enum.Font.GothamBold
    resultText.Parent = resultFrame
    
    -- Score text
    local scoreText = Instance.new("TextLabel")
    scoreText.Size = UDim2.new(1, 0, 0.3, 0)
    scoreText.Position = UDim2.new(0, 0, 0.5, 0)
    scoreText.BackgroundTransparency = 1
    scoreText.Text = "Score: " .. tostring(score) .. " / 15"
    scoreText.TextColor3 = Colors.Text
    scoreText.TextScaled = false
    scoreText.TextSize = 24
    scoreText.Font = Enum.Font.Gotham
    scoreText.Parent = resultFrame
    
    -- Animate in
    resultFrame.Size = UDim2.new(0, 0, 0, 0)
    resultFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local animIn = TweenService:Create(resultFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Size = UDim2.new(0.8, 0, 0.6, 0),
        Position = UDim2.new(0.1, 0, 0.2, 0)
    })
    animIn:Play()
end

-- Simple celebration effect
function QuizUIManager.Celebrate(bg)
    -- Create simple particle effects
    for i = 1, 20 do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, 10, 0, 10)
        particle.Position = UDim2.new(0.5, math.random(-200, 200), 1, 0)
        particle.BackgroundColor3 = Color3.fromRGB(
            math.random(100, 255),
            math.random(100, 255),
            math.random(100, 255)
        )
        particle.BorderSizePixel = 0
        particle.Parent = bg
        
        local particleCorner = Instance.new("UICorner")
        particleCorner.CornerRadius = UDim.new(0.5, 0)
        particleCorner.Parent = particle
        
        -- Animate upward
        local moveTween = TweenService:Create(particle, TweenInfo.new(2, Enum.EasingStyle.Linear), {
            Position = UDim2.new(particle.Position.X.Scale, particle.Position.X.Offset, -0.1, 0)
        })
        
        moveTween:Play()
        moveTween.Completed:Connect(function()
            particle:Destroy()
        end)
        
        wait(0.1)
    end
end

return QuizUIManager