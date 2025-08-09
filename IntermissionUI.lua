-- IntermissionUI.lua
-- Client-side script for managing the Intermission countdown UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for UI to be created
local intermissionGui = playerGui:WaitForChild("IntermissionUI", 10)
if not intermissionGui then
	-- Create the UI if it doesn't exist
	intermissionGui = Instance.new("ScreenGui")
	intermissionGui.Name = "IntermissionUI"
	intermissionGui.ResetOnSpawn = false
	intermissionGui.Parent = playerGui
	
	-- Create background frame
	local bgFrame = Instance.new("Frame")
	bgFrame.Name = "BG"
	bgFrame.Size = UDim2.new(1, 0, 1, 0)
	bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	bgFrame.BackgroundTransparency = 0.3
	bgFrame.Parent = intermissionGui
	
	-- Create countdown container
	local countdownFrame = Instance.new("Frame")
	countdownFrame.Name = "CountdownFrame"
	countdownFrame.Size = UDim2.new(0.4, 0, 0.3, 0)
	countdownFrame.Position = UDim2.new(0.3, 0, 0.35, 0)
	countdownFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	countdownFrame.BackgroundTransparency = 0
	countdownFrame.Parent = bgFrame
	
	-- Add corner rounding
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 20)
	uiCorner.Parent = countdownFrame
	
	-- Add stroke
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(100, 150, 250)
	uiStroke.Thickness = 3
	uiStroke.Parent = countdownFrame
	
	-- Create title label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(0.8, 0, 0.4, 0)
	titleLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.Gotham
	titleLabel.Text = "Game will start in"
	titleLabel.TextColor3 = Color3.fromRGB(100, 150, 250)
	titleLabel.TextScaled = true
	titleLabel.Parent = countdownFrame
	
	-- Create countdown number label
	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "CountdownLabel"
	countdownLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
	countdownLabel.Position = UDim2.new(0.2, 0, 0.5, 0)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Font = Enum.Font.GothamBold
	countdownLabel.Text = "5"
	countdownLabel.TextColor3 = Color3.fromRGB(100, 150, 250)
	countdownLabel.TextScaled = true
	countdownLabel.Parent = countdownFrame
end

-- Get UI elements
local bgFrame = intermissionGui:WaitForChild("BG")
local countdownFrame = bgFrame:WaitForChild("CountdownFrame")
local titleLabel = countdownFrame:WaitForChild("TitleLabel")
local countdownLabel = countdownFrame:WaitForChild("CountdownLabel")

-- Get RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local updateIntermissionRemote = remoteEvents:WaitForChild("UpdateIntermission")

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

-- Show/hide intermission UI
local function updateIntermission(isActive, timeLeft)
	if isActive then
		-- Show UI
		intermissionGui.Enabled = true
		bgFrame.BackgroundTransparency = 1
		countdownFrame.Size = UDim2.new(0.3, 0, 0.25, 0)
		countdownFrame.Position = UDim2.new(0.35, 0, 0.375, 0)
		
		-- Fade in background
		tweenElement(bgFrame, {BackgroundTransparency = 0.3}, 0.5)
		
		-- Animate countdown frame
		tweenElement(countdownFrame, {
			Size = UDim2.new(0.4, 0, 0.3, 0),
			Position = UDim2.new(0.3, 0, 0.35, 0)
		}, 0.5)
		
		-- Update countdown text
		countdownLabel.Text = tostring(math.max(0, timeLeft))
		
		-- Pulse effect for countdown
		if timeLeft > 0 then
			local pulseTween = tweenElement(countdownLabel, {TextTransparency = 0.2}, 0.3)
			pulseTween.Completed:Connect(function()
				tweenElement(countdownLabel, {TextTransparency = 0}, 0.3)
			end)
		end
		
		-- Change color for final seconds
		if timeLeft <= 3 then
			countdownLabel.TextColor3 = Color3.new(1, 0.5, 0)
		else
			countdownLabel.TextColor3 = Color3.fromRGB(100, 150, 250)
		end
		
	else
		-- Hide UI with animation
		tweenElement(bgFrame, {BackgroundTransparency = 1}, 0.5)
		tweenElement(countdownFrame, {
			Size = UDim2.new(0.3, 0, 0.25, 0),
			Position = UDim2.new(0.35, 0, 0.375, 0)
		}, 0.5).Completed:Connect(function()
			intermissionGui.Enabled = false
		end)
	end
end

-- Connect to remote event
updateIntermissionRemote.OnClientEvent:Connect(updateIntermission)

-- Hide initially
intermissionGui.Enabled = false

print("[IntermissionUI] Intermission UI initialized")