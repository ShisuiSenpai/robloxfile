-- QuickMatchServerV2.lua
-- Server-side quick match system using RemoteEvents (more reliable)
-- Place this in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Try to find TableManager with error handling
local TableManager
local success, err = pcall(function()
	TableManager = require(script.Parent:WaitForChild("TableManager"))
end)

if not success then
	warn("[QuickMatch Server V2] Failed to load TableManager:", err)
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
		print("[QuickMatch Server V2] Found TableManager at:", moduleScript:GetFullName())
	else
		error("[QuickMatch Server V2] Could not find TableManager module!")
	end
end

-- Get RemoteEvents for QuickMatch
local quickMatchEvent = ReplicatedStorage:WaitForChild("QuickMatchEvent")
local requestEvent = quickMatchEvent:WaitForChild("QuickMatchRequest")
local responseEvent = quickMatchEvent:WaitForChild("QuickMatchResponse")

-- Track pending requests to prevent spam
local pendingRequests = {}

-- Handle quick match requests
requestEvent.OnServerEvent:Connect(function(player)
	-- Prevent spam
	if pendingRequests[player] then
		print("[QuickMatch Server V2] Ignoring duplicate request from:", player.Name)
		return
	end

	pendingRequests[player] = true

	print("[QuickMatch Server V2] Request from:", player.Name)

	-- Process request
	local success, result = pcall(function()
		-- Check if player exists
		if not player or not player.Parent then
			print("[QuickMatch Server V2] Player object invalid")
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
			print("[QuickMatch Server V2] Error checking player table:", currentTable)
			return {
				success = false,
				message = "Error checking current table!"
			}
		end

		if currentTable then
			print("[QuickMatch Server V2] Player already seated at table:", currentTable.tableId)
			return {
				success = false,
				message = "You are already seated at a table!"
			}
		end

		-- Check if player has a character
		if not player.Character then
			print("[QuickMatch Server V2] No character found for player")
			return {
				success = false,
				message = "Character not found!"
			}
		end

		-- Check character parent (might be nil during respawn)
		if not player.Character.Parent then
			print("[QuickMatch Server V2] Character has no parent (respawning?)")
			return {
				success = false,
				message = "Character is respawning, please try again!"
			}
		end

		local humanoid = player.Character:FindFirstChild("Humanoid")
		if not humanoid then
			print("[QuickMatch Server V2] No humanoid found in character")
			return {
				success = false,
				message = "Humanoid not found!"
			}
		end

		print("[QuickMatch Server V2] Player checks passed, looking for tables...")

		-- Find best available table
		local tableInstance, seat
		local findSuccess, findError = pcall(function()
			tableInstance, seat = TableManager.getBestTableForQuickMatch()
		end)

		if not findSuccess then
			print("[QuickMatch Server V2] Error finding table:", findError)
			return {
				success = false,
				message = "Error finding available table!"
			}
		end

		if not tableInstance or not seat then
			print("[QuickMatch Server V2] No available tables found")
			return {
				success = false,
				message = "No available tables found!"
			}
		end

		print("[QuickMatch Server V2] Found table:", tableInstance.tableId, "seat:", seat.Name)

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
			print("[QuickMatch Server V2] Player", player.Name, "matched to table", tableInstance.tableId)

			return {
				success = true,
				tableId = tableInstance.tableId,
				message = "Successfully matched to table " .. tableInstance.tableId .. "!"
			}
		else
			print("[QuickMatch Server V2] Failed to teleport player to seat")
			return {
				success = false,
				message = "Failed to teleport to seat!"
			}
		end
	end)

	-- Clear pending flag
	pendingRequests[player] = nil

	-- Send response
	if success and result then
		print("[QuickMatch Server V2] Sending response to", player.Name, "- Success:", result.success)
		responseEvent:FireClient(player, result)
	else
		print("[QuickMatch Server V2] Error during request:", result)
		responseEvent:FireClient(player, {
			success = false,
			message = "Server error: " .. tostring(result)
		})
	end
end)

-- Clean up pending requests when player leaves
Players.PlayerRemoving:Connect(function(player)
	pendingRequests[player] = nil
end)

print("[QuickMatch Server V2] Initialized with RemoteEvents")