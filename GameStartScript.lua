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

-- Store card visual states
local cardVisualStates = {}
local isAnimating = false

-- Animate card shuffle (visual only, no actual position changes)
local function animateCardShuffle(onComplete)
	if isAnimating then return end
	isAnimating = true
	
	local allCards = getCards()
	if #allCards == 0 then
		print("[GameStart] No cards found to shuffle")
		isAnimating = false
		if onComplete then onComplete() end
		return
	end
	
	-- Cancel any existing shuffle tweens
	for _, tween in pairs(shuffleTweens) do
		tween:Cancel()
	end
	shuffleTweens = {}
	
	-- Store original transparencies
	for _, card in ipairs(allCards) do
		cardVisualStates[card] = {
			transparency = card.Transparency,
			cframe = card.CFrame
		}
	end
	
	-- Calculate center of table
	local centerPosition = table1.Position
	
	-- Create a model to hold cards during animation
	local animModel = Instance.new("Model")
	animModel.Name = "ShuffleAnimation"
	animModel.Parent = workspace.CurrentCamera
	
	-- Phase 1: Fade out real cards and create animated versions
	for _, card in ipairs(allCards) do
		-- Fade out original
		local fadeTween = TweenService:Create(card,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad),
			{Transparency = 1}
		)
		fadeTween:Play()
	end
	
	wait(0.2)
	
	-- Create visual copies for animation
	local animCards = {}
	for i, card in ipairs(allCards) do
		local animCard = card:Clone()
		animCard.Parent = animModel
		animCard.Anchored = true
		animCard.CanCollide = false
		animCard.CanQuery = false
		animCard.CanTouch = false
		animCard.Transparency = 0
		
		table.insert(animCards, animCard)
	end
	
	-- Phase 2: Lift and gather cards
	for i, animCard in ipairs(animCards) do
		local raisedCFrame = CFrame.new(centerPosition + Vector3.new(0, SHUFFLE_HEIGHT + (i * 0.05), 0))
		local tween = TweenService:Create(animCard,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{CFrame = raisedCFrame}
		)
		table.insert(shuffleTweens, tween)
		tween:Play()
	end
	
	wait(0.4)
	
	-- Phase 3: Quick shuffle spin
	local shuffleTime = 0.8
	local startTime = tick()
	local spinConnection
	
	spinConnection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		if elapsed > shuffleTime then 
			spinConnection:Disconnect()
			return 
		end
		
		local progress = elapsed / shuffleTime
		local spin = progress * math.pi * 4 -- 2 full rotations
		
		for i, animCard in ipairs(animCards) do
			local angle = (i / #animCards) * math.pi * 2 + spin
			local radius = SHUFFLE_SPREAD * math.sin(progress * math.pi) -- Expand and contract
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			local y = SHUFFLE_HEIGHT + math.sin(progress * math.pi * 2) * 2
			
			animCard.CFrame = CFrame.new(centerPosition + Vector3.new(x, y, z)) * CFrame.Angles(0, angle, 0)
		end
	end)
	
	wait(shuffleTime)
	
	-- Phase 4: Cards drop and spread to new positions
	local positions = {}
	for _, card in ipairs(allCards) do
		table.insert(positions, cardVisualStates[card].cframe)
	end
	
	-- Shuffle the positions array
	local shuffledPositions = shuffleArray(positions)
	
	for i, animCard in ipairs(animCards) do
		local targetCFrame = shuffledPositions[i]
		local dropTween = TweenService:Create(animCard,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				CFrame = targetCFrame,
				Transparency = 1
			}
		)
		table.insert(shuffleTweens, dropTween)
		dropTween:Play()
	end
	
	-- Fade in real cards at same time
	wait(0.15) -- Start fading in halfway through drop
	for _, card in ipairs(allCards) do
		local fadeInTween = TweenService:Create(card,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad),
			{Transparency = 0}
		)
		fadeInTween:Play()
	end
	
	wait(0.15)
	
	-- Clean up
	animModel:Destroy()
	shuffleTweens = {}
	cardVisualStates = {}
	isAnimating = false
	
	print("[GameStart] Shuffle animation complete")
	if onComplete then onComplete() end
end

-- Start game countdown (only visual, actual game starts from server)
local function startGameCountdown()
	-- Check if both seats are occupied
	local player1Occupied = player1Chair.Occupant ~= nil
	local player2Occupied = player2Chair.Occupant ~= nil
	
	if not player1Occupied or not player2Occupied then
		-- Don't start countdown if both seats aren't taken
		return
	end
	
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
			print("[GameStart] Game countdown complete!")
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