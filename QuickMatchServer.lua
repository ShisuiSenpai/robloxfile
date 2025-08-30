-- QuickMatchServer.lua
-- Server-side quick match system
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableManager = require(script.Parent:WaitForChild("TableManager"))

-- Get RemoteFunction for QuickMatch
local quickMatchEvent = ReplicatedStorage:WaitForChild("QuickMatchEvent")
local quickMatchRemote = quickMatchEvent:WaitForChild("QuickMatchFunction")

-- Handle quick match requests
quickMatchRemote.OnServerInvoke = function(player)
	-- Check if player is already seated
	local currentTable = TableManager.getPlayerTable(player)
	if currentTable then
		return {
			success = false,
			message = "You are already seated at a table!"
		}
	end
	
	-- Check if player has a character
	if not player.Character then
		return {
			success = false,
			message = "Character not found!"
		}
	end
	
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then
		return {
			success = false,
			message = "Humanoid not found!"
		}
	end
	
	-- Find best available table
	local tableInstance, seat = TableManager.getBestTableForQuickMatch()
	
	if not tableInstance or not seat then
		return {
			success = false,
			message = "No available tables found!"
		}
	end
	
	-- Teleport player to the seat
	local success = pcall(function()
		-- Unseat player if currently seated elsewhere
		if humanoid.SeatPart then
			humanoid.Sit = false
			wait(0.1)
		end
		
		-- Teleport character near the seat
		local seatPosition = seat.Position
		local teleportPosition = seatPosition + Vector3.new(0, 3, 0) -- Slightly above seat
		player.Character:SetPrimaryPartCFrame(CFrame.new(teleportPosition))
		
		-- Wait a frame for physics
		wait()
		
		-- Sit the player
		seat:Sit(humanoid)
	end)
	
	if success then
		-- Log the match
		print("[QuickMatch] Player", player.Name, "matched to table", tableInstance.tableId)
		
		return {
			success = true,
			tableId = tableInstance.tableId,
			message = "Successfully matched to table " .. tableInstance.tableId .. "!"
		}
	else
		return {
			success = false,
			message = "Failed to seat player!"
		}
	end
end

-- Initialize all tables on server start
for tableId, config in pairs(TableManager.TABLE_CONFIGS) do
	local tableInstance = TableManager.initializeTable(tableId)
	if tableInstance then
		print("[QuickMatch] Table", tableId, "initialized for quick match")
	end
end

print("[QuickMatch] Server initialized")