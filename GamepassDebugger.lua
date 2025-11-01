-- Gamepass Debugger - Server Script
-- Place this in ServerScriptService TEMPORARILY to debug gamepass issues
-- Remove this script once everything is working!

local Players = game:GetService("Players")

print("[GAMEPASS DEBUG] Debugger loaded - waiting for GamepassManager...")

-- Wait for GamepassManager to load
task.wait(2)

if not _G.GamepassManager then
	warn("[GAMEPASS DEBUG] GamepassManager not found! Make sure GamepassManager.lua is running!")
	return
end

print("[GAMEPASS DEBUG] GamepassManager found!")

-- Check the gamepass IDs
local ids = _G.GamepassManager.GAMEPASS_IDS
if ids then
	print("========================================")
	print("[GAMEPASS DEBUG] Current Gamepass IDs:")
	print("PUSH_BOOST:", ids.PUSH_BOOST)
	print("WINS_2X:", ids.WINS_2X)
	print("SPEED_BOOST:", ids.SPEED_BOOST)
	print("========================================")
	
	if ids.PUSH_BOOST == 0 or ids.WINS_2X == 0 or ids.SPEED_BOOST == 0 then
		warn("[GAMEPASS DEBUG] ?? Some IDs are still 0! You need to replace them with real gamepass IDs!")
	end
end

-- Add a command to manually check gamepass ownership
Players.PlayerAdded:Connect(function(player)
	print("[GAMEPASS DEBUG]", player.Name, "joined - checking their gamepasses...")
	
	-- Wait for gamepasses to load
	task.wait(3)
	
	-- Check each gamepass
	local hasBoost = _G.GamepassManager.hasGamepass(player, "PUSH_BOOST")
	local hasWins = _G.GamepassManager.hasGamepass(player, "WINS_2X")
	local hasSpeed = _G.GamepassManager.hasGamepass(player, "SPEED_BOOST")
	
	print("========================================")
	print("[GAMEPASS DEBUG]", player.Name, "'s Gamepasses:")
	print("Push Boost (2x):", hasBoost)
	print("Wins (2x):", hasWins)
	print("Speed Boost:", hasSpeed)
	print("========================================")
end)

-- Monitor all gamepass-related activity
local MarketplaceService = game:GetService("MarketplaceService")

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, purchaseSuccess)
	print("========================================")
	print("[GAMEPASS DEBUG] Purchase Event:")
	print("Player:", player.Name)
	print("Gamepass ID:", gamepassId)
	print("Success:", purchaseSuccess)
	print("========================================")
	
	if purchaseSuccess then
		-- Wait for cache to update
		task.wait(2)
		
		-- Check if they now have the gamepass
		print("[GAMEPASS DEBUG] Checking ownership after purchase...")
		
		if _G.GamepassManager and _G.GamepassManager.checkOwnership then
			local success, testOwnership = pcall(function()
				return _G.GamepassManager.checkOwnership(player, gamepassId)
			end)
			
			if success then
				print("[GAMEPASS DEBUG] Direct ownership check result:", testOwnership)
			else
				warn("[GAMEPASS DEBUG] Error checking ownership:", testOwnership)
			end
		else
			warn("[GAMEPASS DEBUG] checkOwnership function not found!")
		end
		
		-- Also check if this gamepass ID is in the GAMEPASS_IDS table
		local ids = _G.GamepassManager.GAMEPASS_IDS
		local foundMatch = false
		for name, id in pairs(ids) do
			if id == gamepassId then
				print("[GAMEPASS DEBUG] Purchased gamepass matches:", name)
				foundMatch = true
				break
			end
		end
		
		if not foundMatch then
			warn("[GAMEPASS DEBUG] ?? Purchased gamepass ID", gamepassId, "is NOT in GAMEPASS_IDS table!")
			warn("[GAMEPASS DEBUG] This gamepass won't do anything! Check your ShopUI.lua IDs!")
		end
	end
end)

print("[GAMEPASS DEBUG] Debugger active! Watch the output for gamepass info.")
print("[GAMEPASS DEBUG] Remove this script once everything is working correctly.")
