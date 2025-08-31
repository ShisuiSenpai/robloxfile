-- PokerGameClientFix_Winner.lua
-- This is a targeted fix for the winner UI issue

-- Add this function to your PokerGameClientMulti.lua after the validateUI function

-- Force complete UI reset for a table
local function forceUIReset(tableData)
	print("[PokerGame] Forcing complete UI reset for table", tableData.id)
	
	-- Disable and clear existing UI
	if tableData.gameUI then
		tableData.gameUI.Enabled = false
		tableData.gameUI = nil
	end
	
	-- Clear all UI references
	tableData.turnLabel = nil
	tableData.statusLabel = nil
	
	-- Wait a frame to ensure cleanup
	RunService.Heartbeat:Wait()
	
	-- Setup fresh UI
	setupGameUI(tableData)
	
	-- Ensure UI is enabled
	if tableData.gameUI then
		tableData.gameUI.Enabled = true
		print("[PokerGame] UI reset complete for table", tableData.id)
		return true
	else
		warn("[PokerGame] UI reset failed for table", tableData.id)
		return false
	end
end

-- REPLACE the existing game_end handler with this:
elseif state == "game_end" then
	print("[PokerGame] Game ended for table", tableData.id, "- Player:", player.Name, "Winner:", data and data.winner)
	
	-- Check if we're the winner
	local isWinner = data and data.winner == player.Name
	
	-- Immediately set game as inactive
	tableData.gameActive = false
	tableData.isMyTurn = false
	tableData.isCountdownActive = false
	tableData.currentHoveredCard = nil
	
	-- Don't destroy highlights yet - just disable them
	-- They will be destroyed on full_reset
	for card, highlight in pairs(tableData.cardHighlights) do
		if highlight and highlight.Parent then
			highlight.Enabled = false
		end
	end
	
	-- Show winner/loser message if at this table
	if tableData.gameUI and getCurrentTable() == tableData then
		local statusFrame = tableData.gameUI.StatusFrame
		statusFrame.Visible = true
		
		local statusLabel = tableData.statusLabel
		if statusLabel then
			if data and data.winner == player.Name then
				statusLabel.Text = "You Win!"
				statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				playSound("Win")
			elseif data and data.loser == player.Name then
				statusLabel.Text = "You Lose!"
				statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
				playSound("Lose")
			else
				statusLabel.Text = data.winner .. " Wins!"
				statusLabel.TextColor3 = Color3.new(1, 1, 1)
			end

			-- Hide after delay and show waiting UI again
			coroutine.wrap(function()
				local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
				local hideDelay = data.winner == player.Name and 2 or 3
				wait(hideDelay)
				
				-- FORCE UI RESET FOR WINNERS
				if isWinner and getCurrentTable() == tableData then
					print("[PokerGame] Winner detected, forcing UI reset")
					forceUIReset(tableData)
				end
				
				if tableData.gameUI then
					-- Fade out status frame
					local fadeTween = TweenService:Create(statusFrame,
						TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
						{Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}
					)
					fadeTween:Play()
					
					fadeTween.Completed:Connect(function()
						statusFrame.Visible = false
						statusFrame.Size = UDim2.new(0, 400, 0, 100)
						statusFrame.Position = UDim2.new(0.5, -200, 0.5, -50)
						
						-- Check if still seated and show waiting UI
						if humanoid and humanoid.SeatPart then
							for _, seat in ipairs(tableData.seats) do
								if humanoid.SeatPart == seat then
									-- Still seated at this table
									if not tableData.gameActive then
										-- Validate UI before using it
										if not validateUI(tableData) then
											warn("[PokerGame] UI invalid after game end, recreating for winner")
											tableData.gameUI = nil
											setupGameUI(tableData)
										end
										
										if tableData.gameUI then
											local turnFrame = tableData.gameUI:FindFirstChild("TurnFrame")
											if turnFrame then
												turnFrame.Visible = true
												stopWaitingAnimation(tableData)
												startWaitingAnimation(tableData, tableData.turnLabel)
											end
										end
									end
									break
								end
							end
						end
					end)
				end
			end)()
		end
	end
	
	-- Hide turn UI
	if tableData.gameUI then
		tableData.gameUI.TurnFrame.Visible = false
	end

-- ALSO REPLACE the countdown_start handler to ensure connections are alive:
if state == "countdown_start" then
	print("[PokerGame] Countdown starting for table:", tableData.id, "- Player:", player.Name)
	tableData.isCountdownActive = true
	tableData.gameActive = false
	
	-- Force UI refresh for all players (especially winners who didn't respawn)
	if getCurrentTable() == tableData then
		-- Check if we need to reset UI (for winners)
		local needsReset = not validateUI(tableData)
		
		-- Also check if we can receive turn updates
		if not needsReset then
			-- Test if connections are working by checking UI responsiveness
			local testUI = tableData.gameUI
			if testUI and testUI.Parent then
				-- UI exists, but let's make sure it's truly functional
				local turnFrame = testUI:FindFirstChild("TurnFrame")
				if not turnFrame or not turnFrame.Parent then
					needsReset = true
				end
			else
				needsReset = true
			end
		end
		
		if needsReset then
			warn("[PokerGame] UI needs reset at countdown start")
			forceUIReset(tableData)
		end
	end
	
	if tableData.gameUI then
		-- print("[DEBUG] Hiding TurnFrame for countdown")
		local turnFrame = tableData.gameUI:FindFirstChild("TurnFrame")
		if turnFrame then
			turnFrame.Visible = false
		end
	end