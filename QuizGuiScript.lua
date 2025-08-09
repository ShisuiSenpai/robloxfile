-- QuizGuiScript.lua
-- Client-side script for managing the Quiz UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get UI elements
local quizGui = script.Parent
local bg = quizGui:WaitForChild("BG")
local questionFrame = bg:WaitForChild("QuestionFrame")
local questionText = questionFrame:WaitForChild("QuestionText")
local timerFrame = bg:WaitForChild("TimerFrame")
local timerText = timerFrame:WaitForChild("TimerText")
local nextQuestionFrame = bg:WaitForChild("NextQuestionFrame")
local nextQuestionLabel = nextQuestionFrame:WaitForChild("Label")
local nextQuestionTimer = nextQuestionFrame:WaitForChild("Timer")

-- Answer frames
local answerFrames = {
	bg:WaitForChild("AnswerA"),
	bg:WaitForChild("AnswerB"),
	bg:WaitForChild("AnswerC"),
	bg:WaitForChild("AnswerD")
}

-- Get RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local showQuestionRemote = remoteEvents:WaitForChild("ShowQuestion")
local submitAnswerRemote = remoteEvents:WaitForChild("SubmitAnswer")
local updateQuizTimerRemote = remoteEvents:WaitForChild("UpdateQuizTimer")
local showQuizResultRemote = remoteEvents:WaitForChild("ShowQuizResult")
local updateNextQuestionRemote = remoteEvents:WaitForChild("UpdateNextQuestion")

-- Get sound config
local soundConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SoundConfig"))

-- State variables
local currentQuestion = nil
local hasAnswered = false
local selectedAnswer = nil
local isQuizActive = false

-- Colors
local defaultColor = Color3.fromRGB(100, 150, 250)
local selectedColor = Color3.fromRGB(150, 200, 255)
local correctColor = Color3.fromRGB(100, 250, 100)
local wrongColor = Color3.fromRGB(250, 100, 100)
local disabledColor = Color3.fromRGB(200, 200, 200)

-- Create local sounds
local sounds = {}
local function createSound(config)
	local sound = Instance.new("Sound")
	sound.SoundId = config.SoundId
	sound.Volume = config.Volume
	sound.Pitch = config.Pitch
	sound.Parent = SoundService
	return sound
end

-- Initialize sounds
sounds.timerTick = createSound(soundConfig.TimerTick)
sounds.correctAnswer = createSound(soundConfig.CorrectAnswer)
sounds.wrongAnswer = createSound(soundConfig.WrongAnswer)
sounds.questionAppear = createSound(soundConfig.QuestionAppear)
sounds.buttonHover = createSound(soundConfig.ButtonHover)

-- Utility functions
local function tweenElement(element, properties, duration)
	duration = duration or 0.3
	local tween = TweenService:Create(
		element,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		properties
	)
	tween:Play()
	return tween
end

-- Reset answer frame appearance
local function resetAnswerFrame(index)
	local frame = answerFrames[index]
	local uiStroke = frame:FindFirstChild("UIStroke")
	local innerFrame = frame:FindFirstChild("Frame")
	local letterCircle = innerFrame and innerFrame:FindFirstChild("LetterCircle")
	
	if uiStroke then
		uiStroke.Color = defaultColor
		uiStroke.Thickness = 2
	end
	
	if letterCircle then
		letterCircle.BackgroundColor3 = defaultColor
	end
	
	frame.BackgroundTransparency = 0
end

-- Setup answer button
local function setupAnswerButton(index)
	local frame = answerFrames[index]
	local button = frame:FindFirstChild("TextButton")
	local uiStroke = frame:FindFirstChild("UIStroke")
	local innerFrame = frame:FindFirstChild("Frame")
	local letterCircle = innerFrame and innerFrame:FindFirstChild("LetterCircle")
	
	if not button then return end
	
	-- Mouse enter effect
	button.MouseEnter:Connect(function()
		if hasAnswered or not isQuizActive then return end
		
		sounds.buttonHover:Play()
		
		if selectedAnswer ~= index then
			tweenElement(frame, {BackgroundTransparency = 0.1})
			if uiStroke then
				tweenElement(uiStroke, {Thickness = 3})
			end
		end
	end)
	
	-- Mouse leave effect
	button.MouseLeave:Connect(function()
		if hasAnswered or not isQuizActive then return end
		
		if selectedAnswer ~= index then
			tweenElement(frame, {BackgroundTransparency = 0})
			if uiStroke then
				tweenElement(uiStroke, {Thickness = 2})
			end
		end
	end)
	
	-- Click handler
	button.MouseButton1Click:Connect(function()
		if hasAnswered or not isQuizActive then return end
		
		-- Update selected state
		selectedAnswer = index
		hasAnswered = true
		
		-- Visual feedback for selection
		for i = 1, 4 do
			if i == index then
				-- Highlight selected
				local stroke = answerFrames[i]:FindFirstChild("UIStroke")
				if stroke then
					stroke.Color = selectedColor
					stroke.Thickness = 4
				end
				local circle = answerFrames[i]:FindFirstChild("Frame"):FindFirstChild("LetterCircle")
				if circle then
					tweenElement(circle, {BackgroundColor3 = selectedColor})
				end
			else
				-- Dim others
				local stroke = answerFrames[i]:FindFirstChild("UIStroke")
				if stroke then
					stroke.Color = disabledColor
				end
				tweenElement(answerFrames[i], {BackgroundTransparency = 0.3})
			end
		end
		
		-- Submit answer to server
		submitAnswerRemote:FireServer(index)
		
		print("[QuizUI] Submitted answer:", index)
	end)
end

-- Show question on UI
local function showQuestion(questionData, timeLimit)
	if not questionData then return end
	
	print("[QuizUI] Showing question:", questionData.question)
	
	-- Reset state
	currentQuestion = questionData
	hasAnswered = false
	selectedAnswer = nil
	isQuizActive = true
	
	-- Play sound
	sounds.questionAppear:Play()
	
	-- Update question text
	questionText.Text = questionData.question
	
	-- Update answer options
	for i = 1, 4 do
		local frame = answerFrames[i]
		local innerFrame = frame:FindFirstChild("Frame")
		local answerTextLabel = innerFrame and innerFrame:FindFirstChild("AnswerText")
		
		if answerTextLabel and questionData.options[i] then
			answerTextLabel.Text = questionData.options[i]
		end
		
		-- Reset appearance
		resetAnswerFrame(i)
		
		-- Animate in
		frame.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset + 50, frame.Position.Y.Scale, frame.Position.Y.Offset)
		tweenElement(frame, {Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset - 50, frame.Position.Y.Scale, frame.Position.Y.Offset)}, 0.3 + (i * 0.1))
	end
	
	-- Show timer
	timerText.Text = tostring(timeLimit)
	
	-- Animate question frame
	questionFrame.Position = UDim2.new(0.5, -400, 0.45, 0)
	tweenElement(questionFrame, {Position = UDim2.new(0.5, -400, 0.55, 0)}, 0.5)
	
	-- Hide next question frame
	nextQuestionFrame.Visible = false
end

-- Update timer
local lastTimerValue = nil
updateQuizTimerRemote.OnClientEvent:Connect(function(timeLeft)
	timerText.Text = tostring(math.max(0, timeLeft))
	
	-- Play tick sound for last 3 seconds
	if timeLeft <= 3 and timeLeft > 0 and timeLeft ~= lastTimerValue then
		sounds.timerTick:Play()
		
		-- Pulse effect for urgency
		local pulseTween = tweenElement(timerFrame, {Size = UDim2.new(0, 220, 0, 88)}, 0.1)
		pulseTween.Completed:Connect(function()
			tweenElement(timerFrame, {Size = UDim2.new(0, 200, 0, 80)}, 0.1)
		end)
		
		-- Change color for last 3 seconds
		if timeLeft <= 3 then
			timerText.TextColor3 = Color3.new(1, 0.3, 0.3)
		end
	elseif timeLeft > 3 then
		timerText.TextColor3 = Color3.fromRGB(100, 150, 250)
	end
	
	lastTimerValue = timeLeft
end)

-- Show quiz results
showQuizResultRemote.OnClientEvent:Connect(function(results, correctAnswerIndex)
	print("[QuizUI] Showing results. Correct answer:", correctAnswerIndex)
	
	isQuizActive = false
	
	-- Get player's result
	local playerResult = results[player.Name]
	local wasCorrect = playerResult and playerResult.correct
	
	-- Play appropriate sound
	if wasCorrect then
		sounds.correctAnswer:Play()
	elseif selectedAnswer then
		sounds.wrongAnswer:Play()
	end
	
	-- Show correct/wrong answers with animation
	for i = 1, 4 do
		local frame = answerFrames[i]
		local uiStroke = frame:FindFirstChild("UIStroke")
		local innerFrame = frame:FindFirstChild("Frame")
		local letterCircle = innerFrame and innerFrame:FindFirstChild("LetterCircle")
		
		if i == correctAnswerIndex then
			-- Show correct answer in green
			if uiStroke then
				tweenElement(uiStroke, {Color = correctColor, Thickness = 4})
			end
			if letterCircle then
				tweenElement(letterCircle, {BackgroundColor3 = correctColor})
			end
			
			-- Pulse effect
			local pulseTween = tweenElement(frame, {Size = UDim2.new(0, 400, 0, 75)}, 0.2)
			pulseTween.Completed:Connect(function()
				tweenElement(frame, {Size = UDim2.new(0, 380, 0, 70)}, 0.2)
			end)
		elseif i == selectedAnswer and not wasCorrect then
			-- Show wrong answer in red
			if uiStroke then
				tweenElement(uiStroke, {Color = wrongColor, Thickness = 3})
			end
			if letterCircle then
				tweenElement(letterCircle, {BackgroundColor3 = wrongColor})
			end
			
			-- Shake effect for wrong answer
			local originalPos = frame.Position
			for j = 1, 3 do
				task.wait(0.05)
				frame.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + math.random(-5, 5), originalPos.Y.Scale, originalPos.Y.Offset)
			end
			frame.Position = originalPos
		else
			-- Fade out other options
			tweenElement(frame, {BackgroundTransparency = 0.5})
		end
	end
end)

-- Update next question countdown
updateNextQuestionRemote.OnClientEvent:Connect(function(countdown)
	if countdown > 0 then
		nextQuestionFrame.Visible = true
		nextQuestionTimer.Text = tostring(countdown)
		
		-- Pulse effect
		local pulseTween = tweenElement(nextQuestionFrame, {Size = UDim2.new(0.32, 0, 0.135, 0)}, 0.3)
		pulseTween.Completed:Connect(function()
			tweenElement(nextQuestionFrame, {Size = UDim2.new(0.301, 0, 0.126, 0)}, 0.3)
		end)
	else
		-- Hide when countdown ends
		nextQuestionFrame.Visible = false
	end
end)

-- Show question event
showQuestionRemote.OnClientEvent:Connect(showQuestion)

-- Initialize answer buttons
for i = 1, 4 do
	setupAnswerButton(i)
end

-- Hide UI initially
questionFrame.Visible = true
timerFrame.Visible = true
nextQuestionFrame.Visible = false

print("[QuizUI] Quiz interface initialized")