-- PokerGameServerMulti.lua
-- Server-side poker game logic for multiple tables
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for modules
local TableManager = require(ServerScriptService:WaitForChild("TableManager"))
local LeaderstatsManager = require(ServerScriptService:WaitForChild("LeaderstatsManager"))

-- Random seed
math.randomseed(tick())

-- Restore jumping for a player
local function restoreJumping(tableInstance, player)
	if player and player.Character and tableInstance.originalJumpPowers[player] then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.JumpPower = tableInstance.originalJumpPowers[player].JumpPower or 50
			humanoid.JumpHeight = tableInstance.originalJumpPowers[player].JumpHeight or 7.2
			tableInstance.originalJumpPowers[player] = nil
			print("[PokerGame] Restored jumping for", player.Name, "at table", tableInstance.tableId)
		end
	end
end

-- Reset cards to original positions
local function resetCards(tableInstance)
	print("[PokerGame] Resetting cards for table:", tableInstance.tableId)
	tableInstance.gameState.selectedCards = {}
	
	for _, card in ipairs(tableInstance.cards) do
		if card and card.Parent then
			local originalCFrame = tableInstance.originalCardCFrames[card]
			if originalCFrame then
				card.CFrame = originalCFrame
			end
		end
	end
	
	tableInstance.remoteEvents.GameStateUpdate:FireAllClients("cards_reset")
	print("[PokerGame] All cards reset for table:", tableInstance.tableId)
end

-- Shuffle all cards to random positions
local function shuffleCards(tableInstance)
	if not tableInstance.gameState.pokerCard then
		warn("[PokerGame] No poker card found for table:", tableInstance.tableId)
		return
	end
	
	local cards = tableInstance.cards
	
	-- Create a list of all current positions
	local positions = {}
	for _, card in ipairs(cards) do
		table.insert(positions, tableInstance.currentCardCFrames[card])
	end
	
	-- Fisher-Yates shuffle algorithm to randomize positions
	for i = #positions, 2, -1 do
		local j = math.random(1, i)
		positions[i], positions[j] = positions[j], positions[i]
	end
	
	-- Assign shuffled positions to cards
	for i, card in ipairs(cards) do
		card.CFrame = positions[i]
		tableInstance.currentCardCFrames[card] = positions[i]
	end
	
	print("[PokerGame] All cards shuffled for table:", tableInstance.tableId)
end

-- Start the game
local function startGame(tableInstance)
	if tableInstance.gameState.isActive then return end
	
	local player1 = tableInstance.gameState.player1
	local player2 = tableInstance.gameState.player2
	
	print("[PokerGame] Starting game at table", tableInstance.tableId, "with players:", player1.Name, "vs", player2.Name)
	
	-- Disable jumping for both players
	if player1 and player1.Character then
		local humanoid = player1.Character:FindFirstChild("Humanoid")
		if humanoid then
			tableInstance.originalJumpPowers[player1] = {
				JumpPower = humanoid.JumpPower,
				JumpHeight = humanoid.JumpHeight
			}
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
		end
	end
	
	if player2 and player2.Character then
		local humanoid = player2.Character:FindFirstChild("Humanoid")
		if humanoid then
			tableInstance.originalJumpPowers[player2] = {
				JumpPower = humanoid.JumpPower,
				JumpHeight = humanoid.JumpHeight
			}
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
		end
	end
	
	-- Wait for countdown
	wait(4)
	
	-- Notify clients that shuffle is starting
	tableInstance.remoteEvents.GameStateUpdate:FireAllClients("shuffle_start")
	
	-- Shuffle all cards
	shuffleCards(tableInstance)
	
	-- Small delay for visual effect
	wait(0.5)
	
	tableInstance.gameState.isActive = true
	tableInstance.gameState.turnNumber = 1
	tableInstance.gameState.currentTurn = math.random(2) == 1 and player1 or player2
	tableInstance:updateTableState(TableManager.TableState.IN_GAME)
	
	tableInstance.gameState.selectedCards = {}
	
	-- Notify clients
	tableInstance.remoteEvents.GameStateUpdate:FireAllClients("game_start", {
		player1 = player1.Name,
		player2 = player2.Name,
		currentTurn = tableInstance.gameState.currentTurn.Name
	})
	
	tableInstance.remoteEvents.TurnUpdate:FireAllClients(tableInstance.gameState.currentTurn.Name)
end

-- End the game
local function endGame(tableInstance, winner, loser, reason)
	if not tableInstance.gameState.isActive then return end
	
	tableInstance.gameState.isActive = false
	tableInstance:updateTableState(TableManager.TableState.ENDING)
	print("[PokerGame] Game ended at table", tableInstance.tableId, "! Winner:", winner and winner.Name or "None", "Reason:", reason)
	
	-- Award win to the winner
	if winner then
		local success = LeaderstatsManager.IncrementWins(winner)
		if success then
			print("[PokerGame] Awarded win to", winner.Name)
		else
			warn("[PokerGame] Failed to award win to", winner.Name)
		end
	end
	
	-- Immediately notify clients that game has ended
	tableInstance.remoteEvents.GameStateUpdate:FireAllClients("game_end", {
		winner = winner and winner.Name or "None",
		loser = loser and loser.Name or "None",
		reason = reason
	})
	
	-- Restore jumping for both players
	restoreJumping(tableInstance, tableInstance.gameState.player1)
	restoreJumping(tableInstance, tableInstance.gameState.player2)
	
	-- Kill the loser if they picked the poker
	if reason == "poker_picked" and loser and loser.Character then
		wait(0.5) -- Brief delay for dramatic effect
		local humanoid = loser.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end
	
	-- Wait for UI to show results
	wait(2)
	
	-- Force winner to stand up
	if winner and winner.Character then
		local humanoid = winner.Character:FindFirstChild("Humanoid")
		if humanoid and humanoid.SeatPart then
			humanoid.Sit = false
		end
	end
	
	-- Wait a bit more before resetting
	wait(1.5)
	
	-- Reset all cards server-side first
	for _, card in ipairs(tableInstance.cards) do
		if card and card.Parent and tableInstance.originalCardCFrames[card] then
			card.CFrame = tableInstance.originalCardCFrames[card]
		end
	end
	
	-- Update current positions
	for card, originalCFrame in pairs(tableInstance.originalCardCFrames) do
		tableInstance.currentCardCFrames[card] = originalCFrame
	end
	
	-- Clear server game state
	tableInstance.gameState.currentTurn = nil
	tableInstance.gameState.turnNumber = 0
	tableInstance.gameState.player1 = nil
	tableInstance.gameState.player2 = nil
	tableInstance.gameState.selectedCards = {}
	
	-- Tell clients to reset their cards and state
	tableInstance.remoteEvents.CardFlip:FireAllClients("reset_all_cards")
	
	-- Final state reset notification
	wait(0.1)
	tableInstance.remoteEvents.GameStateUpdate:FireAllClients("full_reset")
	
	print("[PokerGame] Table", tableInstance.tableId, "fully reset")
end

-- Handle card selection
local function selectCard(tableInstance, player, card)
	local gameState = tableInstance.gameState
	
	if not gameState.isActive then return end
	if gameState.currentTurn ~= player then return end
	if gameState.selectedCards[card] then return end
	
	gameState.selectedCards[card] = true
	print("[PokerGame] Table", tableInstance.tableId, "-", player.Name, "selected card:", card.Name)
	
	tableInstance.remoteEvents.CardFlip:FireAllClients(card)
	
	if card == gameState.pokerCard then
		local winner = (player == gameState.player1) and gameState.player2 or gameState.player1
		endGame(tableInstance, winner, player, "poker_picked")
	else
		gameState.turnNumber = gameState.turnNumber + 1
		gameState.currentTurn = (gameState.currentTurn == gameState.player1) and gameState.player2 or gameState.player1
		tableInstance.remoteEvents.TurnUpdate:FireAllClients(gameState.currentTurn.Name)
	end
end

-- Setup seat monitoring for a table
local function setupTableMonitoring(tableInstance)
	-- Monitor seat 1
	tableInstance.seat1:GetPropertyChangedSignal("Occupant"):Connect(function()
		local bothSeated = tableInstance:checkSeating()
		
			if bothSeated and not tableInstance.gameState.isActive then
		tableInstance:updateTableState(TableManager.TableState.COUNTDOWN)
		wait(0.5)
		tableInstance.remoteEvents.GameStateUpdate:FireAllClients("countdown_start")
		startGame(tableInstance)
		elseif not bothSeated and tableInstance.gameState.isActive then
			local remainingPlayer = tableInstance.gameState.player1 or tableInstance.gameState.player2
			if remainingPlayer then
				endGame(tableInstance, remainingPlayer, 
					(remainingPlayer == tableInstance.gameState.player1) and tableInstance.gameState.player2 or tableInstance.gameState.player1,
					"player_left")
			else
				restoreJumping(tableInstance, tableInstance.gameState.player1)
				restoreJumping(tableInstance, tableInstance.gameState.player2)
				tableInstance.gameState.isActive = false
				resetCards(tableInstance)
			end
		elseif not bothSeated then
			restoreJumping(tableInstance, tableInstance.gameState.player1)
			restoreJumping(tableInstance, tableInstance.gameState.player2)
		end
	end)
	
	-- Monitor seat 2
	tableInstance.seat2:GetPropertyChangedSignal("Occupant"):Connect(function()
		local bothSeated = tableInstance:checkSeating()
		
			if bothSeated and not tableInstance.gameState.isActive then
		tableInstance:updateTableState(TableManager.TableState.COUNTDOWN)
		wait(0.5)
		tableInstance.remoteEvents.GameStateUpdate:FireAllClients("countdown_start")
		startGame(tableInstance)
		elseif not bothSeated and tableInstance.gameState.isActive then
			local remainingPlayer = tableInstance.gameState.player1 or tableInstance.gameState.player2
			if remainingPlayer then
				endGame(tableInstance, remainingPlayer,
					(remainingPlayer == tableInstance.gameState.player1) and tableInstance.gameState.player2 or tableInstance.gameState.player1,
					"player_left")
			else
				restoreJumping(tableInstance, tableInstance.gameState.player1)
				restoreJumping(tableInstance, tableInstance.gameState.player2)
				tableInstance.gameState.isActive = false
				resetCards(tableInstance)
			end
		elseif not bothSeated then
			restoreJumping(tableInstance, tableInstance.gameState.player1)
			restoreJumping(tableInstance, tableInstance.gameState.player2)
		end
	end)
	
	-- Handle card clicks
	tableInstance.remoteEvents.CardClick.OnServerEvent:Connect(function(player, card)
		if not card or not card:IsDescendantOf(tableInstance.tablePart) then
			return
		end
		selectCard(tableInstance, player, card)
	end)
	
	print("[PokerGame] Monitoring setup complete for table:", tableInstance.tableId)
end

-- Initialize
TableManager.initializeAllTables()

-- Setup monitoring for each table
for tableId, tableInstance in pairs(TableManager.getAllTables()) do
	setupTableMonitoring(tableInstance)
end

print("[PokerGame] Multi-table server initialized")