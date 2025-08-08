-- Example Usage Script for Who Wants to Be a Millionaire Quiz UI
-- This demonstrates how to use the quiz UI and manager

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for UI to load
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local quizUI = playerGui:WaitForChild("QuizUI")

-- Require the manager module (adjust path as needed)
-- local QuizUIManager = require(ReplicatedStorage:WaitForChild("QuizUIManager"))

-- Example quiz data
local questions = {
    {
        question = "What is the capital of France?",
        answers = {"Paris", "London", "Berlin", "Madrid"},
        correct = 1
    },
    {
        question = "Which planet is known as the Red Planet?",
        answers = {"Venus", "Mars", "Jupiter", "Saturn"},
        correct = 2
    },
    {
        question = "Who painted the Mona Lisa?",
        answers = {"Vincent van Gogh", "Pablo Picasso", "Leonardo da Vinci", "Michelangelo"},
        correct = 3
    },
    {
        question = "What is the largest ocean on Earth?",
        answers = {"Atlantic Ocean", "Indian Ocean", "Arctic Ocean", "Pacific Ocean"},
        correct = 4
    }
}

-- Get UI elements
local bg = quizUI:WaitForChild("BG")
local mainContainer = bg:WaitForChild("MainContainer")
local questionFrame = mainContainer:WaitForChild("QuestionFrame")
local answersContainer = mainContainer:WaitForChild("AnswersContainer")
local prizeList = mainContainer:WaitForChild("PrizeFrame"):WaitForChild("PrizeList")
local timerFrame = mainContainer:WaitForChild("TimerFrame")

-- Current question tracking
local currentQuestion = 1

-- Load a question
local function loadQuestion(questionIndex)
    local questionData = questions[questionIndex]
    if not questionData then return end
    
    -- Update question text
    local questionText = questionFrame:WaitForChild("QuestionText")
    questionText.Text = questionData.question
    
    -- Update answers
    local letters = {"A", "B", "C", "D"}
    for i, answer in ipairs(questionData.answers) do
        local answerFrame = answersContainer:WaitForChild("Answer" .. letters[i])
        local answerText = answerFrame:WaitForChild("AnswerText")
        answerText.Text = answer
    end
    
    -- Update prize ladder highlighting
    -- QuizUIManager.UpdatePrizeLadder(prizeList, currentQuestion)
end

-- Handle answer selection
local function setupAnswerButtons()
    local letters = {"A", "B", "C", "D"}
    
    for i, letter in ipairs(letters) do
        local answerFrame = answersContainer:WaitForChild("Answer" .. letter)
        local button = answerFrame:WaitForChild("TextButton")
        
        button.MouseButton1Click:Connect(function()
            local questionData = questions[currentQuestion]
            local isCorrect = (i == questionData.correct)
            
            -- Visual feedback
            -- QuizUIManager.SelectAnswer(answerFrame, function()
            --     QuizUIManager.RevealAnswer(answerFrame, isCorrect)
            -- end)
            
            -- Move to next question after delay
            wait(2)
            if isCorrect and currentQuestion < #questions then
                currentQuestion = currentQuestion + 1
                loadQuestion(currentQuestion)
            elseif isCorrect and currentQuestion == #questions then
                -- Winner!
                print("Congratulations! You've won!")
                -- QuizUIManager.CreateConfetti(bg)
            else
                -- Game over
                print("Sorry, that's incorrect. Game Over!")
            end
        end)
    end
end

-- Setup lifeline buttons
local function setupLifelines()
    local lifelinesFrame = mainContainer:WaitForChild("LifelinesFrame")
    
    -- 50:50
    local fiftyFifty = lifelinesFrame:WaitForChild("FiftyFifty"):WaitForChild("TextButton")
    fiftyFifty.MouseButton1Click:Connect(function()
        print("50:50 lifeline used!")
        -- Remove two incorrect answers
        local questionData = questions[currentQuestion]
        local correctAnswer = questionData.correct
        local letters = {"A", "B", "C", "D"}
        local removed = 0
        
        for i = 1, 4 do
            if i ~= correctAnswer and removed < 2 then
                local answerFrame = answersContainer:WaitForChild("Answer" .. letters[i])
                answerFrame.Visible = false
                removed = removed + 1
            end
        end
        
        -- Disable lifeline
        fiftyFifty.Parent.BackgroundTransparency = 0.7
        fiftyFifty.Active = false
    end)
    
    -- Phone a Friend
    local phoneFriend = lifelinesFrame:WaitForChild("PhoneFriend"):WaitForChild("TextButton")
    phoneFriend.MouseButton1Click:Connect(function()
        print("Phone a Friend lifeline used!")
        -- Show friend's suggestion
        local questionData = questions[currentQuestion]
        local letters = {"A", "B", "C", "D"}
        print("Your friend thinks the answer is " .. letters[questionData.correct])
        
        -- Disable lifeline
        phoneFriend.Parent.BackgroundTransparency = 0.7
        phoneFriend.Active = false
    end)
    
    -- Ask the Audience
    local askAudience = lifelinesFrame:WaitForChild("AskAudience"):WaitForChild("TextButton")
    askAudience.MouseButton1Click:Connect(function()
        print("Ask the Audience lifeline used!")
        -- Show audience poll
        local questionData = questions[currentQuestion]
        print("Audience Poll:")
        print("A: 15%, B: 25%, C: 45%, D: 15%") -- Example percentages
        
        -- Disable lifeline
        askAudience.Parent.BackgroundTransparency = 0.7
        askAudience.Active = false
    end)
end

-- Timer functionality
local timerRunning = false
local timeLeft = 30

local function startTimer()
    timerRunning = true
    timeLeft = 30
    
    spawn(function()
        while timerRunning and timeLeft > 0 do
            local timerText = timerFrame:WaitForChild("TimerText")
            timerText.Text = tostring(timeLeft)
            
            -- Change color when time is running out
            if timeLeft <= 10 then
                timerText.TextColor3 = Color3.fromRGB(255, 100, 100)
            else
                timerText.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
            
            wait(1)
            timeLeft = timeLeft - 1
        end
        
        if timeLeft == 0 then
            print("Time's up!")
            -- Handle timeout
        end
    end)
end

-- Initialize the quiz
local function initializeQuiz()
    setupAnswerButtons()
    setupLifelines()
    loadQuestion(currentQuestion)
    startTimer()
end

-- Start the quiz
wait(2) -- Wait for animations to complete
initializeQuiz()

print("Quiz UI Example loaded! Click on answers to play.")