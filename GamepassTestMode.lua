-- Gamepass Test Mode - Server Script
-- Place this in ServerScriptService
-- Allows testing gamepasses in Studio without buying them
-- REMOVE THIS BEFORE PUBLISHING YOUR GAME!

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Only enable test mode in Studio
local TEST_MODE_ENABLED = RunService:IsStudio()

if not TEST_MODE_ENABLED then
	print("[TEST MODE] Not in Studio - test mode disabled")
	return
end

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
print("[TEST MODE] /checkpass - Check your current gamepasses")
print("[TEST MODE] ========================================")

-- Fake gamepass ownership for testing
local testGamepasses = {} -- [UserId] = {PUSH_BOOST = true/false, etc.}

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
	
	-- Check test mode overrides first
	if testGamepasses[player.UserId] and testGamepasses[player.UserId][gamepassName] ~= nil then
		print("[TEST MODE] Returning test value for", player.Name, "-", gamepassName, ":", testGamepasses[player.UserId][gamepassName])
		return testGamepasses[player.UserId][gamepassName]
	end
	
	-- Fall back to original function (will return false in Studio)
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
		
	elseif command == "/checkpass" then
		print("[TEST MODE] ========================================")
		print("[TEST MODE]", player.Name, "'s Test Gamepasses:")
		
		if testGamepasses[player.UserId] then
			print("[TEST MODE] Push Boost (2x):", testGamepasses[player.UserId].PUSH_BOOST or false)
			print("[TEST MODE] Wins (2x):", testGamepasses[player.UserId].WINS_2X or false)
			print("[TEST MODE] Speed Boost:", testGamepasses[player.UserId].SPEED_BOOST or false)
		else
			print("[TEST MODE] No test gamepasses granted yet")
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

print("[TEST MODE] Commands ready! Type /givepass ALL to test all gamepasses!")
warn("[TEST MODE] ?? REMEMBER TO REMOVE THIS SCRIPT BEFORE PUBLISHING!")
