-- WinsLeaderstat.lua
-- Simple wins tracking system for the poker game
-- Place this in ServerScriptService as a regular Script

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- DataStore for persistence (optional)
local winsDataStore
local dataStoreEnabled = false

-- Try to get DataStore (will fail in Studio without API access)
local success, err = pcall(function()
	winsDataStore = DataStoreService:GetDataStore("PlayerWinsDataV1")
	dataStoreEnabled = true
end)

if not success then
	warn("[WinsLeaderstat] DataStore not available:", err)
end

-- Table to track wins in memory
local playerWins = {}

-- Create leaderstats when player joins
local function onPlayerAdded(player)
	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Create Wins stat
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = leaderstats

	-- Load saved wins if DataStore is available
	if dataStoreEnabled then
		local success, data = pcall(function()
			return winsDataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and data then
			wins.Value = data
			print("[WinsLeaderstat] Loaded", player.Name, "wins:", data)
		end
	end

	-- Track in memory
	playerWins[player] = wins.Value

	print("[WinsLeaderstat] Created leaderstats for", player.Name)
end

-- Save wins when player leaves
local function onPlayerRemoving(player)
	if dataStoreEnabled and playerWins[player] then
		local success, err = pcall(function()
			winsDataStore:SetAsync("Player_" .. player.UserId, playerWins[player])
		end)

		if success then
			print("[WinsLeaderstat] Saved", player.Name, "wins:", playerWins[player])
		else
			warn("[WinsLeaderstat] Failed to save", player.Name, "wins:", err)
		end
	end

	playerWins[player] = nil
end

-- Module functions that other scripts can use
_G.WinsManager = {}

-- Increment wins for a player
function _G.WinsManager.IncrementWins(player)
	if not player or not player.Parent then return false end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return false end

	local wins = leaderstats:FindFirstChild("Wins")
	if not wins then return false end

	wins.Value = wins.Value + 1
	playerWins[player] = wins.Value

	print("[WinsLeaderstat] Incremented wins for", player.Name, "- New total:", wins.Value)
	return true
end

-- Get wins for a player
function _G.WinsManager.GetWins(player)
	if not player or not player.Parent then return 0 end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return 0 end

	local wins = leaderstats:FindFirstChild("Wins")
	return wins and wins.Value or 0
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in game
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Periodic save (every 60 seconds)
if dataStoreEnabled then
	spawn(function()
		while true do
			wait(60)
			for player, wins in pairs(playerWins) do
				if player.Parent then
					local leaderstats = player:FindFirstChild("leaderstats")
					if leaderstats then
						local winsValue = leaderstats:FindFirstChild("Wins")
						if winsValue then
							playerWins[player] = winsValue.Value
						end
					end
				end
			end
		end
	end)
end

print("[WinsLeaderstat] System initialized!")

-- Server shutdown save
game:BindToClose(function()
	if dataStoreEnabled then
		for player, wins in pairs(playerWins) do
			if player.Parent then
				pcall(function()
					winsDataStore:SetAsync("Player_" .. player.UserId, wins)
				end)
			end
		end
		wait(2)
	end
end)