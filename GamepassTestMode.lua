-- Gamepass Test Mode - Server Script
-- Place this in ServerScriptService
-- Allows testing gamepasses in Studio and controlling them in published games
-- Works for game owners who already own gamepasses!

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ALWAYS enabled (works in Studio AND published games)
local TEST_MODE_ENABLED = true

print("[TEST MODE] ========================================")
print("[TEST MODE] GAMEPASS TEST MODE ENABLED")
print("[TEST MODE] Commands available:")
print("[TEST MODE] /givepass PUSH_BOOST - Give yourself 2x Push Boost")
print("[TEST MODE] /givepass WINS_2X - Give yourself 2x Wins")
print("[TEST MODE] /givepass SPEED_BOOST - Give yourself Speed Boost")
print("[TEST MODE] /givepass ALL - Give yourself all gamepasses")
print("[TEST MODE] /removepass PUSH_BOOST - Remove 2x Push Boost")
print("[TEST MODE] /removepass WINS_2X - Remove 2x Wins")
print("[TEST MODE] /removepass SPEED_BOOST - Remove Speed Boost")
print("[TEST MODE] /removepass ALL - Remove all gamepasses")
print("[TEST MODE] /normalplayer - Act as a normal player (no gamepasses)")
print("[TEST MODE] /resetmode - Go back to using your real gamepasses")
print("[TEST MODE] /checkpass - Check your current gamepasses")
print("[TEST MODE] ========================================")

-- Fake gamepass ownership for testing
local testGamepasses = {} -- [UserId] = {PUSH_BOOST = true/false, etc.}
local normalPlayerMode = {} -- [UserId] = true/false (if true, all gamepasses return false)

-- Wait for GamepassManager to load
task.wait(2)

if not _G.GamepassManager then
	warn("[TEST MODE] GamepassManager not found! Make sure it's running.")
	return
end

-- Override the hasGamepass function for testing
local originalHasGamepass = _G.GamepassManager.hasGamepass

_G.GamepassManager.hasGamepass = function(player, gamepassName)
	if not player then return false end
	
	-- Check if player is in "normal player mode" (testing without gamepasses)
	if normalPlayerMode[player.UserId] then
		print("[TEST MODE] Normal player mode - returning false for", gamepassName)
		return false
	end
	
	-- Check test mode overrides
	if testGamepasses[player.UserId] and testGamepasses[player.UserId][gamepassName] ~= nil then
		print("[TEST MODE] Returning test value for", player.Name, "-", gamepassName, ":", testGamepasses[player.UserId][gamepassName])
		return testGamepasses[player.UserId][gamepassName]
	end
	
	-- Fall back to original function (real ownership check)
	return originalHasGamepass(player, gamepassName)
end

print("[TEST MODE] Overrode hasGamepass function for testing!")

-- Command handler
local function handleCommand(player, message)
	local args = string.split(message, " ")
	local command = args[1]:lower()
	
	if command == "/givepass" then
		if not args[2] then
			warn("[TEST MODE]", player.Name, "- Please specify a gamepass name!")
			return
		end
		
		local passName = args[2]:upper()
		
		-- Initialize if needed
		if not testGamepasses[player.UserId] then
			testGamepasses[player.UserId] = {}
		end
		
		if passName == "ALL" then
			testGamepasses[player.UserId].PUSH_BOOST = true
			testGamepasses[player.UserId].WINS_2X = true
			testGamepasses[player.UserId].SPEED_BOOST = true
			print("[TEST MODE]", player.Name, "- Gave all gamepasses!")
			
			-- Apply speed boost immediately
			if player.Character then
				_G.GamepassManager.applySpeedBoost(player.Character, 1.25)
			end
		elseif passName == "PUSH_BOOST" or passName == "WINS_2X" or passName == "SPEED_BOOST" then
			testGamepasses[player.UserId][passName] = true
			print("[TEST MODE]", player.Name, "- Gave", passName, "!")
			
			-- Apply speed boost immediately if needed
			if passName == "SPEED_BOOST" and player.Character then
				_G.GamepassManager.applySpeedBoost(player.Character, 1.25)
			end
		else
			warn("[TEST MODE]", player.Name, "- Invalid gamepass name:", passName)
		end
		
	elseif command == "/removepass" then
		if not args[2] then
			warn("[TEST MODE]", player.Name, "- Please specify a gamepass name!")
			return
		end
		
		local passName = args[2]:upper()
		
		if not testGamepasses[player.UserId] then
			testGamepasses[player.UserId] = {}
		end
		
		if passName == "ALL" then
			testGamepasses[player.UserId].PUSH_BOOST = false
			testGamepasses[player.UserId].WINS_2X = false
			testGamepasses[player.UserId].SPEED_BOOST = false
			print("[TEST MODE]", player.Name, "- Removed all gamepasses!")
			
			-- Remove speed boost
			if player.Character then
				_G.GamepassManager.applySpeedBoost(player.Character, 1)
			end
		elseif passName == "PUSH_BOOST" or passName == "WINS_2X" or passName == "SPEED_BOOST" then
			testGamepasses[player.UserId][passName] = false
			print("[TEST MODE]", player.Name, "- Removed", passName, "!")
			
			-- Remove speed boost if needed
			if passName == "SPEED_BOOST" and player.Character then
				_G.GamepassManager.applySpeedBoost(player.Character, 1)
			end
		else
			warn("[TEST MODE]", player.Name, "- Invalid gamepass name:", passName)
		end
		
	elseif command == "/normalplayer" then
		normalPlayerMode[player.UserId] = true
		testGamepasses[player.UserId] = nil -- Clear any test passes
		print("[TEST MODE] ========================================")
		print("[TEST MODE]", player.Name, "- Now acting as NORMAL PLAYER")
		print("[TEST MODE] All gamepasses disabled (even if you own them)")
		print("[TEST MODE] Use /resetmode to go back to normal")
		print("[TEST MODE] ========================================")
		
		-- Remove speed boost
		if player.Character then
			_G.GamepassManager.applySpeedBoost(player.Character, 1)
		end
		
	elseif command == "/resetmode" then
		normalPlayerMode[player.UserId] = false
		testGamepasses[player.UserId] = nil -- Clear any test passes
		print("[TEST MODE] ========================================")
		print("[TEST MODE]", player.Name, "- Reset to NORMAL MODE")
		print("[TEST MODE] Using your real gamepass ownership")
		print("[TEST MODE] ========================================")
		
		-- Reapply speed boost if you own it
		if player.Character and originalHasGamepass(player, "SPEED_BOOST") then
			_G.GamepassManager.applySpeedBoost(player.Character, 1.25)
		end
		
	elseif command == "/checkpass" then
		print("[TEST MODE] ========================================")
		print("[TEST MODE]", player.Name, "'s Gamepass Status:")
		
		if normalPlayerMode[player.UserId] then
			print("[TEST MODE] MODE: Normal Player (all gamepasses disabled)")
		elseif testGamepasses[player.UserId] then
			print("[TEST MODE] MODE: Test Mode (custom gamepasses)")
			print("[TEST MODE] Push Boost (2x):", testGamepasses[player.UserId].PUSH_BOOST or false)
			print("[TEST MODE] Wins (2x):", testGamepasses[player.UserId].WINS_2X or false)
			print("[TEST MODE] Speed Boost:", testGamepasses[player.UserId].SPEED_BOOST or false)
		else
			print("[TEST MODE] MODE: Normal (using real ownership)")
			print("[TEST MODE] Push Boost (2x):", originalHasGamepass(player, "PUSH_BOOST"))
			print("[TEST MODE] Wins (2x):", originalHasGamepass(player, "WINS_2X"))
			print("[TEST MODE] Speed Boost:", originalHasGamepass(player, "SPEED_BOOST"))
		end
		
		print("[TEST MODE] ========================================")
	end
end

-- Connect to player chat
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		handleCommand(player, message)
	end)
end)

-- Connect for existing players
for _, player in pairs(Players:GetPlayers()) do
	player.Chatted:Connect(function(message)
		handleCommand(player, message)
	end)
end

print("[TEST MODE] Commands ready!")
print("[TEST MODE] Type /normalplayer to test without gamepasses!")
print("[TEST MODE] Type /givepass ALL to test with all gamepasses!")
print("[TEST MODE] Type /resetmode to use your real gamepass ownership!")
warn("[TEST MODE] REMOVE THIS SCRIPT WHEN YOU'RE DONE TESTING!")
