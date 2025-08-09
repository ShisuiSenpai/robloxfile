-- WinnerUI.lua
-- Client-side script for displaying winner announcements

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get sound config
local soundConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SoundConfig"))

-- Create winner UI
local winnerGui = Instance.new("ScreenGui")
winnerGui.Name = "WinnerUI"
winnerGui.ResetOnSpawn = false
winnerGui.Parent = playerGui

-- Create background frame
local bgFrame = Instance.new("Frame")
bgFrame.Name = "BG"
bgFrame.Size = UDim2.new(1, 0, 1, 0)
bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
bgFrame.BackgroundTransparency = 0.5
bgFrame.Visible = false
bgFrame.Parent = winnerGui

-- Create winner container
local winnerFrame = Instance.new("Frame")
winnerFrame.Name = "WinnerFrame"
winnerFrame.Size = UDim2.new(0.5, 0, 0.4, 0)
winnerFrame.Position = UDim2.new(0.25, 0, 0.3, 0)
winnerFrame.BackgroundColor3 = Color3.new(1, 1, 1)
winnerFrame.BackgroundTransparency = 0
winnerFrame.Parent = bgFrame

-- Add corner rounding
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 30)
uiCorner.Parent = winnerFrame

-- Add gradient
local uiGradient = Instance.new("UIGradient")
uiGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)), -- Gold
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 100)) -- Light gold
}
uiGradient.Rotation = 45
uiGradient.Parent = winnerFrame

-- Add stroke
local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(255, 215, 0)
uiStroke.Thickness = 5
uiStroke.Parent = winnerFrame

-- Create crown icon
local crownLabel = Instance.new("TextLabel")
crownLabel.Name = "CrownIcon"
crownLabel.Size = UDim2.new(0.3, 0, 0.3, 0)
crownLabel.Position = UDim2.new(0.35, 0, 0.05, 0)
crownLabel.BackgroundTransparency = 1
crownLabel.Font = Enum.Font.SourceSans
crownLabel.Text = "👑"
crownLabel.TextScaled = true
crownLabel.Parent = winnerFrame

-- Create winner text
local winnerText = Instance.new("TextLabel")
winnerText.Name = "WinnerText"
winnerText.Size = UDim2.new(0.9, 0, 0.25, 0)
winnerText.Position = UDim2.new(0.05, 0, 0.35, 0)
winnerText.BackgroundTransparency = 1
winnerText.Font = Enum.Font.GothamBold
winnerText.Text = "WINNER!"
winnerText.TextColor3 = Color3.new(1, 1, 1)
winnerText.TextScaled = true
winnerText.TextStrokeTransparency = 0
winnerText.TextStrokeColor3 = Color3.fromRGB(150, 100, 0)
winnerText.Parent = winnerFrame

-- Create player name label
local playerNameLabel = Instance.new("TextLabel")
playerNameLabel.Name = "PlayerName"
playerNameLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
playerNameLabel.Position = UDim2.new(0.1, 0, 0.65, 0)
playerNameLabel.BackgroundTransparency = 1
playerNameLabel.Font = Enum.Font.Gotham
playerNameLabel.Text = "PlayerName"
playerNameLabel.TextColor3 = Color3.new(1, 1, 1)
playerNameLabel.TextScaled = true
playerNameLabel.Parent = winnerFrame

-- Create congratulations text
local congratsLabel = Instance.new("TextLabel")
congratsLabel.Name = "CongratsText"
congratsLabel.Size = UDim2.new(0.7, 0, 0.1, 0)
congratsLabel.Position = UDim2.new(0.15, 0, 0.88, 0)
congratsLabel.BackgroundTransparency = 1
congratsLabel.Font = Enum.Font.Gotham
congratsLabel.Text = "Congratulations on your victory!"
congratsLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
congratsLabel.TextScaled = true
congratsLabel.Parent = winnerFrame

-- Create victory sound
local victorySound = Instance.new("Sound")
victorySound.SoundId = soundConfig.Victory.SoundId
victorySound.Volume = soundConfig.Victory.Volume
victorySound.Pitch = soundConfig.Victory.Pitch
victorySound.Parent = SoundService

-- Get RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local announceWinnerRemote = remoteEvents:WaitForChild("AnnounceWinner")

-- Animation functions
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

-- Create particle effect
local function createConfetti()
	-- Create confetti particles
	for i = 1, 50 do
		task.spawn(function()
			local confetti = Instance.new("Frame")
			confetti.Size = UDim2.new(0, math.random(10, 20), 0, math.random(10, 20))
			confetti.Position = UDim2.new(math.random(), 0, -0.1, 0)
			confetti.BackgroundColor3 = Color3.fromHSV(math.random(), 0.8, 1)
			confetti.BorderSizePixel = 0
			confetti.Parent = bgFrame
			
			-- Random rotation
			confetti.Rotation = math.random(0, 360)
			
			-- Fall animation
			local fallTime = math.random(3, 5)
			local endY = 1.1
			local swayX = math.random(-50, 50) / 100
			
			tweenElement(confetti, {
				Position = UDim2.new(confetti.Position.X.Scale + swayX, 0, endY, 0),
				Rotation = confetti.Rotation + math.random(180, 720)
			}, fallTime).Completed:Connect(function()
				confetti:Destroy()
			end)
		end)
	end
end

-- Show winner announcement
local function announceWinner(winnerPlayer)
	print("[WinnerUI] Announcing winner:", winnerPlayer.Name)
	
	-- Update player name
	playerNameLabel.Text = winnerPlayer.Name
	
	-- Check if local player won
	if winnerPlayer == player then
		winnerText.Text = "YOU WIN!"
		playerNameLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		winnerText.Text = "WINNER!"
		playerNameLabel.TextColor3 = Color3.new(1, 1, 1)
	end
	
	-- Show UI
	bgFrame.Visible = true
	bgFrame.BackgroundTransparency = 1
	winnerFrame.Size = UDim2.new(0.4, 0, 0.3, 0)
	winnerFrame.Position = UDim2.new(0.3, 0, 0.35, 0)
	crownLabel.Rotation = -15
	
	-- Play victory sound
	victorySound:Play()
	
	-- Fade in background
	tweenElement(bgFrame, {BackgroundTransparency = 0.5}, 0.5)
	
	-- Animate winner frame
	tweenElement(winnerFrame, {
		Size = UDim2.new(0.5, 0, 0.4, 0),
		Position = UDim2.new(0.25, 0, 0.3, 0)
	}, 0.5)
	
	-- Animate crown
	local crownTween = tweenElement(crownLabel, {Rotation = 15}, 0.5)
	crownTween.Completed:Connect(function()
		-- Crown wobble animation
		while bgFrame.Visible do
			tweenElement(crownLabel, {Rotation = -15}, 1)
			task.wait(1)
			tweenElement(crownLabel, {Rotation = 15}, 1)
			task.wait(1)
		end
	end)
	
	-- Create confetti after a short delay
	task.wait(0.5)
	createConfetti()
	
	-- Repeat confetti every 2 seconds
	task.spawn(function()
		while bgFrame.Visible do
			task.wait(2)
			if bgFrame.Visible then
				createConfetti()
			end
		end
	end)
	
	-- Hide after 10 seconds
	task.wait(10)
	tweenElement(bgFrame, {BackgroundTransparency = 1}, 1).Completed:Connect(function()
		bgFrame.Visible = false
	end)
end

-- Connect to remote event
announceWinnerRemote.OnClientEvent:Connect(announceWinner)

-- Hide initially
bgFrame.Visible = false

print("[WinnerUI] Winner UI initialized")