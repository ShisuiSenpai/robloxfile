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
	},
	Table3 = {
		folderName = "Table3Folder",
		remoteFolder = "Table3",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table4 = {
		folderName = "Table4Folder",
		remoteFolder = "Table4",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table5 = {
		folderName = "Table5Folder",
		remoteFolder = "Table5",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table6 = {
		folderName = "Table6Folder",
		remoteFolder = "Table6",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table7 = {
		folderName = "Table7Folder",
		remoteFolder = "Table7",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table8 = {
		folderName = "Table8Folder",
		remoteFolder = "Table8",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table9 = {
		folderName = "Table9Folder",
		remoteFolder = "Table9",
		seats = {"Player1Chair", "Player2Chair"}
	},
	Table10 = {
		folderName = "Table10Folder",
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
	print("[GameStart] SoundManager loaded")
end)

if not success then
	warn("[GameStart] SoundManager not found - sounds disabled")
end

-- Get table components
local tables = {}
local allSeats = {}
local seatToTable = {}

print("[DEBUG GameStart] Initializing tables from TABLE_CONFIGS...")
-- Wait longer for all assets to load (seats might stream in late)
wait(3)

for tableId, config in pairs(TABLE_CONFIGS) do
	-- print("[DEBUG GameStart] Setting up table:", tableId)
	
	local folder = workspace:WaitForChild(config.folderName)
	local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild(config.remoteFolder)
	
	-- print("[DEBUG GameStart] Found folder:", folder.Name, "and remote folder:", remoteFolder.Name)
	
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
			-- print("[DEBUG GameStart] Found chair:", seatName, "Type:", chair.ClassName)
			
			-- Wait for chair contents to load if it's a model
			if chair:IsA("Model") then
				-- Wait for at least one child
				local attempts = 0
				while #chair:GetChildren() == 0 and attempts < 10 do
					wait(0.1)
					attempts = attempts + 1
				end
				
				if attempts >= 10 then
					print("[DEBUG GameStart] WARNING: Chair model has no children after waiting")
				end
			end
			
			-- Try different ways to find the seat
			local seat = chair:FindFirstChild("Seat") or chair:FindFirstChildWhichIsA("Seat") or chair:FindFirstChildWhichIsA("VehicleSeat")
			
			-- If chair is a model, look deeper
			if not seat and chair:IsA("Model") then
				for _, child in ipairs(chair:GetDescendants()) do
					if child:IsA("Seat") or child:IsA("VehicleSeat") or (child:IsA("Part") and child.Name == "Seat") then
						seat = child
						-- print("[DEBUG GameStart] Found seat in descendants:", child:GetFullName())
						break
					end
				end
			end
			
			if seat then
				table.insert(tableData.seats, seat)
				table.insert(allSeats, seat)
				seatToTable[seat] = tableData
				-- print("[DEBUG GameStart] Added seat:", seatName, "to table:", tableId, "Seat:", seat:GetFullName())
			else
				warn("[DEBUG GameStart] WARNING: No Seat part in chair:", seatName, "for table:", tableId)
			end
		else
			print("[DEBUG GameStart] WARNING: Chair not found:", seatName)
		end
	end
	
	tables[tableId] = tableData
	-- print("[DEBUG GameStart] Table", tableId, "initialized with", #tableData.seats, "seats")
end

-- Count successfully initialized tables
local tablesWithSeats = 0
for _, tableData in pairs(tables) do
	if #tableData.seats > 0 then
		tablesWithSeats = tablesWithSeats + 1
	end
end

print("[DEBUG GameStart] Total tables found:", #tables, "Tables with seats:", tablesWithSeats)

-- If no tables have seats, try again after a longer wait
if tablesWithSeats == 0 then
	warn("[GameStart] No seats found in any table! Retrying in 2 seconds...")
	wait(2)
	
	-- Retry seat detection for all tables
	for tableId, tableData in pairs(tables) do
		local config = TABLE_CONFIGS[tableId]
		local folder = workspace:FindFirstChild(config.folderName)
		
		if folder then
			-- Clear existing seats
			tableData.seats = {}
			
			-- Try to find seats again
			for _, seatName in ipairs(config.seats) do
				local chair = folder:FindFirstChild(seatName)
				if chair then
					-- Wait for chair to load if needed
					if chair:IsA("Model") and #chair:GetChildren() == 0 then
						chair:WaitForChild("Seat", 2)
					end
					
					local seat = chair:FindFirstChild("Seat") or chair:FindFirstChildWhichIsA("Seat") or chair:FindFirstChildWhichIsA("VehicleSeat")
					
					if not seat and chair:IsA("Model") then
						for _, child in ipairs(chair:GetDescendants()) do
							if child:IsA("Seat") or child:IsA("VehicleSeat") then
								seat = child
								break
							end
						end
					end
					
					if seat then
						table.insert(tableData.seats, seat)
						seatToTable[seat] = tableData
						print("[GameStart] Found seat on retry:", seatName, "for table:", tableId)
					end
				end
			end
		end
	end
end

-- Final count
local finalTablesWithSeats = 0
for _, tableData in pairs(tables) do
	if #tableData.seats > 0 then
		finalTablesWithSeats = finalTablesWithSeats + 1
	end
end

if finalTablesWithSeats > 0 then
	print("[GameStart] Successfully initialized", finalTablesWithSeats, "tables with seats")
else
	warn("[GameStart] CRITICAL: No tables have seats! Countdown UI will not work!")
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
	print("[DEBUG GameStart] startGameCountdown called for table:", tableData.id)
	
	if tableData.isGameStarting then 
		print("[DEBUG GameStart] Already starting for table:", tableData.id)
		return 
	end
	
	tableData.isGameStarting = true
	print("[DEBUG GameStart] Starting countdown for table", tableData.id)
	
	-- Create UI
	local gui, countdownLabel = createCountdownUI(tableData)
	if not gui then
		print("[DEBUG GameStart] ERROR: Failed to create countdown UI")
		return
	end
	
	local containerFrame = gui:FindFirstChild("ContainerFrame")
	if not containerFrame then
		print("[DEBUG GameStart] ERROR: No ContainerFrame found")
		return
	end
	
	-- Start with everything transparent for fade-in
	containerFrame.BackgroundTransparency = 1
	for _, child in ipairs(containerFrame:GetDescendants()) do
		if child:IsA("TextLabel") then
			child.TextTransparency = 1
		elseif child:IsA("UIStroke") then
			child.Transparency = 1
		end
	end
	
	-- Fade in animation
	local fadeInTween = TweenService:Create(containerFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 1} -- Keep background transparent
	)
	
	for _, child in ipairs(containerFrame:GetDescendants()) do
		if child:IsA("TextLabel") then
			TweenService:Create(child,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{TextTransparency = 0}
			):Play()
		elseif child:IsA("UIStroke") then
			TweenService:Create(child,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = 0}
			):Play()
		end
	end
	
	fadeInTween:Play()
	
	tableData.currentCountdown = 3 + 0.1 -- Buffer
	local lastDisplayedNumber = 4
	
	-- Show initial number
	countdownLabel.Text = "3"
	
	-- Play first tick after fade in
	fadeInTween.Completed:Connect(function()
		if soundsEnabled and SoundManager then
			SoundManager:PlayCountdownTick()
		end
	end)
	
	-- Countdown logic
	print("[DEBUG GameStart] Starting countdown timer for table:", tableData.id)
	
	tableData.countdownConnection = RunService.Heartbeat:Connect(function(dt)
		tableData.currentCountdown = tableData.currentCountdown - dt
		
		local displayTime = math.ceil(math.max(0, tableData.currentCountdown))
		
		if tableData.currentCountdown > 0 then
			if displayTime ~= lastDisplayedNumber and displayTime >= 0 then
				lastDisplayedNumber = displayTime
				countdownLabel.Text = tostring(displayTime)
				print("[DEBUG GameStart] Countdown update - Table:", tableData.id, "Number:", displayTime)
				
				-- Animate number change with a subtle pop effect
				local popTween = TweenService:Create(countdownLabel,
					TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{TextTransparency = 0.1}
				)
				popTween:Play()
				
				popTween.Completed:Connect(function()
					TweenService:Create(countdownLabel,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{TextTransparency = 0}
					):Play()
				end)
				
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
				countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green for GO!
				
				-- Hide title
				local titleLabel = gui:FindFirstChild("ContainerFrame"):FindFirstChild("TitleLabel")
				if titleLabel then
					titleLabel.Visible = false
				end
				
				-- Make GO! fill the container
				countdownLabel.Size = UDim2.new(1, 0, 1, 0)
				countdownLabel.Position = UDim2.new(0, 0, 0, 0)
				
				-- Animate GO! growing and fading
				local growTween = TweenService:Create(countdownLabel,
					TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{TextTransparency = 0.2}
				)
				growTween:Play()
			end
		else
			-- Fade out and clean up
			if not tableData.fadingOut then
				tableData.fadingOut = true
				
				local containerFrame = gui:FindFirstChild("ContainerFrame")
				if containerFrame then
					local fadeTween = TweenService:Create(containerFrame,
						TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{BackgroundTransparency = 1}
					)
					
					-- Fade all text elements
					for _, child in ipairs(containerFrame:GetDescendants()) do
						if child:IsA("TextLabel") then
							TweenService:Create(child,
								TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
								{TextTransparency = 1}
							):Play()
						elseif child:IsA("UIStroke") then
							TweenService:Create(child,
								TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
								{Transparency = 1}
							):Play()
						end
					end
					
					fadeTween:Play()
					fadeTween.Completed:Connect(function()
						tableData.countdownConnection:Disconnect()
						destroyCountdownUI(tableData)
						tableData.isGameStarting = false
						tableData.fadingOut = false
						tableData.currentCountdown = 3
						print("[GameStart] Countdown complete for table", tableData.id)
					end)
				end
			end
		end
	end)
end

-- Connect to game state events for each table
for tableId, tableData in pairs(tables) do
	print("[DEBUG GameStart] Setting up events for table:", tableId)
	
	tableData.remoteEvents.GameStateUpdate.OnClientEvent:Connect(function(state, data)
		print("[DEBUG GameStart] GameStateUpdate received - Table:", tableId, "State:", state)
		
		if state == "countdown_start" then
			-- Only start countdown if player is at this table
			local currentTable = getCurrentTable()
			print("[DEBUG GameStart] Current player table:", currentTable and currentTable.id or "none")
			
			if currentTable == tableData then
				print("[DEBUG GameStart] Starting countdown for table:", tableId)
				startGameCountdown(tableData)
			else
				print("[DEBUG GameStart] Player not at this table, skipping countdown")
			end
		elseif state == "game_end" then
			-- Clean up if game ends during countdown
			if tableData.isGameStarting then
				print("[DEBUG GameStart] Cleaning up countdown for table:", tableId)
				destroyCountdownUI(tableData)
				tableData.isGameStarting = false
			end
		end
	end)
end

-- Count tables properly
local tableCount = 0
for _ in pairs(tables) do
	tableCount = tableCount + 1
end
print("[DEBUG GameStart] Multi-table countdown script loaded - Tables:", tableCount)