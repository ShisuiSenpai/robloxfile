-- TestStreakUI.lua
-- Manual test script for streak UI
-- Place in ServerScriptService temporarily

local Players = game:GetService("Players")

-- Wait for StreakManager
repeat wait(0.1) until _G.StreakManager

-- Command to manually set streak
game.Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		local args = message:split(" ")
		
		if args[1] == "/streak" and args[2] then
			local streakNum = tonumber(args[2])
			if streakNum then
				-- Reset and then increment to desired number
				_G.StreakManager.ResetStreak(player)
				for i = 1, streakNum do
					_G.StreakManager.IncrementStreak(player)
				end
				print("[TestStreakUI] Set", player.Name, "streak to", streakNum)
			end
		elseif args[1] == "/resetstreak" then
			_G.StreakManager.ResetStreak(player)
			print("[TestStreakUI] Reset", player.Name, "streak")
		end
	end)
end)

print("[TestStreakUI] Test script loaded. Use '/streak [number]' to test streak UI")