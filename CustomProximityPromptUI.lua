--[[
	CUSTOM PROXIMITY PROMPT UI
	Place this LocalScript in StarterPlayerScripts
	
	Creates a modern, hologram-style UI for ProximityPrompts
	
	Note: This UI is purely visual. The ProximityPrompt handles all triggering.
	When the player presses E (or the gamepad/touch equivalent), the
	ProximityPrompt.Triggered event fires as normal on the server.
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
	BackgroundColor = Color3.fromRGB(10, 10, 10), -- Dark background
	TitleBackgroundColor = Color3.fromRGB(5, 5, 5), -- Darker for title section
	TextColor = Color3.fromRGB(255, 255, 255), -- White text
	KeyBackgroundColor = Color3.fromRGB(50, 50, 50), -- Gray for key button
	BorderColor = Color3.fromRGB(200, 200, 200), -- Light gray border

	-- Transparency
	BackgroundTransparency = 0.8, -- More transparent (as requested)
	TitleBackgroundTransparency = 0.6, -- Less transparent for title section
	KeyBackgroundTransparency = 0.3,
	BorderTransparency = 0.4,

	-- Sizes
	ContainerSize = UDim2.new(0, 200, 0, 80), -- Slightly taller for spacing
	CornerRadius = 10, -- Nice rounded corners

	-- Animation
	FadeInTime = 0.25, -- Smooth fade in

	-- Text
	TitleTextSize = 15, -- "Relic" text size
	ActionTextSize = 13, -- "Open" text size
	KeyTextSize = 13, -- "E" text size

	-- Spacing
	Padding = 14, -- More internal padding
	Spacing = 10, -- More space between elements
	TitlePadding = 10, -- Padding inside title section
}

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Get the input key as a string (e.g., "E", "ButtonX")
local function getKeyString(inputType)
	-- Handle ProximityPromptInputType enum
	if inputType == Enum.ProximityPromptInputType.Keyboard then
		return "E"
	elseif inputType == Enum.ProximityPromptInputType.Gamepad then
		return "X" -- Xbox button
	elseif inputType == Enum.ProximityPromptInputType.Touch then
		return "TAP"
	end

	-- Fallback
	return "E"
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
	container.Size = UDim2.new(0, 200, 0, 90)
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

	-- Border
	local stroke = Instance.new("UIStroke")
	stroke.Color = UI_SETTINGS.BorderColor
	stroke.Thickness = 1.5
	stroke.Transparency = UI_SETTINGS.BorderTransparency
	stroke.Parent = background

	-- Title section with darker background
	local titleSection = Instance.new("Frame")
	titleSection.Name = "TitleSection"
	titleSection.Size = UDim2.new(1, 0, 0, 36)
	titleSection.Position = UDim2.new(0, 0, 0, 0)
	titleSection.BackgroundColor3 = UI_SETTINGS.TitleBackgroundColor
	titleSection.BackgroundTransparency = UI_SETTINGS.TitleBackgroundTransparency
	titleSection.BorderSizePixel = 0
	titleSection.Parent = background

	-- Rounded corners for title section (only top corners)
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, UI_SETTINGS.CornerRadius)
	titleCorner.Parent = titleSection

	-- Title padding
	local titlePadding = Instance.new("UIPadding")
	titlePadding.PaddingTop = UDim.new(0, UI_SETTINGS.TitlePadding)
	titlePadding.PaddingBottom = UDim.new(0, UI_SETTINGS.TitlePadding)
	titlePadding.PaddingLeft = UDim.new(0, UI_SETTINGS.TitlePadding)
	titlePadding.PaddingRight = UDim.new(0, UI_SETTINGS.TitlePadding)
	titlePadding.Parent = titleSection

	-- Title text ("Relic | ¥ 250")
	local titleText = Instance.new("TextLabel")
	titleText.Name = "TitleText"
	titleText.Size = UDim2.new(1, 0, 1, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = prompt.ObjectText .. " | ¥ 250"
	titleText.TextColor3 = UI_SETTINGS.TextColor
	titleText.TextSize = UI_SETTINGS.TitleTextSize
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Center
	titleText.TextYAlignment = Enum.TextYAlignment.Center
	titleText.Parent = titleSection

	-- Bottom section (key + action)
	local actionContainer = Instance.new("Frame")
	actionContainer.Name = "ActionContainer"
	actionContainer.Size = UDim2.new(1, -28, 0, 26) -- Account for padding
	actionContainer.Position = UDim2.new(0, 14, 0, 46) -- Position below title with spacing
	actionContainer.BackgroundTransparency = 1
	actionContainer.Parent = background

	local actionLayout = Instance.new("UIListLayout")
	actionLayout.FillDirection = Enum.FillDirection.Horizontal
	actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	actionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	actionLayout.Padding = UDim.new(0, 8)
	actionLayout.Parent = actionContainer

	-- Key display (E) - Visual only, ProximityPrompt handles the actual trigger
	local keyLabel = Instance.new("TextLabel")
	keyLabel.Name = "KeyLabel"
	keyLabel.Size = UDim2.new(0, 30, 0, 26)
	keyLabel.BackgroundColor3 = UI_SETTINGS.KeyBackgroundColor
	keyLabel.BackgroundTransparency = UI_SETTINGS.KeyBackgroundTransparency
	keyLabel.BorderSizePixel = 0
	keyLabel.LayoutOrder = 1
	keyLabel.Text = getKeyString(inputType)
	keyLabel.TextColor3 = UI_SETTINGS.TextColor
	keyLabel.TextSize = UI_SETTINGS.KeyTextSize
	keyLabel.Font = Enum.Font.GothamBold
	keyLabel.Parent = actionContainer

	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 5)
	keyCorner.Parent = keyLabel

	local keyStroke = Instance.new("UIStroke")
	keyStroke.Color = UI_SETTINGS.BorderColor
	keyStroke.Thickness = 1.5
	keyStroke.Transparency = UI_SETTINGS.BorderTransparency
	keyStroke.Parent = keyLabel

	-- Action text ("Open")
	local actionText = Instance.new("TextLabel")
	actionText.Name = "ActionText"
	actionText.AutomaticSize = Enum.AutomaticSize.X
	actionText.Size = UDim2.new(0, 0, 0, 26)
	actionText.BackgroundTransparency = 1
	actionText.Text = prompt.ActionText
	actionText.TextColor3 = UI_SETTINGS.TextColor
	actionText.TextSize = UI_SETTINGS.ActionTextSize
	actionText.Font = Enum.Font.GothamMedium
	actionText.TextXAlignment = Enum.TextXAlignment.Left
	actionText.LayoutOrder = 2
	actionText.Parent = actionContainer

	-- Fade in animation
	background.BackgroundTransparency = 1
	stroke.Transparency = 1
	titleSection.BackgroundTransparency = 1
	titleText.TextTransparency = 1
	keyLabel.BackgroundTransparency = 1
	keyLabel.TextTransparency = 1
	keyStroke.Transparency = 1
	actionText.TextTransparency = 1

	local tweenInfo = TweenInfo.new(UI_SETTINGS.FadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	TweenService:Create(background, tweenInfo, {BackgroundTransparency = UI_SETTINGS.BackgroundTransparency}):Play()
	TweenService:Create(stroke, tweenInfo, {Transparency = UI_SETTINGS.BorderTransparency}):Play()
	TweenService:Create(titleSection, tweenInfo, {BackgroundTransparency = UI_SETTINGS.TitleBackgroundTransparency}):Play()
	TweenService:Create(titleText, tweenInfo, {TextTransparency = 0}):Play()
	TweenService:Create(keyLabel, tweenInfo, {BackgroundTransparency = UI_SETTINGS.KeyBackgroundTransparency, TextTransparency = 0}):Play()
	TweenService:Create(keyStroke, tweenInfo, {Transparency = UI_SETTINGS.BorderTransparency}):Play()
	TweenService:Create(actionText, tweenInfo, {TextTransparency = 0}):Play()

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
