-- Round System UI Client
-- Place this as a LocalScript in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local roundEvents = ReplicatedStorage:WaitForChild("RoundEvents")
local stateChangeRemote = roundEvents:WaitForChild("StateChange")
local timerRemote = roundEvents:WaitForChild("TimerUpdate")

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoundUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main frame for status
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(0.4, 0, 0.15, 0)
statusFrame.Position = UDim2.new(0.3, 0, 0.05, 0)
statusFrame.BackgroundColor3 = Color3.new(0, 0, 0)
statusFrame.BackgroundTransparency = 0.3
statusFrame.BorderSizePixel = 0
statusFrame.Parent = screenGui

-- Add rounded corners
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = statusFrame

-- Add gradient
local uiGradient = Instance.new("UIGradient")
uiGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.new(0.2, 0.2, 0.3)),
	ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.1, 0.2))
}
uiGradient.Rotation = 90
uiGradient.Parent = statusFrame

-- Status text
local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, 0, 0.5, 0)
statusText.Position = UDim2.new(0, 0, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "Waiting for players..."
statusText.TextColor3 = Color3.new(1, 1, 1)
statusText.TextScaled = true
statusText.Font = Enum.Font.SourceSansBold
statusText.Parent = statusFrame

-- Timer text
local timerText = Instance.new("TextLabel")
timerText.Size = UDim2.new(1, 0, 0.38, 0)
timerText.Position = UDim2.new(0, 0, 0.5, 0)
timerText.BackgroundTransparency = 1
timerText.Text = ""
timerText.TextColor3 = Color3.new(1, 0.8, 0)
timerText.TextScaled = true
timerText.Font = Enum.Font.SourceSans
timerText.Parent = statusFrame

-- Progress bar
local progressBack = Instance.new("Frame")
progressBack.Name = "ProgressBack"
progressBack.Size = UDim2.new(1, 0, 0.12, 0)
progressBack.Position = UDim2.new(0, 0, 0.88, 0)
progressBack.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
progressBack.BackgroundTransparency = 0.2
progressBack.BorderSizePixel = 0
progressBack.Visible = false
progressBack.Parent = statusFrame

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 10)
progressCorner.Parent = progressBack

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBack

local progressFillCorner = Instance.new("UICorner")
progressFillCorner.CornerRadius = UDim.new(0, 10)
progressFillCorner.Parent = progressFill

local progressGradient = Instance.new("UIGradient")
progressGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 190, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 110, 0))
}
progressGradient.Parent = progressFill

-- Winner announcement frame (hidden initially)
local winnerFrame = Instance.new("Frame")
winnerFrame.Size = UDim2.new(0.6, 0, 0.3, 0)
winnerFrame.Position = UDim2.new(0.2, 0, 2, 0) -- Off screen
winnerFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
winnerFrame.BackgroundTransparency = 0.1
winnerFrame.BorderSizePixel = 0
winnerFrame.Parent = screenGui

local winnerCorner = Instance.new("UICorner")
winnerCorner.CornerRadius = UDim.new(0, 20)
winnerCorner.Parent = winnerFrame

local winnerGradient = Instance.new("UIGradient")
winnerGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.new(1, 0.8, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.6, 0)),
	ColorSequenceKeypoint.new(1, Color3.new(1, 0.4, 0))
}
winnerGradient.Rotation = 45
winnerGradient.Parent = winnerFrame

local winnerText = Instance.new("TextLabel")
winnerText.Size = UDim2.new(1, 0, 1, 0)
winnerText.BackgroundTransparency = 1
winnerText.Text = "WINNER!"
winnerText.TextColor3 = Color3.new(1, 1, 1)
winnerText.TextScaled = true
winnerText.Font = Enum.Font.SourceSansBold
winnerText.Parent = winnerFrame

-- Countdown frame (for 3-2-1 countdown)
local countdownFrame = Instance.new("Frame")
countdownFrame.Size = UDim2.new(0.3, 0, 0.3, 0)
countdownFrame.Position = UDim2.new(0.35, 0, 2, 0) -- Off screen
countdownFrame.BackgroundColor3 = Color3.new(0, 0, 0)
countdownFrame.BackgroundTransparency = 0.5
countdownFrame.BorderSizePixel = 0
countdownFrame.Parent = screenGui

local countdownCorner = Instance.new("UICorner")
countdownCorner.CornerRadius = UDim.new(0.5, 0)
countdownCorner.Parent = countdownFrame

local countdownText = Instance.new("TextLabel")
countdownText.Size = UDim2.new(1, 0, 1, 0)
countdownText.BackgroundTransparency = 1
countdownText.Text = "3"
countdownText.TextColor3 = Color3.new(1, 1, 1)
countdownText.TextScaled = true
countdownText.Font = Enum.Font.SourceSansBold
countdownText.Parent = countdownFrame

-- Animation functions
local function showWinner(text)
	winnerText.Text = text
	local tween = TweenService:Create(winnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.2, 0, 0.35, 0)
	})
	tween:Play()

	task.wait(3)

	local hideTween = TweenService:Create(winnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.2, 0, 2, 0)
	})
	hideTween:Play()
end

local function showCountdown(number)
	countdownText.Text = tostring(number)
	countdownFrame.Position = UDim2.new(0.35, 0, 0.35, 0)
	countdownFrame.Size = UDim2.new(0.3, 0, 0.3, 0)

	local tween = TweenService:Create(countdownFrame, TweenInfo.new(1, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0.4, 0, 0.4, 0),
		BackgroundTransparency = 1
	})

	local textTween = TweenService:Create(countdownText, TweenInfo.new(1, Enum.EasingStyle.Linear), {
		TextTransparency = 1
	})

	tween:Play()
	textTween:Play()

	tween.Completed:Connect(function()
		countdownFrame.Position = UDim2.new(0.35, 0, 2, 0)
		countdownFrame.BackgroundTransparency = 0.5
		countdownText.TextTransparency = 0
	end)
end

-- Handle state changes
stateChangeRemote.OnClientEvent:Connect(function(state, message)
	statusText.Text = message or state

	-- Handle different states with refined colors
	if state == "WAITING" then
		statusText.TextColor3 = Color3.fromRGB(180, 180, 190)
		timerText.Text = ""
	elseif state == "INTERMISSION" then
		statusText.TextColor3 = Color3.fromRGB(255, 220, 80)
	elseif state == "STARTING" then
		statusText.TextColor3 = Color3.fromRGB(90, 220, 255)
		-- Show countdown if it's a number
		local num = tonumber(string.match(message or "", "%d+"))
		if num and num <= 3 then
			showCountdown(num)
		end
	elseif state == "IN_PROGRESS" then
		statusText.TextColor3 = Color3.fromRGB(80, 255, 200)
		timerText.Text = ""
		if message == "GO!" then
			showCountdown("GO!")
		end
	elseif state == "ENDING" then
		statusText.TextColor3 = Color3.fromRGB(255, 160, 90)
		timerText.Text = ""
		if message and message:find("wins!") then
			showWinner(message)
		end
	end
end)

-- Handle timer updates with phase-aware progress bar
timerRemote.OnClientEvent:Connect(function(timeLeft, totalTime, phase)
	if totalTime and timeLeft and timeLeft >= 0 then
		-- Show a phase-aware progress bar
		progressBack.Visible = true

		-- Fill grows from 0 -> 1 as time counts down
		local ratio = math.clamp(1 - (timeLeft / totalTime), 0, 1)
		progressFill.Size = UDim2.new(ratio, 0, 1, 0)

		-- Update timer text and accent color by phase
		if phase == "INTERMISSION" then
			timerText.TextColor3 = Color3.fromRGB(255, 200, 0)
			statusText.Text = "Intermission"
		elseif phase == "FREEZE" then
			timerText.TextColor3 = Color3.fromRGB(140, 200, 255)
			statusText.Text = "Get Ready"
		end

		timerText.Text = "Time: " .. timeLeft .. "s"
	else
		-- Hide bar when no active phase timer
		progressBack.Visible = false
		progressFill.Size = UDim2.new(0, 0, 1, 0)
		timerText.Text = ""
	end
end)

print("[ROUND UI] Client UI initialized")

