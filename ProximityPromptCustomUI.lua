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
	-- Colors
	BackgroundColor = Color3.fromRGB(20, 20, 25), -- Dark background
	AccentColor = Color3.fromRGB(138, 43, 226), -- Purple accent (hologram vibe)
	TextColor = Color3.fromRGB(255, 255, 255), -- White text
	
	-- Transparency
	BackgroundTransparency = 0.3, -- Semi-transparent background
	GlowTransparency = 0.5, -- Glow effect transparency
	
	-- Sizes
	ContainerSize = UDim2.new(0, 280, 0, 80), -- Main container size
	CornerRadius = 12, -- Rounded corners
	
	-- Animation
	FadeInTime = 0.3, -- Fade in duration
	PulseSpeed = 1.5, -- Pulse animation speed (seconds)
	
	-- Text
	ObjectTextSize = 20, -- "Relic" text size
	ActionTextSize = 16, -- "Open" text size
	KeyTextSize = 18, -- "[E]" text size
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
	container.Size = UDim2.new(0, 300, 0, 120)
	container.StudsOffset = Vector3.new(0, 3, 0) -- Height above the part
	container.AlwaysOnTop = false -- Hologram effect (can be occluded)
	container.Parent = screenGui
	
	-- Background frame with blur effect
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
	
	-- Glow effect (accent border)
	local glow = Instance.new("UIStroke")
	glow.Name = "Glow"
	glow.Color = UI_SETTINGS.AccentColor
	glow.Thickness = 2
	glow.Transparency = UI_SETTINGS.GlowTransparency
	glow.Parent = background
	
	-- Gradient overlay for depth
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
	})
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(1, 0.95),
	})
	gradient.Parent = background
	
	-- Object text ("Relic")
	local objectText = Instance.new("TextLabel")
	objectText.Name = "ObjectText"
	objectText.Size = UDim2.new(1, -20, 0, 30)
	objectText.Position = UDim2.new(0, 10, 0, 10)
	objectText.BackgroundTransparency = 1
	objectText.Text = prompt.ObjectText
	objectText.TextColor3 = UI_SETTINGS.TextColor
	objectText.TextSize = UI_SETTINGS.ObjectTextSize
	objectText.Font = Enum.Font.GothamBold
	objectText.TextXAlignment = Enum.TextXAlignment.Left
	objectText.Parent = background
	
	-- Accent line separator
	local separator = Instance.new("Frame")
	separator.Name = "Separator"
	separator.Size = UDim2.new(1, -20, 0, 2)
	separator.Position = UDim2.new(0, 10, 0, 45)
	separator.BackgroundColor3 = UI_SETTINGS.AccentColor
	separator.BackgroundTransparency = 0.3
	separator.BorderSizePixel = 0
	separator.Parent = background
	
	local sepCorner = Instance.new("UICorner")
	sepCorner.CornerRadius = UDim.new(1, 0)
	sepCorner.Parent = separator
	
	-- Action container (holds key and action text)
	local actionContainer = Instance.new("Frame")
	actionContainer.Name = "ActionContainer"
	actionContainer.Size = UDim2.new(1, -20, 0, 25)
	actionContainer.Position = UDim2.new(0, 10, 1, -35)
	actionContainer.BackgroundTransparency = 1
	actionContainer.Parent = background
	
	-- Key display ([E])
	local keyText = Instance.new("TextLabel")
	keyText.Name = "KeyText"
	keyText.Size = UDim2.new(0, 35, 1, 0)
	keyText.Position = UDim2.new(0, 0, 0, 0)
	keyText.BackgroundColor3 = UI_SETTINGS.AccentColor
	keyText.BackgroundTransparency = 0.2
	keyText.Text = "[" .. getKeyString(inputType) .. "]"
	keyText.TextColor3 = UI_SETTINGS.TextColor
	keyText.TextSize = UI_SETTINGS.KeyTextSize
	keyText.Font = Enum.Font.GothamBold
	keyText.Parent = actionContainer
	
	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 6)
	keyCorner.Parent = keyText
	
	-- Action text ("Open")
	local actionText = Instance.new("TextLabel")
	actionText.Name = "ActionText"
	actionText.Size = UDim2.new(1, -45, 1, 0)
	actionText.Position = UDim2.new(0, 45, 0, 0)
	actionText.BackgroundTransparency = 1
	actionText.Text = prompt.ActionText
	actionText.TextColor3 = UI_SETTINGS.TextColor
	actionText.TextSize = UI_SETTINGS.ActionTextSize
	actionText.Font = Enum.Font.Gotham
	actionText.TextXAlignment = Enum.TextXAlignment.Left
	actionText.Parent = actionContainer
	
	-- Fade in animation
	background.BackgroundTransparency = 1
	glow.Transparency = 1
	objectText.TextTransparency = 1
	separator.BackgroundTransparency = 1
	keyText.BackgroundTransparency = 1
	keyText.TextTransparency = 1
	actionText.TextTransparency = 1
	
	local fadeIn = TweenService:Create(
		background,
		TweenInfo.new(UI_SETTINGS.FadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = UI_SETTINGS.BackgroundTransparency}
	)
	local glowFadeIn = TweenService:Create(glow, TweenInfo.new(UI_SETTINGS.FadeInTime), {Transparency = UI_SETTINGS.GlowTransparency})
	local textFadeIn = TweenService:Create(objectText, TweenInfo.new(UI_SETTINGS.FadeInTime), {TextTransparency = 0})
	local sepFadeIn = TweenService:Create(separator, TweenInfo.new(UI_SETTINGS.FadeInTime), {BackgroundTransparency = 0.3})
	local keyBgFadeIn = TweenService:Create(keyText, TweenInfo.new(UI_SETTINGS.FadeInTime), {BackgroundTransparency = 0.2, TextTransparency = 0})
	local actionFadeIn = TweenService:Create(actionText, TweenInfo.new(UI_SETTINGS.FadeInTime), {TextTransparency = 0})
	
	fadeIn:Play()
	glowFadeIn:Play()
	textFadeIn:Play()
	sepFadeIn:Play()
	keyBgFadeIn:Play()
	actionFadeIn:Play()
	
	-- Pulse animation (glow effect)
	task.spawn(function()
		while screenGui.Parent do
			local pulseOut = TweenService:Create(
				glow,
				TweenInfo.new(UI_SETTINGS.PulseSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.2}
			)
			pulseOut:Play()
			pulseOut.Completed:Wait()
			
			if not screenGui.Parent then break end
			
			local pulseIn = TweenService:Create(
				glow,
				TweenInfo.new(UI_SETTINGS.PulseSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = UI_SETTINGS.GlowTransparency}
			)
			pulseIn:Play()
			pulseIn.Completed:Wait()
		end
	end)
	
	return screenGui
end

-- ========================================
-- PROXIMITY PROMPT SERVICE SETUP
-- ========================================

-- Track active custom UIs
local activePrompts = {}

-- Create custom UI when prompt is shown
ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
	print("🔔 PromptShown event fired for:", prompt.Parent.Name, "Style:", prompt.Style)
	
	-- Only customize prompts with Style = Custom
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then 
		print("⚠️ Prompt style is not Custom, skipping")
		return 
	end
	
	-- Don't create duplicate UIs
	if activePrompts[prompt] then 
		print("⚠️ UI already exists for this prompt")
		return 
	end
	
	print("✅ Creating custom UI for:", prompt.ObjectText)
	
	-- Create custom UI
	local customUI = createCustomUI(prompt, inputType)
	activePrompts[prompt] = customUI
	
	-- Cleanup when prompt is hidden
	local connection
	connection = ProximityPromptService.PromptHidden:Connect(function(hiddenPrompt)
		if hiddenPrompt == prompt then
			print("🚫 Prompt hidden, cleaning up UI for:", prompt.ObjectText)
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

print("✨ Custom Proximity Prompt UI Loaded!")
