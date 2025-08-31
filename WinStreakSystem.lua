-- WinStreakSystem.lua
-- Manages win streaks and displays them above player heads
-- Place this in ServerScriptService as a regular Script

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configuration
local MIN_STREAK_TO_SHOW = 2 -- Only show streak UI after 2 wins in a row
local STREAK_UI_HEIGHT = 3 -- Height above character's head

-- Table to track player streaks
local playerStreaks = {}
local streakUIs = {}

-- Colors for different streak levels
local STREAK_COLORS = {
	[2] = Color3.fromRGB(255, 255, 255),    -- White (2-4 wins)
	[5] = Color3.fromRGB(255, 215, 0),      -- Gold (5-9 wins)
	[10] = Color3.fromRGB(255, 69, 0),      -- Red-Orange (10-14 wins)
	[15] = Color3.fromRGB(148, 0, 211),     -- Purple (15-19 wins)
	[20] = Color3.fromRGB(0, 255, 255),     -- Cyan (20+ wins)
}

-- Get color based on streak
local function getStreakColor(streak)
	local color = STREAK_COLORS[2] -- Default white
	for threshold, col in pairs(STREAK_COLORS) do
		if streak >= threshold then
			color = col
		end
	end
	return color
end

-- Create streak UI above character
local function createStreakUI(character, streak)
	if not character then return end
	
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoidRootPart then return end
	
	-- Create BillboardGui
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "StreakDisplay"
	billboardGui.Size = UDim2.new(4, 0, 1.5, 0)
	billboardGui.StudsOffset = Vector3.new(0, STREAK_UI_HEIGHT, 0)
	billboardGui.AlwaysOnTop = false
	billboardGui.LightInfluence = 0
	billboardGui.Parent = humanoidRootPart
	
	-- Background frame with gradient
	local bgFrame = Instance.new("Frame")
	bgFrame.Name = "Background"
	bgFrame.Size = UDim2.new(1, 0, 1, 0)
	bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	bgFrame.BackgroundTransparency = 0.3
	bgFrame.BorderSizePixel = 0
	bgFrame.Parent = billboardGui
	
	-- Add rounded corners
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.3, 0)
	uiCorner.Parent = bgFrame
	
	-- Add gradient
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Rotation = 90
	uiGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 0.3)
	})
	uiGradient.Parent = bgFrame
	
	-- Fire emoji
	local fireLabel = Instance.new("TextLabel")
	fireLabel.Name = "FireEmoji"
	fireLabel.Size = UDim2.new(0.3, 0, 0.8, 0)
	fireLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
	fireLabel.BackgroundTransparency = 1
	fireLabel.Text = "🔥"
	fireLabel.TextScaled = true
	fireLabel.Font = Enum.Font.SourceSans
	fireLabel.Parent = bgFrame
	
	-- Streak number
	local streakLabel = Instance.new("TextLabel")
	streakLabel.Name = "StreakNumber"
	streakLabel.Size = UDim2.new(0.4, 0, 0.8, 0)
	streakLabel.Position = UDim2.new(0.3, 0, 0.1, 0)
	streakLabel.BackgroundTransparency = 1
	streakLabel.Text = tostring(streak)
	streakLabel.TextScaled = true
	streakLabel.TextColor3 = getStreakColor(streak)
	streakLabel.Font = Enum.Font.SourceSansBold
	streakLabel.Parent = bgFrame
	
	-- Add text stroke
	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.new(0, 0, 0)
	textStroke.Thickness = 2
	textStroke.Parent = streakLabel
	
	-- "WIN STREAK" text
	local winStreakLabel = Instance.new("TextLabel")
	winStreakLabel.Name = "WinStreakText"
	winStreakLabel.Size = UDim2.new(0.3, 0, 0.4, 0)
	winStreakLabel.Position = UDim2.new(0.65, 0, 0.3, 0)
	winStreakLabel.BackgroundTransparency = 1
	winStreakLabel.Text = "STREAK"
	winStreakLabel.TextScaled = true
	winStreakLabel.TextColor3 = Color3.new(1, 1, 1)
	winStreakLabel.Font = Enum.Font.SourceSans
	winStreakLabel.Parent = bgFrame
	
	-- Animate in
	billboardGui.Size = UDim2.new(0, 0, 0, 0)
	local sizeTween = TweenService:Create(
		billboardGui,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(4, 0, 1.5, 0)}
	)
	sizeTween:Play()
	
	-- Add pulsing effect for high streaks
	if streak >= 10 then
		spawn(function()
			while billboardGui.Parent do
				local pulseTween = TweenService:Create(
					bgFrame,
					TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{BackgroundTransparency = 0.1}
				)
				pulseTween:Play()
				pulseTween.Completed:Wait()
				
				local pulseTween2 = TweenService:Create(
					bgFrame,
					TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{BackgroundTransparency = 0.3}
				)
				pulseTween2:Play()
				pulseTween2.Completed:Wait()
			end
		end)
	end
	
	return billboardGui
end

-- Update or create streak UI
local function updateStreakUI(player, streak)
	local character = player.Character
	if not character then return end
	
	-- Remove old UI if exists
	if streakUIs[player] then
		streakUIs[player]:Destroy()
		streakUIs[player] = nil
	end
	
	-- Create new UI if streak is high enough
	if streak >= MIN_STREAK_TO_SHOW then
		streakUIs[player] = createStreakUI(character, streak)
	end
end

-- Remove streak UI
local function removeStreakUI(player)
	if streakUIs[player] then
		-- Animate out
		local shrinkTween = TweenService:Create(
			streakUIs[player],
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{Size = UDim2.new(0, 0, 0, 0)}
		)
		shrinkTween:Play()
		shrinkTween.Completed:Connect(function()
			if streakUIs[player] then
				streakUIs[player]:Destroy()
				streakUIs[player] = nil
			end
		end)
	end
end

-- Handle character respawning
local function onCharacterAdded(character)
	local player = Players:GetPlayerFromCharacter(character)
	if player and playerStreaks[player] and playerStreaks[player] >= MIN_STREAK_TO_SHOW then
		-- Recreate streak UI after respawn
		wait(1) -- Wait for character to load
		updateStreakUI(player, playerStreaks[player])
	end
end

-- Initialize player
local function onPlayerAdded(player)
	playerStreaks[player] = 0
	
	-- Handle character spawning
	player.CharacterAdded:Connect(onCharacterAdded)
	
	-- If character already exists
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

-- Clean up when player leaves
local function onPlayerRemoving(player)
	playerStreaks[player] = nil
	if streakUIs[player] then
		streakUIs[player]:Destroy()
		streakUIs[player] = nil
	end
end

-- Global functions for other scripts to use
_G.StreakManager = {}

-- Increment streak
function _G.StreakManager.IncrementStreak(player)
	if not player or not playerStreaks[player] then return end
	
	playerStreaks[player] = playerStreaks[player] + 1
	updateStreakUI(player, playerStreaks[player])
	
	print("[StreakManager] " .. player.Name .. " win streak: " .. playerStreaks[player])
	return playerStreaks[player]
end

-- Reset streak
function _G.StreakManager.ResetStreak(player)
	if not player or not playerStreaks[player] then return end
	
	local previousStreak = playerStreaks[player]
	playerStreaks[player] = 0
	removeStreakUI(player)
	
	if previousStreak > 0 then
		print("[StreakManager] " .. player.Name .. " streak reset (was " .. previousStreak .. ")")
	end
end

-- Get current streak
function _G.StreakManager.GetStreak(player)
	return playerStreaks[player] or 0
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("[StreakManager] Win streak system initialized!")