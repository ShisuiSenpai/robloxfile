-- QuizGui.client.lua
-- Client-side quiz UI handler with modern design

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local gui = script.Parent

-- UI Elements
local mainFrame = gui:WaitForChild("MainFrame")
local questionFrame = mainFrame:WaitForChild("QuestionFrame")
local questionLabel = questionFrame:WaitForChild("QuestionLabel")
local categoryLabel = questionFrame:WaitForChild("CategoryLabel")
local timerFrame = mainFrame:WaitForChild("TimerFrame")
local timerBar = timerFrame:WaitForChild("TimerBar")
local timerLabel = timerFrame:WaitForChild("TimerLabel")
local answersFrame = mainFrame:WaitForChild("AnswersFrame")
local resultFrame = gui:WaitForChild("ResultFrame")
local resultLabel = resultFrame:WaitForChild("ResultLabel")
local correctAnswerLabel = resultFrame:WaitForChild("CorrectAnswerLabel")
local winnerFrame = gui:WaitForChild("WinnerFrame")
local winnerLabel = winnerFrame:WaitForChild("WinnerLabel")

-- RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local showQuestionRemote = remoteEvents:WaitForChild("ShowQuestion")
local submitAnswerRemote = remoteEvents:WaitForChild("SubmitAnswer")
local updateQuizTimerRemote = remoteEvents:WaitForChild("UpdateQuizTimer")
local showQuizResultRemote = remoteEvents:WaitForChild("ShowQuizResult")
local announceWinnerRemote = remoteEvents:WaitForChild("AnnounceWinner")

-- Animation tweens
local fadeInInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local fadeOutInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local scaleInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- State
local currentQuestion = nil
local hasAnswered = false
local maxTime = 15

-- Answer button references
local answerButtons = {}
for i = 1, 4 do
    local button = answersFrame:FindFirstChild("Answer" .. i)
    if button then
        answerButtons[i] = button
        
        -- Add hover effect
        button.MouseEnter:Connect(function()
            if not hasAnswered then
                TweenService:Create(button, scaleInfo, {
                    Size = UDim2.new(0.48, 0, 0.22, 0)
                }):Play()
            end
        end)
        
        button.MouseLeave:Connect(function()
            if not hasAnswered then
                TweenService:Create(button, scaleInfo, {
                    Size = UDim2.new(0.47, 0, 0.2, 0)
                }):Play()
            end
        end)
        
        -- Handle click
        button.MouseButton1Click:Connect(function()
            if not hasAnswered and currentQuestion then
                SelectAnswer(i)
            end
        end)
    end
end

function ShowQuestion(question, totalTime)
    currentQuestion = question
    hasAnswered = false
    maxTime = totalTime
    
    -- Reset UI
    gui.Enabled = true
    mainFrame.Visible = true
    resultFrame.Visible = false
    winnerFrame.Visible = false
    
    -- Animate in
    mainFrame.Position = UDim2.new(0.5, 0, -0.5, 0)
    TweenService:Create(mainFrame, fadeInInfo, {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    
    -- Set question text
    questionLabel.Text = question.question
    categoryLabel.Text = question.category or "General"
    
    -- Set answer options
    for i = 1, 4 do
        local button = answerButtons[i]
        if button and question.options[i] then
            button.Text = question.options[i]
            button.BackgroundColor3 = Color3.fromRGB(70, 130, 180) -- Steel blue
            button.TextColor3 = Color3.new(1, 1, 1)
            button.BackgroundTransparency = 0
            
            -- Stagger animation
            button.Size = UDim2.new(0, 0, 0.2, 0)
            wait(0.1)
            TweenService:Create(button, fadeInInfo, {
                Size = UDim2.new(0.47, 0, 0.2, 0)
            }):Play()
        end
    end
    
    -- Reset timer
    timerBar.Size = UDim2.new(1, 0, 1, 0)
    timerBar.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Green
end

function SelectAnswer(index)
    if hasAnswered then return end
    
    hasAnswered = true
    
    -- Visual feedback
    local selectedButton = answerButtons[index]
    if selectedButton then
        -- Highlight selection
        selectedButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219) -- Bright blue
        
        -- Pulse effect
        local originalSize = selectedButton.Size
        TweenService:Create(selectedButton, scaleInfo, {
            Size = originalSize + UDim2.new(0.02, 0, 0.02, 0)
        }):Play()
        
        wait(0.2)
        
        TweenService:Create(selectedButton, scaleInfo, {
            Size = originalSize
        }):Play()
    end
    
    -- Disable other buttons
    for i, button in ipairs(answerButtons) do
        if i ~= index then
            button.BackgroundTransparency = 0.5
            button.TextTransparency = 0.5
        end
    end
    
    -- Submit answer
    submitAnswerRemote:FireServer(index)
end

function UpdateTimer(timeLeft)
    local percentage = timeLeft / maxTime
    
    -- Update timer bar
    TweenService:Create(timerBar, TweenInfo.new(0.1), {
        Size = UDim2.new(percentage, 0, 1, 0)
    }):Play()
    
    -- Change color based on time left
    if percentage > 0.5 then
        timerBar.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Green
    elseif percentage > 0.25 then
        timerBar.BackgroundColor3 = Color3.fromRGB(241, 196, 15) -- Yellow
    else
        timerBar.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Red
    end
    
    -- Update text
    timerLabel.Text = tostring(math.ceil(timeLeft))
end

function ShowResults(results, correctAnswer)
    -- Hide question UI
    TweenService:Create(mainFrame, fadeOutInfo, {
        Position = UDim2.new(0.5, 0, 1.5, 0)
    }):Play()
    
    wait(0.3)
    mainFrame.Visible = false
    
    -- Show correct answer on buttons
    for i, button in ipairs(answerButtons) do
        if i == correctAnswer then
            button.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Green
            button.BackgroundTransparency = 0
            button.TextTransparency = 0
        end
    end
    
    -- Check if player was correct
    local playerResult = results[player]
    if playerResult then
        resultFrame.Visible = true
        
        if playerResult.correct then
            resultLabel.Text = "CORRECT! ✓"
            resultLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
        else
            resultLabel.Text = "WRONG! ✗"
            resultLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
        end
        
        correctAnswerLabel.Text = "Correct answer was: " .. currentQuestion.options[correctAnswer]
        
        -- Animate result
        resultFrame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(resultFrame, fadeInInfo, {
            Size = UDim2.new(0.4, 0, 0.2, 0)
        }):Play()
    end
    
    -- Hide after delay
    wait(3)
    TweenService:Create(resultFrame, fadeOutInfo, {
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    wait(0.3)
    gui.Enabled = false
end

function AnnounceWinner(winner)
    gui.Enabled = true
    winnerFrame.Visible = true
    
    if winner == player then
        winnerLabel.Text = "🎉 YOU WIN! 🎉"
        winnerLabel.TextColor3 = Color3.fromRGB(241, 196, 15) -- Gold
    else
        winnerLabel.Text = winner.Name .. " WINS!"
        winnerLabel.TextColor3 = Color3.fromRGB(52, 152, 219) -- Blue
    end
    
    -- Animate
    winnerFrame.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(winnerFrame, TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
        Size = UDim2.new(0.6, 0, 0.3, 0)
    }):Play()
    
    -- Confetti effect would go here
    
    wait(5)
    TweenService:Create(winnerFrame, fadeOutInfo, {
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    wait(0.3)
    gui.Enabled = false
end

-- Connect RemoteEvents
showQuestionRemote.OnClientEvent:Connect(ShowQuestion)
updateQuizTimerRemote.OnClientEvent:Connect(UpdateTimer)
showQuizResultRemote.OnClientEvent:Connect(ShowResults)
announceWinnerRemote.OnClientEvent:Connect(AnnounceWinner)

-- Initially hide
gui.Enabled = false