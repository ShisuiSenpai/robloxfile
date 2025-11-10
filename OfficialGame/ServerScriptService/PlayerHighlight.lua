-- Player Highlight System - Server Script
-- Place this in ServerScriptService
-- Adds a highlight effect to all players for better visibility

local Players = game:GetService("Players")

print("[HIGHLIGHT] Player Highlight System starting...")

-- ==================== CONFIGURATION ====================

local HIGHLIGHT_SETTINGS = {
	FillColor = Color3.fromRGB(26, 26, 26),       -- White fill
	FillTransparency = 0.9,                         -- Very transparent fill
	OutlineColor = Color3.fromRGB(206, 206, 206),       -- Dark gray outline
	OutlineTransparency = 0.3,                       -- Semi-transparent outline
	DepthMode = Enum.HighlightDepthMode.Occluded, -- Always visible through walls
	Enabled = true
}

-- ==================== HIGHLIGHT FUNCTIONS ====================

-- Apply highlight to a character
local function applyHighlight(character)
	if not character then return end

	-- Check if highlight already exists
	local existingHighlight = character:FindFirstChild("PlayerHighlight")
	if existingHighlight then
		existingHighlight:Destroy()
	end

	-- Create new highlight
	local highlight = Instance.new("Highlight")
	highlight.Name = "PlayerHighlight"
	highlight.FillColor = HIGHLIGHT_SETTINGS.FillColor
	highlight.FillTransparency = HIGHLIGHT_SETTINGS.FillTransparency
	highlight.OutlineColor = HIGHLIGHT_SETTINGS.OutlineColor
	highlight.OutlineTransparency = HIGHLIGHT_SETTINGS.OutlineTransparency
	highlight.DepthMode = HIGHLIGHT_SETTINGS.DepthMode
	highlight.Enabled = HIGHLIGHT_SETTINGS.Enabled
	highlight.Parent = character

	print("[HIGHLIGHT] Applied highlight to:", character.Name)
end

-- Setup player for highlights
local function setupPlayer(player)
	-- Handle current character
	if player.Character then
		applyHighlight(player.Character)
	end

	-- Handle future characters (respawns)
	player.CharacterAdded:Connect(function(character)
		-- Wait a moment for character to fully load
		task.wait(0.1)
		applyHighlight(character)
	end)

	print("[HIGHLIGHT] Setup player:", player.Name)
end

-- ==================== PLAYER EVENTS ====================

-- Handle players joining
Players.PlayerAdded:Connect(function(player)
	setupPlayer(player)
end)

-- Handle existing players (in case script loads after players join)
for _, player in pairs(Players:GetPlayers()) do
	setupPlayer(player)
end

print("========================================")
print("Player Highlight System Ready!")
print("========================================")
print("FillColor:", HIGHLIGHT_SETTINGS.FillColor)
print("FillTransparency:", HIGHLIGHT_SETTINGS.FillTransparency)
print("OutlineColor:", HIGHLIGHT_SETTINGS.OutlineColor)
print("OutlineTransparency:", HIGHLIGHT_SETTINGS.OutlineTransparency)
print("========================================")
