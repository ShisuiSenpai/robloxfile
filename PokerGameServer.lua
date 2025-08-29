-- Poker Card Game Server Script
-- Handles all game logic, turn management, and win conditions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Initialize random seed for better randomness
math.randomseed(tick())

-- Configuration
local GAME_RESET_TIME = 5 -- Time before resetting after game ends

-- Game State
local GameState = {
	isActive = false,
	currentTurn = nil,
	player1 = nil,
	player2 = nil,
	player1Seat = nil,
	player2Seat = nil,
	selectedCards = {}, -- Track which cards have been selected
	turnNumber = 0
}

-- References
local table1Folder = workspace:WaitForChild("Table1Folder")
local table1 = table1Folder:WaitForChild("Table1")
local player1Chair = table1Folder:WaitForChild("Player1Chair"):WaitForChild("Seat")
local player2Chair = table1Folder:WaitForChild("Player2Chair"):WaitForChild("Seat")

-- Get RemoteEvents from ReplicatedStorage
local remoteEvents = ReplicatedStorage:WaitForChild("PokerGameEvents")
local cardClickEvent = remoteEvents:WaitForChild("CardClick")
local gameStateEvent = remoteEvents:WaitForChild("GameStateUpdate")
local turnUpdateEvent = remoteEvents:WaitForChild("TurnUpdate")
local cardFlipEvent = remoteEvents:WaitForChild("CardFlip")

-- Get all cards and identify the poker
local cards = {}
local pokerCard = nil
local originalCardCFrames = {} -- The TRUE original positions (before any shuffles)
local currentCardCFrames = {} -- Current positions (updated after shuffles)

local function initializeCards()
	cards = {}
	for _, child in ipairs(table1:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(cards, child)
			-- Store the TRUE original position (only set once at server start)
			originalCardCFrames[child] = child.CFrame
			currentCardCFrames[child] = child.CFrame
			
			if child.Name == "Poker" then
				pokerCard = child
				print("[PokerGame] Found poker card:", child.Name)
			end
		end
	end
	print("[PokerGame] Initialized", #cards, "cards")
end

-- Reset card states
local function resetCards()
	print("[PokerGame DEBUG] resetCards() called")
	GameState.selectedCards = {}
	
	-- Debug: Show what we're resetting
	print("[PokerGame DEBUG] Number of cards to reset:", #cards)
	local count = 0
	for k, v in pairs(originalCardCFrames) do
		count = count + 1
	end
	print("[PokerGame DEBUG] Original positions stored:", count)
	
	-- Reset all card positions and rotations to original state
	for _, card in ipairs(cards) do
		if card and card.Parent then
			local originalCFrame = originalCardCFrames[card]
			if originalCFrame then
				print("[PokerGame DEBUG] Resetting card:", card.Name, "to position:", originalCFrame.Position)
				card.CFrame = originalCFrame
			else
				print("[PokerGame DEBUG] WARNING: No original CFrame for card:", card.Name)
			end
		else
			print("[PokerGame DEBUG] WARNING: Card is nil or has no parent")
		end
	end
	
	-- Tell all clients to reset their card states
	gameStateEvent:FireAllClients("cards_reset")
	
	print("[PokerGame] All cards reset to original positions")
end

-- Check if both seats are occupied
local function checkSeating()
	local player1Humanoid = player1Chair.Occupant
	local player2Humanoid = player2Chair.Occupant
	
	local newPlayer1 = nil
	local newPlayer2 = nil
	
	if player1Humanoid then
		local character = player1Humanoid.Parent
		newPlayer1 = Players:GetPlayerFromCharacter(character)
	end
	
	if player2Humanoid then
		local character = player2Humanoid.Parent
		newPlayer2 = Players:GetPlayerFromCharacter(character)
	end
	
	-- Update game state
	GameState.player1 = newPlayer1
	GameState.player2 = newPlayer2
	GameState.player1Seat = player1Humanoid
	GameState.player2Seat = player2Humanoid
	
	return newPlayer1 ~= nil and newPlayer2 ~= nil
end

-- Shuffle array using Fisher-Yates algorithm
local function shuffleArray(array)
	local shuffled = {}
	for i = 1, #array do
		shuffled[i] = array[i]
	end
	
	for i = #shuffled, 2, -1 do
		local j = math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	
	return shuffled
end

-- Simple shuffle - just swap poker card with a random card
local function shuffleCards()
	if not pokerCard then
		print("[PokerGame] Warning: No poker card found!")
		return
	end
	
	-- Find a random card that isn't the poker
	local otherCards = {}
	for _, card in ipairs(cards) do
		if card ~= pokerCard then
			table.insert(otherCards, card)
		end
	end
	
	if #otherCards == 0 then
		return
	end
	
	-- Pick a random card to swap with
	local randomCard = otherCards[math.random(1, #otherCards)]
	
	-- Swap positions
	local pokerPos = pokerCard.CFrame
	local randomPos = randomCard.CFrame
	
	pokerCard.CFrame = randomPos
	randomCard.CFrame = pokerPos
	
	-- Update current positions
	currentCardCFrames[pokerCard] = randomPos
	currentCardCFrames[randomCard] = pokerPos
	
	print("[PokerGame] Poker card shuffled")
end

-- Start the game
local function startGame()
	if GameState.isActive then return end
	
	print("[PokerGame] Starting game with players:", GameState.player1.Name, "vs", GameState.player2.Name)
	
	-- Wait for countdown to complete (3 seconds countdown + 1 second for "GO!")
	wait(4)
	
	GameState.isActive = true
	GameState.turnNumber = 1
	
	-- Randomly select who goes first
	GameState.currentTurn = math.random(2) == 1 and GameState.player1 or GameState.player2
	
	-- Simple shuffle
	shuffleCards()
	
	-- Reset game state
	GameState.selectedCards = {}
	
	-- Notify all clients about game start
	gameStateEvent:FireAllClients("game_start", {
		player1 = GameState.player1.Name,
		player2 = GameState.player2.Name,
		currentTurn = GameState.currentTurn.Name
	})
	
	-- Update turn display
	turnUpdateEvent:FireAllClients(GameState.currentTurn.Name)
end

-- End the game
local function endGame(winner, loser, reason)
	if not GameState.isActive then return end
	
	GameState.isActive = false
	print("[PokerGame] Game ended! Winner:", winner and winner.Name or "None", "Reason:", reason)
	
	-- Notify all clients
	gameStateEvent:FireAllClients("game_end", {
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
	
	-- Force winner to stand up after a short delay
	wait(1.5) -- Give time for death animation and victory message
	
	if winner and winner.Character then
		local humanoid = winner.Character:FindFirstChild("Humanoid")
		if humanoid and humanoid.SeatPart then
			humanoid.Sit = false
		end
	end
	
	-- Reset game state
	wait(2) -- Additional wait for cleanup
	
	-- First reset all cards on server
	resetCards()
	
	-- Update current positions to match original
	for card, originalCFrame in pairs(originalCardCFrames) do
		currentCardCFrames[card] = originalCFrame
	end
	
	-- Force sync with all clients by sending card states
	wait(0.1)
	cardFlipEvent:FireAllClients("reset_all_cards")
	
	-- Additional safety: Send individual card resets
	for _, card in ipairs(cards) do
		if card and card.Parent and originalCardCFrames[card] then
			-- Ensure card is at original position on server
			card.CFrame = originalCardCFrames[card]
		end
	end
	
	-- Give clients time to process
	wait(0.5)
	
	-- Clear game state after cards are reset
	GameState.currentTurn = nil
	GameState.turnNumber = 0
	GameState.player1 = nil
	GameState.player2 = nil
	GameState.player1Seat = nil
	GameState.player2Seat = nil
	GameState.selectedCards = {}
	
	print("[PokerGame] Game fully reset, ready for next game")
end

-- Handle card selection
local function selectCard(player, card)
	-- Validate game state
	if not GameState.isActive then
		return
	end
	
	if GameState.currentTurn ~= player then
		return
	end
	
	if GameState.selectedCards[card] then
		return
	end
	
	-- Mark card as selected
	GameState.selectedCards[card] = true
	
	print("[PokerGame]", player.Name, "selected card:", card.Name)
	
	-- Tell all clients to flip this card
	cardFlipEvent:FireAllClients(card)
	
	-- Check if it's the poker card
	if card == pokerCard then
		-- Player loses!
		local winner = (player == GameState.player1) and GameState.player2 or GameState.player1
		endGame(winner, player, "poker_picked")
	else
		-- Normal card - switch turns
		GameState.turnNumber = GameState.turnNumber + 1
		GameState.currentTurn = (GameState.currentTurn == GameState.player1) and GameState.player2 or GameState.player1
		
		-- Update turn display
		turnUpdateEvent:FireAllClients(GameState.currentTurn.Name)
		
		-- Check if all cards except poker have been selected (rare case)
		local unselectedCount = 0
		for _, c in ipairs(cards) do
			if not GameState.selectedCards[c] then
				unselectedCount = unselectedCount + 1
			end
		end
		
		if unselectedCount == 1 and not GameState.selectedCards[pokerCard] then
			-- Only poker remains - current player wins
			endGame(GameState.currentTurn, 
				(GameState.currentTurn == GameState.player1) and GameState.player2 or GameState.player1, 
				"last_card_poker")
		end
	end
end

-- Handle remote events
cardClickEvent.OnServerEvent:Connect(function(player, card)
	-- Validate the card
	if not card or not card:IsDescendantOf(table1) then
		return
	end
	
	selectCard(player, card)
end)

-- Monitor seat occupancy
player1Chair:GetPropertyChangedSignal("Occupant"):Connect(function()
	local bothSeated = checkSeating()
	
	if bothSeated and not GameState.isActive then
		-- Both players seated - start game
		wait(0.5) -- Small delay to ensure everything is loaded
		
		-- Notify clients that countdown is starting
		gameStateEvent:FireAllClients("countdown_start")
		
		startGame()
	elseif not bothSeated and GameState.isActive then
		-- Someone left during game
		local remainingPlayer = GameState.player1 or GameState.player2
		if remainingPlayer then
			endGame(remainingPlayer, 
				(remainingPlayer == GameState.player1) and GameState.player2 or GameState.player1,
				"player_left")
		else
			-- Both left
			GameState.isActive = false
			resetCards()
		end
	end
end)

player2Chair:GetPropertyChangedSignal("Occupant"):Connect(function()
	local bothSeated = checkSeating()
	
	if bothSeated and not GameState.isActive then
		-- Both players seated - start game
		wait(0.5) -- Small delay to ensure everything is loaded
		
		-- Notify clients that countdown is starting
		gameStateEvent:FireAllClients("countdown_start")
		
		startGame()
	elseif not bothSeated and GameState.isActive then
		-- Someone left during game
		local remainingPlayer = GameState.player1 or GameState.player2
		if remainingPlayer then
			endGame(remainingPlayer,
				(remainingPlayer == GameState.player1) and GameState.player2 or GameState.player1,
				"player_left")
		else
			-- Both left
			GameState.isActive = false
			resetCards()
		end
	end
end)

-- Initialize with a delay to ensure CardOrientationFixer has run
task.wait(0.5) -- Wait for CardOrientationFixer to set initial orientations
initializeCards()
print("[PokerGame] Server initialized. Waiting for players...")