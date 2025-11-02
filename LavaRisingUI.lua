-- Lava Rising UI - Client Script
-- Place this as a LocalScript in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvent
local lavaStatusEvent = ReplicatedStorage:WaitForChild("LavaStatus", 10)

if not lavaStatusEvent then
	warn("[LAVA UI] Could not find LavaStatus RemoteEvent!")
	return
end

print("[LAVA UI] Loaded successfully")

-- ==================== UI CREATION ====================

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LavaRisingUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

-- Warning Frame (appears when lava rises)
local warningFrame = Instance.new("Frame")
warningFrame.Name = "LavaWarning"
warningFrame.AnchorPoint = Vector2.new(0.5, 1)
warningFrame.Position = UDim2.new(0.5, 0, 1, 100) -- Start off-screen at bottom
warningFrame.Size = UDim2.new(0, 380, 0, 60)
warningFrame.BackgroundColor3 = Color3.fromRGB(255, 80, 60)
warningFrame.BackgroundTransparency = 0.3
warningFrame.BorderSizePixel = 0
warningFrame.Visible = false
warningFrame.Parent = screenGui

-- Add UIScale for mobile support
local warningScale = Instance.new("UIScale")
warningScale.Parent = warningFrame

local warningCorner = Instance.new("UICorner")
warningCorner.CornerRadius = UDim.new(0, 12)
warningCorner.Parent = warningFrame

local warningStroke = Instance.new("UIStroke")
warningStroke.Color = Color3.fromRGB(255, 50, 30)
warningStroke.Thickness = 2
warningStroke.Transparency = 0.4
warningStroke.Parent = warningFrame

-- Warning icon (?? emoji or text)
local warningIcon = Instance.new("TextLabel")
warningIcon.Name = "Icon"
warningIcon.Position = UDim2.new(0, 10, 0, 0)
warningIcon.Size = UDim2.new(0, 50, 1, 0)
warningIcon.BackgroundTransparency = 1
warningIcon.Font = Enum.Font.GothamBold
warningIcon.Text = "??"
warningIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
warningIcon.TextSize = 32
warningIcon.Parent = warningFrame

-- Warning text
local warningText = Instance.new("TextLabel")
warningText.Name = "WarningText"
warningText.Position = UDim2.new(0, 62, 0, 8)
warningText.Size = UDim2.new(1, -70, 0, 24)
warningText.BackgroundTransparency = 1
warningText.Font = Enum.Font.GothamBold
warningText.Text = "LAVA RISING!"
warningText.TextColor3 = Color3.fromRGB(255, 255, 255)
warningText.TextSize = 19
warningText.TextXAlignment = Enum.TextXAlignment.Left
warningText.TextStrokeTransparency = 0.7
warningText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
warningText.Parent = warningFrame

-- Height indicator
local heightText = Instance.new("TextLabel")
heightText.Name = "HeightText"
heightText.Position = UDim2.new(0, 62, 0, 34)
heightText.Size = UDim2.new(1, -70, 0, 18)
heightText.BackgroundTransparency = 1
heightText.Font = Enum.Font.Gotham
heightText.Text = "Height: 0%"
heightText.TextColor3 = Color3.fromRGB(255, 220, 200)
heightText.TextSize = 14
heightText.TextXAlignment = Enum.TextXAlignment.Left
heightText.TextTransparency = 0.2
heightText.Parent = warningFrame

-- ==================== MOBILE SCALING ====================

local function updateUIScale()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local screenWidth = viewportSize.X
	local screenHeight = viewportSize.Y
	
	local baseScale = math.min(screenWidth / 1920, screenHeight / 1080)
	local scale = math.clamp(baseScale, 0.85, 1.3)
	
	warningScale.Scale = scale
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale)
updateUIScale()

-- ==================== ANIMATION FUNCTIONS ====================

local warningTween = nil
local pulseTween = nil

-- Define hideWarning first
local function hideWarning()
	if warningTween then warningTween:Cancel() end
	
	-- Stop pulse
	if pulseTween then
		pulseTween:Cancel()
	end
	
	-- Slide down
	warningTween = TweenService:Create(
		warningFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, 0, 1, 100)}
	)
	warningTween:Play()
	
	task.spawn(function()
		warningTween.Completed:Wait()
		warningFrame.Visible = false
	end)
end

local function showWarning(height, maxHeight)
	warningFrame.Visible = true
	
	-- Update height percentage
	local percentage = math.floor((height / maxHeight) * 100)
	heightText.Text = "Height: " .. percentage .. "%"
	
	-- Slide up from bottom
	if warningTween then warningTween:Cancel() end
	warningTween = TweenService:Create(
		warningFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 1, -70)}
	)
	warningTween:Play()
	
	-- Pulse effect
	if not pulseTween or pulseTween.PlaybackState ~= Enum.PlaybackState.Playing then
		pulseTween = TweenService:Create(
			warningStroke,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Transparency = 0.1}
		)
		pulseTween:Play()
	end
	
	-- Play warning sound (optional - skip if sound fails)
	pcall(function()
		if _G.SoundManager then
			_G.SoundManager.play("become_king", true)
		end
	end)
	
	-- Auto-hide after 3 seconds
	task.delay(3, function()
		hideWarning()
	end)
end

-- ==================== EVENT HANDLERS ====================

lavaStatusEvent.OnClientEvent:Connect(function(status, currentHeight, maxHeight)
	print("[LAVA UI] Status:", status, "Height:", currentHeight, "/", maxHeight)
	
	if status == "started" then
		-- Lava rising has begun
		showWarning(currentHeight, maxHeight)
		
	elseif status == "rising" then
		-- Lava is rising right now
		showWarning(currentHeight, maxHeight)
		
	elseif status == "maxHeight" then
		-- Lava reached maximum
		warningText.Text = "LAVA AT MAX HEIGHT!"
		showWarning(currentHeight, maxHeight)
		
	elseif status == "reset" then
		-- Lava reset to start
		hideWarning()
	end
end)

-- Cleanup
player.CharacterRemoving:Connect(function()
	if warningTween then warningTween:Cancel() end
	if pulseTween then pulseTween:Cancel() end
end)

print("[LAVA UI] Ready!")
