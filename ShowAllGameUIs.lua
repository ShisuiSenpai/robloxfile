-- ShowAllGameUIs.lua
-- This script shows ALL game UIs at once for testing/viewing in StarterGui
-- Place this in StarterPlayer > StarterPlayerScripts
-- REMOVE THIS SCRIPT WHEN YOU'RE DONE TESTING

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for game to initialize
wait(5)

-- Function to make all poker UIs visible
local function showAllPokerUIs()
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui.Name:match("^PokerGameUI_") then
			print("[ShowAllGameUIs] Found UI:", gui.Name)
			
			-- Show the status frame (win/lose UI)
			local statusFrame = gui:FindFirstChild("StatusFrame")
			if statusFrame then
				statusFrame.Visible = true
				local statusLabel = statusFrame:FindFirstChild("StatusLabel")
				if statusLabel then
					-- Set example text
					local tableId = gui.Name:match("PokerGameUI_(.+)")
					if tableId == "Table1" then
						statusLabel.Text = "You Win!"
						statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
					elseif tableId == "Table2" then
						statusLabel.Text = "You found the Poker! You Lose!"
						statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
					else
						statusLabel.Text = "Game Over"
						statusLabel.TextColor3 = Color3.new(1, 1, 1)
					end
				end
			end
			
			-- Also show the turn frame
			local turnFrame = gui:FindFirstChild("TurnFrame")
			if turnFrame then
				turnFrame.Visible = true
				local turnLabel = turnFrame:FindFirstChild("TurnLabel")
				if turnLabel then
					turnLabel.Text = "Your Turn"
				end
			end
		end
	end
end

-- Show all UIs
showAllPokerUIs()

-- Keep checking for new UIs every 2 seconds
while wait(2) do
	showAllPokerUIs()
end