-- Poker Card Game Server Script
-- Handles all game logic, turn management, and win conditions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

-- Create RemoteEvents in ReplicatedStorage
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "PokerGameEvents"
remoteEvents.Parent = ReplicatedStorage

local cardClickEvent = Instance.new("RemoteEvent")
cardClickEvent.Name = "CardClick"
cardClickEvent.Parent = remoteEvents

local gameStateEvent = Instance.new("RemoteEvent")
gameStateEvent.Name = "GameStateUpdate"
gameStateEvent.Parent = remoteEvents

local turnUpdateEvent = Instance.new("RemoteEvent")
turnUpdateEvent.Name = "TurnUpdate"
turnUpdateEvent.Parent = remoteEvents

local cardFlipEvent = Instance.new("RemoteEvent")
cardFlipEvent.Name = "CardFlip"
cardFlipEvent.Parent = remoteEvents

-- Get all cards and identify the poker
local cards = {}
local pokerCard = nil
local originalCardCFrames = {}

local function initializeCards()
	cards = {}
	for _, child in ipairs(table1:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(cards, child)
			originalCardCFrames[child] = child.CFrame
			
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
	GameState.selectedCards = {}
	
	-- Reset all card positions
	for card, originalCFrame in pairs(originalCardCFrames) do
		if card.Parent then
			card.CFrame = originalCFrame
		end
	end
	
	-- Tell all clients to reset their card states
	gameStateEvent:FireAllClients("cards_reset")
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

-- Start the game
local function startGame()
	if GameState.isActive then return end
	
	print("[PokerGame] Starting game with players:", GameState.player1.Name, "vs", GameState.player2.Name)
	
	GameState.isActive = true
	GameState.turnNumber = 1
	
	-- Randomly select who goes first
	GameState.currentTurn = math.random(2) == 1 and GameState.player1 or GameState.player2
	
	-- Reset cards
	resetCards()
	
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
	
	-- Reset game after delay
	wait(GAME_RESET_TIME)
	
	-- Clear game state
	GameState.currentTurn = nil
	GameState.turnNumber = 0
	resetCards()
	
	-- Check if players are still seated to start new game
	if checkSeating() then
		startGame()
	end
end

-- Handle card selection
local function selectCard(player, card)
	-- Validate game state
	if not GameState.isActive then
		print("[PokerGame] Game not active")
		return
	end
	
	if GameState.currentTurn ~= player then
		print("[PokerGame] Not player's turn:", player.Name)
		return
	end
	
	if GameState.selectedCards[card] then
		print("[PokerGame] Card already selected")
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