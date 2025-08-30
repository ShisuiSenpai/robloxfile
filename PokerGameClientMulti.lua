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
	},
	Table3 = {
		folderName = "Table3Folder", 
		tableName = "Table3",
		remoteFolder = "Table3",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table4 = {
		folderName = "Table4Folder", 
		tableName = "Table4",
		remoteFolder = "Table4",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table5 = {
		folderName = "Table5Folder", 
		tableName = "Table5",
		remoteFolder = "Table5",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table6 = {
		folderName = "Table6Folder", 
		tableName = "Table6",
		remoteFolder = "Table6",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table7 = {
		folderName = "Table7Folder", 
		tableName = "Table7",
		remoteFolder = "Table7",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table8 = {
		folderName = "Table8Folder", 
		tableName = "Table8",
		remoteFolder = "Table8",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table9 = {
		folderName = "Table9Folder", 
		tableName = "Table9",
		remoteFolder = "Table9",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table10 = {
		folderName = "Table10Folder", 
		tableName = "Table10",
		remoteFolder = "Table10",
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
	
	-- Get UI references (but don't enable yet)
	local playerGui = player:WaitForChild("PlayerGui")
	local uiName = "PokerGameUI_" .. tableId
	local screenGui = playerGui:FindFirstChild(uiName)
	
	if screenGui then
		tableData.gameUI = screenGui
		local turnFrame = screenGui:FindFirstChild("TurnFrame")
		if turnFrame then
			tableData.turnLabel = turnFrame:FindFirstChild("TurnLabel")
		end
		local statusFrame = screenGui:FindFirstChild("StatusFrame") 
		if statusFrame then
			tableData.statusLabel = statusFrame:FindFirstChild("StatusLabel")
		end
		-- Keep UI disabled until player sits at this table
		screenGui.Enabled = false
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
	-- print("[DEBUG] startWaitingAnimation called for table:", tableData.id)
	-- print("[DEBUG] turnLabel exists:", turnLabel ~= nil)
	
	if waitingAnimations[tableData.id] then 
		-- print("[DEBUG] Animation already running for table:", tableData.id)
		return 
	end
	
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
			-- print("[DEBUG] Waiting animation updated - Table:", tableData.id, "Text:", turnLabel.Text)
		end
	end)
	
	-- print("[DEBUG] Waiting animation started for table:", tableData.id)
end

-- Stop waiting animation
local function stopWaitingAnimation(tableData)
	if waitingAnimations[tableData.id] then
		waitingAnimations[tableData.id]:Disconnect()
		waitingAnimations[tableData.id] = nil
	end
end

-- Clean up table state when leaving
local function cleanupTableState(tableData)
	-- print("[DEBUG] Cleaning up table state for:", tableData.id)
	
	-- Disable UI instead of destroying (since they're pre-made)
	if tableData.gameUI then
		tableData.gameUI.Enabled = false
		-- Reset UI to default state
		if tableData.turnLabel then
			tableData.turnLabel.Text = "Waiting for players"
		end
		if tableData.statusLabel then
			tableData.statusLabel.Parent.Visible = false -- Hide StatusFrame
		end
	end
	
	-- Stop animations
	stopWaitingAnimation(tableData)
	
	-- Clean up highlights
	for card, highlight in pairs(tableData.cardHighlights) do
		if highlight then
			highlight:Destroy()
		end
	end
	tableData.cardHighlights = {}
	
	-- Reset game state
	tableData.gameActive = false
	tableData.isMyTurn = false
	tableData.isCountdownActive = false
	tableData.currentHoveredCard = nil
	tableData.selectedCards = {}
	tableData.flippedCards = {}
	
	-- Note: We don't clear originalCardCFrames as these should persist
	
	-- print("[DEBUG] Cleanup complete for table:", tableData.id)
end

-- Create game UI for a table
local function setupGameUI(tableData)
	-- We already have the UI references from initialization
	if not tableData.gameUI then
		warn("[PokerGame] No UI found for table:", tableData.id)
		return
	end
	
	-- Reset to default state
	if tableData.turnLabel then
		tableData.turnLabel.Text = "Waiting for players"
	end
	if tableData.statusLabel and tableData.statusLabel.Parent then
		tableData.statusLabel.Parent.Visible = false -- Hide StatusFrame
	end
	
	return tableData.gameUI, tableData.turnLabel, tableData.statusLabel
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
	local highlightCount = 0
	for card, highlight in pairs(tableData.cardHighlights) do
		highlightCount = highlightCount + 1
		if tableData.selectedCards[card] or tableData.flippedCards[card] then
			highlight.FillColor = SELECTED_CARD_COLOR
			highlight.OutlineColor = SELECTED_CARD_COLOR
			highlight.Enabled = true
			-- print("[DEBUG] Card", card.Name, "highlighted as SELECTED/FLIPPED")
		elseif tableData.currentHoveredCard == card and tableData.gameActive and tableData.isMyTurn then
			highlight.FillColor = HIGHLIGHT_COLOR
			highlight.OutlineColor = HIGHLIGHT_COLOR
			highlight.Enabled = true
			-- print("[DEBUG] Card", card.Name, "highlighted as HOVERED - isMyTurn:", tableData.isMyTurn)
		else
			highlight.Enabled = false
		end
	end
	-- print("[DEBUG] updateCardHighlighting - Table:", tableData.id, "Processed:", highlightCount, "highlights, gameActive:", tableData.gameActive, "isMyTurn:", tableData.isMyTurn)
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
	-- Clear card state
	tableData.flippedCards[card] = nil
	tableData.selectedCards[card] = nil
	
	-- Clear highlight state for this card
	local highlight = tableData.cardHighlights[card]
	if highlight and highlight.Parent then
		highlight.Enabled = false
	end
	
	local originalCFrame = tableData.originalCardCFrames[card]
	if originalCFrame and card.Parent then
		-- Cancel any existing animations by setting directly first
		card.CFrame = originalCFrame
		
		-- Then do smooth animation if card is visibly flipped
		local angleDiff = math.abs((card.CFrame:ToEulerAnglesXYZ()) - (originalCFrame:ToEulerAnglesXYZ()))
		if angleDiff > 0.1 then
			-- Smooth reset animation
			coroutine.wrap(function()
				local startCFrame = card.CFrame
				local duration = 0.3
				local elapsed = 0
				
				while elapsed < duration and card.Parent do
					elapsed = elapsed + RunService.Heartbeat:Wait()
					local alpha = math.min(elapsed / duration, 1)
					alpha = alpha * alpha * (3 - 2 * alpha) -- Smooth step
					
					if card.Parent then
						card.CFrame = startCFrame:Lerp(originalCFrame, alpha)
					end
				end
				
				-- Final position
				if card.Parent then
					card.CFrame = originalCFrame
				end
			end)()
		end
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
			-- print("[DEBUG] Direct card hover:", cardTarget.Name)
		elseif target.Parent and target.Parent.Parent == currentTable.tablePart and target.Parent:IsA("BasePart") then
			cardTarget = target.Parent
			-- print("[DEBUG] Indirect card hover (via child):", cardTarget.Name)
		else
			-- Debug why it's not detecting as a card
			if target.Parent then
				-- print("[DEBUG] Mouse target parent:", target.Parent.Name, "Expected table:", currentTable.tablePart.Name)
			end
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
	-- print("[DEBUG] onMouseClick - currentTable:", currentTable and currentTable.id or "none")
	
	if not currentTable or not currentTable.gameActive or not currentTable.isMyTurn or 
	   not currentTable.currentHoveredCard or currentTable.isCountdownActive then
		-- print("[DEBUG] Click blocked - gameActive:", currentTable and currentTable.gameActive,
		--	"isMyTurn:", currentTable and currentTable.isMyTurn,
		--	"hoveredCard:", currentTable and currentTable.currentHoveredCard and currentTable.currentHoveredCard.Name or "none",
		--	"isCountdown:", currentTable and currentTable.isCountdownActive)
		return
	end
	
	if currentTable.selectedCards[currentTable.currentHoveredCard] then
		-- print("[DEBUG] Card already selected:", currentTable.currentHoveredCard.Name)
		return
	end
	
	-- print("[DEBUG] Clicking card:", currentTable.currentHoveredCard.Name)
	
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
	-- print("[DEBUG] checkSeatingStatus called for table:", tableData.id)
	
	if not player.Character then 
		-- print("[DEBUG] No player character")
		return 
	end
	
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then 
		-- print("[DEBUG] No humanoid found")
		return 
	end
	
	-- Check if seated at this table
	local isSeated = false
	for _, seat in ipairs(tableData.seats) do
		if humanoid.SeatPart == seat then
			isSeated = true
			-- print("[DEBUG] Player is seated at table:", tableData.id, "on seat:", seat.Name)
			break
		end
	end
	
	if not isSeated then
		-- Not seated at this table
		-- print("[DEBUG] Player not seated at table:", tableData.id)
		cleanupTableState(tableData)
		return
	end
	
	-- Seated at this table
	if not tableData.gameUI then
		-- print("[DEBUG] Creating UI for table:", tableData.id)
		setupGameUI(tableData)
		-- Enable the UI when player sits
		tableData.gameUI.Enabled = true
	end
	
	-- Check if both seats are occupied
	local bothSeated = true
	for _, seat in ipairs(tableData.seats) do
		if not seat.Occupant then
			bothSeated = false
			break
		end
	end
	
	-- print("[DEBUG] Table", tableData.id, "- isSeated:", isSeated, "bothSeated:", bothSeated,
	--	"gameActive:", tableData.gameActive, "isCountdownActive:", tableData.isCountdownActive)
	
	-- Update UI based on game state
	if tableData.gameUI and tableData.gameUI.TurnFrame then
		if isSeated and not tableData.gameActive and not tableData.isCountdownActive then
			-- Show waiting UI when seated but game hasn't started
			-- print("[DEBUG] Showing waiting UI for table:", tableData.id)
			tableData.gameUI.TurnFrame.Visible = true
			stopWaitingAnimation(tableData) -- Stop any existing animation first
			startWaitingAnimation(tableData, tableData.turnLabel)
		elseif isSeated and tableData.gameActive then
			-- Keep UI visible during game
			-- print("[DEBUG] Showing game UI for table:", tableData.id)
			tableData.gameUI.TurnFrame.Visible = true
			stopWaitingAnimation(tableData)
		elseif tableData.isCountdownActive then
			-- Hide during countdown
			-- print("[DEBUG] Hiding UI during countdown for table:", tableData.id)
			tableData.gameUI.TurnFrame.Visible = false
			stopWaitingAnimation(tableData)
		else
			-- Hide UI when not seated
			tableData.gameUI.TurnFrame.Visible = false
			stopWaitingAnimation(tableData)
		end
	end
end

-- Connect events for each table
for tableId, tableData in pairs(tables) do
	local screenGui, turnLabel, statusLabel
	
	-- Game state updates
	tableData.remoteEvents.GameStateUpdate.OnClientEvent:Connect(function(state, data)
		-- print("[DEBUG] GameStateUpdate received for table:", tableData.id, "State:", state)
		
		if state == "countdown_start" then
			-- print("[DEBUG] Countdown starting for table:", tableData.id)
			tableData.isCountdownActive = true
			tableData.gameActive = false
			if tableData.gameUI then
				-- print("[DEBUG] Hiding TurnFrame for countdown")
				tableData.gameUI.TurnFrame.Visible = false
			end
			
		elseif state == "shuffle_start" then
			-- Cards are being shuffled server-side
			-- We could add a visual effect here if desired
			-- For now, just prepare for game start
			
		elseif state == "game_start" then
			-- print("[DEBUG] Game starting for table:", tableData.id)
			tableData.isCountdownActive = false
			tableData.gameActive = true
			tableData.selectedCards = {}
			tableData.flippedCards = {}
			
			-- Stop waiting animation
			stopWaitingAnimation(tableData)
			
			-- Update UI if seated at this table
			if getCurrentTable() == tableData then
				-- print("[DEBUG] Player is at this table, showing game UI")
				if not tableData.gameUI then
					setupGameUI(tableData)
		-- Enable the UI when player sits
		tableData.gameUI.Enabled = true
				end
				tableData.gameUI.TurnFrame.Visible = true
			else
				-- print("[DEBUG] Player is NOT at this table")
			end
			
			-- Create highlights for all cards
			-- print("[DEBUG] Creating highlights for table:", tableData.id)
			local cardCount = 0
			
			-- Check direct children
			for _, card in ipairs(tableData.tablePart:GetChildren()) do
				if card:IsA("BasePart") and not card.Name:match("Camera") then
					-- print("[DEBUG] Creating highlight for card:", card.Name)
					getOrCreateHighlight(tableData, card)
					cardCount = cardCount + 1
				end
			end
			
			-- Also check if tablePart is a model with cards inside
			if tableData.tablePart:IsA("Model") then
				for _, child in ipairs(tableData.tablePart:GetDescendants()) do
					if child:IsA("BasePart") and child.Parent == tableData.tablePart and not child.Name:match("Camera") then
						if not tableData.cardHighlights[child] then
							-- print("[DEBUG] Creating highlight for nested card:", child.Name)
							getOrCreateHighlight(tableData, child)
							cardCount = cardCount + 1
						end
					end
				end
			end
			
			-- print("[DEBUG] Created highlights for", cardCount, "cards on table:", tableData.id)
			
			updateCardHighlighting(tableData)
			
		elseif state == "game_end" then
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
				tableData.gameUI.TurnFrame.Visible = false

				local statusLabel = statusFrame.StatusLabel
				if data.winner == player.Name then
					statusLabel.Text = "You Win!"
					statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
					-- Add pulse effect for winner
					local pulseEffect = TweenService:Create(statusLabel,
						TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 3, true),
						{TextTransparency = 0.3}
					)
					pulseEffect:Play()
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

				-- Hide after delay and show waiting UI again
				coroutine.wrap(function()
					local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
					local hideDelay = data.winner == player.Name and 2 or 3
					wait(hideDelay)
					
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
											tableData.gameUI.TurnFrame.Visible = true
											stopWaitingAnimation(tableData)
											startWaitingAnimation(tableData, tableData.turnLabel)
										end
										break
									end
								end
							end
						end)
					end
				end)()
			end
			
		elseif state == "cards_reset" then
			tableData.selectedCards = {}
			tableData.flippedCards = {}
			updateCardHighlighting(tableData)
			
		elseif state == "full_reset" then
			-- Complete reset of table state
			tableData.gameActive = false
			tableData.isMyTurn = false
			tableData.isCountdownActive = false
			tableData.selectedCards = {}
			tableData.flippedCards = {}
			tableData.currentHoveredCard = nil
			
			-- Ensure all highlights are properly cleaned
			for card, highlight in pairs(tableData.cardHighlights) do
				if highlight and highlight.Parent then
					highlight:Destroy()
				end
			end
			tableData.cardHighlights = {}
			
			-- Check if player is still seated and update UI accordingly
			checkSeatingStatus(tableData)
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
			-- Reset all cards for this table
			for _, card in ipairs(tableData.tablePart:GetChildren()) do
				if card:IsA("BasePart") and not card.Name:match("Camera") then
					resetCard(tableData, card)
				end
			end
			
			-- Also check descendants if table is a model
			if tableData.tablePart:IsA("Model") then
				for _, child in ipairs(tableData.tablePart:GetDescendants()) do
					if child:IsA("BasePart") and child.Parent == tableData.tablePart and not child.Name:match("Camera") then
						resetCard(tableData, child)
					end
				end
			end
			
			-- Clear all state
			tableData.selectedCards = {}
			tableData.flippedCards = {}
			tableData.currentHoveredCard = nil
			
			-- Disable and clean all highlights
			for card, highlight in pairs(tableData.cardHighlights) do
				if highlight and highlight.Parent then
					highlight.Enabled = false
				end
			end
		else
			flipCard(tableData, cardOrAction)
		end
	end)
end

-- Monitor character and seating
local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	
	-- Reset all table states on respawn
	for _, tableData in pairs(tables) do
		-- Clear any leftover state
		tableData.gameActive = false
		tableData.isMyTurn = false
		tableData.isCountdownActive = false
		tableData.currentHoveredCard = nil
		
		-- Destroy old highlights
		for card, highlight in pairs(tableData.cardHighlights) do
			if highlight and highlight.Parent then
				highlight:Destroy()
			end
		end
		tableData.cardHighlights = {}
	end
	
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
		cleanupTableState(tableData)
	end
end)

-- Connect mouse events
mouse.Move:Connect(onMouseMove)
mouse.Button1Down:Connect(onMouseClick)

-- Mobile touch support
local function handleTouch(touchPos)
	-- Get the camera
	local camera = workspace.CurrentCamera
	if not camera then return end
	
	-- Cast a ray from touch position
	local ray = camera:ScreenPointToRay(touchPos.X, touchPos.Y)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {player.Character}
	
	local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
	
	if raycastResult then
		local target = raycastResult.Instance
		
		-- Check if it's a card at current table
		local currentTable = getCurrentTable()
		if currentTable then
			local cardTarget = nil
			
			-- Check if target is a card
			if target.Parent == currentTable.tablePart and target:IsA("BasePart") and not target.Name:match("Camera") then
				cardTarget = target
			elseif target.Parent and target.Parent.Parent == currentTable.tablePart and target.Parent:IsA("BasePart") then
				cardTarget = target.Parent
			end
			
			if cardTarget then
				-- Update hover state
				if currentTable.currentHoveredCard ~= cardTarget then
					currentTable.currentHoveredCard = cardTarget
					updateCardHighlighting(currentTable)
				end
				
				-- Simulate click
				onMouseClick()
			end
		end
	end
end

-- Touch events for mobile
UserInputService.TouchTap:Connect(function(touchPositions, gameProcessedEvent)
	if gameProcessedEvent then return end
	if #touchPositions > 0 then
		handleTouch(touchPositions[1])
	end
end)

-- Also handle input began for touch
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.UserInputType == Enum.UserInputType.Touch then
		handleTouch(input.Position)
	end
end)

-- Handle input changed for touch movement
UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.UserInputType ~= Enum.UserInputType.Touch then return end
	
	-- Get the camera
	local camera = workspace.CurrentCamera
	if not camera then return end
	
	-- Cast a ray from touch position
	local ray = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {player.Character}
	
	local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
	
	if raycastResult then
		-- Update mouse target for hover effect
		local currentTable = getCurrentTable()
		if currentTable then
			local target = raycastResult.Instance
			local cardTarget = nil
			
			-- Check if target is a card
			if target.Parent == currentTable.tablePart and target:IsA("BasePart") and not target.Name:match("Camera") then
				cardTarget = target
			elseif target.Parent and target.Parent.Parent == currentTable.tablePart and target.Parent:IsA("BasePart") then
				cardTarget = target.Parent
			end
			
			-- Update hover state
			if cardTarget then
				if currentTable.currentHoveredCard ~= cardTarget then
					currentTable.currentHoveredCard = cardTarget
					updateCardHighlighting(currentTable)
					
					-- Play hover sound if appropriate
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
	else
		-- Clear hover if not hitting anything
		local currentTable = getCurrentTable()
		if currentTable and currentTable.currentHoveredCard then
			currentTable.currentHoveredCard = nil
			updateCardHighlighting(currentTable)
		end
	end
end)

-- Handle touch ended to clear hover state
-- Clear hover state on input end
UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
	if input.UserInputType ~= Enum.UserInputType.Touch then return end
	if gameProcessedEvent then return end
	
	-- Clear hover state when touch ends
	local currentTable = getCurrentTable()
	if currentTable and currentTable.currentHoveredCard then
		currentTable.currentHoveredCard = nil
		updateCardHighlighting(currentTable)
	end
end)

print("[PokerGame] Multi-table client initialized with mobile support")