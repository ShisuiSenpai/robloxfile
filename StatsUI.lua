-- Stats UI - Client Script
-- Place this as a LocalScript in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local updateStatsEvent = ReplicatedStorage:WaitForChild("UpdateStats", 10)
local requestStatsEvent = ReplicatedStorage:WaitForChild("RequestStats", 10)

if not updateStatsEvent or not requestStatsEvent then
	warn("[STATS UI] Could not find stats RemoteEvents!")
	return
end

print("[STATS UI] Loaded successfully")

-- ==================== UI CREATION ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatsUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

-- Stats display frame (top-right corner)
local statsFrame = Instance.new("Frame")
statsFrame.Name = "StatsDisplay"
statsFrame.AnchorPoint = Vector2.new(1, 0)
statsFrame.Position = UDim2.new(1, -10, 0, 10)
statsFrame.Size = UDim2.new(0, 180, 0, 75)
statsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
statsFrame.BackgroundTransparency = 0.2
statsFrame.BorderSizePixel = 0
statsFrame.Parent = screenGui

local statsScale = Instance.new("UIScale")
statsScale.Parent = statsFrame

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 10)
statsCorner.Parent = statsFrame

local statsStroke = Instance.new("UIStroke")
statsStroke.Color = Color3.fromRGB(100, 150, 255)
statsStroke.Thickness = 1.5
statsStroke.Transparency = 0.6
statsStroke.Parent = statsFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Position = UDim2.new(0, 0, 0, 5)
titleLabel.Size = UDim2.new(1, 0, 0, 18)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "YOUR STATS"
titleLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
titleLabel.TextSize = 12
titleLabel.TextTransparency = 0.3
titleLabel.Parent = statsFrame

-- Kills stat
local killsFrame = Instance.new("Frame")
killsFrame.Position = UDim2.new(0, 8, 0, 28)
killsFrame.Size = UDim2.new(1, -16, 0, 20)
killsFrame.BackgroundTransparency = 1
killsFrame.Parent = statsFrame

local killsIcon = Instance.new("TextLabel")
killsIcon.Position = UDim2.new(0, 0, 0, 0)
killsIcon.Size = UDim2.new(0, 20, 1, 0)
killsIcon.BackgroundTransparency = 1
killsIcon.Font = Enum.Font.GothamBold
killsIcon.Text = "??"
killsIcon.TextColor3 = Color3.fromRGB(255, 200, 100)
killsIcon.TextSize = 16
killsIcon.Parent = killsFrame

local killsLabel = Instance.new("TextLabel")
killsLabel.Position = UDim2.new(0, 25, 0, 0)
killsLabel.Size = UDim2.new(0.6, -25, 1, 0)
killsLabel.BackgroundTransparency = 1
killsLabel.Font = Enum.Font.Gotham
killsLabel.Text = "Kills"
killsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
killsLabel.TextSize = 14
killsLabel.TextXAlignment = Enum.TextXAlignment.Left
killsLabel.Parent = killsFrame

local killsValue = Instance.new("TextLabel")
killsValue.Name = "KillsValue"
killsValue.Position = UDim2.new(0.6, 0, 0, 0)
killsValue.Size = UDim2.new(0.4, 0, 1, 0)
killsValue.BackgroundTransparency = 1
killsValue.Font = Enum.Font.GothamBold
killsValue.Text = "0"
killsValue.TextColor3 = Color3.fromRGB(255, 255, 255)
killsValue.TextSize = 16
killsValue.TextXAlignment = Enum.TextXAlignment.Right
killsValue.Parent = killsFrame

-- Wins stat
local winsFrame = Instance.new("Frame")
winsFrame.Position = UDim2.new(0, 8, 0, 50)
winsFrame.Size = UDim2.new(1, -16, 0, 20)
winsFrame.BackgroundTransparency = 1
winsFrame.Parent = statsFrame

local winsIcon = Instance.new("TextLabel")
winsIcon.Position = UDim2.new(0, 0, 0, 0)
winsIcon.Size = UDim2.new(0, 20, 1, 0)
winsIcon.BackgroundTransparency = 1
winsIcon.Font = Enum.Font.GothamBold
winsIcon.Text = "??"
winsIcon.TextColor3 = Color3.fromRGB(255, 220, 100)
winsIcon.TextSize = 16
winsIcon.Parent = winsFrame

local winsLabel = Instance.new("TextLabel")
winsLabel.Position = UDim2.new(0, 25, 0, 0)
winsLabel.Size = UDim2.new(0.6, -25, 1, 0)
winsLabel.BackgroundTransparency = 1
winsLabel.Font = Enum.Font.Gotham
winsLabel.Text = "Wins"
winsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
winsLabel.TextSize = 14
winsLabel.TextXAlignment = Enum.TextXAlignment.Left
winsLabel.Parent = winsFrame

local winsValue = Instance.new("TextLabel")
winsValue.Name = "WinsValue"
winsValue.Position = UDim2.new(0.6, 0, 0, 0)
winsValue.Size = UDim2.new(0.4, 0, 1, 0)
winsValue.BackgroundTransparency = 1
winsValue.Font = Enum.Font.GothamBold
winsValue.Text = "0"
winsValue.TextColor3 = Color3.fromRGB(255, 255, 255)
winsValue.TextSize = 16
winsValue.TextXAlignment = Enum.TextXAlignment.Right
winsValue.Parent = winsFrame

-- ==================== MOBILE SCALING ====================

local function updateUIScale()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local baseScale = math.min(viewportSize.X / 1920, viewportSize.Y / 1080)
	local scale = math.clamp(baseScale, 0.85, 1.3)
	statsScale.Scale = scale
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale)
updateUIScale()

-- ==================== UPDATE HANDLING ====================

-- Update UI when stats change
updateStatsEvent.OnClientEvent:Connect(function(stats)
	if not stats then return end
	
	print("[STATS UI] Updated - Kills:", stats.Kills, "Wins:", stats.Wins)
	
	killsValue.Text = tostring(stats.Kills)
	winsValue.Text = tostring(stats.Wins)
end)

-- Request initial stats
task.delay(1, function()
	requestStatsEvent:FireServer()
end)

print("[STATS UI] Ready!")
