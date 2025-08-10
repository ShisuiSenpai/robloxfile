-- QuizUI LocalScript
-- Handles all client-side quiz interface functionality for Step to Victory

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = script.Parent

-- Wait for essential modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConstants = require(Modules:WaitForChild("GameConstants"))
local SoundConfig = require(Modules:WaitForChild("SoundConfig"))

-- Wait for UI elements
local BG = gui:WaitForChild("BG")

-- Get all UI elements with proper error handling
local function getUIElements()
	local elements = {}
	
	-- Main frames
	elements.questionFrame = BG:WaitForChild("QuestionFrame")
	elements.questionText = elements.questionFrame:WaitForChild("QuestionText")
	
	elements.timerFrame = BG:WaitForChild("TimerFrame")
	elements.timerText = elements.timerFrame:WaitForChild("TimerText")
	
	elements.nextQuestionFrame = BG:WaitForChild("NextQuestionFrame")
	elements.nextQuestionLabel = elements.nextQuestionFrame:WaitForChild("Label")
	elements.nextQuestionTimer = elements.nextQuestionFrame:WaitForChild("Timer")
	
	-- Answer frames
	elements.answerFrames = {
		BG:WaitForChild("AnswerA"),
		BG:WaitForChild("AnswerB"),
		BG:WaitForChild("AnswerC"),
		BG:WaitForChild("AnswerD")
	}
	
	return elements
end

local UI = getUIElements()

-- Get RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local showQuestionRemote = remoteEvents:WaitForChild("ShowQuestion")
local submitAnswerRemote = remoteEvents:WaitForChild("SubmitAnswer")
local updateQuizTimerRemote = remoteEvents:WaitForChild("UpdateQuizTimer")
local showQuizResultRemote = remoteEvents:WaitForChild("ShowQuizResult")
local announceWinnerRemote = remoteEvents:WaitForChild("AnnounceWinner")
local updateNextQuestionRemote = remoteEvents:WaitForChild("UpdateNextQuestion")

-- Color palette
local Colors = {
	Primary = Color3.fromRGB(100, 150, 250),      -- Blue
	PrimaryDark = Color3.fromRGB(80, 130, 230),   -- Darker blue
	PrimaryLight = Color3.fromRGB(120, 170, 255), -- Light blue
	Success = Color3.fromRGB(50, 200, 50),         -- Darker Green
	Error = Color3.fromRGB(200, 50, 50),           -- Darker Red
	Warning = Color3.fromRGB(241, 196, 15),        -- Yellow
	Neutral = Color3.fromRGB(200, 200, 200),       -- Grey
	White = Color3.fromRGB(255, 255, 255)
}

-- State management
local QuizState = {
	currentQuestion = nil,
	hasAnswered = false,
	selectedAnswer = nil,
	isQuizActive = false,
	maxTime = 15,
	lastTickSecond = -1
}

-- Sound management
local SoundManager = {}
SoundManager.__index = SoundManager

function SoundManager.new()
	local self = setmetatable({}, SoundManager)
	self.sounds = {}
	self:initializeSounds()
	return self
end

function SoundManager:initializeSounds()
	local soundConfigs = {
		timerTick = SoundConfig.TimerTick,
		correct = SoundConfig.CorrectAnswer,
		wrong = SoundConfig.WrongAnswer,
		victory = SoundConfig.Victory,
		hover = SoundConfig.ButtonHover,
		appear = SoundConfig.QuestionAppear
	}
	
	for name, config in pairs(soundConfigs) do
		local sound = Instance.new("Sound")
		sound.Name = name .. "Sound"
		sound.SoundId = config.SoundId
		sound.Volume = config.Volume
		sound.Pitch = config.Pitch
		sound.EmitterSize = config.EmitterSize
		sound.Parent = SoundService
		self.sounds[name] = sound
	end
end

function SoundManager:play(soundName)
	local sound = self.sounds[soundName]
	if sound then
		sound:Play()
	else
		warn("[SoundManager] Sound not found:", soundName)
	end
end

local soundManager = SoundManager.new()

-- Animation utilities
local AnimationUtils = {}

function AnimationUtils.tween(instance, properties, duration, easingStyle, easingDirection)
	duration = duration or 0.3
	easingStyle = easingStyle or Enum.EasingStyle.Quad
	easingDirection = easingDirection or Enum.EasingDirection.Out
	
	local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end

function AnimationUtils.pulse(instance, scale, duration)
	scale = scale or 1.1
	duration = duration or 0.2
	
	local originalSize = instance.Size
	local targetSize = UDim2.new(
		originalSize.X.Scale * scale,
		originalSize.X.Offset * scale,
		originalSize.Y.Scale * scale,
		originalSize.Y.Offset * scale
	)
	
	AnimationUtils.tween(instance, {Size = targetSize}, duration / 2)
	
	task.wait(duration / 2)
	
	AnimationUtils.tween(instance, {Size = originalSize}, duration / 2)
end

function AnimationUtils.shake(instance, intensity, duration)
	intensity = intensity or 5
	duration = duration or 0.3
	local originalPos = instance.Position
	local shakeCount = 4
	local shakeTime = duration / (shakeCount * 2)
	
	for i = 1, shakeCount do
		instance.Position = UDim2.new(
			originalPos.X.Scale,
			originalPos.X.Offset + math.random(-intensity, intensity),
			originalPos.Y.Scale,
			originalPos.Y.Offset
		)
		task.wait(shakeTime)
		instance.Position = originalPos
		task.wait(shakeTime)
	end
end

-- Answer button management
local AnswerButtonManager = {}
AnswerButtonManager.__index = AnswerButtonManager

function AnswerButtonManager.new(answerFrames)
	local self = setmetatable({}, AnswerButtonManager)
	self.answerFrames = answerFrames
	self.buttons = {}
	self:initialize()
	return self
end

function AnswerButtonManager:initialize()
	for i, frame in ipairs(self.answerFrames) do
		local button = frame:FindFirstChildOfClass("TextButton")
		if button then
			self.buttons[i] = button
			self:setupButton(i, frame, button)
		end
	end
end

function AnswerButtonManager:setupButton(index, frame, button)
	-- Hover effects
	button.MouseEnter:Connect(function()
		if not QuizState.hasAnswered and QuizState.isQuizActive then
			soundManager:play("hover")
			
			local uiStroke = frame:FindFirstChild("UIStroke")
			if uiStroke then
				AnimationUtils.tween(uiStroke, {Thickness = 3}, 0.15)
			end
			
			-- Slight scale up for hover
			local targetSize = UDim2.new(
				frame.Size.X.Scale * 1.02,
				frame.Size.X.Offset,
				frame.Size.Y.Scale * 1.02,
				frame.Size.Y.Offset
			)
			AnimationUtils.tween(frame, {Size = targetSize}, 0.15)
		end
	end)
	
	button.MouseLeave:Connect(function()
		if not QuizState.hasAnswered and QuizState.isQuizActive then
			local uiStroke = frame:FindFirstChild("UIStroke")
			if uiStroke then
				AnimationUtils.tween(uiStroke, {Thickness = 2}, 0.15)
			end
			
			-- Return to original size
			local originalSize = UDim2.new(0.198, 0, 0.073, 0)
			AnimationUtils.tween(frame, {Size = originalSize}, 0.15)
		end
	end)
	
	-- Click handler
	button.MouseButton1Click:Connect(function()
		if not QuizState.hasAnswered and QuizState.isQuizActive and QuizState.currentQuestion then
			self:selectAnswer(index)
		end
	end)
end

function AnswerButtonManager:selectAnswer(index)
	QuizState.hasAnswered = true
	QuizState.selectedAnswer = index
	
	-- Disable all buttons
	for _, button in ipairs(self.buttons) do
		button.Active = false
	end
	
	local selectedFrame = self.answerFrames[index]
	local uiStroke = selectedFrame:FindFirstChild("UIStroke")
	
	-- Immediate visual feedback
	selectedFrame.BackgroundColor3 = Colors.PrimaryDark
	if uiStroke then
		uiStroke.Color = Colors.White
		uiStroke.Thickness = 4
	end
	
	-- Pulse animation
	task.spawn(function()
		for i = 1, 3 do
			AnimationUtils.pulse(selectedFrame, 1.05, 0.3)
			task.wait(0.3)
		end
	end)
	
	-- Submit answer to server
	submitAnswerRemote:FireServer(index)
end

function AnswerButtonManager:reset()
	for i, frame in ipairs(self.answerFrames) do
		-- Reset colors
		frame.BackgroundColor3 = Colors.White
		frame.BackgroundTransparency = 0
		
		-- Reset stroke
		local uiStroke = frame:FindFirstChild("UIStroke")
		if uiStroke then
			uiStroke.Color = Colors.Primary
			uiStroke.Thickness = 2
			uiStroke.Transparency = 0
		end
		
		-- Reset inner elements
		local innerFrame = frame:FindFirstChild("Frame")
		if innerFrame then
			local letterCircle = innerFrame:FindFirstChild("LetterCircle")
			if letterCircle then
				letterCircle.BackgroundColor3 = Colors.Primary
				
				local letter = letterCircle:FindFirstChild("Letter")
				if letter then
					letter.TextColor3 = Colors.White
				end
			end
			
			local answerText = innerFrame:FindFirstChild("AnswerText")
			if answerText then
				answerText.TextColor3 = Colors.Primary
			end
		end
		
		-- Re-enable button
		if self.buttons[i] then
			self.buttons[i].Active = true
		end
	end
end

function AnswerButtonManager:showResults(correctAnswer, playerAnswer)
	for i, frame in ipairs(self.answerFrames) do
		local isCorrect = (i == correctAnswer)
		local isPlayerAnswer = (i == playerAnswer)
		
		local uiStroke = frame:FindFirstChild("UIStroke")
		local innerFrame = frame:FindFirstChild("Frame")
		local letterCircle = innerFrame and innerFrame:FindFirstChild("LetterCircle")
		local letter = letterCircle and letterCircle:FindFirstChild("Letter")
		local answerText = innerFrame and innerFrame:FindFirstChild("AnswerText")
		
		if isCorrect then
			-- Correct answer - green
			AnimationUtils.tween(frame, {BackgroundColor3 = Colors.Success}, 0.3)
			if uiStroke then
				AnimationUtils.tween(uiStroke, {Color = Colors.White, Thickness = 3}, 0.3)
			end
			if letterCircle then
				AnimationUtils.tween(letterCircle, {BackgroundColor3 = Colors.White}, 0.3)
			end
			if letter then
				AnimationUtils.tween(letter, {TextColor3 = Colors.Success}, 0.3)
			end
			if answerText then
				AnimationUtils.tween(answerText, {TextColor3 = Colors.White}, 0.3)
			end
			
			-- Simple glow effect instead of bounce
			task.spawn(function()
				if uiStroke then
					AnimationUtils.tween(uiStroke, {Thickness = 5}, 0.2)
					task.wait(0.2)
					AnimationUtils.tween(uiStroke, {Thickness = 3}, 0.2)
				end
			end)
			
		elseif isPlayerAnswer and not isCorrect then
			-- Wrong answer - red
			AnimationUtils.tween(frame, {BackgroundColor3 = Colors.Error}, 0.3)
			if uiStroke then
				AnimationUtils.tween(uiStroke, {Color = Colors.White, Thickness = 3}, 0.3)
			end
			if letterCircle then
				AnimationUtils.tween(letterCircle, {BackgroundColor3 = Colors.White}, 0.3)
			end
			if letter then
				AnimationUtils.tween(letter, {TextColor3 = Colors.Error}, 0.3)
			end
			if answerText then
				AnimationUtils.tween(answerText, {TextColor3 = Colors.White}, 0.3)
			end
			
			-- Simple flash effect instead of shake
			task.spawn(function()
				AnimationUtils.tween(frame, {BackgroundTransparency = 0.2}, 0.15)
				task.wait(0.15)
				AnimationUtils.tween(frame, {BackgroundTransparency = 0}, 0.15)
			end)
			
		else
			-- Other answers - grey out
			AnimationUtils.tween(frame, {
				BackgroundColor3 = Colors.Neutral,
				BackgroundTransparency = 0.3
			}, 0.3)
			if uiStroke then
				AnimationUtils.tween(uiStroke, {
					Color = Color3.fromRGB(150, 150, 150),
					Thickness = 2
				}, 0.3)
			end
			if letterCircle then
				AnimationUtils.tween(letterCircle, {BackgroundColor3 = Color3.fromRGB(150, 150, 150)}, 0.3)
			end
			if answerText then
				AnimationUtils.tween(answerText, {TextColor3 = Color3.fromRGB(150, 150, 150)}, 0.3)
			end
		end
	end
end

local answerManager = AnswerButtonManager.new(UI.answerFrames)

-- Quiz display functions
local function animateQuizIn()
	-- Hide all elements initially
	UI.questionFrame.Position = UDim2.new(0.291, 0, -0.3, 0)
	UI.timerFrame.Position = UDim2.new(0.448, 0, -0.2, 0)
	
	for i, frame in ipairs(UI.answerFrames) do
		frame.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, 1.2, 0)
	end
	
	-- Animate question
	AnimationUtils.tween(UI.questionFrame, {
		Position = UDim2.new(0.291, 0, 0.55, 0)
	}, 0.8, Enum.EasingStyle.Back)
	
	-- Animate timer
	AnimationUtils.tween(UI.timerFrame, {
		Position = UDim2.new(0.448, 0, 0.05, 0)
	}, 0.6, Enum.EasingStyle.Back)
	
	-- Animate answers with stagger
	task.wait(0.2)
	
	local answerPositions = {
		UDim2.new(0.297, 0, 0.72, 0),
		UDim2.new(0.505, 0, 0.72, 0),
		UDim2.new(0.297, 0, 0.808, 0),
		UDim2.new(0.505, 0, 0.808, 0)
	}
	
	for i, frame in ipairs(UI.answerFrames) do
		AnimationUtils.tween(frame, {
			Position = answerPositions[i]
		}, 0.6, Enum.EasingStyle.Back)
		task.wait(0.1)
	end
end

local function showQuestion(questionData, totalTime)
	QuizState.currentQuestion = questionData
	QuizState.hasAnswered = false
	QuizState.selectedAnswer = nil
	QuizState.isQuizActive = true
	QuizState.maxTime = totalTime
	QuizState.lastTickSecond = -1
	
	-- Reset UI
	gui.Enabled = true
	BG.Visible = true
	UI.nextQuestionFrame.Visible = false
	
	-- IMPORTANT: Reset visibility and transparency for all elements
	UI.questionFrame.Visible = true
	UI.questionFrame.BackgroundTransparency = 0
	UI.timerFrame.Visible = true
	UI.timerFrame.BackgroundTransparency = 0
	
	-- Reset text transparencies
	UI.questionText.TextTransparency = 0
	UI.timerText.TextTransparency = 0
	
	-- Reset answer frames visibility and transparency
	for _, frame in ipairs(UI.answerFrames) do
		frame.Visible = true
		frame.BackgroundTransparency = 0
	end
	
	-- Reset all elements
	answerManager:reset()
	
	-- Update question text
	UI.questionText.Text = questionData.question
	
	-- Update answer options
	for i = 1, 4 do
		local frame = UI.answerFrames[i]
		local innerFrame = frame:FindFirstChild("Frame")
		if innerFrame then
			local answerText = innerFrame:FindFirstChild("AnswerText")
			if answerText and questionData.options[i] then
				answerText.Text = questionData.options[i]
			end
		end
	end
	
	-- Reset timer
	UI.timerText.Text = tostring(totalTime)
	UI.timerText.TextColor3 = Colors.Primary
	
	-- Play appear sound
	soundManager:play("appear")
	
	-- Animate in
	animateQuizIn()
end

local function updateTimer(timeLeft)
	local displayTime = math.max(0, math.ceil(timeLeft))
	UI.timerText.Text = tostring(displayTime)
	
	-- Color changes based on time
	local percentage = timeLeft / QuizState.maxTime
	if percentage > 0.5 then
		UI.timerText.TextColor3 = Colors.Primary
	elseif percentage > 0.25 then
		UI.timerText.TextColor3 = Colors.Warning
	else
		UI.timerText.TextColor3 = Colors.Error
		
		-- Timer tick for last 3 seconds
		if displayTime <= 3 and displayTime > 0 and displayTime ~= QuizState.lastTickSecond then
			QuizState.lastTickSecond = displayTime
			soundManager:play("timerTick")
			
			-- Pulse effect
			task.spawn(function()
				AnimationUtils.pulse(UI.timerFrame, 1.05, 0.3)
			end)
		end
	end
end

local function showResults(results, correctAnswer)
	QuizState.isQuizActive = false
	
	-- Get player result
	local playerResult = results[player.Name]
	
	-- Play appropriate sound
	if playerResult then
		if playerResult.correct then
			soundManager:play("correct")
		else
			soundManager:play("wrong")
		end
	end
	
	-- Show results visually
	answerManager:showResults(correctAnswer, playerResult and playerResult.answer)
	
	-- Wait then fade out
	task.wait(3)
	
	-- Fade out all elements
	local fadeOutElements = {
		{UI.questionFrame, UDim2.new(0.291, 0, -0.3, 0)},
		{UI.timerFrame, UDim2.new(0.448, 0, -0.2, 0)}
	}
	
	for _, data in ipairs(fadeOutElements) do
		AnimationUtils.tween(data[1], {
			Position = data[2]
		}, 0.5)
	end
	
	-- Also fade out text
	AnimationUtils.tween(UI.questionText, {TextTransparency = 1}, 0.5)
	AnimationUtils.tween(UI.timerText, {TextTransparency = 1}, 0.5)
	
	for _, frame in ipairs(UI.answerFrames) do
		AnimationUtils.tween(frame, {
			Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, 1.2, 0)
		}, 0.5)
	end
	
	task.wait(0.5)
	gui.Enabled = false
end

local function showNextQuestionCountdown(timeLeft)
	local displayTime = math.max(0, math.floor(timeLeft + 0.5))
	
	if not gui.Enabled then
		gui.Enabled = true
	end
	
	UI.nextQuestionTimer.Text = tostring(displayTime)
	
	-- Show on first call
	if displayTime == 3 and not UI.nextQuestionFrame.Visible then
		UI.questionFrame.Visible = false
		UI.timerFrame.Visible = false
		for _, frame in ipairs(UI.answerFrames) do
			frame.Visible = false
		end
		
		UI.nextQuestionFrame.Visible = true
		UI.nextQuestionFrame.Position = UDim2.new(0.396, 0, 1.2, 0)
		
		AnimationUtils.tween(UI.nextQuestionFrame, {
			Position = UDim2.new(0.396, 0, 0.85, 0)
		}, 0.5, Enum.EasingStyle.Back)
	end
	
	-- Color based on time
	local color = Colors.Primary
	if displayTime == 2 then
		color = Colors.Warning
	elseif displayTime == 1 then
		color = Color3.fromRGB(255, 140, 0)
	elseif displayTime == 0 then
		color = Colors.Error
	end
	
	UI.nextQuestionTimer.TextColor3 = color
	local uiStroke = UI.nextQuestionFrame:FindFirstChild("UIStroke")
	if uiStroke then
		uiStroke.Color = color
	end
	
	-- Pulse on each second
	if displayTime > 0 and timeLeft == math.floor(timeLeft) then
		soundManager:play("timerTick")
		task.spawn(function()
			AnimationUtils.pulse(UI.nextQuestionFrame, 1.05, 0.2)
		end)
	end
end

local function announceWinner(winner)
	QuizState.isQuizActive = false
	gui.Enabled = true
	BG.Visible = true
	
	soundManager:play("victory")
	
	-- Hide all quiz elements
	for _, child in pairs(BG:GetChildren()) do
		if child:IsA("Frame") then
			child.Visible = false
		end
	end
	
	-- Create winner frame
	local winnerFrame = Instance.new("Frame")
	winnerFrame.Name = "WinnerFrame"
	winnerFrame.Size = UDim2.new(0.4, 0, 0.3, 0)
	winnerFrame.Position = UDim2.new(0.3, 0, 0.35, 0)
	winnerFrame.BackgroundColor3 = Colors.White
	winnerFrame.BorderSizePixel = 0
	winnerFrame.Parent = BG
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 20)
	uiCorner.Parent = winnerFrame
	
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Colors.Primary
	uiStroke.Thickness = 4
	uiStroke.Parent = winnerFrame
	
	local winnerText = Instance.new("TextLabel")
	winnerText.Size = UDim2.new(0.9, 0, 0.4, 0)
	winnerText.Position = UDim2.new(0.05, 0, 0.1, 0)
	winnerText.BackgroundTransparency = 1
	winnerText.Text = winner == player and "🎉 YOU WIN! 🎉" or (winner.Name .. " WINS!")
	winnerText.TextColor3 = Colors.Primary
	winnerText.TextScaled = true
	winnerText.Font = Enum.Font.GothamBold
	winnerText.Parent = winnerFrame
	
	-- Add text size constraint for consistency
	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = 48
	textConstraint.MinTextSize = 24
	textConstraint.Parent = winnerText
	
	-- Animate in
	winnerFrame.Size = UDim2.new(0, 0, 0, 0)
	winnerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	winnerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	
	AnimationUtils.tween(winnerFrame, {
		Size = UDim2.new(0.4, 0, 0.3, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}, 1, Enum.EasingStyle.Elastic)
	
	-- Confetti effect
	task.spawn(function()
		for i = 1, 30 do
			local confetti = Instance.new("Frame")
			confetti.Size = UDim2.new(0, 12, 0, 12)
			confetti.Position = UDim2.new(math.random(), 0, 1, 0)
			confetti.BackgroundColor3 = math.random() > 0.5 and Colors.Primary or Colors.White
			confetti.BorderSizePixel = 0
			confetti.Parent = BG
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = confetti
			
			AnimationUtils.tween(confetti, {
				Position = UDim2.new(confetti.Position.X.Scale, 0, -0.1, 0),
				Rotation = math.random(180, 720)
			}, 3, Enum.EasingStyle.Linear)
			
			task.delay(3, function()
				confetti:Destroy()
			end)
			
			task.wait(0.05)
		end
	end)
	
	-- Hide after 5 seconds
	task.wait(5)
	AnimationUtils.tween(winnerFrame, {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}, 0.5)
	
	task.wait(0.5)
	gui.Enabled = false
end

-- Connect RemoteEvents
showQuestionRemote.OnClientEvent:Connect(showQuestion)
updateQuizTimerRemote.OnClientEvent:Connect(updateTimer)
showQuizResultRemote.OnClientEvent:Connect(showResults)
updateNextQuestionRemote.OnClientEvent:Connect(showNextQuestionCountdown)
announceWinnerRemote.OnClientEvent:Connect(announceWinner)

-- Initialize
gui.Enabled = false
print("[QuizUI] Initialized successfully")