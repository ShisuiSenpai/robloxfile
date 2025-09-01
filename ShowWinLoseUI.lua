-- ShowWinLoseUI.lua
-- Place this in StarterPlayer > StarterPlayerScripts to show the win/lose UI for testing
-- REMOVE THIS SCRIPT WHEN YOU'RE DONE TESTING

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Wait for PlayerGui
local playerGui = player:WaitForChild("PlayerGui")

-- Function to show win/lose UI for a specific table
local function showWinLoseUI(tableId, message, isWin)
	-- Wait for the poker game UI to be created
	wait(2) -- Give time for the game to initialize
	
	local uiName = "PokerGameUI_" .. tableId
	local pokerUI = playerGui:WaitForChild(uiName, 5)
	
	if pokerUI then
		local statusFrame = pokerUI:FindFirstChild("StatusFrame")
		if statusFrame then
			local statusLabel = statusFrame:FindFirstChild("StatusLabel")
			if statusLabel then
				-- Make it visible
				statusFrame.Visible = true
				
				-- Set the message and color
				statusLabel.Text = message
				if isWin then
					statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green for win
				else
					statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red for lose
				end
				
				print("[ShowWinLoseUI] Enabled win/lose UI for", tableId, "with message:", message)
			end
		end
	else
		warn("[ShowWinLoseUI] Could not find PokerGameUI for table:", tableId)
	end
end

-- Example: Show win UI for Table1 after 3 seconds
wait(3)
showWinLoseUI("Table1", "You Win!", true)

-- You can also test the lose UI by uncommenting this:
-- showWinLoseUI("Table1", "You found the Poker! You Lose!", false)

-- Or test for different tables:
-- showWinLoseUI("Table2", "You Win!", true)
-- showWinLoseUI("Table3", "You Lose!", false)