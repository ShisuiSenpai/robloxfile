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

-- Main Frame (Container for king display) - WIDER DESIGN
local mainFrame = Instance.new("Frame")
mainFrame.Name = "KingDisplay"
mainFrame.AnchorPoint = Vector2.new(0.5, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0, -120) -- Start off-screen
mainFrame.Size = UDim2.new(0, 500, 0, 100) -- Wider (500x100 instead of 400x140)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false -- START HIDDEN
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

-- Player Avatar Image (slightly smaller for wider design)
local avatarImage = Instance.new("ImageLabel")
avatarImage.Name = "Avatar"
avatarImage.Position = UDim2.new(0, 12, 0, 12)
avatarImage.Size = UDim2.new(0, 76, 0, 76) -- Fits in the 100px height
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
textContainer.Position = UDim2.new(0, 100, 0, 10)
textContainer.Size = UDim2.new(0, 280, 0, 60)
textContainer.BackgroundTransparency = 1
textContainer.Parent = mainFrame

-- Player Name Label
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "PlayerName"
nameLabel.Position = UDim2.new(0, 0, 0, 0)
nameLabel.Size = UDim2.new(1, 0, 0, 28)
nameLabel.BackgroundTransparency = 1
nameLabel.Font = Enum.Font.GothamBold
nameLabel.Text = ""
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.TextSize = 20
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.TextYAlignment = Enum.TextYAlignment.Top
nameLabel.Parent = textContainer

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Position = UDim2.new(0, 0, 0, 32)
statusLabel.Size = UDim2.new(1, 0, 0, 18)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "is the King of the Pyramid"
statusLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = textContainer

-- Timer Text (top right corner)
local timerText = Instance.new("TextLabel")
timerText.Name = "TimerText"
timerText.Position = UDim2.new(1, -70, 0, 10)
timerText.Size = UDim2.new(0, 60, 0, 30)
timerText.BackgroundTransparency = 1
timerText.Font = Enum.Font.GothamBold
timerText.Text = "5.0s"
timerText.TextColor3 = Color3.fromRGB(255, 255, 255)
timerText.TextSize = 24
timerText.TextXAlignment = Enum.TextXAlignment.Right
timerText.Parent = mainFrame

-- Progress Bar Background (horizontal at bottom)
local progressBg = Instance.new("Frame")
progressBg.Name = "ProgressBackground"
progressBg.Position = UDim2.new(0, 12, 1, -18)
progressBg.Size = UDim2.new(1, -24, 0, 6) -- Thin horizontal bar
progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
progressBg.BackgroundTransparency = 0.4
progressBg.BorderSizePixel = 0
progressBg.Parent = mainFrame

local progressBgCorner = Instance.new("UICorner")
progressBgCorner.CornerRadius = UDim.new(1, 0) -- Fully rounded ends
progressBgCorner.Parent = progressBg

-- Progress Bar Fill (starts from left to right)
local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressFill"
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(100, 180, 255) -- Nice blue
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(1, 0) -- Fully rounded ends
progressCorner.Parent = progressBar

-- Add subtle darkening gradient (left to right - slight darkening)
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 180, 255)), -- Start: Light blue
	ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 140, 220))   -- End: Slightly darker blue
}
gradient.Rotation = 0 -- Horizontal gradient
gradient.Parent = progressBar

-- Winner Announcement Frame
local winnerFrame = Instance.new("Frame")
winnerFrame.Name = "WinnerAnnouncement"
winnerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
winnerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
winnerFrame.Size = UDim2.new(0, 500, 0, 200)
winnerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
winnerFrame.BackgroundTransparency = 1
winnerFrame.BorderSizePixel = 0
winnerFrame.Visible = false
winnerFrame.Parent = screenGui

local winnerCorner = Instance.new("UICorner")
winnerCorner.CornerRadius = UDim.new(0, 20)
winnerCorner.Parent = winnerFrame

local winnerStroke = Instance.new("UIStroke")
winnerStroke.Color = Color3.fromRGB(255, 215, 0)
winnerStroke.Thickness = 3
winnerStroke.Transparency = 0.5
winnerStroke.Parent = winnerFrame

-- Winner Text
local winnerText = Instance.new("TextLabel")
winnerText.Size = UDim2.new(1, 0, 0, 60)
winnerText.Position = UDim2.new(0, 0, 0, 30)
winnerText.BackgroundTransparency = 1
winnerText.Font = Enum.Font.GothamBold
winnerText.Text = "VICTORY"
winnerText.TextColor3 = Color3.fromRGB(255, 215, 0)
winnerText.TextSize = 48
winnerText.TextStrokeTransparency = 0.8
winnerText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
winnerText.Parent = winnerFrame

-- Winner Player Name
local winnerPlayerName = Instance.new("TextLabel")
winnerPlayerName.Size = UDim2.new(1, 0, 0, 40)
winnerPlayerName.Position = UDim2.new(0, 0, 0, 100)
winnerPlayerName.BackgroundTransparency = 1
winnerPlayerName.Font = Enum.Font.GothamBold
winnerPlayerName.Text = ""
winnerPlayerName.TextColor3 = Color3.fromRGB(255, 255, 255)
winnerPlayerName.TextSize = 32
winnerPlayerName.Parent = winnerFrame

-- Winner Subtitle
local winnerSubtitle = Instance.new("TextLabel")
winnerSubtitle.Size = UDim2.new(1, 0, 0, 30)
winnerSubtitle.Position = UDim2.new(0, 0, 0, 145)
winnerSubtitle.BackgroundTransparency = 1
winnerSubtitle.Font = Enum.Font.Gotham
winnerSubtitle.Text = "conquered the pyramid!"
winnerSubtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
winnerSubtitle.TextSize = 20
winnerSubtitle.Parent = winnerFrame

-- Animation functions
local currentTween = nil

local function showKingDisplay()
	mainFrame.Visible = true
	if currentTween then currentTween:Cancel() end
	currentTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0, 20)}
	)
	currentTween:Play()
	print("[KING UI] Showing king display")
end

local function hideKingDisplay()
	if currentTween then currentTween:Cancel() end
	currentTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, 0, 0, -120)} -- Updated for new height
	)
	currentTween:Play()
	currentTween.Completed:Connect(function()
		mainFrame.Visible = false
	end)
	print("[KING UI] Hiding king display")
end

local function updateProgressBar(timeRemaining, totalTime)
	local progress = (totalTime - timeRemaining) / totalTime
	
	-- Smooth progress animation
	local progressTween = TweenService:Create(
		progressBar,
		TweenInfo.new(0.1, Enum.EasingStyle.Linear),
		{Size = UDim2.new(progress, 0, 1, 0)}
	)
	progressTween:Play()
	
	-- Update timer text
	timerText.Text = string.format("%.1fs", math.max(0, timeRemaining))
	
	-- Subtle darkening as progress increases (stays blue, just gets slightly darker)
	local baseBlue = 100
	local baseBrightness = 180
	local baseBlue2 = 255
	
	-- Calculate darkening factor (0 to 0.3 max darkening)
	local darkenAmount = progress * 0.25
	
	-- Update gradient colors to gradually darken
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(
			baseBlue * (1 - darkenAmount),
			baseBrightness * (1 - darkenAmount),
			baseBlue2 * (1 - darkenAmount * 0.5)
		)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(
			70 * (1 - darkenAmount * 1.2),
			140 * (1 - darkenAmount * 1.2),
			220 * (1 - darkenAmount * 0.7)
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
		
		-- Show winner announcement
		winnerFrame.Visible = true
		winnerFrame.BackgroundTransparency = 1
		winnerText.TextTransparency = 1
		winnerPlayerName.TextTransparency = 1
		winnerSubtitle.TextTransparency = 1
		
		-- Fade in animation
		local fadeIn = TweenService:Create(
			winnerFrame,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 0.1}
		)
		fadeIn:Play()
		
		TweenService:Create(winnerText, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
		TweenService:Create(winnerPlayerName, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
		TweenService:Create(winnerSubtitle, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
		
		-- Hide after 5 seconds
		task.wait(5)
		
		local fadeOut = TweenService:Create(
			winnerFrame,
			TweenInfo.new(0.5),
			{BackgroundTransparency = 1}
		)
		fadeOut:Play()
		
		TweenService:Create(winnerText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		TweenService:Create(winnerPlayerName, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		TweenService:Create(winnerSubtitle, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		
		fadeOut.Completed:Wait()
		winnerFrame.Visible = false
	end
end)

print("[KING UI] Ready!")
