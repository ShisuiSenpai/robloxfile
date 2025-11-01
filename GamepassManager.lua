-- Gamepass Manager - Server Script
-- Place this in ServerScriptService
-- Handles gamepass ownership checking and effects

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

print("[GAMEPASS] Gamepass Manager starting...")

-- ==================== CONFIGURATION ====================

-- Gamepass IDs (replace with your actual IDs)
-- IMPORTANT: These IDs must match the ones in ShopUI.lua!
local GAMEPASS_IDS = {
	PUSH_BOOST = 0, -- Replace with real gamepass ID (matches ShopUI "2x Push Boost")
	WINS_2X = 0,    -- Replace with real gamepass ID (matches ShopUI "2x Wins")
	SPEED_BOOST = 0 -- Replace with real gamepass ID (matches ShopUI "Speed Boost")
}

-- Cache gamepass ownership to reduce API calls
local playerGamepasses = {} -- [UserId] = {PUSH_BOOST = true/false, etc.}

-- ==================== OWNERSHIP CHECKING ====================

-- Check if player owns a specific gamepass (with retry logic)
local function checkGamepassOwnership(player, gamepassId, retryCount)
	if gamepassId == 0 then
		warn("[GAMEPASS] Gamepass ID is 0 (placeholder) - returning false")
		return false
	end
	
	retryCount = retryCount or 0
	
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)
	
	if success then
		print("[GAMEPASS] Ownership check for", player.Name, "- Gamepass", gamepassId, ":", hasPass)
		return hasPass
	else
		warn("[GAMEPASS] Error checking gamepass for", player.Name, "- Attempt", retryCount + 1)
		
		-- Retry up to 3 times with delay
		if retryCount < 3 then
			task.wait(0.5)
			return checkGamepassOwnership(player, gamepassId, retryCount + 1)
		else
			warn("[GAMEPASS] Failed to check ownership after 3 attempts - assuming false")
			return false
		end
	end
end

-- Load all gamepasses for a player (called on join)
local function loadPlayerGamepasses(player)
	local userId = player.UserId
	playerGamepasses[userId] = {}
	
	print("[GAMEPASS] Loading gamepasses for", player.Name)
	
	-- Check each gamepass
	for passName, passId in pairs(GAMEPASS_IDS) do
		local hasPass = checkGamepassOwnership(player, passId)
		playerGamepasses[userId][passName] = hasPass
		
		if hasPass then
			print("[GAMEPASS]", player.Name, "owns", passName)
		end
	end
	
	print("[GAMEPASS] Loaded", player.Name, "'s gamepasses")
end

-- Get cached gamepass status (fast, no API call)
local function hasGamepass(player, gamepassName)
	if not player then return false end
	
	local userId = player.UserId
	if not playerGamepasses[userId] then
		-- Not loaded yet, do a quick load
		loadPlayerGamepasses(player)
	end
	
	return playerGamepasses[userId][gamepassName] == true
end

-- ==================== GAMEPASS EFFECTS ====================

-- Get win multiplier for player
local function getWinMultiplier(player)
	if hasGamepass(player, "WINS_2X") then
		return 2
	end
	return 1
end

-- Get push force multiplier for player
local function getPushMultiplier(player)
	if hasGamepass(player, "PUSH_BOOST") then
		return 2
	end
	return 1
end

-- Get speed multiplier for player
local function getSpeedMultiplier(player)
	if hasGamepass(player, "SPEED_BOOST") then
		return 1.25 -- 25% faster
	end
	return 1
end

-- Apply speed boost to character
local function applySpeedBoost(character, multiplier)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Base speeds
		local baseWalkSpeed = 16
		local baseJumpPower = 50
		
		humanoid.WalkSpeed = baseWalkSpeed * multiplier
		humanoid.JumpPower = baseJumpPower -- Keep jump the same
		
		print("[GAMEPASS] Applied speed boost:", multiplier, "x")
	end
end

-- ==================== PLAYER EVENTS ====================

-- Initialize player on join
Players.PlayerAdded:Connect(function(player)
	-- Load gamepasses
	loadPlayerGamepasses(player)
	
	-- Handle character spawning for speed boost
	player.CharacterAdded:Connect(function(character)
		-- Wait a moment for character to fully load
		task.wait(0.5)
		
		local speedMultiplier = getSpeedMultiplier(player)
		if speedMultiplier > 1 then
			applySpeedBoost(character, speedMultiplier)
		end
	end)
	
	-- If character already exists
	if player.Character then
		task.spawn(function()
			task.wait(0.5)
			local speedMultiplier = getSpeedMultiplier(player)
			if speedMultiplier > 1 then
				applySpeedBoost(player.Character, speedMultiplier)
			end
		end)
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	playerGamepasses[player.UserId] = nil
end)

-- Load gamepasses for existing players
for _, player in pairs(Players:GetPlayers()) do
	loadPlayerGamepasses(player)
	
	if player.Character then
		task.spawn(function()
			task.wait(0.5)
			local speedMultiplier = getSpeedMultiplier(player)
			if speedMultiplier > 1 then
				applySpeedBoost(player.Character, speedMultiplier)
			end
		end)
	end
end

-- ==================== PURCHASE DETECTION ====================

-- Detect when a player purchases a gamepass in-game
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, purchaseSuccess)
	print("[GAMEPASS] Purchase prompt finished for", player.Name, "- Gamepass:", gamepassId, "Success:", purchaseSuccess)
	
	if not purchaseSuccess then 
		warn("[GAMEPASS] Purchase was not successful or was cancelled")
		return 
	end
	
	print("[GAMEPASS] ?", player.Name, "successfully purchased gamepass:", gamepassId)
	
	-- Wait a moment for Roblox to register the purchase
	task.wait(1)
	
	-- Refresh the player's gamepass cache
	print("[GAMEPASS] Refreshing gamepass cache for", player.Name)
	loadPlayerGamepasses(player)
	
	-- Apply speed boost immediately if they bought it
	if gamepassId == GAMEPASS_IDS.SPEED_BOOST and player.Character then
		print("[GAMEPASS] Applying speed boost immediately")
		local speedMultiplier = getSpeedMultiplier(player)
		if speedMultiplier > 1 then
			applySpeedBoost(player.Character, speedMultiplier)
		end
	end
	
	-- Notify player
	print("[GAMEPASS] Gamepass activated for", player.Name, "!")
end)

-- ==================== GLOBAL API ====================

_G.GamepassManager = {
	hasGamepass = hasGamepass,
	getWinMultiplier = getWinMultiplier,
	getPushMultiplier = getPushMultiplier,
	getSpeedMultiplier = getSpeedMultiplier,
	applySpeedBoost = applySpeedBoost,
	refreshPlayer = loadPlayerGamepasses,
	checkOwnership = checkGamepassOwnership, -- Exposed for debugging
	GAMEPASS_IDS = GAMEPASS_IDS -- Exposed so other scripts can verify IDs match
}

print("========================================")
print("Gamepass Manager Ready!")
print("Push Boost ID:", GAMEPASS_IDS.PUSH_BOOST)
print("2x Wins ID:", GAMEPASS_IDS.WINS_2X)
print("Speed Boost ID:", GAMEPASS_IDS.SPEED_BOOST)
if GAMEPASS_IDS.PUSH_BOOST == 0 or GAMEPASS_IDS.WINS_2X == 0 or GAMEPASS_IDS.SPEED_BOOST == 0 then
	warn("[GAMEPASS] WARNING: Some gamepass IDs are still set to 0 (placeholder)!")
	warn("[GAMEPASS] Make sure to replace them with your real gamepass IDs!")
end
print("========================================")
