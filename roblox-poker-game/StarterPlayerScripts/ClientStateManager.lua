-- ClientStateManager.lua
-- Centralized state management for poker game client
-- This module ensures consistent state across all components

local ClientStateManager = {}
ClientStateManager.__index = ClientStateManager

-- State definitions
local GameState = {
	IDLE = "idle",
	WAITING = "waiting",
	COUNTDOWN = "countdown",
	IN_GAME = "in_game",
	ENDING = "ending"
}

-- Create a new state manager for a table
function ClientStateManager.new(tableId)
	local self = setmetatable({}, ClientStateManager)

	self.tableId = tableId
	self.currentState = GameState.IDLE
	self.stateChangeCallbacks = {}
	self.initializationQueue = {}
	self.initialized = false
	self.retryAttempts = {}

	-- Component states
	self.components = {
		ui = { initialized = false, element = nil },
		highlights = { initialized = false, elements = {} },
		cards = { initialized = false, elements = {} },
		camera = { initialized = false }
	}

	-- Game data
	self.gameData = {
		isMyTurn = false,
		currentPlayer = nil,
		selectedCards = {},
		flippedCards = {},
		timeLeft = 0
	}

	return self
end

-- State management
function ClientStateManager:setState(newState)
	if self.currentState == newState then return end

	local oldState = self.currentState
	self.currentState = newState

	print(string.format("[StateManager] Table %s: %s -> %s", self.tableId, oldState, newState))

	-- Notify callbacks
	for _, callback in ipairs(self.stateChangeCallbacks) do
		callback(oldState, newState)
	end
end

function ClientStateManager:getState()
	return self.currentState
end

function ClientStateManager:onStateChange(callback)
	table.insert(self.stateChangeCallbacks, callback)
end

-- Component initialization with retry logic
function ClientStateManager:initializeComponent(componentName, initFunction, maxRetries)
	maxRetries = maxRetries or 3
	local attempts = self.retryAttempts[componentName] or 0

	if self.components[componentName].initialized then
		return true
	end

	local success, result = pcall(initFunction)

	if success and result then
		self.components[componentName].initialized = true
		self.retryAttempts[componentName] = 0
		print(string.format("[StateManager] Table %s: %s initialized successfully", self.tableId, componentName))
		return true
	else
		attempts = attempts + 1
		self.retryAttempts[componentName] = attempts

		if attempts < maxRetries then
			warn(string.format("[StateManager] Table %s: %s initialization failed (attempt %d/%d), retrying...", 
				self.tableId, componentName, attempts, maxRetries))

			-- Schedule retry
			task.wait(0.5 * attempts) -- Exponential backoff
			return self:initializeComponent(componentName, initFunction, maxRetries)
		else
			warn(string.format("[StateManager] Table %s: %s initialization failed after %d attempts", 
				self.tableId, componentName, maxRetries))
			return false
		end
	end
end

-- Queue system for ordered initialization
function ClientStateManager:queueInitialization(priority, name, func)
	table.insert(self.initializationQueue, {
		priority = priority,
		name = name,
		func = func
	})

	-- Sort by priority (lower number = higher priority)
	table.sort(self.initializationQueue, function(a, b)
		return a.priority < b.priority
	end)
end

function ClientStateManager:processInitializationQueue()
	print(string.format("[StateManager] Table %s: Processing initialization queue (%d items)", 
		self.tableId, #self.initializationQueue))

	for i, item in ipairs(self.initializationQueue) do
		print(string.format("[StateManager] Table %s: Initializing %s (priority %d)", 
			self.tableId, item.name, item.priority))

		local success = self:initializeComponent(item.name, item.func)

		if not success then
			warn(string.format("[StateManager] Table %s: Critical component %s failed to initialize", 
				self.tableId, item.name))
		end
	end

	self.initializationQueue = {}
	self.initialized = true
end

-- Validation and recovery
function ClientStateManager:validateState()
	local issues = {}

	-- Check UI
	if self.currentState ~= GameState.IDLE and not self.components.ui.initialized then
		table.insert(issues, "UI not initialized during active state")
	end

	-- Check highlights during game
	if self.currentState == GameState.IN_GAME and not self.components.highlights.initialized then
		table.insert(issues, "Highlights not initialized during game")
	end

	-- Check game data consistency
	if self.currentState == GameState.IN_GAME then
		if not self.gameData.currentPlayer then
			table.insert(issues, "No current player during game")
		end
	end

	return #issues == 0, issues
end

function ClientStateManager:recover()
	print(string.format("[StateManager] Table %s: Attempting recovery", self.tableId))

	local isValid, issues = self:validateState()

	if not isValid then
		print(string.format("[StateManager] Table %s: Found %d issues:", self.tableId, #issues))
		for _, issue in ipairs(issues) do
			print("  - " .. issue)
		end

		-- Reset problematic components
		for componentName, component in pairs(self.components) do
			if not component.initialized then
				component.initialized = false
				self.retryAttempts[componentName] = 0
			end
		end

		-- Re-run initialization for current state
		return true -- Signal that recovery was attempted
	end

	return false -- No recovery needed
end

-- Cleanup
function ClientStateManager:cleanup()
	print(string.format("[StateManager] Table %s: Cleaning up", self.tableId))

	-- Reset all components
	for componentName, component in pairs(self.components) do
		component.initialized = false
		if component.element then
			component.element = nil
		elseif component.elements then
			component.elements = {}
		end
	end

	-- Clear game data
	self.gameData = {
		isMyTurn = false,
		currentPlayer = nil,
		selectedCards = {},
		flippedCards = {},
		timeLeft = 0
	}

	-- Reset state
	self.currentState = GameState.IDLE
	self.initialized = false
	self.retryAttempts = {}
end

ClientStateManager.GameState = GameState

return ClientStateManager