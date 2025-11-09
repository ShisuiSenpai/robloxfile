--[[
	CUSTOM PROXIMITY PROMPT UI
	Place this LocalScript in StarterPlayerScripts
	
	Creates a modern, hologram-style UI for ProximityPrompts
]]

local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ========================================
-- UI SETTINGS (CUSTOMIZE HERE)
-- ========================================

local UI_SETTINGS = {
	-- Colors (Simple black and white)
	BackgroundColor = Color3.fromRGB(0, 0, 0), -- Black background
	TextColor = Color3.fromRGB(255, 255, 255), -- White text
	KeyBackgroundColor = Color3.fromRGB(40, 40, 40), -- Dark gray for key button
	
	-- Transparency
	BackgroundTransparency = 0.4, -- Semi-transparent
	KeyBackgroundTransparency = 0.3,
	
	-- Sizes
	ContainerSize = UDim2.new(0, 200, 0, 65), -- Smaller, cleaner size
	CornerRadius = 8, -- Subtle rounded corners
	
	-- Animation
	FadeInTime = 0.2, -- Quick fade in
	
	-- Text
	TitleTextSize = 16, -- "Relic" text size
	ActionTextSize = 14, -- "Open" text size
	KeyTextSize = 14, -- "E" text size
}

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Get the input key as a string (e.g., "E", "ButtonX")
local function getKeyString(keycode)
	local inputString = UserInputService:GetStringForKeyCode(keycode)
	
	-- Handle gamepad buttons
	if inputString == "" then
		inputString = string.gsub(tostring(keycode), "Enum.KeyCode.", "")
	end
	
	-- Shorten common inputs
	if inputString == "ButtonX" then return "X" end
	if inputString == "ButtonA" then return "A" end
	if inputString == "ButtonB" then return "B" end
	if inputString == "ButtonY" then return "Y" end
	
	return inputString
end

-- ========================================
-- UI CREATION
-- ========================================

-- Create custom UI for a proximity prompt
local function createCustomUI(prompt, inputType, gamepadKeyCode)
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ProximityPromptUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10
	screenGui.Parent = playerGui
	
	-- Create main container (follows the prompt in 3D space)
	local container = Instance.new("BillboardGui")
	container.Name = "PromptContainer"
	container.Adornee = prompt.Parent
	container.Size = UDim2.new(0, 220, 0, 80)
	container.StudsOffset = Vector3.new(0, 2.5, 0) -- Height above the part
	container.AlwaysOnTop = true -- Always visible
	container.Parent = screenGui
	
	-- Background frame
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UI_SETTINGS.ContainerSize
	background.Position = UDim2.new(0.5, 0, 0.5, 0)
	background.AnchorPoint = Vector2.new(0.5, 0.5)
	background.BackgroundColor3 = UI_SETTINGS.BackgroundColor
	background.BackgroundTransparency = UI_SETTINGS.BackgroundTransparency
	background.BorderSizePixel = 0
	background.Parent = container
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UI_SETTINGS.CornerRadius)
	corner.Parent = background
	
	-- Subtle white border
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 1
	stroke.Transparency = 0.7
	stroke.Parent = background
	
	-- Title text ("Relic")
	local titleText = Instance.new("TextLabel")
	titleText.Name = "TitleText"
	titleText.Size = UDim2.new(1, -20, 0, 22)
	titleText.Position = UDim2.new(0, 10, 0, 8)
	titleText.BackgroundTransparency = 1
	titleText.Text = prompt.ObjectText
	titleText.TextColor3 = UI_SETTINGS.TextColor
	titleText.TextSize = UI_SETTINGS.TitleTextSize
	titleText.Font = Enum.Font.GothamMedium
	titleText.TextXAlignment = Enum.TextXAlignment.Center
	titleText.Parent = background
	
	-- Bottom section with key + action
	local bottomContainer = Instance.new("Frame")
	bottomContainer.Name = "BottomContainer"
	bottomContainer.Size = UDim2.new(1, 0, 0, 25)
	bottomContainer.Position = UDim2.new(0, 0, 1, -32)
	bottomContainer.BackgroundTransparency = 1
	bottomContainer.Parent = background
	
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = bottomContainer
	
	-- Key button (E)
	local keyButton = Instance.new("Frame")
	keyButton.Name = "KeyButton"
	keyButton.Size = UDim2.new(0, 28, 0, 24)
	keyButton.BackgroundColor3 = UI_SETTINGS.KeyBackgroundColor
	keyButton.BackgroundTransparency = UI_SETTINGS.KeyBackgroundTransparency
	keyButton.BorderSizePixel = 0
	keyButton.LayoutOrder = 1
	keyButton.Parent = bottomContainer
	
	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 4)
	keyCorner.Parent = keyButton
	
	local keyStroke = Instance.new("UIStroke")
	keyStroke.Color = Color3.fromRGB(255, 255, 255)
	keyStroke.Thickness = 1
	keyStroke.Transparency = 0.6
	keyStroke.Parent = keyButton
	
	local keyLabel = Instance.new("TextLabel")
	keyLabel.Size = UDim2.new(1, 0, 1, 0)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Text = getKeyString(inputType)
	keyLabel.TextColor3 = UI_SETTINGS.TextColor
	keyLabel.TextSize = UI_SETTINGS.KeyTextSize
	keyLabel.Font = Enum.Font.GothamBold
	keyLabel.Parent = keyButton
	
	-- Action text ("Open")
	local actionText = Instance.new("TextLabel")
	actionText.Name = "ActionText"
	actionText.Size = UDim2.new(0, 80, 0, 24)
	actionText.BackgroundTransparency = 1
	actionText.Text = prompt.ActionText
	actionText.TextColor3 = UI_SETTINGS.TextColor
	actionText.TextSize = UI_SETTINGS.ActionTextSize
	actionText.Font = Enum.Font.Gotham
	actionText.TextXAlignment = Enum.TextXAlignment.Left
	actionText.LayoutOrder = 2
	actionText.Parent = bottomContainer
	
	-- Fade in animation
	background.BackgroundTransparency = 1
	stroke.Transparency = 1
	titleText.TextTransparency = 1
	keyButton.BackgroundTransparency = 1
	keyStroke.Transparency = 1
	keyLabel.TextTransparency = 1
	actionText.TextTransparency = 1
	
	local fadeIn = TweenService:Create(
		background,
		TweenInfo.new(UI_SETTINGS.FadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = UI_SETTINGS.BackgroundTransparency}
	)
	local strokeFade = TweenService:Create(stroke, TweenInfo.new(UI_SETTINGS.FadeInTime), {Transparency = 0.7})
	local titleFade = TweenService:Create(titleText, TweenInfo.new(UI_SETTINGS.FadeInTime), {TextTransparency = 0})
	local keyBgFade = TweenService:Create(keyButton, TweenInfo.new(UI_SETTINGS.FadeInTime), {BackgroundTransparency = UI_SETTINGS.KeyBackgroundTransparency})
	local keyStrokeFade = TweenService:Create(keyStroke, TweenInfo.new(UI_SETTINGS.FadeInTime), {Transparency = 0.6})
	local keyTextFade = TweenService:Create(keyLabel, TweenInfo.new(UI_SETTINGS.FadeInTime), {TextTransparency = 0})
	local actionFade = TweenService:Create(actionText, TweenInfo.new(UI_SETTINGS.FadeInTime), {TextTransparency = 0})
	
	fadeIn:Play()
	strokeFade:Play()
	titleFade:Play()
	keyBgFade:Play()
	keyStrokeFade:Play()
	keyTextFade:Play()
	actionFade:Play()
	
	return screenGui
end

-- ========================================
-- PROXIMITY PROMPT SERVICE SETUP
-- ========================================

-- Track active custom UIs
local activePrompts = {}

-- Create custom UI when prompt is shown
ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
	-- Only customize prompts with Style = Custom
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then 
		return 
	end
	
	-- Don't create duplicate UIs
	if activePrompts[prompt] then 
		return 
	end
	
	-- Create custom UI
	local customUI = createCustomUI(prompt, inputType)
	activePrompts[prompt] = customUI
	
	-- Cleanup when prompt is hidden
	local connection
	connection = ProximityPromptService.PromptHidden:Connect(function(hiddenPrompt)
		if hiddenPrompt == prompt then
			if activePrompts[prompt] then
				activePrompts[prompt]:Destroy()
				activePrompts[prompt] = nil
			end
			connection:Disconnect()
		end
	end)
end)

-- Also handle prompt button hold progress (optional - for hold duration)
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then return end
	-- You can add a progress bar animation here if needed
end)

ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then return end
	-- Reset progress bar if you added one
end)
