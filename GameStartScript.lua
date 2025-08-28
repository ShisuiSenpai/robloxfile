-- Game Start Script with Countdown and Card Shuffling
-- This script handles the game initialization when a player sits at the table

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local COUNTDOWN_TIME = 3 -- Seconds before game starts
local SHUFFLE_HEIGHT = 5 -- How high cards rise during shuffle
local SHUFFLE_SPREAD = 10 -- How far cards spread during shuffle
local CARD_MOVE_TIME = 0.3 -- Time for individual card movements
local SHUFFLE_ROTATIONS = 3 -- Number of times to shuffle

-- References
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for table components
local table1Folder = workspace:WaitForChild("Table1Folder")
local table1 = table1Folder:WaitForChild("Table1")
local player1Chair = table1Folder:WaitForChild("Player1Chair"):WaitForChild("Seat")
local player2Chair = table1Folder:WaitForChild("Player2Chair"):WaitForChild("Seat")

-- UI Storage
local countdownGui = nil
local isGameStarting = false
local currentCountdown = nil

-- Card management
local cards = {}
local originalPositions = {}
local shuffleTweens = {}

-- Create countdown UI
local function createCountdownUI()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameCountdownGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Create container frame (invisible, just for positioning)
	local containerFrame = Instance.new("Frame")
	containerFrame.Name = "ContainerFrame"
	containerFrame.Size = UDim2.new(0, 300, 0, 150)
	containerFrame.Position = UDim2.new(0.5, -150, 0, 50) -- Top center
	containerFrame.BackgroundTransparency = 1
	containerFrame.Parent = screenGui
	
	-- Create title label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 50)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Game Starting"
	titleLabel.TextColor3 = Color3.new(1, 1, 1) -- White
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Parent = containerFrame
	
	-- Add text stroke to title
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.new(0, 0, 0) -- Black stroke
	titleStroke.Thickness = 3
	titleStroke.Parent = titleLabel
	
	-- Create countdown label
	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "CountdownLabel"
	countdownLabel.Size = UDim2.new(1, 0, 0, 80)
	countdownLabel.Position = UDim2.new(0, 0, 0, 60)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Text = "3"
	countdownLabel.TextColor3 = Color3.new(1, 1, 1) -- White
	countdownLabel.TextScaled = true
	countdownLabel.Font = Enum.Font.SourceSansBold
	countdownLabel.Parent = containerFrame
	
	-- Add text stroke for better visibility
	local countdownStroke = Instance.new("UIStroke")
	countdownStroke.Color = Color3.new(0, 0, 0) -- Black stroke
	countdownStroke.Thickness = 4
	countdownStroke.Parent = countdownLabel
	
	-- Initial animation (fade in from top)
	containerFrame.Position = UDim2.new(0.5, -150, 0, -50)
	titleLabel.TextTransparency = 1
	countdownLabel.TextTransparency = 1
	titleStroke.Transparency = 1
	countdownStroke.Transparency = 1
	
	-- Animate in
	local positionTween = TweenService:Create(containerFrame, 
		TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -150, 0, 50)}
	)
	
	local fadeInTween1 = TweenService:Create(titleLabel,
		TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)
	
	local fadeInTween2 = TweenService:Create(countdownLabel,
		TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)
	
	local fadeInTween3 = TweenService:Create(titleStroke,
		TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{Transparency = 0}
	)
	
	local fadeInTween4 = TweenService:Create(countdownStroke,
		TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{Transparency = 0}
	)
	
	positionTween:Play()
	fadeInTween1:Play()
	fadeInTween2:Play()
	fadeInTween3:Play()
	fadeInTween4:Play()
	
	return screenGui, countdownLabel, containerFrame
end

-- Destroy countdown UI with animation
local function destroyCountdownUI()
	if countdownGui then
		local containerFrame = countdownGui:FindFirstChild("ContainerFrame")
		if containerFrame then
			local titleLabel = containerFrame:FindFirstChild("TitleLabel")
			local countdownLabel = containerFrame:FindFirstChild("CountdownLabel")
			local titleStroke = titleLabel and titleLabel:FindFirstChildOfClass("UIStroke")
			local countdownStroke = countdownLabel and countdownLabel:FindFirstChildOfClass("UIStroke")
			
			-- Fade out animations
			local fadeOutTween1 = TweenService:Create(containerFrame,
				TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, -150, 0, -50)}
			)
			
			if titleLabel then
				local fadeOutTween2 = TweenService:Create(titleLabel,
					TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
					{TextTransparency = 1}
				)
				fadeOutTween2:Play()
			end
			
			if countdownLabel then
				local fadeOutTween3 = TweenService:Create(countdownLabel,
					TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
					{TextTransparency = 1}
				)
				fadeOutTween3:Play()
			end
			
			if titleStroke then
				local fadeOutTween4 = TweenService:Create(titleStroke,
					TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
					{Transparency = 1}
				)
				fadeOutTween4:Play()
			end
			
			if countdownStroke then
				local fadeOutTween5 = TweenService:Create(countdownStroke,
					TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
					{Transparency = 1}
				)
				fadeOutTween5:Play()
			end
			
			fadeOutTween1:Play()
			fadeOutTween1.Completed:Connect(function()
				countdownGui:Destroy()
				countdownGui = nil
			end)
		else
			countdownGui:Destroy()
			countdownGui = nil
		end
	end
end

-- Get all cards from the table
local function getCards()
	cards = {}
	originalPositions = {}
	
	for _, child in ipairs(table1:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(cards, child)
			originalPositions[child] = child.CFrame
		end
	end
	
	print("[GameStart] Found", #cards, "cards on the table")
	return cards
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

-- Animate card shuffle
local function animateCardShuffle(onComplete)
	local allCards = getCards()
	if #allCards == 0 then
		print("[GameStart] No cards found to shuffle")
		if onComplete then onComplete() end
		return
	end
	
	-- Cancel any existing shuffle tweens
	for _, tween in pairs(shuffleTweens) do
		tween:Cancel()
	end
	shuffleTweens = {}
	
	-- Calculate center of table
	local centerPosition = table1.Position
	
	-- Phase 1: Lift all cards and move to center
	for i, card in ipairs(allCards) do
		local raisedCFrame = CFrame.new(centerPosition + Vector3.new(0, SHUFFLE_HEIGHT + (i * 0.1), 0))
		local tween = TweenService:Create(card,
			TweenInfo.new(CARD_MOVE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{CFrame = raisedCFrame}
		)
		table.insert(shuffleTweens, tween)
		tween:Play()
	end
	
	wait(CARD_MOVE_TIME)
	
	-- Phase 2: Shuffle animation (cards spinning and moving)
	for rotation = 1, SHUFFLE_ROTATIONS do
		for i, card in ipairs(allCards) do
			local angle = (i / #allCards) * math.pi * 2
			local radius = SHUFFLE_SPREAD * (rotation / SHUFFLE_ROTATIONS)
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			
			local shuffleCFrame = CFrame.new(
				centerPosition + Vector3.new(x, SHUFFLE_HEIGHT, z)
			) * CFrame.Angles(0, angle, 0)
			
			local tween = TweenService:Create(card,
				TweenInfo.new(0.2, Enum.EasingStyle.Linear),
				{CFrame = shuffleCFrame}
			)
			table.insert(shuffleTweens, tween)
			tween:Play()
		end
		wait(0.2)
	end
	
	-- Phase 3: Return cards to positions (shuffled)
	local positions = {}
	for card, pos in pairs(originalPositions) do
		table.insert(positions, pos)
	end
	
	local shuffledPositions = shuffleArray(positions)
	
	for i, card in ipairs(allCards) do
		local targetCFrame = shuffledPositions[i]
		local tween = TweenService:Create(card,
			TweenInfo.new(CARD_MOVE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{CFrame = targetCFrame}
		)
		table.insert(shuffleTweens, tween)
		tween:Play()
	end
	
	wait(CARD_MOVE_TIME)
	
	-- Clear tweens
	shuffleTweens = {}
	
	print("[GameStart] Shuffle animation complete")
	if onComplete then onComplete() end
end

-- Start game countdown
local function startGameCountdown()
	if isGameStarting then return end
	isGameStarting = true
	
	print("[GameStart] Starting game countdown")
	
	-- Create countdown UI
	local gui, countdownLabel = createCountdownUI()
	countdownGui = gui
	
	-- Start shuffle animation
	coroutine.wrap(function()
		animateCardShuffle(function()
			print("[GameStart] Cards shuffled!")
		end)
	end)()
	
	-- Countdown logic
	currentCountdown = COUNTDOWN_TIME
	local lastDisplayedNumber = COUNTDOWN_TIME
	
	local countdownConnection
	countdownConnection = RunService.Heartbeat:Connect(function(dt)
		currentCountdown = currentCountdown - dt
		
		local displayTime = math.ceil(math.max(0, currentCountdown)) -- Clamp to 0 minimum
		
		if currentCountdown > 0 then
			countdownLabel.Text = tostring(displayTime)
			
			-- Pulse effect on countdown change
			if displayTime ~= lastDisplayedNumber and displayTime >= 0 then
				lastDisplayedNumber = displayTime
				
				-- Scale pulse effect
				local pulseTween = TweenService:Create(countdownLabel,
					TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{TextScaled = false, Size = UDim2.new(1.2, 0, 0, 96)} -- Slightly larger
				)
				pulseTween:Play()
				pulseTween.Completed:Connect(function()
					local returnTween = TweenService:Create(countdownLabel,
						TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
						{TextScaled = true, Size = UDim2.new(1, 0, 0, 80)} -- Back to normal
					)
					returnTween:Play()
				end)
			end
		elseif currentCountdown > -0.5 then
			-- Show "GO!" for a brief moment
			if countdownLabel.Text ~= "GO!" then
				countdownLabel.Text = "GO!"
				-- Big pulse for GO!
				local goPulseTween = TweenService:Create(countdownLabel,
					TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{TextScaled = false, Size = UDim2.new(1.5, 0, 0, 120)}
				)
				goPulseTween:Play()
			end
		else
			-- Countdown finished
			countdownConnection:Disconnect()
			destroyCountdownUI()
			isGameStarting = false
			print("[GameStart] Game started!")
		end
	end)
end

-- Monitor seating
local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	
	humanoid.Seated:Connect(function(isSeated, seatPart)
		if isSeated and (seatPart == player1Chair or seatPart == player2Chair) then
			-- Player sat at the table
			startGameCountdown()
		else
			-- Player left the seat
			if isGameStarting then
				-- Cancel countdown
				isGameStarting = false
				destroyCountdownUI()
				
				-- Stop any ongoing shuffle
				for _, tween in pairs(shuffleTweens) do
					tween:Cancel()
				end
				shuffleTweens = {}
				
				-- Return cards to original positions
				for card, originalCFrame in pairs(originalPositions) do
					if card.Parent then
						card.CFrame = originalCFrame
					end
				end
				
				print("[GameStart] Game start cancelled - player left seat")
			end
		end
	end)
end

-- Initialize
if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

print("[GameStart] Script loaded successfully!")