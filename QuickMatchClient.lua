-- QuickMatchClient.lua
-- Client-side quick match button handler
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Wait for UI and RemoteFunction
local playerGui = player:WaitForChild("PlayerGui")
local quickMatchUI = playerGui:WaitForChild("QuickMatchUI")
local quickMatchBtn = quickMatchUI:WaitForChild("QuickMatchBtn")
local quickMatchRemote = ReplicatedStorage:WaitForChild("QuickMatchFunction")

-- UI feedback elements (create if they don't exist)
local feedbackLabel = quickMatchUI:FindFirstChild("FeedbackLabel")
if not feedbackLabel then
	feedbackLabel = Instance.new("TextLabel")
	feedbackLabel.Name = "FeedbackLabel"
	feedbackLabel.Size = UDim2.new(0.8, 0, 0, 30)
	feedbackLabel.Position = UDim2.new(0.1, 0, 1, 10)
	feedbackLabel.BackgroundTransparency = 1
	feedbackLabel.TextScaled = true
	feedbackLabel.Font = Enum.Font.SourceSansBold
	feedbackLabel.TextColor3 = Color3.new(1, 1, 1)
	feedbackLabel.Text = ""
	feedbackLabel.Parent = quickMatchUI
end

-- Cooldown tracking
local isOnCooldown = false
local COOLDOWN_TIME = 2 -- seconds

-- Show feedback message
local function showFeedback(message, isSuccess)
	feedbackLabel.Text = message
	feedbackLabel.TextColor3 = isSuccess and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
	
	-- Fade in
	feedbackLabel.TextTransparency = 1
	local fadeIn = TweenService:Create(feedbackLabel, 
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)
	fadeIn:Play()
	
	-- Fade out after delay
	wait(2)
	local fadeOut = TweenService:Create(feedbackLabel,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{TextTransparency = 1}
	)
	fadeOut:Play()
end

-- Handle button click
quickMatchBtn.MouseButton1Click:Connect(function()
	if isOnCooldown then
		showFeedback("Please wait before trying again...", false)
		return
	end
	
	-- Set cooldown
	isOnCooldown = true
	
	-- Visual feedback
	local originalText = quickMatchBtn.Text
	quickMatchBtn.Text = "Finding match..."
	
	-- Request quick match
	local result = quickMatchRemote:InvokeServer()
	
	-- Reset button text
	quickMatchBtn.Text = originalText
	
	-- Show result
	if result then
		showFeedback(result.message, result.success)
		
		if result.success then
			-- Optional: Add success sound or animation
			-- Play a success sound if you have one
		end
	else
		showFeedback("Connection error! Please try again.", false)
	end
	
	-- Reset cooldown
	wait(COOLDOWN_TIME)
	isOnCooldown = false
end)

-- Optional: Add hover effects
quickMatchBtn.MouseEnter:Connect(function()
	if not isOnCooldown then
		TweenService:Create(quickMatchBtn,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(100, 255, 100)}
		):Play()
	end
end)

quickMatchBtn.MouseLeave:Connect(function()
	TweenService:Create(quickMatchBtn,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundColor3 = Color3.fromRGB(255, 255, 255)}
	):Play()
end)

print("[QuickMatch] Client initialized")