-- PokerGameClientMulti_V2.lua
-- Improved version with better state management and reliability

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Import state manager
local ClientStateManager = require(script.Parent:WaitForChild("ClientStateManager"))

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

-- Storage
local allTables = {}
local allSeats = {}
local seatToTable = {}
local currentTable = nil
local cameraConnection = nil
local originalCamera = nil

-- Helper Functions
local function getCurrentTable()
	return currentTable
end

local function playSound(soundName, position)
	local sound = SoundService.SoundEffects:FindFirstChild(soundName)
	if not sound then
		warn("[PokerGame] Sound not found:", soundName)
		return
	end
	
	sound = sound:Clone()
	
	if position then
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 1
		part.Position = position
		part.Parent = workspace
		
		sound.Parent = part
		sound:Play()
		
		sound.Ended:Connect(function()
			part:Destroy()
		end)
	else
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end
	
	return sound
end

-- Initialize UI with state manager
local function setupGameUI(tableData)
	return function()
		local playerGui = player:FindFirstChild("PlayerGui")
		if not playerGui then return false end
		
		local uiFolder = playerGui:FindFirstChild("PokerGameUI_Table")
		if not uiFolder then return false end
		
		local uiName = "PokerGameUI_" .. tableData.id
		local screenGui = uiFolder:FindFirstChild(uiName)
		if not screenGui then return false end
		
		-- Get UI elements
		local turnFrame = screenGui:FindFirstChild("TurnFrame")
		local statusFrame = screenGui:FindFirstChild("StatusFrame")
		
		if not turnFrame or not statusFrame then return false end
		
		local turnLabel = turnFrame:FindFirstChild("TurnLabel")
		local statusLabel = statusFrame:FindFirstChild("StatusLabel")
		
		if not turnLabel or not statusLabel then return false end
		
		-- Store in state manager
		tableData.stateManager.components.ui.element = {
			screenGui = screenGui,
			turnFrame = turnFrame,
			turnLabel = turnLabel,
			statusFrame = statusFrame,
			statusLabel = statusLabel
		}
		
		-- Reset to default state
		turnLabel.Text = "Waiting for players"
		statusFrame.Visible = false
		turnFrame.Visible = true
		screenGui.Enabled = false -- Will be enabled when needed
		
		return true
	end
end

-- Initialize highlights with state manager
local function initializeHighlights(tableData)
	return function()
		local highlights = {}
		local cards = {}
		
		-- Find all cards
		for _, child in ipairs(tableData.tablePart:GetChildren()) do
			if child:IsA("BasePart") and not child.Name:match("Camera") then
				table.insert(cards, child)
			end
		end
		
		-- Also check if tablePart is a model
		if tableData.tablePart:IsA("Model") then
			for _, descendant in ipairs(tableData.tablePart:GetDescendants()) do
				if descendant:IsA("BasePart") and descendant.Parent == tableData.tablePart and not descendant.Name:match("Camera") then
					table.insert(cards, descendant)
				end
			end
		end
		
		if #cards == 0 then return false end
		
		-- Create highlights for all cards
		for _, card in ipairs(cards) do
			local highlight = Instance.new("Highlight")
			highlight.Parent = card
			highlight.Adornee = card
			highlight.FillTransparency = 0.7
			highlight.OutlineTransparency = 0
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			highlight.Enabled = false
			
			highlights[card] = highlight
		end
		
		-- Store in state manager
		tableData.stateManager.components.highlights.elements = highlights
		tableData.stateManager.components.cards.elements = cards
		
		print(string.format("[PokerGame] Initialized %d highlights for table %s", #cards, tableData.id))
		
		return true
	end
end

-- Update highlights based on state
local function updateHighlights(tableData)
	local stateManager = tableData.stateManager
	local highlights = stateManager.components.highlights.elements
	local gameData = stateManager.gameData
	
	if not highlights or not next(highlights) then
		-- Try to reinitialize if highlights are missing
		if stateManager:getState() == ClientStateManager.GameState.IN_GAME then
			warn("[PokerGame] Highlights missing during game, reinitializing...")
			stateManager:initializeComponent("highlights", initializeHighlights(tableData))
		end
		return
	end
	
	for card, highlight in pairs(highlights) do
		if gameData.selectedCards[card] or gameData.flippedCards[card] then
			highlight.FillColor = SELECTED_CARD_COLOR
			highlight.OutlineColor = SELECTED_CARD_COLOR
			highlight.Enabled = true
		elseif tableData.hoveredCard == card and gameData.isMyTurn and stateManager:getState() == ClientStateManager.GameState.IN_GAME then
			highlight.FillColor = HIGHLIGHT_COLOR
			highlight.OutlineColor = HIGHLIGHT_COLOR
			highlight.Enabled = true
		else
			highlight.Enabled = false
		end
	end
end

-- Handle hover with state validation
local function handleMouseMove(tableData)
	if tableData.stateManager:getState() ~= ClientStateManager.GameState.IN_GAME then
		tableData.hoveredCard = nil
		updateHighlights(tableData)
		return
	end
	
	if not tableData.stateManager.gameData.isMyTurn then
		tableData.hoveredCard = nil
		updateHighlights(tableData)
		return
	end
	
	local target = mouse.Target
	if target and target.Parent == tableData.tablePart then
		if not target.Name:match("Camera") then
			if tableData.hoveredCard ~= target then
				playSound("CardHover", target.Position)
			end
			tableData.hoveredCard = target
		else
			tableData.hoveredCard = nil
		end
	else
		tableData.hoveredCard = nil
	end
	
	updateHighlights(tableData)
end

-- Setup event handlers with state management
local function setupEventHandlers(tableData)
	local stateManager = tableData.stateManager
	
	-- Game state updates
	tableData.remoteEvents.GameStateUpdate.OnClientEvent:Connect(function(state, ...)
		print(string.format("[PokerGame] State update for table %s: %s", tableData.id, state))
		
		if state == "waiting" then
			stateManager:setState(ClientStateManager.GameState.WAITING)
			
			-- Ensure UI is initialized
			if not stateManager.components.ui.initialized then
				stateManager:initializeComponent("ui", setupGameUI(tableData))
			end
			
			-- Show waiting UI if at this table
			if getCurrentTable() == tableData then
				local ui = stateManager.components.ui.element
				if ui then
					ui.screenGui.Enabled = true
					ui.turnFrame.Visible = true
					ui.turnLabel.Text = "Waiting for players"
					
					-- Start waiting animation
					tableData.waitingDots = 0
					if tableData.waitingConnection then
						tableData.waitingConnection:Disconnect()
					end
					
					tableData.waitingConnection = RunService.Heartbeat:Connect(function()
						tableData.waitingDots = (tableData.waitingDots + 0.02) % 4
						local dots = string.rep(".", math.floor(tableData.waitingDots))
						ui.turnLabel.Text = "Waiting for players" .. dots
					end)
				end
			end
			
		elseif state == "countdown" then
			stateManager:setState(ClientStateManager.GameState.COUNTDOWN)
			
			-- Stop waiting animation
			if tableData.waitingConnection then
				tableData.waitingConnection:Disconnect()
				tableData.waitingConnection = nil
			end
			
		elseif state == "game_start" then
			stateManager:setState(ClientStateManager.GameState.IN_GAME)
			
			-- Initialize components in order
			stateManager:queueInitialization(1, "ui", setupGameUI(tableData))
			stateManager:queueInitialization(2, "highlights", initializeHighlights(tableData))
			stateManager:processInitializationQueue()
			
			-- Show game UI if at this table
			if getCurrentTable() == tableData then
				local ui = stateManager.components.ui.element
				if ui then
					ui.screenGui.Enabled = true
					ui.turnFrame.Visible = true
				end
			end
			
		elseif state == "game_end" then
			stateManager:setState(ClientStateManager.GameState.ENDING)
			
			-- Hide UI
			local ui = stateManager.components.ui.element
			if ui then
				ui.turnFrame.Visible = false
			end
			
		elseif state == "full_reset" then
			-- Clean up everything
			cleanupTable(tableData)
			stateManager:setState(ClientStateManager.GameState.IDLE)
		end
	end)
	
	-- Turn updates with validation
	tableData.remoteEvents.TurnUpdate.OnClientEvent:Connect(function(currentTurnPlayer, timeLeft)
		if not currentTurnPlayer or currentTurnPlayer == "" then
			return
		end
		
		if stateManager:getState() ~= ClientStateManager.GameState.IN_GAME then
			return
		end
		
		-- Update game data
		stateManager.gameData.currentPlayer = currentTurnPlayer
		stateManager.gameData.isMyTurn = currentTurnPlayer == player.Name
		stateManager.gameData.timeLeft = timeLeft or 0
		
		-- Update UI if at this table
		if getCurrentTable() == tableData then
			local ui = stateManager.components.ui.element
			if not ui or not ui.turnLabel.Parent then
				-- UI missing, try to recover
				warn("[PokerGame] Turn UI missing, attempting recovery...")
				if stateManager:initializeComponent("ui", setupGameUI(tableData)) then
					ui = stateManager.components.ui.element
				else
					return
				end
			end
			
			-- Update turn text
			local turnText = stateManager.gameData.isMyTurn and "Your Turn" or "Opponent's Turn"
			if timeLeft and timeLeft > 0 then
				turnText = turnText .. string.format(" (%d)", math.ceil(timeLeft))
			end
			
			ui.turnLabel.Text = turnText
			
			-- Update colors
			if stateManager.gameData.isMyTurn then
				if timeLeft and timeLeft <= 3 then
					ui.turnLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
				else
					ui.turnLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				end
			else
				ui.turnLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
			end
		end
		
		updateHighlights(tableData)
	end)
	
	-- Card flip events
	tableData.remoteEvents.CardFlip.OnClientEvent:Connect(function(card)
		if card == "reset_all_cards" then
			-- Reset all cards
			for card, _ in pairs(stateManager.gameData.flippedCards) do
				resetCard(tableData, card)
			end
			stateManager.gameData.selectedCards = {}
			stateManager.gameData.flippedCards = {}
		else
			-- Flip specific card
			flipCard(tableData, card)
		end
	end)
	
	-- Mouse events
	local mouseConnection
	
	-- Handle seat changes
	for _, seat in ipairs(tableData.seats) do
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			local humanoid = seat.Occupant
			
			if humanoid and humanoid.Parent and humanoid.Parent == player.Character then
				-- Player sat down
				currentTable = tableData
				
				-- Set up mouse tracking
				if mouseConnection then
					mouseConnection:Disconnect()
				end
				
				mouseConnection = mouse.Move:Connect(function()
					handleMouseMove(tableData)
				end)
				
				-- Handle camera
				local cameraPart = tableData.folder:FindFirstChild(tableData.config.cameraPart)
				if cameraPart then
					transitionCamera(cameraPart)
				end
				
			elseif currentTable == tableData then
				-- Player stood up
				currentTable = nil
				
				if mouseConnection then
					mouseConnection:Disconnect()
					mouseConnection = nil
				end
				
				tableData.hoveredCard = nil
				updateHighlights(tableData)
				
				-- Reset camera
				resetCamera()
				
				-- Clean up
				cleanupTable(tableData)
			end
		end)
	end
	
	-- Click handling
	mouse.Button1Down:Connect(function()
		if currentTable ~= tableData then return end
		if stateManager:getState() ~= ClientStateManager.GameState.IN_GAME then return end
		if not stateManager.gameData.isMyTurn then return end
		
		local target = mouse.Target
		if target and target.Parent == tableData.tablePart and not target.Name:match("Camera") then
			if not stateManager.gameData.selectedCards[target] then
				playSound("CardSelect", target.Position)
				tableData.remoteEvents.CardClick:FireServer(target)
			end
		end
	end)
	
	-- Touch support
	UserInputService.TouchTap:Connect(function(touchPositions, gameProcessedEvent)
		if gameProcessedEvent then return end
		if currentTable ~= tableData then return end
		if stateManager:getState() ~= ClientStateManager.GameState.IN_GAME then return end
		if not stateManager.gameData.isMyTurn then return end
		
		local touchPos = touchPositions[1]
		local camera = workspace.CurrentCamera
		local ray = camera:ScreenPointToRay(touchPos.X, touchPos.Y)
		
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		raycastParams.FilterDescendantsInstances = {player.Character}
		
		local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
		
		if raycastResult then
			local target = raycastResult.Instance
			if target and target.Parent == tableData.tablePart and not target.Name:match("Camera") then
				if not stateManager.gameData.selectedCards[target] then
					playSound("CardSelect", target.Position)
					tableData.remoteEvents.CardClick:FireServer(target)
				end
			end
		end
	end)
end

-- Card animations
local function flipCard(tableData, card)
	local gameData = tableData.stateManager.gameData
	
	if gameData.flippedCards[card] then return end
	
	gameData.flippedCards[card] = true
	gameData.selectedCards[card] = true
	
	local flipTween = TweenService:Create(card,
		TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{CFrame = card.CFrame * CFrame.Angles(math.rad(180), 0, 0)}
	)
	
	flipTween:Play()
	updateHighlights(tableData)
end

local function resetCard(tableData, card)
	local gameData = tableData.stateManager.gameData
	
	gameData.selectedCards[card] = nil
	gameData.flippedCards[card] = nil
	
	if tableData.originalCardCFrames[card] then
		local resetTween = TweenService:Create(card,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{CFrame = tableData.originalCardCFrames[card]}
		)
		resetTween:Play()
	end
	
	updateHighlights(tableData)
end

-- Camera handling
local function transitionCamera(cameraPart)
	local camera = workspace.CurrentCamera
	
	if not originalCamera then
		originalCamera = {
			CFrame = camera.CFrame,
			FieldOfView = camera.FieldOfView,
			CameraType = camera.CameraType
		}
	end
	
	camera.CameraType = Enum.CameraType.Scriptable
	
	local startCFrame = camera.CFrame
	local startFOV = camera.FieldOfView
	local targetCFrame = cameraPart.CFrame
	local targetFOV = 50
	
	local startTime = tick()
	
	if cameraConnection then
		cameraConnection:Disconnect()
	end
	
	cameraConnection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		local alpha = math.min(elapsed / CAMERA_TRANSITION_TIME, 1)
		
		local smoothAlpha = alpha * alpha * (3 - 2 * alpha)
		
		camera.CFrame = startCFrame:Lerp(targetCFrame, smoothAlpha)
		camera.FieldOfView = startFOV + (targetFOV - startFOV) * smoothAlpha
		
		if alpha >= 1 then
			cameraConnection:Disconnect()
			cameraConnection = nil
		end
	end)
end

local function resetCamera()
	if not originalCamera then return end
	
	local camera = workspace.CurrentCamera
	local startCFrame = camera.CFrame
	local startFOV = camera.FieldOfView
	local startTime = tick()
	
	if cameraConnection then
		cameraConnection:Disconnect()
	end
	
	cameraConnection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		local alpha = math.min(elapsed / CAMERA_TRANSITION_TIME, 1)
		
		local smoothAlpha = alpha * alpha * (3 - 2 * alpha)
		
		camera.CFrame = startCFrame:Lerp(originalCamera.CFrame, smoothAlpha)
		camera.FieldOfView = startFOV + (originalCamera.FieldOfView - startFOV) * smoothAlpha
		
		if alpha >= 1 then
			camera.CameraType = originalCamera.CameraType
			cameraConnection:Disconnect()
			cameraConnection = nil
			originalCamera = nil
		end
	end)
end

-- Cleanup function
local function cleanupTable(tableData)
	local stateManager = tableData.stateManager
	
	-- Clean up highlights
	for card, highlight in pairs(stateManager.components.highlights.elements) do
		if highlight and highlight.Parent then
			highlight:Destroy()
		end
	end
	
	-- Disable UI
	local ui = stateManager.components.ui.element
	if ui and ui.screenGui then
		ui.screenGui.Enabled = false
	end
	
	-- Stop animations
	if tableData.waitingConnection then
		tableData.waitingConnection:Disconnect()
		tableData.waitingConnection = nil
	end
	
	-- Clean up state manager
	stateManager:cleanup()
end

-- Diagnostic system
local function runDiagnostics()
	task.spawn(function()
		while true do
			task.wait(5) -- Check every 5 seconds
			
			for tableId, tableData in pairs(allTables) do
				local stateManager = tableData.stateManager
				
				-- Only check active tables
				if stateManager:getState() ~= ClientStateManager.GameState.IDLE then
					local needsRecovery = stateManager:recover()
					
					if needsRecovery then
						print(string.format("[Diagnostics] Recovery performed for table %s", tableId))
					end
				end
			end
		end
	end)
end

-- Initialize all tables
for tableId, config in pairs(TABLE_CONFIGS) do
	local folder = workspace:WaitForChild(config.folderName)
	local tablePart = folder:WaitForChild(config.tableName)
	local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild(config.remoteFolder)
	
	local tableData = {
		id = tableId,
		config = config,
		folder = folder,
		tablePart = tablePart,
		seats = {},
		remoteEvents = {
			CardClick = remoteFolder:WaitForChild("CardClick"),
			GameStateUpdate = remoteFolder:WaitForChild("GameStateUpdate"),
			TurnUpdate = remoteFolder:WaitForChild("TurnUpdate"),
			CardFlip = remoteFolder:WaitForChild("CardFlip")
		},
		originalCardCFrames = {},
		hoveredCard = nil,
		waitingConnection = nil,
		
		-- State manager
		stateManager = ClientStateManager.new(tableId)
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
	
	-- Set up event handlers
	setupEventHandlers(tableData)
	
	allTables[tableId] = tableData
	
	print(string.format("[PokerGame] Initialized table %s with state manager", tableId))
end

-- Start diagnostic system
runDiagnostics()

print("[PokerGame] Client V2 initialized with improved state management")