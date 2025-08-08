-- Example Usage Script for Minimal Quiz UI
-- This demonstrates how to use the clean quiz interface

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
    },
    {
        question = "What year did World War II end?",
        answers = {"1943", "1944", "1945", "1946"},
        correct = 3
    }
}

-- Get UI elements
local bg = quizUI:WaitForChild("BG")
local questionFrame = bg:WaitForChild("QuestionFrame")
local answersContainer = bg:WaitForChild("AnswersContainer")

-- Current question tracking
local currentQuestion = 1
local score = 0
local isAnswering = false

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
        local contentFrame = answerFrame:WaitForChild("Frame")
        local answerText = contentFrame:WaitForChild("AnswerText")
        answerText.Text = answer
    end
    
    -- Reset answer states if using manager
    -- QuizUIManager.ResetAnswers(answersContainer)
    
    isAnswering = false
end

-- Handle answer selection
local function setupAnswerButtons()
    local letters = {"A", "B", "C", "D"}
    
    for i, letter in ipairs(letters) do
        local answerFrame = answersContainer:WaitForChild("Answer" .. letter)
        local button = answerFrame:WaitForChild("TextButton")
        
        button.MouseButton1Click:Connect(function()
            if isAnswering then return end
            isAnswering = true
            
            local questionData = questions[currentQuestion]
            local isCorrect = (i == questionData.correct)
            
            -- Visual feedback (if using manager)
            -- QuizUIManager.SelectAnswer(answerFrame, function()
            --     QuizUIManager.RevealAnswer(answerFrame, isCorrect)
            -- end)
            
            -- Basic visual feedback without manager
            if isCorrect then
                answerFrame.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
                score = score + 1
            else
                answerFrame.BackgroundColor3 = Color3.fromRGB(250, 100, 100)
                -- Show correct answer
                local correctFrame = answersContainer:WaitForChild("Answer" .. letters[questionData.correct])
                correctFrame.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            end
            
            -- Move to next question after delay
            wait(2)
            
            if currentQuestion < #questions then
                currentQuestion = currentQuestion + 1
                -- QuizUIManager.TransitionToNextQuestion(bg, function()
                --     loadQuestion(currentQuestion)
                -- end)
                
                -- Simple transition without manager
                loadQuestion(currentQuestion)
                -- Reset colors
                for _, l in ipairs(letters) do
                    local frame = answersContainer:WaitForChild("Answer" .. l)
                    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                end
            else
                -- Quiz complete!
                print("Quiz Complete! Score: " .. score .. "/" .. #questions)
                
                -- Show result (if using manager)
                -- QuizUIManager.ShowResult(bg, score == #questions, score)
                -- if score == #questions then
                --     QuizUIManager.Celebrate(bg)
                -- end
                
                -- Simple completion message
                local title = bg:WaitForChild("Title")
                title.Text = score == #questions and "PERFECT SCORE!" or "QUIZ COMPLETE!"
                title.TextColor3 = score == #questions and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(100, 150, 250)
            end
        end)
    end
end

-- Initialize the quiz
local function initializeQuiz()
    setupAnswerButtons()
    loadQuestion(currentQuestion)
end

-- Start the quiz
wait(1) -- Wait for entrance animation
initializeQuiz()

print("Minimal Quiz UI loaded! Click on answers to play.")