-- PokerGameClientMulti.lua
-- Client-side poker game logic for multiple tables
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Table configurations
local TABLE_CONFIGS = {
	Table1 = {
		folderName = "Table1Folder",
		tableName = "Table1",
		remoteFolder = "Table1",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table2 = {
		folderName = "Table2Folder", 
		tableName = "Table2",
		remoteFolder = "Table2",
		seats = {"Player1Chair", "Player2Chair"}
	}
}

-- Sound Manager (optional)
local SoundManager
local soundsEnabled = false

local success = pcall(function()
	SoundManager = require(ReplicatedStorage:WaitForChild("SoundManager", 2))
	soundsEnabled = true
	print("[PokerGame] SoundManager loaded successfully")
end)

if not success then
	warn("[PokerGame] SoundManager not found - sounds disabled")
end

-- Get all table components
local tables = {}
local allSeats = {}
local seatToTable = {}

for tableId, config in pairs(TABLE_CONFIGS) do
	local folder = workspace:WaitForChild(config.folderName)
	local tablePart = folder:WaitForChild(config.tableName)
	local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild(config.remoteFolder)
	
	local tableData = {
		id = tableId,
		folder = folder,
		tablePart = tablePart,
		seats = {},
		remoteEvents = {
			CardClick = remoteFolder:WaitForChild("CardClick"),
			GameStateUpdate = remoteFolder:WaitForChild("GameStateUpdate"),
			TurnUpdate = remoteFolder:WaitForChild("TurnUpdate"),
			CardFlip = remoteFolder:WaitForChild("CardFlip")
		},
		-- Game state for this table
		gameActive = false,
		isMyTurn = false,
		isCountdownActive = false,
		selectedCards = {},
		flippedCards = {},
		originalCardCFrames = {},
		cardHighlights = {},
		currentHoveredCard = nil,
		gameUI = nil
	}
	
	-- Get seats
	for _, seatName in ipairs(config.seats) do
		local chair = folder:FindFirstChild(seatName)
		if chair then
			local seat = chair:FindFirstChild("Seat")
			if seat then
				table.insert(tableData.seats, seat)
				table.insert(allSeats, seat)
				seatToTable[seat] = tableData
			end
		end
	end
	
	-- Store original card positions
	for _, card in ipairs(tablePart:GetChildren()) do
		if card:IsA("BasePart") then
			tableData.originalCardCFrames[card] = card.CFrame
		end
	end
	
	tables[tableId] = tableData
end

-- Get current table based on seating
local function getCurrentTable()
	if not player.Character then return nil end
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid or not humanoid.SeatPart then return nil end
	
	return seatToTable[humanoid.SeatPart]
end

-- Check if seated at any table
local function isSeatedAtAnyTable()
	return getCurrentTable() ~= nil
end

-- UI Colors
local HIGHLIGHT_COLOR = Color3.fromRGB(150, 255, 150)
local SELECTED_CARD_COLOR = Color3.fromRGB(100, 100, 100)

-- Waiting animation variables
local waitingAnimations = {}

-- Start waiting animation
local function startWaitingAnimation(tableData, turnLabel)
	if waitingAnimations[tableData.id] then return end
	
	local dots = ""
	local frameCount = 0
	
	waitingAnimations[tableData.id] = RunService.Heartbeat:Connect(function()
		frameCount = frameCount + 1
		if frameCount % 60 == 0 then -- Update every second (60 frames)
			if #dots >= 3 then
				dots = ""
			else
				dots = dots .. "."
			end
			turnLabel.Text = "Waiting for players" .. dots
		end
	end)
end

-- Stop waiting animation
local function stopWaitingAnimation(tableData)
	if waitingAnimations[tableData.id] then
		waitingAnimations[tableData.id]:Disconnect()
		waitingAnimations[tableData.id] = nil
	end
end

-- Create game UI for a table
local function createGameUI(tableData)
	if tableData.gameUI then
		tableData.gameUI:Destroy()
	end
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PokerGameUI_" .. tableData.id
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")
	
	-- Turn indicator
	local turnFrame = Instance.new("Frame")
	turnFrame.Name = "TurnFrame"
	turnFrame.Size = UDim2.new(0, 300, 0, 50)
	turnFrame.Position = UDim2.new(0.5, -150, 0, 20)
	turnFrame.BackgroundTransparency = 0.3
	turnFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	turnFrame.BorderSizePixel = 0
	turnFrame.Parent = screenGui
	
	local turnLabel = Instance.new("TextLabel")
	turnLabel.Name = "TurnLabel"
	turnLabel.Size = UDim2.new(1, 0, 1, 0)
	turnLabel.BackgroundTransparency = 1
	turnLabel.Text = "Waiting for players..."
	turnLabel.TextColor3 = Color3.new(1, 1, 1)
	turnLabel.TextScaled = true
	turnLabel.Font = Enum.Font.SourceSansBold
	turnLabel.Parent = turnFrame
	
	-- Status frame for win/lose
	local statusFrame = Instance.new("Frame")
	statusFrame.Name = "StatusFrame"
	statusFrame.Size = UDim2.new(0, 400, 0, 100)
	statusFrame.Position = UDim2.new(0.5, -200, 0.5, -50)
	statusFrame.BackgroundTransparency = 0.2
	statusFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	statusFrame.BorderSizePixel = 0
	statusFrame.Visible = false
	statusFrame.Parent = screenGui
	
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 1, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.new(1, 1, 1)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.SourceSansBold
	statusLabel.Parent = statusFrame
	
	tableData.gameUI = screenGui
	tableData.turnLabel = turnLabel
	tableData.statusLabel = statusLabel
	return screenGui, turnLabel, statusLabel
end

-- Get or create highlight for a card
local function getOrCreateHighlight(tableData, card)
	if tableData.cardHighlights[card] then
		return tableData.cardHighlights[card]
	end
	
	local highlight = Instance.new("Highlight")
	highlight.Parent = card
	highlight.Adornee = card
	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Enabled = false
	
	tableData.cardHighlights[card] = highlight
	return highlight
end

-- Update card highlighting
local function updateCardHighlighting(tableData)
	for card, highlight in pairs(tableData.cardHighlights) do
		if tableData.selectedCards[card] or tableData.flippedCards[card] then
			highlight.FillColor = SELECTED_CARD_COLOR
			highlight.OutlineColor = SELECTED_CARD_COLOR
			highlight.Enabled = true
		elseif tableData.currentHoveredCard == card and tableData.gameActive and tableData.isMyTurn then
			highlight.FillColor = HIGHLIGHT_COLOR
			highlight.OutlineColor = HIGHLIGHT_COLOR
			highlight.Enabled = true
		else
			highlight.Enabled = false
		end
	end
end

-- Flip card animation
local function flipCard(tableData, card)
	if tableData.flippedCards[card] then return end
	
	tableData.flippedCards[card] = true
	tableData.selectedCards[card] = true
	
	local flipTween = TweenService:Create(card,
		TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{CFrame = card.CFrame * CFrame.Angles(math.rad(180), 0, 0)}
	)
	
	flipTween:Play()
	updateCardHighlighting(tableData)
end

-- Reset card
local function resetCard(tableData, card)
	tableData.flippedCards[card] = nil
	tableData.selectedCards[card] = nil
	
	local originalCFrame = tableData.originalCardCFrames[card]
	if originalCFrame then
		-- Smooth reset animation
		coroutine.wrap(function()
			local startCFrame = card.CFrame
			local duration = 0.3
			local elapsed = 0
			
			while elapsed < duration and card.Parent do
				elapsed = elapsed + RunService.Heartbeat:Wait()
				local alpha = math.min(elapsed / duration, 1)
				alpha = alpha * alpha * (3 - 2 * alpha) -- Smooth step
				
				card.CFrame = startCFrame:Lerp(originalCFrame, alpha)
			end
			
			if card.Parent then
				card.CFrame = originalCFrame
			end
		end)()
	end
end

-- Handle mouse movement
local function onMouseMove()
	local currentTable = getCurrentTable()
	if not currentTable then
		-- Clear hover for all tables
		for _, tableData in pairs(tables) do
			if tableData.currentHoveredCard then
				tableData.currentHoveredCard = nil
				updateCardHighlighting(tableData)
			end
		end
		return
	end
	
	local target = mouse.Target
	local cardTarget = nil
	
	if target then
		-- Check if hovering over a card (exclude camera parts)
		if target.Parent == currentTable.tablePart and target:IsA("BasePart") and not target.Name:match("Camera") then
			cardTarget = target
		elseif target.Parent and target.Parent.Parent == currentTable.tablePart and target.Parent:IsA("BasePart") then
			cardTarget = target.Parent
		end
	end
	
	if cardTarget then
		if currentTable.currentHoveredCard ~= cardTarget then
			currentTable.currentHoveredCard = cardTarget
			updateCardHighlighting(currentTable)
			
			if soundsEnabled and currentTable.gameActive and currentTable.isMyTurn and not currentTable.selectedCards[cardTarget] then
				SoundManager:PlayHoverSound(cardTarget.Position)
			end
		end
	else
		if currentTable.currentHoveredCard then
			currentTable.currentHoveredCard = nil
			updateCardHighlighting(currentTable)
		end
	end
end

-- Handle mouse click
local function onMouseClick()
	local currentTable = getCurrentTable()
	if not currentTable or not currentTable.gameActive or not currentTable.isMyTurn or 
	   not currentTable.currentHoveredCard or currentTable.isCountdownActive then
		return
	end
	
	if currentTable.selectedCards[currentTable.currentHoveredCard] then
		return
	end
	
	if soundsEnabled then
		if currentTable.currentHoveredCard.Name == "Poker" then
			SoundManager:PlayPokerClickSound(currentTable.currentHoveredCard.Position)
		else
			SoundManager:PlayClickSound(currentTable.currentHoveredCard.Position)
		end
	end
	
	currentTable.remoteEvents.CardClick:FireServer(currentTable.currentHoveredCard)
end

-- Check seating status for a table
local checkSeatingStatus = function(tableData)
	if not player.Character then return end
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	-- Check if seated at this table
	local isSeated = false
	for _, seat in ipairs(tableData.seats) do
		if humanoid.SeatPart == seat then
			isSeated = true
			break
		end
	end
	
	if not isSeated then
		-- Not seated at this table
		if tableData.gameUI then
			tableData.gameUI:Destroy()
			tableData.gameUI = nil
		end
		stopWaitingAnimation(tableData)
		return
	end
	
	-- Seated at this table
	if not tableData.gameUI then
		createGameUI(tableData)
	end
	
	-- Check if both seats are occupied
	local bothSeated = true
	for _, seat in ipairs(tableData.seats) do
		if not seat.Occupant then
			bothSeated = false
			break
		end
	end
	
	-- Update UI based on game state
	if tableData.gameUI then
		if not tableData.gameActive and not tableData.isCountdownActive then
			tableData.gameUI.TurnFrame.Visible = true
			if bothSeated then
				stopWaitingAnimation(tableData)
				-- Don't show "Starting soon..." - let the countdown handle it
				tableData.gameUI.TurnFrame.Visible = false
			else
				startWaitingAnimation(tableData, tableData.turnLabel)
			end
		end
	end
end

-- Connect events for each table
for tableId, tableData in pairs(tables) do
	local screenGui, turnLabel, statusLabel
	
	-- Game state updates
	tableData.remoteEvents.GameStateUpdate.OnClientEvent:Connect(function(state, data)
		if state == "countdown_start" then
			tableData.isCountdownActive = true
			tableData.gameActive = false
			if tableData.gameUI then
				tableData.gameUI.TurnFrame.Visible = false
			end
			
		elseif state == "game_start" then
			tableData.isCountdownActive = false
			tableData.gameActive = true
			tableData.selectedCards = {}
			tableData.flippedCards = {}
			
			-- Stop waiting animation
			stopWaitingAnimation(tableData)
			
			-- Update UI if seated at this table
			if getCurrentTable() == tableData then
				if not tableData.gameUI then
					createGameUI(tableData)
				end
				tableData.gameUI.TurnFrame.Visible = true
			end
			
			-- Create highlights for all cards
			for _, card in ipairs(tableData.tablePart:GetChildren()) do
				if card:IsA("BasePart") then
					getOrCreateHighlight(tableData, card)
				end
			end
			
			updateCardHighlighting(tableData)
			
		elseif state == "game_end" then
			tableData.gameActive = false
			tableData.isMyTurn = false
			tableData.isCountdownActive = false
			
			-- Show winner/loser message if at this table
			if tableData.gameUI and getCurrentTable() == tableData then
				local statusFrame = tableData.gameUI.StatusFrame
				statusFrame.Visible = true
				tableData.gameUI.TurnFrame.Visible = false
				
				local statusLabel = statusFrame.StatusLabel
				if data.winner == player.Name then
					statusLabel.Text = "You Win!"
					statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				elseif data.loser == player.Name then
					if data.reason == "poker_picked" then
						statusLabel.Text = "You found the Poker! You Lose!"
					else
						statusLabel.Text = "You Lose!"
					end
					statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
				else
					statusLabel.Text = data.winner .. " Wins!"
					statusLabel.TextColor3 = Color3.new(1, 1, 1)
				end
				
				-- Hide after delay
				coroutine.wrap(function()
					wait(3)
					if tableData.gameUI then
						statusFrame.Visible = false
						-- Check seating status after game end
						task.wait(0.5)
						checkSeatingStatus(tableData)
					end
				end)()
			end
			
		elseif state == "cards_reset" then
			tableData.selectedCards = {}
			tableData.flippedCards = {}
			updateCardHighlighting(tableData)
		end
	end)
	
	-- Turn updates
	tableData.remoteEvents.TurnUpdate.OnClientEvent:Connect(function(currentTurnPlayer)
		if not tableData.gameActive then return end
		
		tableData.isMyTurn = currentTurnPlayer == player.Name
		
		if tableData.gameUI and getCurrentTable() == tableData then
			local turnLabel = tableData.gameUI.TurnFrame.TurnLabel
			if tableData.isMyTurn then
				turnLabel.Text = "Your Turn"
				turnLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			else
				turnLabel.Text = "Opponent's Turn"
				turnLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
			end
		end
		
		updateCardHighlighting(tableData)
	end)
	
	-- Card flip events
	tableData.remoteEvents.CardFlip.OnClientEvent:Connect(function(cardOrAction)
		if cardOrAction == "reset_all_cards" then
			for _, card in ipairs(tableData.tablePart:GetChildren()) do
				if card:IsA("BasePart") then
					resetCard(tableData, card)
				end
			end
			tableData.selectedCards = {}
			tableData.flippedCards = {}
			
			for card, highlight in pairs(tableData.cardHighlights) do
				highlight.Enabled = false
			end
		else
			flipCard(tableData, cardOrAction)
		end
	end)
end

-- Monitor character and seating
local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	
	-- Check all tables when seated
	humanoid.Seated:Connect(function()
		task.wait(0.2)
		for _, tableData in pairs(tables) do
			checkSeatingStatus(tableData)
		end
	end)
	
	-- Monitor seat changes
	humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		for _, tableData in pairs(tables) do
			checkSeatingStatus(tableData)
		end
	end)
	
	-- Initial check
	task.wait(0.5)
	for _, tableData in pairs(tables) do
		checkSeatingStatus(tableData)
	end
end

-- Monitor seat occupancy changes
for tableId, tableData in pairs(tables) do
	for _, seat in ipairs(tableData.seats) do
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			task.wait(0.1)
			checkSeatingStatus(tableData)
		end)
	end
end

-- Connect to character
if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Clean up on character removal
player.CharacterRemoving:Connect(function()
	for _, tableData in pairs(tables) do
		stopWaitingAnimation(tableData)
		if tableData.gameUI then
			tableData.gameUI:Destroy()
			tableData.gameUI = nil
		end
	end
end)

-- Connect mouse events
mouse.Move:Connect(onMouseMove)
mouse.Button1Down:Connect(onMouseClick)

print("[PokerGame] Multi-table client initialized")