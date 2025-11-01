-- Round System UI (Combines King Display + Intermission)
-- Place this as a LocalScript in StarterPlayer > StarterPlayerScripts
-- REPLACES KingOfTheHillUI.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local updateKingEvent = ReplicatedStorage:WaitForChild("UpdateKing", 10)
local roundStatusEvent = ReplicatedStorage:WaitForChild("RoundStatus", 10)
local winnerEvent = ReplicatedStorage:WaitForChild("Winner", 10)

if not updateKingEvent or not roundStatusEvent or not winnerEvent then
	warn("[ROUND UI] Could not find RemoteEvents!")
	return
end

print("[ROUND UI] Loaded successfully")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoundSystemUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ==================== KING DISPLAY ====================

local mainFrame = Instance.new("Frame")
mainFrame.Name = "KingDisplay"
mainFrame.AnchorPoint = Vector2.new(0.5, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0, -100)
mainFrame.Size = UDim2.new(0, 420, 0, 85)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 150, 255)
mainStroke.Thickness = 2
mainStroke.Transparency = 0.5
mainStroke.Parent = mainFrame

local avatarImage = Instance.new("ImageLabel")
avatarImage.Name = "Avatar"
avatarImage.Position = UDim2.new(0, 10, 0, 10)
avatarImage.Size = UDim2.new(0, 65, 0, 65)
avatarImage.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
avatarImage.BackgroundTransparency = 0.3
avatarImage.BorderSizePixel = 0
avatarImage.Image = ""
avatarImage.Parent = mainFrame

local avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(0, 12)
avatarCorner.Parent = avatarImage

local avatarStroke = Instance.new("UIStroke")
avatarStroke.Color = Color3.fromRGB(100, 150, 255)
avatarStroke.Thickness = 2
avatarStroke.Transparency = 0.6
avatarStroke.Parent = avatarImage

local textContainer = Instance.new("Frame")
textContainer.Name = "TextContainer"
textContainer.Position = UDim2.new(0, 85, 0, 8)
textContainer.Size = UDim2.new(0, 240, 0, 50)
textContainer.BackgroundTransparency = 1
textContainer.Parent = mainFrame

local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "PlayerName"
nameLabel.Position = UDim2.new(0, 0, 0, 0)
nameLabel.Size = UDim2.new(1, 0, 0, 24)
nameLabel.BackgroundTransparency = 1
nameLabel.Font = Enum.Font.GothamBold
nameLabel.Text = ""
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.TextSize = 18
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.TextYAlignment = Enum.TextYAlignment.Top
nameLabel.Parent = textContainer

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Position = UDim2.new(0, 0, 0, 28)
statusLabel.Size = UDim2.new(1, 0, 0, 16)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "is the King of the Pyramid"
statusLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = textContainer

local timerText = Instance.new("TextLabel")
timerText.Name = "TimerText"
timerText.Position = UDim2.new(1, -60, 0, 8)
timerText.Size = UDim2.new(0, 50, 0, 26)
timerText.BackgroundTransparency = 1
timerText.Font = Enum.Font.GothamBold
timerText.Text = "5.0s"
timerText.TextColor3 = Color3.fromRGB(255, 255, 255)
timerText.TextSize = 22
timerText.TextXAlignment = Enum.TextXAlignment.Right
timerText.Parent = mainFrame

local progressBg = Instance.new("Frame")
progressBg.Name = "ProgressBackground"
progressBg.Position = UDim2.new(0, 10, 1, 2)
progressBg.Size = UDim2.new(1, -20, 0, 6)
progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
progressBg.BackgroundTransparency = 0.4
progressBg.BorderSizePixel = 0
progressBg.ClipsDescendants = true
progressBg.ZIndex = 2
progressBg.Parent = mainFrame

local progressBgCorner = Instance.new("UICorner")
progressBgCorner.CornerRadius = UDim.new(1, 0)
progressBgCorner.Parent = progressBg

local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressFill"
progressBar.Position = UDim2.new(0, 0, 0, 0)
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(1, 0)
progressCorner.Parent = progressBar

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 180, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 140, 220))
}
gradient.Rotation = 0
gradient.Parent = progressBar

-- ==================== INTERMISSION/STATUS DISPLAY ====================

local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusDisplay"
statusFrame.AnchorPoint = Vector2.new(0.5, 0)
statusFrame.Position = UDim2.new(0.5, 0, 0, 20)
statusFrame.Size = UDim2.new(0, 350, 0, 70)
statusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
statusFrame.BackgroundTransparency = 0.15
statusFrame.BorderSizePixel = 0
statusFrame.Visible = false
statusFrame.Parent = screenGui

-- ==================== COUNTDOWN DISPLAY ====================

local countdownFrame = Instance.new("Frame")
countdownFrame.Name = "CountdownDisplay"
countdownFrame.AnchorPoint = Vector2.new(0.5, 0.5)
countdownFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
countdownFrame.Size = UDim2.new(0, 200, 0, 200)
countdownFrame.BackgroundTransparency = 1
countdownFrame.Visible = false
countdownFrame.Parent = screenGui

local countdownNumber = Instance.new("TextLabel")
countdownNumber.Name = "CountdownNumber"
countdownNumber.Size = UDim2.new(1, 0, 1, 0)
countdownNumber.BackgroundTransparency = 1
countdownNumber.Font = Enum.Font.GothamBold
countdownNumber.Text = "3"
countdownNumber.TextColor3 = Color3.fromRGB(100, 180, 255)
countdownNumber.TextSize = 120
countdownNumber.TextStrokeTransparency = 0.5
countdownNumber.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
countdownNumber.Parent = countdownFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 14)
statusCorner.Parent = statusFrame

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Color3.fromRGB(100, 150, 255)
statusStroke.Thickness = 2
statusStroke.Transparency = 0.5
statusStroke.Parent = statusFrame

local statusTitle = Instance.new("TextLabel")
statusTitle.Name = "StatusTitle"
statusTitle.Position = UDim2.new(0, 0, 0, 12)
statusTitle.Size = UDim2.new(1, 0, 0, 24)
statusTitle.BackgroundTransparency = 1
statusTitle.Font = Enum.Font.GothamBold
statusTitle.Text = "INTERMISSION"
statusTitle.TextColor3 = Color3.fromRGB(100, 180, 255)
statusTitle.TextSize = 16
statusTitle.Parent = statusFrame

local statusSubtitle = Instance.new("TextLabel")
statusSubtitle.Name = "StatusSubtitle"
statusSubtitle.Position = UDim2.new(0, 0, 0, 40)
statusSubtitle.Size = UDim2.new(1, 0, 0, 20)
statusSubtitle.BackgroundTransparency = 1
statusSubtitle.Font = Enum.Font.Gotham
statusSubtitle.Text = "Next round in 5 seconds"
statusSubtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
statusSubtitle.TextSize = 13
statusSubtitle.Parent = statusFrame

-- ==================== WINNER ANNOUNCEMENT ====================

local winnerFrame = Instance.new("Frame")
winnerFrame.Name = "WinnerAnnouncement"
winnerFrame.AnchorPoint = Vector2.new(0.5, 0)
winnerFrame.Position = UDim2.new(0.5, 0, 0, -120)
winnerFrame.Size = UDim2.new(0, 550, 0, 100)
winnerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
winnerFrame.BackgroundTransparency = 0.12
winnerFrame.BorderSizePixel = 0
winnerFrame.Visible = false
winnerFrame.Parent = screenGui

local winnerCorner = Instance.new("UICorner")
winnerCorner.CornerRadius = UDim.new(0, 16)
winnerCorner.Parent = winnerFrame

local winnerStroke = Instance.new("UIStroke")
winnerStroke.Color = Color3.fromRGB(100, 180, 255)
winnerStroke.Thickness = 2.5
winnerStroke.Transparency = 0.3
winnerStroke.Parent = winnerFrame

local winnerAvatar = Instance.new("ImageLabel")
winnerAvatar.Name = "WinnerAvatar"
winnerAvatar.Position = UDim2.new(0, 20, 0.5, -20)
winnerAvatar.Size = UDim2.new(0, 40, 0, 40)
winnerAvatar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
winnerAvatar.BackgroundTransparency = 0.3
winnerAvatar.BorderSizePixel = 0
winnerAvatar.Image = ""
winnerAvatar.Parent = winnerFrame

local winnerAvatarCorner = Instance.new("UICorner")
winnerAvatarCorner.CornerRadius = UDim.new(0, 10)
winnerAvatarCorner.Parent = winnerAvatar

local winnerAvatarStroke = Instance.new("UIStroke")
winnerAvatarStroke.Color = Color3.fromRGB(100, 180, 255)
winnerAvatarStroke.Thickness = 2
winnerAvatarStroke.Transparency = 0.4
winnerAvatarStroke.Parent = winnerAvatar

local winnerLabel = Instance.new("TextLabel")
winnerLabel.Position = UDim2.new(0, 70, 0, 20)
winnerLabel.Size = UDim2.new(0, 100, 0, 22)
winnerLabel.BackgroundTransparency = 1
winnerLabel.Font = Enum.Font.GothamBold
winnerLabel.Text = "WINNER"
winnerLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
winnerLabel.TextSize = 14
winnerLabel.TextXAlignment = Enum.TextXAlignment.Left
winnerLabel.TextYAlignment = Enum.TextYAlignment.Center
winnerLabel.Parent = winnerFrame

local winnerPlayerName = Instance.new("TextLabel")
winnerPlayerName.Position = UDim2.new(0, 70, 0, 40)
winnerPlayerName.Size = UDim2.new(1, -90, 0, 32)
winnerPlayerName.BackgroundTransparency = 1
winnerPlayerName.Font = Enum.Font.GothamBold
winnerPlayerName.Text = ""
winnerPlayerName.TextColor3 = Color3.fromRGB(255, 255, 255)
winnerPlayerName.TextSize = 26
winnerPlayerName.TextXAlignment = Enum.TextXAlignment.Left
winnerPlayerName.TextYAlignment = Enum.TextYAlignment.Center
winnerPlayerName.Parent = winnerFrame

local winnerSubtitle = Instance.new("TextLabel")
winnerSubtitle.Position = UDim2.new(0, 70, 0, 70)
winnerSubtitle.Size = UDim2.new(1, -90, 0, 18)
winnerSubtitle.BackgroundTransparency = 1
winnerSubtitle.Font = Enum.Font.Gotham
winnerSubtitle.Text = "conquered the pyramid"
winnerSubtitle.TextColor3 = Color3.fromRGB(180, 200, 255)
winnerSubtitle.TextSize = 13
winnerSubtitle.TextXAlignment = Enum.TextXAlignment.Left
winnerSubtitle.TextYAlignment = Enum.TextYAlignment.Center
winnerSubtitle.Parent = winnerFrame

-- ==================== ANIMATION FUNCTIONS ====================

local currentTween = nil
local lastProgress = 0

local function showKingDisplay()
	mainFrame.Visible = true
	if currentTween then currentTween:Cancel() end
	currentTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0, 20)}
	)
	currentTween:Play()
end

local function hideKingDisplay()
	if currentTween then currentTween:Cancel() end
	currentTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, 0, 0, -100)}
	)
	currentTween:Play()
	currentTween.Completed:Connect(function()
		mainFrame.Visible = false
	end)
end

local currentProgressTween = nil

local function updateProgressBar(timeRemaining, totalTime)
	local progress = (totalTime - timeRemaining) / totalTime
	
	-- Cancel existing tween for smooth transition
	if currentProgressTween then
		currentProgressTween:Cancel()
	end
	
	-- Smooth liquid-like animation with consistent timing
	currentProgressTween = TweenService:Create(
		progressBar,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(progress, 0, 1, 0)}
	)
	currentProgressTween:Play()
	
	lastProgress = progress
	timerText.Text = string.format("%.1fs", math.max(0, timeRemaining))
	
	-- Subtle darkening gradient
	local darkenAmount = progress * 0.15
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(
			math.floor(100 * (1 - darkenAmount)),
			math.floor(180 * (1 - darkenAmount)),
			math.floor(255 * (1 - darkenAmount * 0.5))
		)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(
			math.floor(70 * (1 - darkenAmount * 1.2)),
			math.floor(140 * (1 - darkenAmount * 1.2)),
			math.floor(220 * (1 - darkenAmount * 0.7))
		))
	}
end

-- ==================== STATUS DISPLAY ANIMATIONS ====================

local function showStatusDisplay()
	statusFrame.Visible = true
end

local function hideStatusDisplay()
	statusFrame.Visible = false
end

-- Animated dots for "Waiting for players..."
local dotCount = 0
local dotAnimation = nil

local function startDotAnimation()
	if dotAnimation then
		dotAnimation:Disconnect()
	end
	
	dotAnimation = game:GetService("RunService").Heartbeat:Connect(function()
		dotCount = (dotCount + 1) % 40 -- Update every ~40 frames
		if dotCount == 0 then
			local dots = math.floor(tick() % 4) -- 0, 1, 2, 3
			statusSubtitle.Text = "Waiting for players" .. string.rep(".", dots)
		end
	end)
end

local function stopDotAnimation()
	if dotAnimation then
		dotAnimation:Disconnect()
		dotAnimation = nil
	end
end

-- ==================== EVENT HANDLERS ====================

-- Handle king updates
updateKingEvent.OnClientEvent:Connect(function(kingPlayer, timeRemaining, totalTime)
	if kingPlayer then
		nameLabel.Text = kingPlayer.Name
		
		local success, thumbnail = pcall(function()
			return Players:GetUserThumbnailAsync(kingPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		
		if success then
			avatarImage.Image = thumbnail
		end
		
		updateProgressBar(timeRemaining, totalTime)
		showKingDisplay()
	else
		hideKingDisplay()
	end
end)

-- Handle round status updates
roundStatusEvent.OnClientEvent:Connect(function(status, timeOrData)
	if status == "waitingForPlayers" then
		-- Show waiting message
		statusTitle.Text = "WAITING FOR PLAYERS"
		statusTitle.TextColor3 = Color3.fromRGB(255, 180, 100)
		statusSubtitle.Text = "Waiting for players..."
		startDotAnimation()
		showStatusDisplay()
		hideKingDisplay()
		countdownFrame.Visible = false
		
	elseif status == "intermission" then
		-- Show intermission with countdown
		stopDotAnimation()
		statusTitle.Text = "INTERMISSION"
		statusTitle.TextColor3 = Color3.fromRGB(100, 180, 255)
		statusSubtitle.Text = "Next round in " .. timeOrData .. " seconds"
		showStatusDisplay()
		hideKingDisplay()
		countdownFrame.Visible = false
		
		-- Countdown
		for i = timeOrData, 1, -1 do
			statusSubtitle.Text = "Next round in " .. i .. " second" .. (i == 1 and "" or "s")
			task.wait(1)
		end
		
	elseif status == "countdown" then
		-- Show countdown number (3, 2, 1)
		stopDotAnimation()
		hideStatusDisplay()
		hideKingDisplay()
		
		local number = timeOrData
		countdownNumber.Text = tostring(number)
		countdownNumber.TextColor3 = Color3.fromRGB(100, 180, 255)
		countdownNumber.TextSize = 120
		countdownFrame.Visible = true
		
		-- Pulse animation
		countdownNumber.Size = UDim2.new(0, 0, 0, 0)
		local pulseTween = TweenService:Create(
			countdownNumber,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.new(1, 0, 1, 0)}
		)
		pulseTween:Play()
		
	elseif status == "roundStart" then
		-- Show GO! and hide everything
		stopDotAnimation()
		hideStatusDisplay()
		
		-- Show GO!
		countdownNumber.Text = "GO!"
		countdownNumber.TextColor3 = Color3.fromRGB(100, 255, 150)
		countdownNumber.TextSize = 100
		countdownFrame.Visible = true
		
		-- Pulse and fade out
		countdownNumber.Size = UDim2.new(0, 0, 0, 0)
		local goTween = TweenService:Create(
			countdownNumber,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.new(1.2, 0, 1.2, 0)}
		)
		goTween:Play()
		
		task.wait(0.5)
		
		local fadeOut = TweenService:Create(
			countdownNumber,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{TextTransparency = 1, TextStrokeTransparency = 1}
		)
		fadeOut:Play()
		
		fadeOut.Completed:Wait()
		countdownFrame.Visible = false
		countdownNumber.TextTransparency = 0
		countdownNumber.TextStrokeTransparency = 0.5
	end
end)

-- Handle winner announcement
winnerEvent.OnClientEvent:Connect(function(winner)
	if winner then
		print("[ROUND UI] Winner:", winner.Name)
		
		hideKingDisplay()
		hideStatusDisplay()
		
		winnerPlayerName.Text = winner.Name
		
		local success, thumbnail = pcall(function()
			return Players:GetUserThumbnailAsync(winner.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		
		if success then
			winnerAvatar.Image = thumbnail
		end
		
		winnerFrame.Visible = true
		
		local slideDown = TweenService:Create(
			winnerFrame,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Position = UDim2.new(0.5, 0, 0, 30)}
		)
		slideDown:Play()
		
		task.wait(4)
		
		local slideUp = TweenService:Create(
			winnerFrame,
			TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{Position = UDim2.new(0.5, 0, 0, -120)}
		)
		slideUp:Play()
		
		slideUp.Completed:Wait()
		winnerFrame.Visible = false
	end
end)

print("[ROUND UI] Ready!")
