-- Quiz UI Manager Module - White & Blue Theme
-- Helper functions for the Who Wants to Be a Millionaire UI

local TweenService = game:GetService("TweenService")

local QuizUIManager = {}

-- Color schemes - Only White and Blue
local Colors = {
    Correct = Color3.fromRGB(50, 200, 100),     -- Green for correct
    Incorrect = Color3.fromRGB(250, 100, 100),  -- Red for incorrect
    Blue = Color3.fromRGB(100, 150, 250),       -- Main blue
    BlueLight = Color3.fromRGB(120, 170, 255),  -- Lighter blue
    BlueDark = Color3.fromRGB(80, 130, 230),    -- Darker blue
    White = Color3.fromRGB(255, 255, 255)       -- Pure white
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
function QuizUIManager.SetAnswers(bg, answers)
    local letters = {"A", "B", "C", "D"}
    
    for i, answer in ipairs(answers) do
        if i > 4 then break end
        
        local answerFrame = bg:FindFirstChild("Answer" .. letters[i])
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
    local border = answerFrame:FindFirstChild("UIStroke")
    
    -- Pulse effect
    local pulse1 = TweenService:Create(answerFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 330, 0, 58)
    })
    
    local pulse2 = TweenService:Create(answerFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
        Size = originalSize
    })
    
    -- Border pulse
    if border then
        TweenService:Create(border, TweenInfo.new(0.15), {
            Thickness = 4,
            Color = Colors.BlueDark
        }):Play()
    end
    
    -- Play pulse animation 3 times
    for i = 1, 3 do
        pulse1:Play()
        wait(0.15)
        pulse2:Play()
        wait(0.15)
    end
    
    if callback then
        wait(0.3)
        callback()
    end
end

-- Show correct/incorrect answer
function QuizUIManager.RevealAnswer(answerFrame, isCorrect)
    local targetColor = isCorrect and Colors.Correct or Colors.Incorrect
    local border = answerFrame:FindFirstChild("UIStroke")
    local contentFrame = answerFrame:FindFirstChild("Frame")
    local letterCircle = contentFrame and contentFrame:FindFirstChild("LetterCircle")
    
    -- Update colors
    TweenService:Create(answerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), {
        BackgroundColor3 = targetColor
    }):Play()
    
    if border then
        TweenService:Create(border, TweenInfo.new(0.3), {
            Color = Colors.White,
            Thickness = 3
        }):Play()
    end
    
    if letterCircle then
        TweenService:Create(letterCircle, TweenInfo.new(0.3), {
            BackgroundColor3 = Colors.White
        }):Play()
        
        local letterLabel = letterCircle:FindFirstChild("Letter")
        if letterLabel then
            TweenService:Create(letterLabel, TweenInfo.new(0.3), {
                TextColor3 = targetColor
            }):Play()
        end
    end
    
    -- Update answer text to white
    if contentFrame then
        local answerText = contentFrame:FindFirstChild("AnswerText")
        if answerText then
            TweenService:Create(answerText, TweenInfo.new(0.3), {
                TextColor3 = Colors.White
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
function QuizUIManager.ResetAnswers(bg)
    local letters = {"A", "B", "C", "D"}
    
    for i, letter in ipairs(letters) do
        local answerFrame = bg:FindFirstChild("Answer" .. letter)
        if answerFrame then
            -- Reset background color
            TweenService:Create(answerFrame, TweenInfo.new(0.3), {
                BackgroundColor3 = Colors.White
            }):Play()
            
            -- Reset border
            local border = answerFrame:FindFirstChild("UIStroke")
            if border then
                TweenService:Create(border, TweenInfo.new(0.3), {
                    Color = Colors.Blue,
                    Thickness = 2
                }):Play()
            end
            
            -- Reset letter circle and text colors
            local contentFrame = answerFrame:FindFirstChild("Frame")
            if contentFrame then
                local letterCircle = contentFrame:FindFirstChild("LetterCircle")
                if letterCircle then
                    TweenService:Create(letterCircle, TweenInfo.new(0.3), {
                        BackgroundColor3 = Colors.Blue
                    }):Play()
                    
                    local letterLabel = letterCircle:FindFirstChild("Letter")
                    if letterLabel then
                        TweenService:Create(letterLabel, TweenInfo.new(0.3), {
                            TextColor3 = Colors.White
                        }):Play()
                    end
                end
                
                local answerText = contentFrame:FindFirstChild("AnswerText")
                if answerText then
                    TweenService:Create(answerText, TweenInfo.new(0.3), {
                        TextColor3 = Colors.Blue
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
    -- Get all UI elements
    local elements = {}
    for _, child in pairs(bg:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            table.insert(elements, child)
        end
    end
    
    -- Fade out
    for _, element in ipairs(elements) do
        TweenService:Create(element, TweenInfo.new(0.3), {
            BackgroundTransparency = 1
        }):Play()
        
        -- Also fade text elements
        for _, descendant in pairs(element:GetDescendants()) do
            if descendant:IsA("TextLabel") then
                TweenService:Create(descendant, TweenInfo.new(0.3), {
                    TextTransparency = 1
                }):Play()
            end
        end
    end
    
    wait(0.4)
    if callback then callback() end
    
    -- Fade back in
    for _, element in ipairs(elements) do
        TweenService:Create(element, TweenInfo.new(0.3), {
            BackgroundTransparency = element.Name == "BG" and 1 or 0
        }):Play()
        
        for _, descendant in pairs(element:GetDescendants()) do
            if descendant:IsA("TextLabel") then
                TweenService:Create(descendant, TweenInfo.new(0.3), {
                    TextTransparency = 0
                }):Play()
            end
        end
    end
end

-- Show result screen
function QuizUIManager.ShowResult(bg, isWinner, score)
    -- Create result overlay
    local resultFrame = Instance.new("Frame")
    resultFrame.Name = "ResultFrame"
    resultFrame.Size = UDim2.new(0, 500, 0, 300)
    resultFrame.Position = UDim2.new(0.5, -250, 0.5, -150)
    resultFrame.BackgroundColor3 = Colors.White
    resultFrame.BorderSizePixel = 0
    resultFrame.Parent = bg
    
    local resultCorner = Instance.new("UICorner")
    resultCorner.CornerRadius = UDim.new(0, 20)
    resultCorner.Parent = resultFrame
    
    local resultBorder = Instance.new("UIStroke")
    resultBorder.Color = Colors.Blue
    resultBorder.Thickness = 4
    resultBorder.Parent = resultFrame
    
    -- Result text
    local resultText = Instance.new("TextLabel")
    resultText.Size = UDim2.new(1, 0, 0.4, 0)
    resultText.Position = UDim2.new(0, 0, 0.1, 0)
    resultText.BackgroundTransparency = 1
    resultText.Text = isWinner and "CONGRATULATIONS!" or "QUIZ COMPLETE!"
    resultText.TextColor3 = Colors.Blue
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
    scoreText.TextColor3 = Colors.Blue
    scoreText.TextScaled = false
    scoreText.TextSize = 24
    scoreText.Font = Enum.Font.Gotham
    scoreText.Parent = resultFrame
    
    -- Animate in
    resultFrame.Size = UDim2.new(0, 0, 0, 0)
    resultFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local animIn = TweenService:Create(resultFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 500, 0, 300),
        Position = UDim2.new(0.5, -250, 0.5, -150)
    })
    animIn:Play()
end

-- Celebration effect
function QuizUIManager.Celebrate(bg)
    -- Create blue and white confetti
    for i = 1, 30 do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, 12, 0, 12)
        particle.Position = UDim2.new(0.5, math.random(-300, 300), 1, 0)
        particle.BackgroundColor3 = math.random() > 0.5 and Colors.Blue or Colors.White
        particle.BorderSizePixel = 0
        particle.Parent = bg
        
        local particleCorner = Instance.new("UICorner")
        particleCorner.CornerRadius = UDim.new(0.5, 0)
        particleCorner.Parent = particle
        
        if particle.BackgroundColor3 == Colors.White then
            local border = Instance.new("UIStroke")
            border.Color = Colors.Blue
            border.Thickness = 1
            border.Parent = particle
        end
        
        -- Animate upward with rotation
        local moveTween = TweenService:Create(particle, TweenInfo.new(3, Enum.EasingStyle.Linear), {
            Position = UDim2.new(particle.Position.X.Scale, particle.Position.X.Offset + math.random(-50, 50), -0.2, 0),
            Rotation = math.random(180, 720)
        })
        
        moveTween:Play()
        moveTween.Completed:Connect(function()
            particle:Destroy()
        end)
        
        wait(0.05)
    end
end

return QuizUIManager