-- Stats Manager - Server Script
-- Place this in ServerScriptService
-- Handles kill and win tracking with DataStore persistence

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local DATASTORE_NAME = "PlayerStats_v1"
local AUTO_SAVE_INTERVAL = 120 -- Auto-save every 2 minutes
local DEBUG = false

-- DataStore
local statsDataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

-- Player stats cache (in-memory for performance)
local playerStats = {} -- [UserId] = {Kills = 0, Wins = 0}

-- Save queue to prevent data loss
local saveQueue = {}
local isSaving = false

-- Debug print
local function debugPrint(...)
	if DEBUG then
		print("[STATS]", ...)
	end
end

print("[STATS] Stats Manager starting...")

-- Create RemoteEvents
local updateStatsEvent = ReplicatedStorage:FindFirstChild("UpdateStats") or Instance.new("RemoteEvent")
updateStatsEvent.Name = "UpdateStats"
updateStatsEvent.Parent = ReplicatedStorage

local requestStatsEvent = ReplicatedStorage:FindFirstChild("RequestStats") or Instance.new("RemoteEvent")
requestStatsEvent.Name = "RequestStats"
requestStatsEvent.Parent = ReplicatedStorage

debugPrint("RemoteEvents created")

-- ==================== DATA MANAGEMENT ====================

-- Default stats
local function getDefaultStats()
	return {
		Kills = 0,
		Wins = 0
	}
end

-- Load player stats from DataStore
local function loadStats(player)
	local userId = player.UserId
	local success, data = pcall(function()
		return statsDataStore:GetAsync("Player_" .. userId)
	end)
	
	if success and data then
		playerStats[userId] = data
		print("[STATS] Loaded stats for", player.Name, "- Kills:", data.Kills, "Wins:", data.Wins)
	else
		playerStats[userId] = getDefaultStats()
		print("[STATS] Created new stats for", player.Name)
		if not success then
			warn("[STATS] Failed to load data for", player.Name, "- Using defaults")
		end
	end
	
	-- Send stats to client
	updateStatsEvent:FireClient(player, playerStats[userId])
	
	return playerStats[userId]
end

-- Save player stats to DataStore (with retry logic)
local function saveStats(player, retryCount)
	if not player then return end
	
	local userId = player.UserId
	local stats = playerStats[userId]
	
	if not stats then return end
	
	retryCount = retryCount or 0
	
	local success, errorMsg = pcall(function()
		statsDataStore:SetAsync("Player_" .. userId, stats)
	end)
	
	if success then
		print("[STATS] Saved stats for", player.Name, "- Kills:", stats.Kills, "Wins:", stats.Wins)
		saveQueue[userId] = nil -- Clear from save queue
	else
		warn("[STATS] Failed to save stats for", player.Name, ":", errorMsg)
		
		-- Retry up to 3 times
		if retryCount < 3 then
			saveQueue[userId] = true
			task.delay(2, function()
				saveStats(player, retryCount + 1)
			end)
		else
			warn("[STATS] Gave up saving stats for", player.Name, "after 3 attempts")
		end
	end
end

-- Batch save all players in queue
local function batchSaveAll()
	if isSaving then return end
	isSaving = true
	
	debugPrint("Starting batch save...")
	
	for _, player in pairs(Players:GetPlayers()) do
		saveStats(player)
		task.wait(0.1) -- Small delay to avoid rate limiting
	end
	
	isSaving = false
	debugPrint("Batch save complete")
end

-- ==================== STAT MODIFICATION ====================

-- Add a kill to a player
local function addKill(player)
	if not player then return end
	
	local userId = player.UserId
	local stats = playerStats[userId]
	
	if stats then
		stats.Kills = stats.Kills + 1
		print("[STATS]", player.Name, "got a kill! Total kills:", stats.Kills)
		
		-- Update client
		updateStatsEvent:FireClient(player, stats)
		
		-- Mark for saving
		saveQueue[userId] = true
	end
end

-- Add a win to a player
local function addWin(player)
	if not player then return end
	
	local userId = player.UserId
	local stats = playerStats[userId]
	
	if stats then
		stats.Wins = stats.Wins + 1
		print("[STATS]", player.Name, "got a win! Total wins:", stats.Wins)
		
		-- Update client
		updateStatsEvent:FireClient(player, stats)
		
		-- Mark for saving
		saveQueue[userId] = true
	end
end

-- Get player stats (for other scripts)
local function getStats(player)
	if not player then return nil end
	return playerStats[player.UserId]
end

-- ==================== PLAYER EVENTS ====================

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	-- Load stats when player joins
	loadStats(player)
end)

-- Handle player leaving (save immediately)
Players.PlayerRemoving:Connect(function(player)
	print("[STATS] Player leaving, saving stats for", player.Name)
	saveStats(player)
	
	-- Clean up cache after saving
	task.delay(5, function()
		playerStats[player.UserId] = nil
	end)
end)

-- Load stats for existing players
for _, player in pairs(Players:GetPlayers()) do
	loadStats(player)
end

-- ==================== AUTO-SAVE SYSTEM ====================

-- Auto-save every 2 minutes
task.spawn(function()
	while true do
		task.wait(AUTO_SAVE_INTERVAL)
		
		-- Only save players who have unsaved changes
		local saveCount = 0
		for userId, _ in pairs(saveQueue) do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				saveStats(player)
				saveCount = saveCount + 1
			end
		end
		
		if saveCount > 0 then
			print("[STATS] Auto-saved", saveCount, "player(s)")
		end
	end
end)

-- ==================== GLOBAL API ====================

-- Make functions accessible to other scripts
_G.StatsManager = {
	addKill = addKill,
	addWin = addWin,
	getStats = getStats,
	saveStats = saveStats,
	saveAll = batchSaveAll
}

-- ==================== GRACEFUL SHUTDOWN ====================

-- Save all on server shutdown
game:BindToClose(function()
	print("[STATS] Server shutting down, saving all player stats...")
	
	for _, player in pairs(Players:GetPlayers()) do
		saveStats(player)
	end
	
	-- Wait a moment for saves to complete
	task.wait(3)
end)

-- Handle client requests for stats
requestStatsEvent.OnServerEvent:Connect(function(player)
	local stats = playerStats[player.UserId]
	if stats then
		updateStatsEvent:FireClient(player, stats)
	end
end)

print("========================================")
print("Stats Manager Ready!")
print("DataStore:", DATASTORE_NAME)
print("Auto-save interval:", AUTO_SAVE_INTERVAL, "seconds")
print("========================================")
