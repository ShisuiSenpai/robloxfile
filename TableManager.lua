-- TableManager.lua
-- ModuleScript to manage multiple poker tables
-- Place this in ServerScriptService

local TableManager = {}
TableManager.__index = TableManager

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Table configurations
local TABLE_CONFIGS = {
	Table1 = {
		folderName = "Table1Folder",
		tableName = "Table1",
		chair1Name = "Player1Chair",
		chair2Name = "Player2Chair",
		cameraPartName = "CameraPartTable1",
		remoteFolder = "Table1"
	},
	Table2 = {
		folderName = "Table2Folder",
		tableName = "Table2",
		chair1Name = "Player1Chair",
		chair2Name = "Player2Chair",
		cameraPartName = "CameraPartTable2",
		remoteFolder = "Table2"
	},
	Table3 = {
		folderName = "Table3Folder",
		tableName = "Table3",
		chair1Name = "Player1Chair",
		chair2Name = "Player2Chair",
		cameraPartName = "CameraPartTable3",
		remoteFolder = "Table3"
	},
	Table4 = {
		folderName = "Table4Folder",
		tableName = "Table4",
		chair1Name = "Player1Chair",
		chair2Name = "Player2Chair",
		cameraPartName = "CameraPartTable4",
		remoteFolder = "Table4"
	},
	Table5 = {
		folderName = "Table5Folder",
		tableName = "Table5",
		chair1Name = "Player1Chair",
		chair2Name = "Player2Chair",
		cameraPartName = "CameraPartTable5",
		remoteFolder = "Table5"
	},
	Table6 = {
		folderName = "Table6Folder",
		tableName = "Table6",
		chair1Name = "Player1Chair",
		chair2Name = "Player2Chair",
		cameraPartName = "CameraPartTable6",
		remoteFolder = "Table6"
	},
	Table7 = {
		folderName = "Table7Folder",
		tableName = "Table7",
		chair1Name = "Player1Chair",
		chair2Name = "Player2Chair",
		cameraPartName = "CameraPartTable7",
		remoteFolder = "Table7"
	},
	Table8 = {
		folderName = "Table8Folder",
		tableName = "Table8",
		chair1Name = "Player1Chair",
		chair2Name = "Player2Chair",
		cameraPartName = "CameraPartTable8",
		remoteFolder = "Table8"
	},
	Table9 = {
		folderName = "Table9Folder",
		tableName = "Table9",
		chair1Name = "Player1Chair",
		chair2Name = "Player2Chair",
		cameraPartName = "CameraPartTable9",
		remoteFolder = "Table9"
	},
	Table10 = {
		folderName = "Table10Folder",
		tableName = "Table10",
		chair1Name = "Player1Chair",
		chair2Name = "Player2Chair",
		cameraPartName = "CameraPartTable10",
		remoteFolder = "Table10"
	}
}

-- Table states
TableManager.TableState = {
	EMPTY = "EMPTY",                    -- No players seated
	WAITING_FOR_PLAYER = "WAITING",     -- One player seated, waiting for opponent
	COUNTDOWN = "COUNTDOWN",            -- Both players seated, countdown in progress
	IN_GAME = "IN_GAME",               -- Game is active
	ENDING = "ENDING"                   -- Game is ending
}

-- Store active table instances
local activeTables = {}

-- Create a new table instance
function TableManager.new(tableId)
	local self = setmetatable({}, TableManager)
	
	self.tableId = tableId
	self.config = TABLE_CONFIGS[tableId]
	if not self.config then
		warn("[TableManager] Invalid table ID:", tableId)
		return nil
	end
	
	-- Get table components
	local tableFolder = Workspace:FindFirstChild(self.config.folderName)
	if not tableFolder then
		warn("[TableManager] Table folder not found:", self.config.folderName)
		return nil
	end
	
	self.tableFolder = tableFolder
	self.tablePart = tableFolder:FindFirstChild(self.config.tableName)
	self.chair1 = tableFolder:FindFirstChild(self.config.chair1Name)
	self.chair2 = tableFolder:FindFirstChild(self.config.chair2Name)
	self.cameraPart = tableFolder:FindFirstChild(self.config.cameraPartName)
	
	-- Validate components
	if not self.tablePart or not self.chair1 or not self.chair2 then
		warn("[TableManager] Missing table components for:", tableId)
		return nil
	end
	
	-- Get seats from chair models
	self.seat1 = self.chair1:FindFirstChild("Seat")
	self.seat2 = self.chair2:FindFirstChild("Seat")
	
	if not self.seat1 or not self.seat2 then
		warn("[TableManager] Missing seats in chairs for:", tableId)
		return nil
	end
	
	-- Get remote events
	local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
	local tableRemoteFolder = remoteEventsFolder:FindFirstChild(self.config.remoteFolder)
	
	if not tableRemoteFolder then
		warn("[TableManager] Remote folder not found:", self.config.remoteFolder)
		return nil
	end
	
	self.remoteEvents = {
		CardClick = tableRemoteFolder:FindFirstChild("CardClick"),
		GameStateUpdate = tableRemoteFolder:FindFirstChild("GameStateUpdate"),
		TurnUpdate = tableRemoteFolder:FindFirstChild("TurnUpdate"),
		CardFlip = tableRemoteFolder:FindFirstChild("CardFlip")
	}
	
	-- Validate remote events
	for name, event in pairs(self.remoteEvents) do
		if not event then
			warn("[TableManager] Missing remote event:", name, "for table:", tableId)
			return nil
		end
	end
	
	-- Initialize game state
	self.gameState = {
		isActive = false,
		player1 = nil,
		player2 = nil,
		currentTurn = nil,
		turnNumber = 0,
		selectedCards = {},
		pokerCard = nil,
		tableState = TableManager.TableState.EMPTY,
		lastStateChange = tick()
	}
	
	-- Card management
	self.cards = {}
	self.originalCardCFrames = {}
	self.currentCardCFrames = {}
	self.originalJumpPowers = {}
	
	print("[TableManager] Initialized table:", tableId)
	return self
end

-- Initialize cards for this table
function TableManager:initializeCards()
	self.cards = {}
	for _, child in ipairs(self.tablePart:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(self.cards, child)
			-- Store the TRUE original position (only set once at server start)
			self.originalCardCFrames[child] = child.CFrame
			self.currentCardCFrames[child] = child.CFrame
			
			if child.Name == "Poker" then
				self.gameState.pokerCard = child
				print("[TableManager] Found poker card for table:", self.tableId)
			end
		end
	end
	print("[TableManager] Initialized", #self.cards, "cards for table:", self.tableId)
end

-- Check if both seats are occupied
function TableManager:checkSeating()
	local player1Humanoid = self.seat1.Occupant
	local player2Humanoid = self.seat2.Occupant
	
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
	self.gameState.player1 = newPlayer1
	self.gameState.player2 = newPlayer2
	
	-- Update table state based on seating
	local bothSeated = newPlayer1 ~= nil and newPlayer2 ~= nil
	local oneSeated = (newPlayer1 ~= nil and newPlayer2 == nil) or (newPlayer1 == nil and newPlayer2 ~= nil)
	local noneSeated = newPlayer1 == nil and newPlayer2 == nil
	
	if noneSeated then
		self:updateTableState(TableManager.TableState.EMPTY)
	elseif oneSeated and self.gameState.tableState ~= TableManager.TableState.IN_GAME and 
	       self.gameState.tableState ~= TableManager.TableState.COUNTDOWN and
	       self.gameState.tableState ~= TableManager.TableState.ENDING then
		self:updateTableState(TableManager.TableState.WAITING_FOR_PLAYER)
	end
	
	return bothSeated
end

-- Update table state
function TableManager:updateTableState(newState)
	if self.gameState.tableState ~= newState then
		self.gameState.tableState = newState
		self.gameState.lastStateChange = tick()
		
		-- Notify clients of state change
		if self.remoteEvents.GameStateUpdate then
			self.remoteEvents.GameStateUpdate:FireAllClients("table_state_changed", {
				tableId = self.tableId,
				state = newState
			})
		end
	end
end

-- Get current table state
function TableManager:getTableState()
	return self.gameState.tableState
end

-- Check if table is available for quick match
function TableManager:isAvailableForQuickMatch()
	local state = self.gameState.tableState
	return state == TableManager.TableState.EMPTY or state == TableManager.TableState.WAITING_FOR_PLAYER
end

-- Get available seat
function TableManager:getAvailableSeat()
	if not self.seat1.Occupant then
		return self.seat1
	elseif not self.seat2.Occupant then
		return self.seat2
	end
	return nil
end

-- Get which table a player is seated at
function TableManager.getPlayerTable(player)
	if not player.Character then return nil end
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid or not humanoid.SeatPart then return nil end
	
	-- Check each active table
	for tableId, tableInstance in pairs(activeTables) do
		if humanoid.SeatPart == tableInstance.seat1 or humanoid.SeatPart == tableInstance.seat2 then
			return tableInstance
		end
	end
	
	return nil
end

-- Initialize all tables
function TableManager.initializeAllTables()
	for tableId, config in pairs(TABLE_CONFIGS) do
		local tableInstance = TableManager.new(tableId)
		if tableInstance then
			activeTables[tableId] = tableInstance
			-- Initialize cards after a delay to ensure CardOrientationFixer has run
			task.wait(0.5)
			tableInstance:initializeCards()
		end
	end
	print("[TableManager] All tables initialized")
end

-- Get a specific table instance
function TableManager.getTable(tableId)
	return activeTables[tableId]
end

-- Get all active tables
function TableManager.getAllTables()
	return activeTables
end

-- Get best table for quick match
function TableManager.getBestTableForQuickMatch()
	-- First priority: Find a table with one player waiting
	for tableId, tableInstance in pairs(activeTables) do
		if tableInstance:getTableState() == TableManager.TableState.WAITING_FOR_PLAYER then
			local availableSeat = tableInstance:getAvailableSeat()
			if availableSeat then
				return tableInstance, availableSeat
			end
		end
	end
	
	-- Second priority: Find an empty table
	for tableId, tableInstance in pairs(activeTables) do
		if tableInstance:getTableState() == TableManager.TableState.EMPTY then
			local availableSeat = tableInstance:getAvailableSeat()
			if availableSeat then
				return tableInstance, availableSeat
			end
		end
	end
	
	-- No available tables
	return nil, nil
end

-- Expose table configurations
TableManager.TABLE_CONFIGS = TABLE_CONFIGS

return TableManager