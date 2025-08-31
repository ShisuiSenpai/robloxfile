-- WinStreakSystem.lua
-- Manages win streaks and displays them above player heads
-- Place this in ServerScriptService as a regular Script

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configuration
local MIN_STREAK_TO_SHOW = 2 -- Only show streak UI after 2 wins in a row
local STREAK_UI_HEIGHT = 2.5 -- Height above character's head

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
	print("[StreakManager] createStreakUI called")
	if not character then 
		print("[StreakManager] No character in createStreakUI")
		return 
	end
	
	local head = character:WaitForChild("Head", 5)
	if not head then 
		print("[StreakManager] No head found in createStreakUI")
		return 
	end
	
	print("[StreakManager] Creating BillboardGui...")
	
	-- Create BillboardGui
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "StreakDisplay"
	billboardGui.Size = UDim2.new(2, 0, 0.8, 0) -- Smaller size
	billboardGui.StudsOffset = Vector3.new(0, STREAK_UI_HEIGHT, 0)
	billboardGui.AlwaysOnTop = false
	billboardGui.LightInfluence = 0
	billboardGui.Parent = head
	
	-- Single text label for fire emoji and number
	local streakLabel = Instance.new("TextLabel")
	streakLabel.Name = "StreakLabel"
	streakLabel.Size = UDim2.new(1, 0, 1, 0)
	streakLabel.Position = UDim2.new(0, 0, 0, 0)
	streakLabel.BackgroundTransparency = 1 -- No background
	streakLabel.Text = "🔥" .. tostring(streak)
	streakLabel.TextScaled = true
	streakLabel.TextColor3 = getStreakColor(streak)
	streakLabel.Font = Enum.Font.SourceSansBold
	streakLabel.Parent = billboardGui
	
	-- Add text stroke for visibility
	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.new(0, 0, 0)
	textStroke.Thickness = 2
	textStroke.Transparency = 0
	textStroke.Parent = streakLabel
	
	-- Animate in
	billboardGui.Size = UDim2.new(0, 0, 0, 0)
	local sizeTween = TweenService:Create(
		billboardGui,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(2, 0, 0.8, 0)}
	)
	sizeTween:Play()
	
	-- Add pulsing effect for high streaks (scale pulsing)
	if streak >= 10 then
		spawn(function()
			while billboardGui.Parent do
				local pulseTween = TweenService:Create(
					billboardGui,
					TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Size = UDim2.new(2.2, 0, 0.9, 0)}
				)
				pulseTween:Play()
				pulseTween.Completed:Wait()
				
				local pulseTween2 = TweenService:Create(
					billboardGui,
					TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Size = UDim2.new(2, 0, 0.8, 0)}
				)
				pulseTween2:Play()
				pulseTween2.Completed:Wait()
			end
		end)
	end
	
	print("[StreakManager] BillboardGui created successfully, returning it")
	return billboardGui
end

-- Update or create streak UI
local function updateStreakUI(player, streak)
	print("[StreakManager] updateStreakUI called for", player.Name, "with streak:", streak, "MIN_STREAK_TO_SHOW:", MIN_STREAK_TO_SHOW)
	
	local character = player.Character
	if not character then 
		print("[StreakManager] No character found for", player.Name)
		return 
	end
	
	-- Remove old UI if exists
	if streakUIs[player] then
		streakUIs[player]:Destroy()
		streakUIs[player] = nil
	end
	
	-- Create new UI if streak is high enough
	if streak >= MIN_STREAK_TO_SHOW then
		print("[StreakManager] Streak high enough, creating UI")
		local success, result = pcall(function()
			return createStreakUI(character, streak)
		end)
		
		if success and result then
			streakUIs[player] = result
			print("[StreakManager] UI created and stored successfully")
		else
			warn("[StreakManager] Failed to create UI:", result)
		end
	else
		print("[StreakManager] Streak too low:", streak, "<", MIN_STREAK_TO_SHOW)
	end
end

-- Remove streak UI
local function removeStreakUI(player)
	if streakUIs[player] then
		-- Animate out
		local shrinkTween = TweenService:Create(
			streakUIs[player],
			TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
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
	-- Don't reset streak if player already has one
	if playerStreaks[player] == nil then
		playerStreaks[player] = 0
		print("[StreakManager] Initialized", player.Name, "with streak 0")
	else
		print("[StreakManager] Player", player.Name, "rejoined with existing streak:", playerStreaks[player])
	end
	
	-- Handle character spawning
	player.CharacterAdded:Connect(onCharacterAdded)
	
	-- If character already exists
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

-- Clean up when player leaves
local function onPlayerRemoving(player)
	print("[StreakManager] Player", player.Name, "leaving with streak:", playerStreaks[player] or 0)
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
	if not player then 
		warn("[StreakManager] IncrementStreak called with nil player")
		return 
	end
	
	if playerStreaks[player] == nil then
		warn("[StreakManager] Player", player.Name, "not initialized in playerStreaks")
		playerStreaks[player] = 0
	end
	
	playerStreaks[player] = playerStreaks[player] + 1
	print("[StreakManager] " .. player.Name .. " win streak increased to: " .. playerStreaks[player])
	
	updateStreakUI(player, playerStreaks[player])
	
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