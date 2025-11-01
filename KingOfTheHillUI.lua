-- King of the Hill UI Script
-- Place this as a LocalScript in StarterPlayer > StarterPlayerScripts

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
	warn("[KING UI] Could not find RemoteEvents!")
	return
end

print("[KING UI] Loaded successfully")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KingOfTheHillUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main Frame (Container for king display) - COMPACT DESIGN
local mainFrame = Instance.new("Frame")
mainFrame.Name = "KingDisplay"
mainFrame.AnchorPoint = Vector2.new(0.5, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0, -100) -- Start off-screen
mainFrame.Size = UDim2.new(0, 420, 0, 85) -- More compact (420x85)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false -- START HIDDEN
mainFrame.ClipsDescendants = false -- Allow progress bar to extend below
mainFrame.Parent = screenGui

-- Add UICorner for rounded edges
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

-- Add subtle shadow/glow effect
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 150, 255)
mainStroke.Thickness = 2
mainStroke.Transparency = 0.5
mainStroke.Parent = mainFrame

-- Player Avatar Image (compact size)
local avatarImage = Instance.new("ImageLabel")
avatarImage.Name = "Avatar"
avatarImage.Position = UDim2.new(0, 10, 0, 10)
avatarImage.Size = UDim2.new(0, 65, 0, 65) -- Smaller avatar
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

-- Text container (next to avatar)
local textContainer = Instance.new("Frame")
textContainer.Name = "TextContainer"
textContainer.Position = UDim2.new(0, 85, 0, 8)
textContainer.Size = UDim2.new(0, 240, 0, 50)
textContainer.BackgroundTransparency = 1
textContainer.Parent = mainFrame

-- Player Name Label
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

-- Status Label
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

-- Timer Text (top right corner)
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

-- Progress Bar Background (extends slightly below the main frame)
local progressBg = Instance.new("Frame")
progressBg.Name = "ProgressBackground"
progressBg.Position = UDim2.new(0, 10, 1, 2) -- Extends 2px below the frame
progressBg.Size = UDim2.new(1, -20, 0, 6) -- Inset from sides
progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
progressBg.BackgroundTransparency = 0.4
progressBg.BorderSizePixel = 0
progressBg.ClipsDescendants = true -- Clips progress bar to rounded corners
progressBg.ZIndex = 2 -- Above main frame
progressBg.Parent = mainFrame

-- Rounded corners for smooth look
local progressBgCorner = Instance.new("UICorner")
progressBgCorner.CornerRadius = UDim.new(1, 0) -- Fully rounded pill shape
progressBgCorner.Parent = progressBg

-- Progress Bar Fill (starts from left to right)
local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressFill"
progressBar.Position = UDim2.new(0, 0, 0, 0)
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(100, 180, 255) -- Nice blue
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg

-- Rounded corners for the fill
local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(1, 0) -- Fully rounded pill shape
progressCorner.Parent = progressBar

-- Add subtle darkening gradient (left to right - slight darkening)
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 180, 255)), -- Start: Light blue
	ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 140, 220))   -- End: Slightly darker blue
}
gradient.Rotation = 0 -- Horizontal gradient
gradient.Parent = progressBar

-- Winner Announcement Frame (Top of screen, wider design)
local winnerFrame = Instance.new("Frame")
winnerFrame.Name = "WinnerAnnouncement"
winnerFrame.AnchorPoint = Vector2.new(0.5, 0)
winnerFrame.Position = UDim2.new(0.5, 0, 0, -120) -- Start off-screen at top
winnerFrame.Size = UDim2.new(0, 550, 0, 100) -- Wider, similar height to king display
winnerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
winnerFrame.BackgroundTransparency = 0.12 -- Slightly less transparent for emphasis
winnerFrame.BorderSizePixel = 0
winnerFrame.Visible = false
winnerFrame.Parent = screenGui

local winnerCorner = Instance.new("UICorner")
winnerCorner.CornerRadius = UDim.new(0, 16)
winnerCorner.Parent = winnerFrame

-- Blue stroke to match king display
local winnerStroke = Instance.new("UIStroke")
winnerStroke.Color = Color3.fromRGB(100, 180, 255)
winnerStroke.Thickness = 2.5
winnerStroke.Transparency = 0.3
winnerStroke.Parent = winnerFrame

-- Winner Avatar Image
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

-- Winner Label (simple "WINNER" text)
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

-- Winner Player Name (prominent)
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

-- Winner Subtitle
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

-- Animation functions
local currentTween = nil

local function showKingDisplay()
	mainFrame.Visible = true
	if currentTween then currentTween:Cancel() end
	currentTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0, 20)}
	)
	currentTween:Play()
	print("[KING UI] Showing king display")
end

local function hideKingDisplay()
	if currentTween then currentTween:Cancel() end
	currentTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, 0, 0, -100)} -- Updated for new height
	)
	currentTween:Play()
	currentTween.Completed:Connect(function()
		mainFrame.Visible = false
	end)
	print("[KING UI] Hiding king display")
end

-- Track last progress to make animation smoother
local lastProgress = 0

local function updateProgressBar(timeRemaining, totalTime)
	local progress = (totalTime - timeRemaining) / totalTime
	
	-- Calculate smooth interpolation time based on progress change
	local progressDelta = math.abs(progress - lastProgress)
	local tweenTime = math.max(0.08, progressDelta * 0.5) -- Adaptive tween time
	
	-- Ultra smooth progress animation
	local progressTween = TweenService:Create(
		progressBar,
		TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{Size = UDim2.new(progress, 0, 1, 0)}
	)
	progressTween:Play()
	
	lastProgress = progress
	
	-- Update timer text with smooth formatting
	timerText.Text = string.format("%.1fs", math.max(0, timeRemaining))
	
	-- Subtle darkening as progress increases (stays blue, just gets slightly darker)
	local baseBlue = 100
	local baseBrightness = 180
	local baseBlue2 = 255
	
	-- Calculate darkening factor (0 to 0.25 max darkening)
	local darkenAmount = progress * 0.2
	
	-- Update gradient colors to gradually darken smoothly
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(
			math.floor(baseBlue * (1 - darkenAmount)),
			math.floor(baseBrightness * (1 - darkenAmount)),
			math.floor(baseBlue2 * (1 - darkenAmount * 0.5))
		)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(
			math.floor(70 * (1 - darkenAmount * 1.1)),
			math.floor(140 * (1 - darkenAmount * 1.1)),
			math.floor(220 * (1 - darkenAmount * 0.6))
		))
	}
end

-- Handle king update from server
updateKingEvent.OnClientEvent:Connect(function(kingPlayer, timeRemaining, totalTime)
	print("[KING UI] Received update - King:", kingPlayer and kingPlayer.Name or "nil", "Time:", timeRemaining)
	
	if kingPlayer then
		-- Show the king display
		nameLabel.Text = kingPlayer.Name
		
		-- Get player avatar (with error handling)
		local success, thumbnail = pcall(function()
			return Players:GetUserThumbnailAsync(kingPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		
		if success then
			avatarImage.Image = thumbnail
		else
			warn("[KING UI] Failed to load avatar for", kingPlayer.Name)
			avatarImage.Image = ""
		end
		
		-- Update progress bar
		updateProgressBar(timeRemaining, totalTime)
		
		-- Show the frame
		showKingDisplay()
	else
		-- Hide the king display
		hideKingDisplay()
	end
end)

-- Handle winner announcement
winnerEvent.OnClientEvent:Connect(function(winner)
	if winner then
		print("[KING UI] Winner announced:", winner.Name)
		
		-- Hide king display first
		hideKingDisplay()
		
		-- Set winner text
		winnerPlayerName.Text = winner.Name
		
		-- Load winner's avatar
		local success, thumbnail = pcall(function()
			return Players:GetUserThumbnailAsync(winner.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		
		if success then
			winnerAvatar.Image = thumbnail
		else
			warn("[KING UI] Failed to load winner avatar for", winner.Name)
			winnerAvatar.Image = ""
		end
		
		-- Show winner frame (slide down animation)
		winnerFrame.Visible = true
		
		local slideDown = TweenService:Create(
			winnerFrame,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Position = UDim2.new(0.5, 0, 0, 30)}
		)
		slideDown:Play()
		
		-- Wait to display
		task.wait(4)
		
		-- Slide back up
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

print("[KING UI] Ready!")
