-- Win Streak System - Server Script
-- Place this in ServerScriptService
-- Manages win streaks and displays them above player heads

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

print("[STREAK] Win Streak System starting...")

-- Configuration
local MIN_STREAK_TO_SHOW = 1 -- Show streak UI starting from 1 win
local STREAK_UI_HEIGHT = 3 -- Height above character's head

-- Table to track player streaks
local playerStreaks = {} -- [Player] = number
local streakUIs = {} -- [Player] = BillboardGui

-- Colors for different streak levels
local STREAK_COLORS = {
	[2] = Color3.fromRGB(255, 255, 255),    -- White (2-4 wins)
	[5] = Color3.fromRGB(255, 215, 0),      -- Gold (5-9 wins)
	[10] = Color3.fromRGB(255, 100, 50),    -- Orange-Red (10-14 wins)
	[15] = Color3.fromRGB(200, 50, 255),    -- Purple (15-19 wins)
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

	local head = character:WaitForChild("Head", 5)
	if not head then return end

	-- Remove any existing streak display
	local existingUI = head:FindFirstChild("StreakDisplay")
	if existingUI then
		existingUI:Destroy()
	end

	-- Create BillboardGui
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "StreakDisplay"
	billboardGui.Size = UDim2.new(3, 0, 1, 0)
	billboardGui.StudsOffset = Vector3.new(0, STREAK_UI_HEIGHT, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.LightInfluence = 0
	billboardGui.Parent = head

	-- Background frame (semi-transparent, modern look)
	local bgFrame = Instance.new("Frame")
	bgFrame.Name = "Background"
	bgFrame.Size = UDim2.new(1, 0, 1, 0)
	bgFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	bgFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	bgFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	bgFrame.BackgroundTransparency = 0.3
	bgFrame.BorderSizePixel = 0
	bgFrame.Parent = billboardGui

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0.3, 0)
	bgCorner.Parent = bgFrame

	local bgStroke = Instance.new("UIStroke")
	bgStroke.Color = getStreakColor(streak)
	bgStroke.Thickness = 2
	bgStroke.Transparency = 0.4
	bgStroke.Parent = bgFrame

	-- Fire emoji
	local fireLabel = Instance.new("TextLabel")
	fireLabel.Name = "FireEmoji"
	fireLabel.Size = UDim2.new(0.4, 0, 0.8, 0)
	fireLabel.Position = UDim2.new(0.15, 0, 0.5, 0)
	fireLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	fireLabel.BackgroundTransparency = 1
	fireLabel.Text = "🔥"
	fireLabel.TextScaled = true
	fireLabel.Font = Enum.Font.GothamBold
	fireLabel.Parent = bgFrame

	-- Streak number label
	local streakLabel = Instance.new("TextLabel")
	streakLabel.Name = "StreakLabel"
	streakLabel.Size = UDim2.new(0.6, 0, 0.8, 0)
	streakLabel.Position = UDim2.new(0.6, 0, 0.5, 0)
	streakLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	streakLabel.BackgroundTransparency = 1
	streakLabel.Text = tostring(streak)
	streakLabel.TextScaled = true
	streakLabel.TextColor3 = getStreakColor(streak)
	streakLabel.Font = Enum.Font.GothamBold
	streakLabel.Parent = bgFrame

	-- Text stroke for visibility
	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.fromRGB(0, 0, 0)
	textStroke.Thickness = 1.5
	textStroke.Transparency = 0
	textStroke.Parent = streakLabel

	-- Animate in (pop effect)
	bgFrame.Size = UDim2.new(0, 0, 0, 0)
	local sizeTween = TweenService:Create(
		bgFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(1, 0, 1, 0)}
	)
	sizeTween:Play()

	-- Add pulsing glow effect for high streaks
	if streak >= 10 then
		task.spawn(function()
			while billboardGui and billboardGui.Parent do
				-- Pulse the stroke
				local pulseTween = TweenService:Create(
					bgStroke,
					TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Transparency = 0.1}
				)
				pulseTween:Play()
				pulseTween.Completed:Wait()

				local pulseTween2 = TweenService:Create(
					bgStroke,
					TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Transparency = 0.4}
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
		local success, result = pcall(function()
			return createStreakUI(character, streak)
		end)

		if success and result then
			streakUIs[player] = result
		else
			warn("[STREAK] Failed to create UI for", player.Name)
		end
	end
end

-- Remove streak UI
local function removeStreakUI(player)
	if streakUIs[player] then
		local billboardGui = streakUIs[player]
		local bgFrame = billboardGui:FindFirstChild("Background")

		if bgFrame then
			-- Animate out
			local shrinkTween = TweenService:Create(
				bgFrame,
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
		else
			billboardGui:Destroy()
			streakUIs[player] = nil
		end
	end
end

-- Handle character respawning
local function onCharacterAdded(character)
	local player = Players:GetPlayerFromCharacter(character)
	if player and playerStreaks[player] and playerStreaks[player] >= MIN_STREAK_TO_SHOW then
		-- Recreate streak UI after respawn
		task.wait(0.5) -- Wait for character to load
		updateStreakUI(player, playerStreaks[player])
	end
end

-- Initialize player
local function onPlayerAdded(player)
	playerStreaks[player] = 0
	print("[STREAK] Initialized", player.Name, "with streak 0")

	-- Handle character spawning
	player.CharacterAdded:Connect(onCharacterAdded)

	-- If character already exists
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

-- Clean up when player leaves
local function onPlayerRemoving(player)
	if playerStreaks[player] and playerStreaks[player] > 0 then
		print("[STREAK]", player.Name, "leaving with streak:", playerStreaks[player])
	end

	playerStreaks[player] = nil

	if streakUIs[player] then
		streakUIs[player]:Destroy()
		streakUIs[player] = nil
	end
end

-- ==================== GLOBAL API ====================

_G.StreakManager = {}

-- Increment streak
function _G.StreakManager.incrementStreak(player)
	if not player then 
		warn("[STREAK] incrementStreak called with nil player")
		return 
	end

	-- Ensure player is initialized
	if playerStreaks[player] == nil then
		playerStreaks[player] = 0
	end

	playerStreaks[player] = playerStreaks[player] + 1
	print("[STREAK]", player.Name, "win streak increased to:", playerStreaks[player])

	updateStreakUI(player, playerStreaks[player])

	return playerStreaks[player]
end

-- Reset streak
function _G.StreakManager.resetStreak(player)
	if not player or not playerStreaks[player] then return end

	local previousStreak = playerStreaks[player]
	playerStreaks[player] = 0
	removeStreakUI(player)

	if previousStreak > 0 then
		print("[STREAK]", player.Name, "streak reset (was", previousStreak .. ")")
	end
end

-- Get current streak
function _G.StreakManager.getStreak(player)
	return playerStreaks[player] or 0
end

-- ==================== EVENTS ====================

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("========================================")
print("Win Streak System Ready!")
print("Min streak to show:", MIN_STREAK_TO_SHOW)
print("========================================")
