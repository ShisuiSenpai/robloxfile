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
	print("[PokerGame DEBUG] Original positions stored:", #originalCardCFrames)
	
	-- Reset all card positions and rotations to original state
	for _, card in ipairs(cards) do
		if card.Parent and originalCardCFrames[card] then
			local originalCFrame = originalCardCFrames[card]
			print("[PokerGame DEBUG] Resetting card:", card.Name)
			print("[PokerGame DEBUG]   From:", card.CFrame.Position, "Rotation:", card.CFrame.LookVector)
			print("[PokerGame DEBUG]   To:", originalCFrame.Position, "Rotation:", originalCFrame.LookVector)
			
			-- Force reset to exact original state
			card.CFrame = originalCFrame
			
			-- Double-check it worked
			if card.CFrame ~= originalCFrame then
				print("[PokerGame DEBUG] ERROR: Card did not reset properly!")
			end
		else
			print("[PokerGame DEBUG] WARNING: Card missing data:", card.Name)
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
	print("[PokerGame DEBUG] shuffleCards() called")
	
	if not pokerCard then
		print("[PokerGame] ERROR: No poker card found!")
		return
	end
	
	print("[PokerGame DEBUG] Poker card before shuffle:", pokerCard.Name, "at", pokerCard.Position)
	
	-- Find a random card that isn't the poker
	local otherCards = {}
	for _, card in ipairs(cards) do
		if card ~= pokerCard then
			table.insert(otherCards, card)
		end
	end
	
	if #otherCards == 0 then
		print("[PokerGame] ERROR: No other cards to swap with!")
		return
	end
	
	-- Pick a random card to swap with
	local randomCard = otherCards[math.random(1, #otherCards)]
	
	print("[PokerGame DEBUG] Swapping poker with:", randomCard.Name)
	
	-- Get current positions
	local pokerPos = pokerCard.CFrame
	local randomPos = randomCard.CFrame
	
	print("[PokerGame DEBUG] Poker position before:", pokerPos.Position)
	print("[PokerGame DEBUG] Random card position before:", randomPos.Position)
	
	-- Swap positions
	pokerCard.CFrame = randomPos
	randomCard.CFrame = pokerPos
	
	-- Update current positions
	currentCardCFrames[pokerCard] = randomPos
	currentCardCFrames[randomCard] = pokerPos
	
	print("[PokerGame DEBUG] Poker position after:", pokerCard.Position)
	print("[PokerGame DEBUG] Random card position after:", randomCard.Position)
end

-- Start the game
local function startGame()
	if GameState.isActive then return end
	
	print("[PokerGame] Starting game with players:", GameState.player1.Name, "vs", GameState.player2.Name)
	
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
	print("[PokerGame] Game ended! Winner:", winner.Name, "Reason:", reason)
	
	-- Notify all clients
	gameStateEvent:FireAllClients("game_end", {
		winner = winner.Name,
		loser = loser.Name,
		reason = reason
	})
	
	-- Kill the loser if they picked the poker
	if reason == "poker_picked" and loser.Character then
		local humanoid = loser.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end
	
	-- Force winner to stand up after a short delay
	wait(1.5) -- Give time for death animation and victory message
	
	if winner.Character then
		local humanoid = winner.Character:FindFirstChild("Humanoid")
		if humanoid and humanoid.SeatPart then
			humanoid.Sit = false
		end
	end
	
	-- Reset game state
	wait(2) -- Additional wait for cleanup
	
	-- First tell clients to reset their visual states
	cardFlipEvent:FireAllClients("reset_all_cards")
	
	-- Small delay to ensure clients process the reset
	wait(0.1)
	
	-- Clear game state
	GameState.currentTurn = nil
	GameState.turnNumber = 0
	GameState.player1 = nil
	GameState.player2 = nil
	GameState.player1Seat = nil
	GameState.player2Seat = nil
	GameState.selectedCards = {}
	
	-- Reset all cards to face down on server
	resetCards()
	
	-- Update current positions to match original
	for card, originalCFrame in pairs(originalCardCFrames) do
		currentCardCFrames[card] = originalCFrame
	end
	
	print("[PokerGame] Game fully reset, ready for next game")
end

-- Handle card selection
local function selectCard(player, card)
	print("[PokerGame DEBUG] selectCard called by", player.Name, "for card", card.Name)
	
	-- Validate game state
	if not GameState.isActive then
		print("[PokerGame DEBUG] ERROR: Game not active")
		return
	end
	
	if GameState.currentTurn ~= player then
		print("[PokerGame DEBUG] ERROR: Not player's turn. Current turn:", GameState.currentTurn.Name)
		return
	end
	
	if GameState.selectedCards[card] then
		print("[PokerGame DEBUG] ERROR: Card already selected")
		return
	end
	
	-- Mark card as selected
	GameState.selectedCards[card] = true
	
	print("[PokerGame DEBUG] Card selected successfully. Is it poker?", card == pokerCard)
	
	-- Tell all clients to flip this card
	cardFlipEvent:FireAllClients(card)
	
	-- Check if it's the poker card
	if card == pokerCard then
		print("[PokerGame DEBUG] POKER CARD FOUND! Player loses:", player.Name)
		-- Player loses!
		local winner = (player == GameState.player1) and GameState.player2 or GameState.player1
		endGame(winner, player, "poker_picked")
	else
		print("[PokerGame DEBUG] Normal card selected, switching turns")
		-- Normal card - switch turns
		GameState.turnNumber = GameState.turnNumber + 1
		GameState.currentTurn = (GameState.currentTurn == GameState.player1) and GameState.player2 or GameState.player1
		
		print("[PokerGame DEBUG] New turn:", GameState.currentTurn.Name)
		
		-- Update turn display
		turnUpdateEvent:FireAllClients(GameState.currentTurn.Name)
		
		-- Check if all cards except poker have been selected (rare case)
		local unselectedCount = 0
		for _, c in ipairs(cards) do
			if not GameState.selectedCards[c] then
				unselectedCount = unselectedCount + 1
			end
		end
		
		print("[PokerGame DEBUG] Unselected cards remaining:", unselectedCount)
		
		if unselectedCount == 1 and not GameState.selectedCards[pokerCard] then
			-- Only poker remains - current player wins
			print("[PokerGame DEBUG] Only poker remains, current player wins!")
			endGame(GameState.currentTurn, 
				(GameState.currentTurn == GameState.player1) and GameState.player2 or GameState.player1, 
				"last_card_poker")
		end
	end
end

-- Handle remote events
cardClickEvent.OnServerEvent:Connect(function(player, card)
	print("[PokerGame DEBUG] Card click received from", player.Name, "for", card and card.Name or "nil")
	
	-- Validate the card
	if not card or not card:IsDescendantOf(table1) then
		print("[PokerGame DEBUG] ERROR: Invalid card")
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

-- Initialize
initializeCards()
print("[PokerGame] Server initialized. Waiting for players...")