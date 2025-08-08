-- QuizGui.client.lua
-- Client-side script for the new white & blue quiz UI

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = script.Parent

-- Wait for UI elements
local BG = gui:WaitForChild("BG")
local questionFrame = BG:WaitForChild("QuestionFrame")
local questionText = questionFrame:WaitForChild("QuestionText")

-- Get answer buttons
local answerFrames = {
    BG:WaitForChild("AnswerA"),
    BG:WaitForChild("AnswerB"),
    BG:WaitForChild("AnswerC"),
    BG:WaitForChild("AnswerD")
}

-- Color scheme
local Colors = {
    Correct = Color3.fromRGB(50, 200, 100),
    Incorrect = Color3.fromRGB(250, 100, 100),
    Blue = Color3.fromRGB(100, 150, 250),
    BlueLight = Color3.fromRGB(120, 170, 255),
    BlueDark = Color3.fromRGB(80, 130, 230),
    White = Color3.fromRGB(255, 255, 255)
}

-- RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local showQuestionRemote = remoteEvents:WaitForChild("ShowQuestion")
local submitAnswerRemote = remoteEvents:WaitForChild("SubmitAnswer")
local updateQuizTimerRemote = remoteEvents:WaitForChild("UpdateQuizTimer")
local showQuizResultRemote = remoteEvents:WaitForChild("ShowQuizResult")
local announceWinnerRemote = remoteEvents:WaitForChild("AnnounceWinner")

-- State
local currentQuestion = nil
local hasAnswered = false
local maxTime = 15
local floatingConnections = {}

-- Timer display (create it or find existing)
local timerFrame = BG:FindFirstChild("TimerFrame")
local timerText

if not timerFrame then
    timerFrame = Instance.new("Frame")
    timerFrame.Name = "TimerFrame"
    timerFrame.Size = UDim2.new(0, 200, 0, 80)
    timerFrame.Position = UDim2.new(0.5, -100, 0.05, 0)
    timerFrame.BackgroundColor3 = Colors.White
    timerFrame.BorderSizePixel = 0
    timerFrame.Parent = BG

    local timerCorner = Instance.new("UICorner")
    timerCorner.CornerRadius = UDim.new(0, 40)
    timerCorner.Parent = timerFrame

    local timerBorder = Instance.new("UIStroke")
    timerBorder.Color = Colors.Blue
    timerBorder.Thickness = 3
    timerBorder.Parent = timerFrame

    timerText = Instance.new("TextLabel")
    timerText.Name = "TimerText"
    timerText.Size = UDim2.new(1, 0, 1, 0)
    timerText.BackgroundTransparency = 1
    timerText.Text = "15"
    timerText.TextColor3 = Colors.Blue
    timerText.TextScaled = false
    timerText.TextSize = 36
    timerText.Font = Enum.Font.GothamBold
    timerText.Parent = timerFrame
else
    timerText = timerFrame:FindFirstChild("TimerText")
end

-- Helper functions
local function clearFloatingEffects()
    for _, connection in pairs(floatingConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    floatingConnections = {}
end

local function addFloatingEffect(element, delay, amplitude)
    task.wait(delay)
    local originalY = element.Position.Y.Offset
    local connection = RunService.Heartbeat:Connect(function()
        if element.Parent then
            local time = tick()
            local offset = math.sin(time * 0.5) * amplitude
            element.Position = UDim2.new(
                element.Position.X.Scale,
                element.Position.X.Offset,
                element.Position.Y.Scale,
                originalY + offset
            )
        end
    end)
    table.insert(floatingConnections, connection)
end

local function animateIn()
    -- Clear any existing floating effects
    clearFloatingEffects()
    
    -- Animate question
    questionFrame.Position = UDim2.new(0.5, -400, -0.3, 0)
    local questionTween = TweenService:Create(questionFrame, TweenInfo.new(0.8, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -400, 0.55, 0)
    })
    questionTween:Play()
    
    -- Animate timer
    timerFrame.Position = UDim2.new(0.5, -100, -0.2, 0)
    local timerTween = TweenService:Create(timerFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -100, 0.05, 0)
    })
    timerTween:Play()
    
    -- Animate answer buttons
    task.wait(0.2)
    for i, answerFrame in ipairs(answerFrames) do
        local originalPos = answerFrame.Position
        answerFrame.Position = UDim2.new(answerFrame.Position.X.Scale, answerFrame.Position.X.Offset, 1.2, 0)
        local answerTween = TweenService:Create(answerFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back), {
            Position = originalPos
        })
        task.wait(0.1)
        answerTween:Play()
    end
    
    -- Floating effect removed for cleaner look
    -- (No more up/down movement)
end

local function resetAnswerButtons()
    for _, answerFrame in ipairs(answerFrames) do
        -- Reset colors and transparency
        answerFrame.BackgroundColor3 = Colors.White
        answerFrame.BackgroundTransparency = 0
        
        local border = answerFrame:FindFirstChild("UIStroke")
        if border then
            border.Color = Colors.Blue
            border.Thickness = 2
            border.Transparency = 0
        end
        
        local contentFrame = answerFrame:FindFirstChild("Frame")
        if contentFrame then
            contentFrame.BackgroundTransparency = contentFrame.BackgroundTransparency or 1 -- Keep transparent if it was
            
            local letterCircle = contentFrame:FindFirstChild("LetterCircle")
            if letterCircle then
                letterCircle.BackgroundColor3 = Colors.Blue
                letterCircle.BackgroundTransparency = 0
                local letter = letterCircle:FindFirstChild("Letter")
                if letter then
                    letter.TextColor3 = Colors.White
                    letter.TextTransparency = 0
                end
            end
            
            local answerText = contentFrame:FindFirstChild("AnswerText")
            if answerText then
                answerText.TextColor3 = Colors.Blue
                answerText.TextTransparency = 0
            end
            
            -- Reset all descendants transparency
            for _, descendant in pairs(contentFrame:GetDescendants()) do
                if descendant:IsA("Frame") and descendant.Name ~= "Frame" then
                    descendant.BackgroundTransparency = descendant.Name == "Frame" and 1 or 0
                elseif descendant:IsA("TextLabel") then
                    descendant.TextTransparency = 0
                end
            end
        end
        
        -- Re-enable button
        local button = answerFrame:FindFirstChildOfClass("TextButton")
        if button then
            button.Active = true
        end
    end
end

-- Handle answer button clicks and hover effects
for i, answerFrame in ipairs(answerFrames) do
    local button = answerFrame:FindFirstChildOfClass("TextButton")
    if button then
        -- Store original size for hover effect
        local originalSize = UDim2.new(0, 380, 0, 70)
        local hoverSize = UDim2.new(0, 385, 0, 72)
        
        -- Mouse enter - smooth scale up
        button.MouseEnter:Connect(function()
            if not hasAnswered then
                TweenService:Create(answerFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = hoverSize
                }):Play()
                
                local border = answerFrame:FindFirstChild("UIStroke")
                if border then
                    TweenService:Create(border, TweenInfo.new(0.2), {
                        Thickness = 3
                    }):Play()
                end
            end
        end)
        
        -- Mouse leave - smooth scale down
        button.MouseLeave:Connect(function()
            if not hasAnswered then
                TweenService:Create(answerFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = originalSize
                }):Play()
                
                local border = answerFrame:FindFirstChild("UIStroke")
                if border then
                    TweenService:Create(border, TweenInfo.new(0.2), {
                        Thickness = 2
                    }):Play()
                end
            end
        end)
        
        -- Click handler
        button.MouseButton1Click:Connect(function()
            if not hasAnswered and currentQuestion then
                SelectAnswer(i, answerFrame)
            end
        end)
    end
end

function SelectAnswer(index, answerFrame)
    if hasAnswered then return end
    hasAnswered = true
    
    -- Disable all buttons
    for _, frame in ipairs(answerFrames) do
        local btn = frame:FindFirstChildOfClass("TextButton")
        if btn then btn.Active = false end
    end
    
    -- Determine correct answer (assuming it's in the question data)
    local correctAnswerIndex = currentQuestion.correct
    local isCorrect = (index == correctAnswerIndex)
    
    -- Pulse animation first
    local originalSize = answerFrame.Size
    local border = answerFrame:FindFirstChild("UIStroke")
    
    -- Initial selection feedback (still blue during pulse)
    answerFrame.BackgroundColor3 = Colors.BlueDark
    if border then
        border.Thickness = 4
        border.Color = Colors.White
    end
    
    -- Pulse effect
    for i = 1, 3 do
        TweenService:Create(answerFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 390, 0, 75)
        }):Play()
        task.wait(0.15)
        TweenService:Create(answerFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            Size = originalSize
        }):Play()
        task.wait(0.15)
    end
    
    -- Now show the results colors
    -- Selected answer turns red if wrong
    if not isCorrect then
        TweenService:Create(answerFrame, TweenInfo.new(0.3), {
            BackgroundColor3 = Colors.Incorrect
        }):Play()
        
        local contentFrame = answerFrame:FindFirstChild("Frame")
        if contentFrame then
            local letterCircle = contentFrame:FindFirstChild("LetterCircle")
            if letterCircle then
                TweenService:Create(letterCircle, TweenInfo.new(0.3), {
                    BackgroundColor3 = Colors.White
                }):Play()
                local letter = letterCircle:FindFirstChild("Letter")
                if letter then
                    TweenService:Create(letter, TweenInfo.new(0.3), {
                        TextColor3 = Colors.Incorrect
                    }):Play()
                end
            end
            
            local answerText = contentFrame:FindFirstChild("AnswerText")
            if answerText then
                TweenService:Create(answerText, TweenInfo.new(0.3), {
                    TextColor3 = Colors.White
                }):Play()
            end
        end
    end
    
    -- Show correct answer in green and grey out others
    for i, frame in ipairs(answerFrames) do
        if i == correctAnswerIndex then
            -- Correct answer - green
            TweenService:Create(frame, TweenInfo.new(0.3), {
                BackgroundColor3 = Colors.Correct,
                BackgroundTransparency = 0
            }):Play()
            
            local border = frame:FindFirstChild("UIStroke")
            if border then
                TweenService:Create(border, TweenInfo.new(0.3), {
                    Color = Colors.White,
                    Thickness = 3
                }):Play()
            end
            
            local contentFrame = frame:FindFirstChild("Frame")
            if contentFrame then
                local letterCircle = contentFrame:FindFirstChild("LetterCircle")
                if letterCircle then
                    TweenService:Create(letterCircle, TweenInfo.new(0.3), {
                        BackgroundColor3 = Colors.White
                    }):Play()
                    local letter = letterCircle:FindFirstChild("Letter")
                    if letter then
                        TweenService:Create(letter, TweenInfo.new(0.3), {
                            TextColor3 = Colors.Correct
                        }):Play()
                    end
                end
                
                local answerText = contentFrame:FindFirstChild("AnswerText")
                if answerText then
                    TweenService:Create(answerText, TweenInfo.new(0.3), {
                        TextColor3 = Colors.White
                    }):Play()
                end
            end
            
        elseif frame ~= answerFrame then
            -- Other answers - grey
            TweenService:Create(frame, TweenInfo.new(0.3), {
                BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                BackgroundTransparency = 0.3
            }):Play()
            
            local border = frame:FindFirstChild("UIStroke")
            if border then
                TweenService:Create(border, TweenInfo.new(0.3), {
                    Color = Color3.fromRGB(150, 150, 150),
                    Thickness = 2
                }):Play()
            end
            
            local contentFrame = frame:FindFirstChild("Frame")
            if contentFrame then
                local letterCircle = contentFrame:FindFirstChild("LetterCircle")
                if letterCircle then
                    TweenService:Create(letterCircle, TweenInfo.new(0.3), {
                        BackgroundColor3 = Color3.fromRGB(150, 150, 150)
                    }):Play()
                end
                
                local answerText = contentFrame:FindFirstChild("AnswerText")
                if answerText then
                    TweenService:Create(answerText, TweenInfo.new(0.3), {
                        TextColor3 = Color3.fromRGB(150, 150, 150)
                    }):Play()
                end
            end
        end
    end
    
    -- Submit answer
    submitAnswerRemote:FireServer(index)
end

function ShowQuestion(question, totalTime)
    currentQuestion = question
    hasAnswered = false
    maxTime = totalTime
    
    -- Reset UI
    gui.Enabled = true
    BG.Visible = true
    
    -- Reset all elements to their original state
    -- Reset question frame
    questionFrame.Visible = true
    questionFrame.BackgroundTransparency = 0
    questionFrame.Position = UDim2.new(0.5, -400, 0.55, 0) -- Original position
    questionText.TextTransparency = 0
    
    -- Reset timer frame
    if timerFrame then
        timerFrame.Visible = true
        timerFrame.BackgroundTransparency = 0
        timerFrame.Position = UDim2.new(0.5, -100, 0.05, 0) -- Original position
        timerFrame.Size = UDim2.new(0, 200, 0, 80) -- Original size
        timerText.TextTransparency = 0
    end
    
    -- Reset answer frames to original positions
    local originalPositions = {
        UDim2.new(0.5, -390, 0.72, 0),   -- A
        UDim2.new(0.5, 10, 0.72, 0),     -- B
        UDim2.new(0.5, -390, 0.72, 85),  -- C
        UDim2.new(0.5, 10, 0.72, 85)     -- D
    }
    
    for i, answerFrame in ipairs(answerFrames) do
        answerFrame.Visible = true
        answerFrame.Position = originalPositions[i]
        answerFrame.Size = UDim2.new(0, 380, 0, 70) -- Original size
        answerFrame.BackgroundTransparency = 0
    end
    
    -- Now reset button states
    resetAnswerButtons()
    
    -- Clean up any leftover frames
    for _, child in pairs(BG:GetChildren()) do
        if child.Name == "WinnerFrame" or child.Name == "ResultFrame" then
            child:Destroy()
        end
    end
    
    -- Update question text
    questionText.Text = question.question
    
    -- Update answer options
    local letters = {"A", "B", "C", "D"}
    for i = 1, 4 do
        local answerFrame = answerFrames[i]
        if answerFrame and question.options[i] then
            local contentFrame = answerFrame:FindFirstChild("Frame")
            if contentFrame then
                local answerText = contentFrame:FindFirstChild("AnswerText")
                if answerText then
                    answerText.Text = question.options[i]
                end
            end
        end
    end
    
    -- Reset timer
    timerText.Text = tostring(maxTime)
    timerText.TextColor3 = Colors.Blue
    
    -- Animate in
    animateIn()
end

function UpdateTimer(timeLeft)
    timerText.Text = tostring(math.ceil(timeLeft))
    
    -- Change color based on time
    local percentage = timeLeft / maxTime
    if percentage > 0.5 then
        timerText.TextColor3 = Colors.Blue
    elseif percentage > 0.25 then
        timerText.TextColor3 = Color3.fromRGB(241, 196, 15) -- Yellow
    else
        timerText.TextColor3 = Colors.Incorrect -- Red
        -- Smooth pulse effect when low on time (without wait)
        if math.ceil(timeLeft) <= 3 and math.ceil(timeLeft) == timeLeft then
            -- Only pulse on whole seconds
            TweenService:Create(timerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 210, 0, 84)
            }):Play()
            
            task.delay(0.3, function()
                TweenService:Create(timerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Size = UDim2.new(0, 200, 0, 80)
                }):Play()
            end)
        end
    end
end

function ShowResults(results, correctAnswer)
    -- Show correct/incorrect answers
    for i, answerFrame in ipairs(answerFrames) do
        local isCorrect = (i == correctAnswer)
        local isPlayerAnswer = hasAnswered and results[player] and results[player].answer == i
        
        if isCorrect then
            -- Correct answer - always green
            answerFrame.BackgroundColor3 = Colors.Correct
            answerFrame.BackgroundTransparency = 0
            
            -- Update border
            local border = answerFrame:FindFirstChild("UIStroke")
            if border then
                border.Color = Colors.White
                border.Thickness = 3
            end
            
            -- Update text colors for correct answer
            local contentFrame = answerFrame:FindFirstChild("Frame")
            if contentFrame then
                local letterCircle = contentFrame:FindFirstChild("LetterCircle")
                if letterCircle then
                    letterCircle.BackgroundColor3 = Colors.White
                    local letter = letterCircle:FindFirstChild("Letter")
                    if letter then
                        letter.TextColor3 = Colors.Correct
                    end
                end
                
                local answerText = contentFrame:FindFirstChild("AnswerText")
                if answerText then
                    answerText.TextColor3 = Colors.White
                end
            end
            
            -- Bounce effect for correct answer
            TweenService:Create(answerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), {
                Size = answerFrame.Size + UDim2.new(0, 10, 0, 5)
            }):Play()
            
        elseif isPlayerAnswer and not results[player].correct then
            -- Player's wrong answer - red
            answerFrame.BackgroundColor3 = Colors.Incorrect
            answerFrame.BackgroundTransparency = 0
            
            -- Update border
            local border = answerFrame:FindFirstChild("UIStroke")
            if border then
                border.Color = Colors.White
                border.Thickness = 3
            end
            
            -- Update text colors for wrong answer
            local contentFrame = answerFrame:FindFirstChild("Frame")
            if contentFrame then
                local letterCircle = contentFrame:FindFirstChild("LetterCircle")
                if letterCircle then
                    letterCircle.BackgroundColor3 = Colors.White
                    local letter = letterCircle:FindFirstChild("Letter")
                    if letter then
                        letter.TextColor3 = Colors.Incorrect
                    end
                end
                
                local answerText = contentFrame:FindFirstChild("AnswerText")
                if answerText then
                    answerText.TextColor3 = Colors.White
                end
            end
            
            -- Shake effect for wrong answer
            local originalPos = answerFrame.Position
            for j = 1, 3 do
                answerFrame.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + 5, originalPos.Y.Scale, originalPos.Y.Offset)
                task.wait(0.05)
                answerFrame.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset - 5, originalPos.Y.Scale, originalPos.Y.Offset)
                task.wait(0.05)
            end
            answerFrame.Position = originalPos
            
        else
            -- Other answers - stay grey/faded
            answerFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200) -- Light grey
            answerFrame.BackgroundTransparency = 0.3
            
            -- Update border to grey
            local border = answerFrame:FindFirstChild("UIStroke")
            if border then
                border.Color = Color3.fromRGB(150, 150, 150)
                border.Thickness = 2
            end
            
            -- Update text colors to grey
            local contentFrame = answerFrame:FindFirstChild("Frame")
            if contentFrame then
                local letterCircle = contentFrame:FindFirstChild("LetterCircle")
                if letterCircle then
                    letterCircle.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
                    local letter = letterCircle:FindFirstChild("Letter")
                    if letter then
                        letter.TextColor3 = Colors.White
                    end
                end
                
                local answerText = contentFrame:FindFirstChild("AnswerText")
                if answerText then
                    answerText.TextColor3 = Color3.fromRGB(150, 150, 150)
                end
            end
        end
    end
    
    -- Wait before hiding
    task.wait(3)
    
    -- Fade out all elements
    clearFloatingEffects()
    for _, element in pairs(BG:GetChildren()) do
        if element:IsA("Frame") then
            TweenService:Create(element, TweenInfo.new(0.5), {
                Position = element.Position + UDim2.new(0, 0, 0.5, 0),
                BackgroundTransparency = 1
            }):Play()
        end
    end
    
    task.wait(0.5)
    gui.Enabled = false
end

function AnnounceWinner(winner)
    clearFloatingEffects()
    gui.Enabled = true
    BG.Visible = true
    
    -- Hide all elements except BG
    for _, child in pairs(BG:GetChildren()) do
        if child ~= BG then
            child.Visible = false
        end
    end
    
    -- Create winner announcement
    local winnerFrame = Instance.new("Frame")
    winnerFrame.Name = "WinnerFrame"
    winnerFrame.Size = UDim2.new(0, 600, 0, 350)
    winnerFrame.Position = UDim2.new(0.5, -300, 0.5, -175)
    winnerFrame.BackgroundColor3 = Colors.White
    winnerFrame.BorderSizePixel = 0
    winnerFrame.Parent = BG
    
    local winnerCorner = Instance.new("UICorner")
    winnerCorner.CornerRadius = UDim.new(0, 20)
    winnerCorner.Parent = winnerFrame
    
    local winnerBorder = Instance.new("UIStroke")
    winnerBorder.Color = Colors.Blue
    winnerBorder.Thickness = 4
    winnerBorder.Parent = winnerFrame
    
    local winnerText = Instance.new("TextLabel")
    winnerText.Size = UDim2.new(1, 0, 0.4, 0)
    winnerText.Position = UDim2.new(0, 0, 0.1, 0)
    winnerText.BackgroundTransparency = 1
    winnerText.Text = winner == player and "🎉 YOU WIN! 🎉" or (winner.Name .. " WINS!")
    winnerText.TextColor3 = Colors.Blue
    winnerText.TextScaled = false
    winnerText.TextSize = 48
    winnerText.Font = Enum.Font.GothamBold
    winnerText.Parent = winnerFrame
    
    local congratsText = Instance.new("TextLabel")
    congratsText.Size = UDim2.new(1, 0, 0.3, 0)
    congratsText.Position = UDim2.new(0, 0, 0.5, 0)
    congratsText.BackgroundTransparency = 1
    congratsText.Text = "Congratulations on completing\nStep to Victory!"
    congratsText.TextColor3 = Colors.Blue
    congratsText.TextScaled = false
    congratsText.TextSize = 24
    congratsText.Font = Enum.Font.Gotham
    congratsText.Parent = winnerFrame
    
    -- Animate in
    winnerFrame.Size = UDim2.new(0, 0, 0, 0)
    winnerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    TweenService:Create(winnerFrame, TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 600, 0, 350),
        Position = UDim2.new(0.5, -300, 0.5, -175)
    }):Play()
    
    -- Confetti effect
    task.spawn(function()
        for i = 1, 30 do
            local particle = Instance.new("Frame")
            particle.Size = UDim2.new(0, 12, 0, 12)
            particle.Position = UDim2.new(0.5, math.random(-300, 300), 1, 0)
            particle.BackgroundColor3 = math.random() > 0.5 and Colors.Blue or Colors.White
            particle.BorderSizePixel = 0
            particle.Parent = BG
            
            local particleCorner = Instance.new("UICorner")
            particleCorner.CornerRadius = UDim.new(0.5, 0)
            particleCorner.Parent = particle
            
            if particle.BackgroundColor3 == Colors.White then
                local border = Instance.new("UIStroke")
                border.Color = Colors.Blue
                border.Thickness = 1
                border.Parent = particle
            end
            
            -- Animate upward
            local moveTween = TweenService:Create(particle, TweenInfo.new(3, Enum.EasingStyle.Linear), {
                Position = UDim2.new(particle.Position.X.Scale, particle.Position.X.Offset + math.random(-50, 50), -0.2, 0),
                Rotation = math.random(180, 720)
            })
            
            moveTween:Play()
            moveTween.Completed:Connect(function()
                particle:Destroy()
            end)
            
            task.wait(0.05)
        end
    end)
    
    -- Hide after delay
    task.wait(5)
    TweenService:Create(winnerFrame, TweenInfo.new(0.5), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    
    task.wait(0.5)
    gui.Enabled = false
end

-- Connect RemoteEvents
showQuestionRemote.OnClientEvent:Connect(ShowQuestion)
updateQuizTimerRemote.OnClientEvent:Connect(UpdateTimer)
showQuizResultRemote.OnClientEvent:Connect(ShowResults)
announceWinnerRemote.OnClientEvent:Connect(AnnounceWinner)

-- Initially hide
gui.Enabled = false
print("[QuizUI] Client script loaded")