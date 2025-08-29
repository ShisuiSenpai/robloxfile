-- GameStartScriptMulti.lua
-- Client-side countdown UI for multiple tables
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Table configurations
local TABLE_CONFIGS = {
	Table1 = {
		folderName = "Table1Folder",
		remoteFolder = "Table1",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table2 = {
		folderName = "Table2Folder",
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
	print("[GameStart] SoundManager loaded")
end)

if not success then
	warn("[GameStart] SoundManager not found - sounds disabled")
end

-- Get table components
local tables = {}
local allSeats = {}
local seatToTable = {}

for tableId, config in pairs(TABLE_CONFIGS) do
	local folder = workspace:WaitForChild(config.folderName)
	local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild(config.remoteFolder)
	
	local tableData = {
		id = tableId,
		folder = folder,
		seats = {},
		remoteEvents = {
			GameStateUpdate = remoteFolder:WaitForChild("GameStateUpdate")
		},
		isGameStarting = false,
		currentCountdown = 3,
		countdownGui = nil,
		countdownConnection = nil
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
	
	tables[tableId] = tableData
end

-- Get current table
local function getCurrentTable()
	if not player.Character then return nil end
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid or not humanoid.SeatPart then return nil end
	
	return seatToTable[humanoid.SeatPart]
end

-- Create countdown UI
local function createCountdownUI(tableData)
	if tableData.countdownGui then
		tableData.countdownGui:Destroy()
	end
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameStartCountdown_" .. tableData.id
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")
	
	local containerFrame = Instance.new("Frame")
	containerFrame.Name = "ContainerFrame"
	containerFrame.Size = UDim2.new(0, 400, 0, 200)
	containerFrame.Position = UDim2.new(0.5, -200, 0, 50)
	containerFrame.BackgroundTransparency = 1
	containerFrame.Parent = screenGui
	
	-- Title label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Game Starting"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Parent = containerFrame
	
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.new(0, 0, 0)
	titleStroke.Thickness = 3
	titleStroke.Parent = titleLabel
	
	-- Countdown label
	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "CountdownLabel"
	countdownLabel.Size = UDim2.new(1, 0, 0.7, 0)
	countdownLabel.Position = UDim2.new(0, 0, 0.3, 0)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Text = "3"
	countdownLabel.TextColor3 = Color3.new(1, 1, 1)
	countdownLabel.TextScaled = true
	countdownLabel.Font = Enum.Font.SourceSansBold
	countdownLabel.Parent = containerFrame
	
	local countdownStroke = Instance.new("UIStroke")
	countdownStroke.Color = Color3.new(0, 0, 0)
	countdownStroke.Thickness = 4
	countdownStroke.Parent = countdownLabel
	
	tableData.countdownGui = screenGui
	return screenGui, countdownLabel
end

-- Destroy countdown UI
local function destroyCountdownUI(tableData)
	if tableData.countdownGui then
		tableData.countdownGui:Destroy()
		tableData.countdownGui = nil
	end
	
	if tableData.countdownConnection then
		tableData.countdownConnection:Disconnect()
		tableData.countdownConnection = nil
	end
end

-- Start countdown
local function startGameCountdown(tableData)
	if tableData.isGameStarting then return end
	
	tableData.isGameStarting = true
	print("[GameStart] Starting countdown for table", tableData.id)
	
	-- Create UI
	local gui, countdownLabel = createCountdownUI(tableData)
	
	tableData.currentCountdown = 3 + 0.1 -- Buffer
	local lastDisplayedNumber = 4
	
	-- Show initial number
	countdownLabel.Text = "3"
	
	-- Play first tick
	if soundsEnabled and SoundManager then
		SoundManager:PlayCountdownTick()
	end
	
	-- Countdown logic
	tableData.countdownConnection = RunService.Heartbeat:Connect(function(dt)
		tableData.currentCountdown = tableData.currentCountdown - dt
		
		local displayTime = math.ceil(math.max(0, tableData.currentCountdown))
		
		if tableData.currentCountdown > 0 then
			if displayTime ~= lastDisplayedNumber and displayTime >= 0 then
				lastDisplayedNumber = displayTime
				countdownLabel.Text = tostring(displayTime)
				
				if soundsEnabled and SoundManager and displayTime > 0 then
					SoundManager:PlayCountdownTick()
				end
			end
		elseif tableData.currentCountdown > -0.5 then
			if countdownLabel.Text ~= "GO!" then
				if soundsEnabled and SoundManager then
					SoundManager:PlayGameStartSound()
				end
				
				countdownLabel.Text = "GO!"
				local titleLabel = gui:FindFirstChild("ContainerFrame"):FindFirstChild("TitleLabel")
				if titleLabel then
					titleLabel.Visible = false
				end
				countdownLabel.Size = UDim2.new(1, 0, 1, 0)
				countdownLabel.Position = UDim2.new(0, 0, 0, 0)
			end
		else
			tableData.countdownConnection:Disconnect()
			destroyCountdownUI(tableData)
			tableData.isGameStarting = false
			tableData.currentCountdown = 3
			print("[GameStart] Countdown complete for table", tableData.id)
		end
	end)
end

-- Connect to game state events for each table
for tableId, tableData in pairs(tables) do
	tableData.remoteEvents.GameStateUpdate.OnClientEvent:Connect(function(state, data)
		if state == "countdown_start" then
			-- Only start countdown if player is at this table
			if getCurrentTable() == tableData then
				startGameCountdown(tableData)
			end
		elseif state == "game_end" then
			-- Clean up if game ends during countdown
			if tableData.isGameStarting then
				destroyCountdownUI(tableData)
				tableData.isGameStarting = false
			end
		end
	end)
end

print("[GameStart] Multi-table countdown script loaded")