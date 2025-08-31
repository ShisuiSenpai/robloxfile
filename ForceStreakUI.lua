-- ForceStreakUI.lua
-- Force update streak UI for testing
-- Place in ServerScriptService temporarily

local Players = game:GetService("Players")

-- Wait for StreakManager
repeat wait(0.1) until _G.StreakManager

-- Add chat command
game.Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if message == "/forceui" then
			-- Get current streak
			local currentStreak = _G.StreakManager.GetStreak(player)
			print("[ForceStreakUI] Current streak for", player.Name, "is", currentStreak)
			
			-- Force increment to trigger UI
			if currentStreak < 2 then
				-- Set to 2 to trigger UI
				for i = currentStreak + 1, 2 do
					_G.StreakManager.IncrementStreak(player)
				end
			else
				-- Just re-increment current
				_G.StreakManager.ResetStreak(player)
				for i = 1, currentStreak do
					_G.StreakManager.IncrementStreak(player)
				end
			end
		end
	end)
end)

print("[ForceStreakUI] Test script loaded. Use '/forceui' to force streak UI update")