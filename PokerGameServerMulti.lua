-- PokerGameServerMulti.lua
-- Server-side poker game logic for multiple tables
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for TableManager
local TableManager = require(ServerScriptService:WaitForChild("TableManager"))

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

-- Shuffle the poker card to a random position
local function shuffleCards(tableInstance)
	if not tableInstance.gameState.pokerCard then
		warn("[PokerGame] No poker card found for table:", tableInstance.tableId)
		return
	end
	
	local cards = tableInstance.cards
	local pokerCard = tableInstance.gameState.pokerCard
	
	-- Pick a random card that isn't the poker card
	local randomCard
	repeat
		randomCard = cards[math.random(#cards)]
	until randomCard ~= pokerCard
	
	-- Swap positions
	local pokerPos = tableInstance.currentCardCFrames[pokerCard]
	local randomPos = tableInstance.currentCardCFrames[randomCard]
	
	pokerCard.CFrame = randomPos
	randomCard.CFrame = pokerPos
	
	-- Update current positions
	tableInstance.currentCardCFrames[pokerCard] = randomPos
	tableInstance.currentCardCFrames[randomCard] = pokerPos
	
	print("[PokerGame] Poker card shuffled for table:", tableInstance.tableId)
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
	
	tableInstance.gameState.isActive = true
	tableInstance.gameState.turnNumber = 1
	tableInstance.gameState.currentTurn = math.random(2) == 1 and player1 or player2
	
	shuffleCards(tableInstance)
	
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
	print("[PokerGame] Game ended at table", tableInstance.tableId, "! Winner:", winner and winner.Name or "None", "Reason:", reason)
	
	-- Restore jumping
	restoreJumping(tableInstance, tableInstance.gameState.player1)
	restoreJumping(tableInstance, tableInstance.gameState.player2)
	
	-- Notify clients
	tableInstance.remoteEvents.GameStateUpdate:FireAllClients("game_end", {
		winner = winner and winner.Name or "None",
		loser = loser and loser.Name or "None",
		reason = reason
	})
	
	-- Kill the loser if they picked the poker
	if reason == "poker_picked" and loser and loser.Character then
		local humanoid = loser.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end
	
	-- Force winner to stand up
	wait(1.5)
	if winner and winner.Character then
		local humanoid = winner.Character:FindFirstChild("Humanoid")
		if humanoid and humanoid.SeatPart then
			humanoid.Sit = false
		end
	end
	
	-- Reset game
	wait(2)
	resetCards(tableInstance)
	
	for card, originalCFrame in pairs(tableInstance.originalCardCFrames) do
		tableInstance.currentCardCFrames[card] = originalCFrame
	end
	
	wait(0.1)
	tableInstance.remoteEvents.CardFlip:FireAllClients("reset_all_cards")
	
	-- Force server-side reset
	for _, card in ipairs(tableInstance.cards) do
		if card and card.Parent and tableInstance.originalCardCFrames[card] then
			card.CFrame = tableInstance.originalCardCFrames[card]
		end
	end
	
	wait(0.5)
	
	-- Clear game state
	tableInstance.gameState.currentTurn = nil
	tableInstance.gameState.turnNumber = 0
	tableInstance.gameState.player1 = nil
	tableInstance.gameState.player2 = nil
	tableInstance.gameState.selectedCards = {}
	
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