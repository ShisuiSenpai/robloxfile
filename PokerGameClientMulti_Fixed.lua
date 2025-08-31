-- PokerGameClientMulti_Fixed.lua
-- Fixed version that properly handles UI persistence between games

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Import SoundManager if it exists
local SoundManager
local soundManagerSuccess = pcall(function()
	SoundManager = require(ReplicatedStorage:WaitForChild("SoundManager", 5))
end)

if soundManagerSuccess and SoundManager then
	print("[PokerGame] SoundManager loaded successfully")
else
	warn("[PokerGame] SoundManager not found - sounds will be disabled")
end

-- Constants
local HIGHLIGHT_COLOR = Color3.fromRGB(255, 255, 100)
local SELECTED_CARD_COLOR = Color3.fromRGB(100, 255, 100)
local CAMERA_TRANSITION_TIME = 1.5

-- Table configurations
local TABLE_CONFIGS = {
	Table1 = {
		folderName = "Table1Folder",
		tableName = "Table1",
		seats = {"Chair1", "Chair2"},
		cameraPart = "CameraPartTable1",
		remoteFolder = "Table1"
	},
	Table2 = {
		folderName = "Table2Folder",
		tableName = "Table2",
		seats = {"Chair3", "Chair4"},
		cameraPart = "CameraPartTable2",
		remoteFolder = "Table2"
	},
	Table3 = {
		folderName = "Table3Folder",
		tableName = "Table3",
		seats = {"Chair5", "Chair6"},
		cameraPart = "CameraPartTable3",
		remoteFolder = "Table3"
	},
	Table4 = {
		folderName = "Table4Folder",
		tableName = "Table4",
		seats = {"Chair7", "Chair8"},
		cameraPart = "CameraPartTable4",
		remoteFolder = "Table4"
	},
	Table5 = {
		folderName = "Table5Folder",
		tableName = "Table5",
		seats = {"Chair9", "Chair10"},
		cameraPart = "CameraPartTable5",
		remoteFolder = "Table5"
	},
	Table6 = {
		folderName = "Table6Folder",
		tableName = "Table6",
		seats = {"Chair11", "Chair12"},
		cameraPart = "CameraPartTable6",
		remoteFolder = "Table6"
	},
	Table7 = {
		folderName = "Table7Folder",
		tableName = "Table7",
		seats = {"Chair13", "Chair14"},
		cameraPart = "CameraPartTable7",
		remoteFolder = "Table7"
	},
	Table8 = {
		folderName = "Table8Folder",
		tableName = "Table8",
		seats = {"Chair15", "Chair16"},
		cameraPart = "CameraPartTable8",
		remoteFolder = "Table8"
	},
	Table9 = {
		folderName = "Table9Folder",
		tableName = "Table9",
		seats = {"Chair17", "Chair18"},
		cameraPart = "CameraPartTable9",
		remoteFolder = "Table9"
	},
	Table10 = {
		folderName = "Table10Folder",
		tableName = "Table10",
		seats = {"Chair19", "Chair20"},
		cameraPart = "CameraPartTable10",
		remoteFolder = "Table10"
	}
}

-- Initialize tables storage
local tables = {}
local allSeats = {}
local seatToTable = {}
local originalCameraState = nil
local cameraConnection = nil
local currentTable = nil
local waitingAnimations = {}

-- Play sound helper
local function playSound(soundName, position)
	if SoundManager and SoundManager.PlaySound then
		SoundManager.PlaySound(soundName, position)
	end
end

-- Helper to get current table
local function getCurrentTable()
	return currentTable
end

-- Start waiting animation
local function startWaitingAnimation(tableData, label)
	if not label or not label.Parent then return end
	
	stopWaitingAnimation(tableData)
	
	local dots = 0
	waitingAnimations[tableData.id] = RunService.Heartbeat:Connect(function()
		if label and label.Parent then
			dots = (dots + 0.02) % 4
			label.Text = "Waiting for players" .. string.rep(".", math.floor(dots))
		else
			stopWaitingAnimation(tableData)
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

-- Validate and repair UI
local function validateAndRepairUI(tableData)
	-- Check if UI exists
	if not tableData.gameUI or not tableData.gameUI.Parent then
		-- UI is completely missing, try to set it up again
		setupGameUI(tableData)
		return false
	end
	
	-- Check if TurnFrame exists
	local turnFrame = tableData.gameUI:FindFirstChild("TurnFrame")
	if not turnFrame then
		warn("[PokerGame] TurnFrame missing for table", tableData.id, "- attempting repair")
		-- Try to recreate the UI
		tableData.gameUI = nil
		setupGameUI(tableData)
		return false
	end
	
	-- Check if TurnLabel exists
	local turnLabel = turnFrame:FindFirstChild("TurnLabel")
	if not turnLabel then
		warn("[PokerGame] TurnLabel missing for table", tableData.id, "- attempting repair")
		tableData.gameUI = nil
		setupGameUI(tableData)
		return false
	end
	
	-- Check StatusFrame
	local statusFrame = tableData.gameUI:FindFirstChild("StatusFrame")
	if not statusFrame then
		warn("[PokerGame] StatusFrame missing for table", tableData.id, "- attempting repair")
		tableData.gameUI = nil
		setupGameUI(tableData)
		return false
	end
	
	return true
end

-- Clean up table state when leaving
local function cleanupTableState(tableData)
	-- Disable UI instead of destroying
	if tableData.gameUI then
		tableData.gameUI.Enabled = false
		-- Reset UI to default state
		if tableData.turnLabel then
			tableData.turnLabel.Text = "Waiting for players"
		end
		if tableData.statusLabel and tableData.statusLabel.Parent then
			tableData.statusLabel.Parent.Visible = false
		end
	end
	
	-- Stop animations
	stopWaitingAnimation(tableData)
	
	-- Clean up highlights
	for card, highlight in pairs(tableData.cardHighlights) do
		if highlight and highlight.Parent then
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
end

-- Get and setup game UI for a table
function setupGameUI(tableData)
	-- Get the pre-made UI from PlayerGui folder
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		warn("[PokerGame] PlayerGui not found")
		return
	end
	
	local uiFolder = playerGui:FindFirstChild("PokerGameUI_Table")
	if not uiFolder then
		warn("[PokerGame] PokerGameUI_Table folder not found")
		return
	end
	
	local uiName = "PokerGameUI_" .. tableData.id
	local screenGui = uiFolder:FindFirstChild(uiName)
	
	if not screenGui then
		warn("[PokerGame] Pre-made UI not found:", uiName)
		return
	end
	
	-- Wait for UI elements with timeout
	local turnFrame = screenGui:FindFirstChild("TurnFrame")
	local statusFrame = screenGui:FindFirstChild("StatusFrame")
	
	if not turnFrame or not statusFrame then
		warn("[PokerGame] UI frames missing for table:", tableData.id)
		return
	end
	
	local turnLabel = turnFrame:FindFirstChild("TurnLabel")
	local statusLabel = statusFrame:FindFirstChild("StatusLabel")
	
	if not turnLabel or not statusLabel then
		warn("[PokerGame] UI labels missing for table:", tableData.id)
		return
	end
	
	-- Reset to default state
	turnLabel.Text = "Waiting for players"
	statusFrame.Visible = false
	turnFrame.Visible = true
	
	-- Store references
	tableData.gameUI = screenGui
	tableData.turnLabel = turnLabel
	tableData.statusLabel = statusLabel
	
	print("[PokerGame] UI setup complete for table:", tableData.id)
	
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
	tableData.selectedCards[card] = nil
	tableData.flippedCards[card] = nil
	
	if tableData.originalCardCFrames[card] then
		local resetTween = TweenService:Create(card,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{CFrame = tableData.originalCardCFrames[card]}
		)
		resetTween:Play()
	end
	
	updateCardHighlighting(tableData)
end

-- Initialize all tables
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
	for _, child in ipairs(tablePart:GetChildren()) do
		if child:IsA("BasePart") and not child.Name:match("Camera") then
			tableData.originalCardCFrames[child] = child.CFrame
		end
	end
	
	tables[tableId] = tableData
end

-- Handle seat occupancy changes
local function handleSeatChange(seat)
	local humanoid = seat.Occupant
	local tableData = seatToTable[seat]
	if not tableData then return end
	
	if humanoid and humanoid.Parent == player.Character then
		-- Player sat down
		currentTable = tableData
		
		-- Setup UI if not already
		if not tableData.gameUI then
			setupGameUI(tableData)
		end
		
		-- Enable the UI
		if tableData.gameUI then
			tableData.gameUI.Enabled = true
		else
			warn("[PokerGame] Failed to setup UI for table:", tableData.id)
		end
		
		updateGameUIVisibility(tableData)
		
	elseif currentTable == tableData and not humanoid then
		-- Player stood up from this table
		currentTable = nil
		cleanupTableState(tableData)
	end
end

-- Update game UI visibility based on state
function updateGameUIVisibility(tableData)
	if not tableData.gameUI then 
		setupGameUI(tableData)
		if not tableData.gameUI then
			return
		end
	end
	
	-- Validate UI before using it
	if not validateAndRepairUI(tableData) then
		return
	end
	
	local isSeated = false
	local bothSeated = true
	
	for _, seat in ipairs(tableData.seats) do
		local occupant = seat.Occupant
		if occupant and occupant.Parent == player.Character then
			isSeated = true
		end
		if not occupant then
			bothSeated = false
		end
	end
	
	-- Safe UI updates with validation
	local turnFrame = tableData.gameUI:FindFirstChild("TurnFrame")
	if turnFrame then
		if isSeated and not tableData.gameActive and not tableData.isCountdownActive then
			turnFrame.Visible = true
			stopWaitingAnimation(tableData)
			startWaitingAnimation(tableData, tableData.turnLabel)
		elseif isSeated and tableData.gameActive then
			turnFrame.Visible = true
			stopWaitingAnimation(tableData)
		elseif tableData.isCountdownActive then
			turnFrame.Visible = false
			stopWaitingAnimation(tableData)
		else
			turnFrame.Visible = false
			stopWaitingAnimation(tableData)
		end
	end
end

-- Connect events for each table
for tableId, tableData in pairs(tables) do
	-- Game state updates
	tableData.remoteEvents.GameStateUpdate.OnClientEvent:Connect(function(state, data)
		if state == "countdown_start" then
			tableData.isCountdownActive = true
			tableData.gameActive = false
			
			-- Validate and update UI
			if tableData.gameUI then
				local turnFrame = tableData.gameUI:FindFirstChild("TurnFrame")
				if turnFrame then
					turnFrame.Visible = false
				end
			end
			
		elseif state == "shuffle_start" then
			-- Cards are being shuffled server-side
			
		elseif state == "game_start" then
			tableData.isCountdownActive = false
			tableData.gameActive = true
			tableData.selectedCards = {}
			tableData.flippedCards = {}
			
			stopWaitingAnimation(tableData)
			
			-- Update UI if seated at this table
			if getCurrentTable() == tableData then
				-- Ensure UI is set up and valid
				if not validateAndRepairUI(tableData) then
					warn("[PokerGame] Failed to validate UI for game start")
					return
				end
				
				if tableData.gameUI then
					tableData.gameUI.Enabled = true
					local turnFrame = tableData.gameUI:FindFirstChild("TurnFrame")
					if turnFrame then
						turnFrame.Visible = true
					end
				end
			end
			
			-- Create highlights for all cards
			local cardCount = 0
			
			-- Check direct children
			for _, card in ipairs(tableData.tablePart:GetChildren()) do
				if card:IsA("BasePart") and not card.Name:match("Camera") then
					getOrCreateHighlight(tableData, card)
					cardCount = cardCount + 1
				end
			end
			
			-- Also check if tablePart is a model
			if tableData.tablePart:IsA("Model") then
				for _, child in ipairs(tableData.tablePart:GetDescendants()) do
					if child:IsA("BasePart") and child.Parent == tableData.tablePart and not child.Name:match("Camera") then
						if not tableData.cardHighlights[child] then
							getOrCreateHighlight(tableData, child)
							cardCount = cardCount + 1
						end
					end
				end
			end
			
			updateCardHighlighting(tableData)
			
		elseif state == "game_end" then
			tableData.gameActive = false
			tableData.isMyTurn = false
			stopWaitingAnimation(tableData)
			
			-- Show win/lose UI based on data
			if data and getCurrentTable() == tableData then
				if tableData.statusLabel and tableData.statusLabel.Parent then
					if data.winner == player.Name then
						tableData.statusLabel.Text = "You Win!"
						tableData.statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
						playSound("Win")
					else
						tableData.statusLabel.Text = "You Lose!"
						tableData.statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
						playSound("Lose")
					end
					tableData.statusLabel.Parent.Visible = true
				end
			end
			
			-- Hide turn UI
			if tableData.gameUI then
				local turnFrame = tableData.gameUI:FindFirstChild("TurnFrame")
				if turnFrame then
					turnFrame.Visible = false
				end
			end
			
			-- Clean up highlights
			for card, highlight in pairs(tableData.cardHighlights) do
				if highlight and highlight.Parent then
					highlight:Destroy()
				end
			end
			tableData.cardHighlights = {}
			
		elseif state == "waiting" then
			tableData.gameActive = false
			tableData.isMyTurn = false
			tableData.isCountdownActive = false
			
			-- Update UI
			updateGameUIVisibility(tableData)
			
		elseif state == "full_reset" then
			-- Reset everything
			cleanupTableState(tableData)
			
			-- Update UI visibility
			updateGameUIVisibility(tableData)
		end
	end)
	
	-- Turn updates with validation
	tableData.remoteEvents.TurnUpdate.OnClientEvent:Connect(function(currentTurnPlayer, timeLeft)
		if not currentTurnPlayer or currentTurnPlayer == "" then
			return
		end
		
		if not tableData.gameActive then 
			return 
		end
		
		tableData.isMyTurn = currentTurnPlayer == player.Name
		
		if tableData.gameUI and getCurrentTable() == tableData then
			-- Validate UI before using it
			if not validateAndRepairUI(tableData) then
				warn("[PokerGame] Failed to validate UI for turn update")
				return
			end
			
			local turnFrame = tableData.gameUI:FindFirstChild("TurnFrame")
			local turnLabel = turnFrame and turnFrame:FindFirstChild("TurnLabel")
			
			if turnLabel then
				-- Update turn text with timer
				local turnText = tableData.isMyTurn and "Your Turn" or "Opponent's Turn"
				if timeLeft then
					turnText = turnText .. string.format(" (%d)", math.ceil(timeLeft))
				end
				
				turnLabel.Text = turnText
				
				-- Color based on turn and urgency
				if tableData.isMyTurn then
					if timeLeft and timeLeft <= 3 then
						turnLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
					else
						turnLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
					end
				else
					turnLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
				end
				
				-- Add pulse effect when time is low
				if tableData.isMyTurn and timeLeft and timeLeft <= 3 and timeLeft > 0 then
					local pulse = TweenService:Create(turnLabel,
						TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
						{TextTransparency = 0.3}
					)
					pulse:Play()
					pulse.Completed:Connect(function()
						if turnLabel and turnLabel.Parent then
							turnLabel.TextTransparency = 0
						end
					end)
				end
			end
		end
		
		updateCardHighlighting(tableData)
	end)
	
	-- Card flip events
	tableData.remoteEvents.CardFlip.OnClientEvent:Connect(function(card)
		if card == "reset_all_cards" then
			for card, _ in pairs(tableData.flippedCards) do
				task.spawn(function()
					resetCard(tableData, card)
				end)
			end
			tableData.selectedCards = {}
			tableData.flippedCards = {}
		else
			flipCard(tableData, card)
		end
	end)
	
	-- Connect seat events
	for _, seat in ipairs(tableData.seats) do
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			handleSeatChange(seat)
		end)
		
		-- Check current occupancy
		handleSeatChange(seat)
	end
end

-- Mouse handling for card hover and clicks
local hoveredCard = nil

mouse.Move:Connect(function()
	local target = mouse.Target
	
	if currentTable and target and target.Parent == currentTable.tablePart then
		if not target.Name:match("Camera") then
			if currentTable.gameActive and currentTable.isMyTurn then
				if hoveredCard ~= target then
					playSound("CardHover", target.Position)
				end
				hoveredCard = target
				currentTable.currentHoveredCard = target
			else
				hoveredCard = nil
				currentTable.currentHoveredCard = nil
			end
		else
			hoveredCard = nil
			if currentTable then
				currentTable.currentHoveredCard = nil
			end
		end
	else
		hoveredCard = nil
		if currentTable then
			currentTable.currentHoveredCard = nil
		end
	end
	
	if currentTable then
		updateCardHighlighting(currentTable)
	end
end)

mouse.Button1Down:Connect(function()
	if not currentTable or not currentTable.gameActive or not currentTable.isMyTurn then
		return
	end
	
	local target = mouse.Target
	if target and target.Parent == currentTable.tablePart and not target.Name:match("Camera") then
		if not currentTable.selectedCards[target] then
			playSound("CardSelect", target.Position)
			currentTable.remoteEvents.CardClick:FireServer(target)
		end
	end
end)

-- Touch support
UserInputService.TouchTap:Connect(function(touchPositions, gameProcessedEvent)
	if gameProcessedEvent or not currentTable or not currentTable.gameActive or not currentTable.isMyTurn then
		return
	end
	
	local touchPos = touchPositions[1]
	local camera = workspace.CurrentCamera
	local ray = camera:ScreenPointToRay(touchPos.X, touchPos.Y)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {player.Character}
	
	local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
	
	if raycastResult then
		local target = raycastResult.Instance
		if target and target.Parent == currentTable.tablePart and not target.Name:match("Camera") then
			if not currentTable.selectedCards[target] then
				playSound("CardSelect", target.Position)
				currentTable.remoteEvents.CardClick:FireServer(target)
			end
		end
	end
end)

-- Periodic UI validation (runs every 2 seconds)
task.spawn(function()
	while true do
		task.wait(2)
		
		-- Check current table
		if currentTable and currentTable.gameActive then
			-- Validate UI is still intact
			if not validateAndRepairUI(currentTable) then
				warn("[PokerGame] UI validation failed, attempted repair")
			end
		end
	end
end)

print("[PokerGame] Multi-table client initialized with improved UI handling")