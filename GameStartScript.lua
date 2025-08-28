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
	
	-- Create background frame
	local backgroundFrame = Instance.new("Frame")
	backgroundFrame.Name = "BackgroundFrame"
	backgroundFrame.Size = UDim2.new(0, 400, 0, 200)
	backgroundFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
	backgroundFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	backgroundFrame.BackgroundTransparency = 0.3
	backgroundFrame.BorderSizePixel = 0
	backgroundFrame.Parent = screenGui
	
	-- Add rounded corners
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 12)
	uiCorner.Parent = backgroundFrame
	
	-- Add gradient
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
	})
	uiGradient.Rotation = 90
	uiGradient.Parent = backgroundFrame
	
	-- Create title label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -20, 0, 60)
	titleLabel.Position = UDim2.new(0, 10, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Game Starting"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Parent = backgroundFrame
	
	-- Create countdown label
	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "CountdownLabel"
	countdownLabel.Size = UDim2.new(1, -20, 0, 80)
	countdownLabel.Position = UDim2.new(0, 10, 0, 80)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Text = "3"
	countdownLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	countdownLabel.TextScaled = true
	countdownLabel.Font = Enum.Font.SourceSansBold
	countdownLabel.Parent = backgroundFrame
	
	-- Add text stroke for better visibility
	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.new(0, 0, 0)
	textStroke.Thickness = 2
	textStroke.Parent = countdownLabel
	
	-- Initial animation
	backgroundFrame.Size = UDim2.new(0, 0, 0, 0)
	backgroundFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	
	local showTween = TweenService:Create(backgroundFrame, 
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 400, 0, 200),
			Position = UDim2.new(0.5, -200, 0.5, -100)
		}
	)
	showTween:Play()
	
	return screenGui, countdownLabel
end

-- Destroy countdown UI with animation
local function destroyCountdownUI()
	if countdownGui then
		local backgroundFrame = countdownGui:FindFirstChild("BackgroundFrame")
		if backgroundFrame then
			local hideTween = TweenService:Create(backgroundFrame,
				TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
				{
					Size = UDim2.new(0, 0, 0, 0),
					Position = UDim2.new(0.5, 0, 0.5, 0)
				}
			)
			hideTween:Play()
			hideTween.Completed:Connect(function()
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
	
	local countdownConnection
	countdownConnection = RunService.Heartbeat:Connect(function(dt)
		currentCountdown = currentCountdown - dt
		
		local displayTime = math.ceil(currentCountdown)
		if displayTime >= 0 then
			countdownLabel.Text = tostring(displayTime)
			
			-- Pulse effect on countdown change
			if displayTime ~= tonumber(countdownLabel.Text) then
				local pulseTween = TweenService:Create(countdownLabel,
					TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{TextTransparency = 0.5}
				)
				pulseTween:Play()
				pulseTween.Completed:Connect(function()
					local returnTween = TweenService:Create(countdownLabel,
						TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{TextTransparency = 0}
					)
					returnTween:Play()
				end)
			end
		else
			-- Countdown finished
			countdownConnection:Disconnect()
			countdownLabel.Text = "GO!"
			
			wait(0.5)
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