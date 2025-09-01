-- LeaderstatsManager.lua
-- Manages player statistics including wins with DataStore persistence
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- Configuration
local DATASTORE_NAME = "PlayerWinsDataStore_v1"
local AUTOSAVE_INTERVAL = 60 -- Autosave every 60 seconds
local MAX_RETRIES = 3
local RETRY_DELAY = 2

-- Create DataStore
local winsDataStore
local dataStoreSuccess, dataStoreError = pcall(function()
	winsDataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
end)

if not dataStoreSuccess then
	warn("[LeaderstatsManager] Failed to get DataStore:", dataStoreError)
end

-- Cache for player data
local playerDataCache = {}
local pendingSaves = {}

-- Module table
local LeaderstatsManager = {}

-- Create leaderstats for a player
local function createLeaderstats(player)
	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	-- Create Wins stat
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = leaderstats
	
	return leaderstats, wins
end

-- Load player data from DataStore
local function loadPlayerData(player)
	if not winsDataStore then
		warn("[LeaderstatsManager] DataStore not available, using default values")
		return {wins = 0}
	end
	
	local key = "Player_" .. player.UserId
	local data = nil
	local success = false
	
	for attempt = 1, MAX_RETRIES do
		success = pcall(function()
			data = winsDataStore:GetAsync(key)
		end)
		
		if success then
			break
		else
			if attempt < MAX_RETRIES then
				wait(RETRY_DELAY)
			end
		end
	end
	
	if success then
		if data then
			print("[LeaderstatsManager] Loaded data for", player.Name, "- Wins:", data.wins or 0)
			return data
		else
			print("[LeaderstatsManager] No saved data for", player.Name, "- Using defaults")
			return {wins = 0}
		end
	else
		warn("[LeaderstatsManager] Failed to load data for", player.Name, "- Using defaults")
		return {wins = 0}
	end
end

-- Save player data to DataStore
local function savePlayerData(player, data)
	if not winsDataStore then
		warn("[LeaderstatsManager] DataStore not available, cannot save")
		return false
	end
	
	local key = "Player_" .. player.UserId
	local success = false
	
	for attempt = 1, MAX_RETRIES do
		success = pcall(function()
			winsDataStore:SetAsync(key, data)
		end)
		
		if success then
			print("[LeaderstatsManager] Saved data for", player.Name, "- Wins:", data.wins)
			break
		else
			if attempt < MAX_RETRIES then
				wait(RETRY_DELAY)
			else
				warn("[LeaderstatsManager] Failed to save data for", player.Name, "after", MAX_RETRIES, "attempts")
			end
		end
	end
	
	return success
end

-- Handle player joining
local function onPlayerAdded(player)
	print("[LeaderstatsManager] Player joined:", player.Name)
	
	-- Create leaderstats
	local leaderstats, winsValue = createLeaderstats(player)
	
	-- Load saved data
	local savedData = loadPlayerData(player)
	playerDataCache[player] = savedData
	
	-- Apply saved values
	winsValue.Value = savedData.wins or 0
	
	-- Track changes
	winsValue.Changed:Connect(function(newValue)
		if playerDataCache[player] then
			playerDataCache[player].wins = newValue
			pendingSaves[player] = true
		end
	end)
end

-- Handle player leaving
local function onPlayerRemoving(player)
	print("[LeaderstatsManager] Player leaving:", player.Name)
	
	-- Save data one last time
	if playerDataCache[player] then
		savePlayerData(player, playerDataCache[player])
		playerDataCache[player] = nil
		pendingSaves[player] = nil
	end
end

-- Increment wins for a player
function LeaderstatsManager.IncrementWins(player, amount)
	amount = amount or 1
	
	if not player or not player:FindFirstChild("leaderstats") then
		warn("[LeaderstatsManager] Cannot increment wins - Invalid player or no leaderstats")
		return false
	end
	
	local wins = player.leaderstats:FindFirstChild("Wins")
	if wins then
		wins.Value = wins.Value + amount
		print("[LeaderstatsManager] Incremented wins for", player.Name, "- New total:", wins.Value)
		return true
	else
		warn("[LeaderstatsManager] Cannot increment wins - Wins stat not found")
		return false
	end
end

-- Get wins for a player
function LeaderstatsManager.GetWins(player)
	if not player or not player:FindFirstChild("leaderstats") then
		return 0
	end
	
	local wins = player.leaderstats:FindFirstChild("Wins")
	return wins and wins.Value or 0
end

-- Set wins for a player (use carefully)
function LeaderstatsManager.SetWins(player, value)
	if not player or not player:FindFirstChild("leaderstats") then
		warn("[LeaderstatsManager] Cannot set wins - Invalid player or no leaderstats")
		return false
	end
	
	local wins = player.leaderstats:FindFirstChild("Wins")
	if wins then
		wins.Value = math.max(0, value) -- Ensure non-negative
		print("[LeaderstatsManager] Set wins for", player.Name, "to", wins.Value)
		return true
	else
		warn("[LeaderstatsManager] Cannot set wins - Wins stat not found")
		return false
	end
end

-- Initialize
local function initialize()
	-- Connect player events
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	
	-- Handle players already in game
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	
	-- Autosave loop
	if winsDataStore then
		spawn(function()
			while true do
				wait(AUTOSAVE_INTERVAL)
				
				-- Save all pending data
				for player, _ in pairs(pendingSaves) do
					if player.Parent and playerDataCache[player] then
						savePlayerData(player, playerDataCache[player])
						pendingSaves[player] = nil
					end
				end
			end
		end)
		
		print("[LeaderstatsManager] Initialized with DataStore support")
	else
		print("[LeaderstatsManager] Initialized without DataStore support (Studio mode)")
	end
end

-- Bind to close (save all data when server shuts down)
game:BindToClose(function()
	print("[LeaderstatsManager] Server shutting down, saving all player data...")
	
	for player, data in pairs(playerDataCache) do
		if player.Parent then
			savePlayerData(player, data)
		end
	end
	
	wait(2) -- Give time for saves to complete
end)

-- Initialize the manager
initialize()

return LeaderstatsManager