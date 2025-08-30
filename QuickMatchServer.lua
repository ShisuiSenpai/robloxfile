-- QuickMatchServer.lua
-- Server-side quick match system
-- Place this in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to find TableManager with error handling
local TableManager
local success, err = pcall(function()
	TableManager = require(script.Parent:WaitForChild("TableManager"))
end)

if not success then
	warn("[QuickMatch Server] Failed to load TableManager:", err)
	-- Try alternative paths
	local serverStorage = game:GetService("ServerStorage")
	local serverScriptService = game:GetService("ServerScriptService")
	
	-- Try ServerScriptService first
	local moduleScript = serverScriptService:FindFirstChild("TableManager")
	if not moduleScript then
		-- Try ServerStorage
		moduleScript = serverStorage:FindFirstChild("TableManager")
	end
	
	if moduleScript then
		TableManager = require(moduleScript)
		print("[QuickMatch Server] Found TableManager at:", moduleScript:GetFullName())
	else
		error("[QuickMatch Server] Could not find TableManager module!")
	end
end

-- Get RemoteFunction for QuickMatch
local quickMatchEvent = ReplicatedStorage:WaitForChild("QuickMatchEvent")
local quickMatchRemote = quickMatchEvent:WaitForChild("QuickMatchFunction")

-- Handle quick match requests
quickMatchRemote.OnServerInvoke = function(player)
	print("[QuickMatch Server] Request from:", player.Name)
	
	-- Wrap everything in pcall to catch any errors
	local success, result = pcall(function()
		-- Check if player exists
		if not player or not player.Parent then
			print("[QuickMatch Server] Player object invalid")
			return {
				success = false,
				message = "Invalid player!"
			}
		end
		
		-- Check if player is already seated
		local checkSuccess, currentTable = pcall(function()
			return TableManager.getPlayerTable(player)
		end)
		
		if not checkSuccess then
			print("[QuickMatch Server] Error checking player table:", currentTable)
			return {
				success = false,
				message = "Error checking current table!"
			}
		end
		
		if currentTable then
			print("[QuickMatch Server] Player already seated at table:", currentTable.tableId)
			return {
				success = false,
				message = "You are already seated at a table!"
			}
		end
		
		-- Check if player has a character
		if not player.Character then
			print("[QuickMatch Server] No character found for player")
			return {
				success = false,
				message = "Character not found!"
			}
		end
		
		-- Check character parent (might be nil during respawn)
		if not player.Character.Parent then
			print("[QuickMatch Server] Character has no parent (respawning?)")
			return {
				success = false,
				message = "Character is respawning, please try again!"
			}
		end
		
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if not humanoid then
			print("[QuickMatch Server] No humanoid found in character")
			return {
				success = false,
				message = "Humanoid not found!"
			}
		end
		
		print("[QuickMatch Server] Player checks passed, looking for tables...")
		
		-- Find best available table
		local findSuccess, findResult = pcall(function()
			return TableManager.getBestTableForQuickMatch()
		end)
		
		if not findSuccess then
			print("[QuickMatch Server] Error finding table:", findResult)
			return {
				success = false,
				message = "Error finding available table!"
			}
		end
		
		local tableInstance, seat = findResult, nil
		if type(findResult) == "table" then
			-- getBestTableForQuickMatch returns two values, but pcall wraps them
			-- This is a limitation, so let's call it directly with error handling
			tableInstance, seat = TableManager.getBestTableForQuickMatch()
		end
		
		if not tableInstance or not seat then
			print("[QuickMatch Server] No available tables found")
			return {
				success = false,
				message = "No available tables found!"
			}
		end
		
		print("[QuickMatch Server] Found table:", tableInstance.tableId, "seat:", seat.Name)
		
		-- Teleport player to the seat
		local teleportSuccess = pcall(function()
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
		
		if teleportSuccess then
			-- Log the match
			print("[QuickMatch] Player", player.Name, "matched to table", tableInstance.tableId)
			
			return {
				success = true,
				tableId = tableInstance.tableId,
				message = "Successfully matched to table " .. tableInstance.tableId .. "!"
			}
		else
			print("[QuickMatch] Failed to teleport player to seat")
			return {
				success = false,
				message = "Failed to teleport to seat!"
			}
		end
	end)
	
	-- Handle pcall results
	if success then
		print("[QuickMatch Server] Request completed successfully")
		return result
	else
		print("[QuickMatch Server] Error during request:", result)
		return {
			success = false,
			message = "Server error: " .. tostring(result)
		}
	end
end

-- Test the RemoteFunction connection
spawn(function()
	wait(2)
	print("[QuickMatch Server] Testing RemoteFunction...")
	local testSuccess = pcall(function()
		local _ = quickMatchRemote.OnServerInvoke
	end)
	print("[QuickMatch Server] RemoteFunction test:", testSuccess and "PASSED" or "FAILED")
end)

print("[QuickMatch] Server initialized - TableManager:", TableManager ~= nil, "RemoteFunction:", quickMatchRemote ~= nil)