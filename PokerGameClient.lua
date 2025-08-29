-- Poker Card Game Client Script
-- Handles UI, card highlighting, and player interactions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Modules
local SoundManager
local soundsEnabled = false

-- Try to load SoundManager
local success, err = pcall(function()
	SoundManager = require(ReplicatedStorage:WaitForChild("SoundManager", 5))
	soundsEnabled = true
	print("[PokerGame] SoundManager loaded successfully")
end)

if not success then
	warn("[PokerGame] Failed to load SoundManager:", err)
	warn("[PokerGame] Sounds will be disabled. Make sure SoundManager is in ReplicatedStorage")
end

-- Configuration
local HIGHLIGHT_COLOR = Color3.fromRGB(100, 255, 100) -- Green for your turn
local OPPONENT_HIGHLIGHT_COLOR = Color3.fromRGB(255, 100, 100) -- Red for opponent's turn
local SELECTED_CARD_COLOR = Color3.fromRGB(150, 150, 150) -- Gray for selected cards
local FLIP_DURATION = 0.45 -- Balanced for smooth, satisfying animation

-- References
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local table1Folder = workspace:WaitForChild("Table1Folder")
local table1 = table1Folder:WaitForChild("Table1")
local player1Chair = table1Folder:WaitForChild("Player1Chair"):WaitForChild("Seat")
local player2Chair = table1Folder:WaitForChild("Player2Chair"):WaitForChild("Seat")

-- Wait for RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("PokerGameEvents")
local cardClickEvent = remoteEvents:WaitForChild("CardClick")
local gameStateEvent = remoteEvents:WaitForChild("GameStateUpdate")
local turnUpdateEvent = remoteEvents:WaitForChild("TurnUpdate")
local cardFlipEvent = remoteEvents:WaitForChild("CardFlip")

-- State
local isMyTurn = false
local gameActive = false
local selectedCards = {}
local cardHighlights = {}
local flippedCards = {}
local originalCardCFrames = {}
local isCountdownActive = false -- Track if countdown is in progress
local currentHoveredCard = nil
local waitingDotsConnection = nil

-- UI Elements
local gameUI = nil
local turnLabel = nil
local statusLabel = nil

-- Store all card positions at startup
local function storeOriginalCardPositions()
	originalCardCFrames = {}
	local count = 0
	for _, card in ipairs(table1:GetChildren()) do
		if card:IsA("BasePart") then
			-- Store the face-down position (cards might start face-up, so flip them first)
			local faceDownCFrame = card.CFrame
			
			-- Check if card needs to be flipped to face-down
			-- If the card's orientation suggests it's face-up, flip it
			local x, y, z = faceDownCFrame:ToEulerAnglesXYZ()
			print("[PokerGame DEBUG] Card", card.Name, "initial rotation:", math.deg(x), math.deg(y), math.deg(z))
			
			originalCardCFrames[card] = faceDownCFrame
			count = count + 1
		end
	end
	print("[PokerGame] Stored", count, "original card positions")
end

-- Animate waiting dots
local function startWaitingAnimation()
	if waitingDotsConnection then
		waitingDotsConnection:Disconnect()
		waitingDotsConnection = nil
	end
	
	local dotCount = 0
	local frameCount = 0
	
	-- Set initial text
	turnLabel.Text = "Waiting for players"
	
	waitingDotsConnection = RunService.Heartbeat:Connect(function(dt)
		frameCount = frameCount + 1
		
		-- Update every 60 frames (approximately 1 second at 60fps)
		if frameCount >= 60 then
			frameCount = 0
			dotCount = (dotCount + 1) % 4
			
			if dotCount == 0 then
				turnLabel.Text = "Waiting for players"
			elseif dotCount == 1 then
				turnLabel.Text = "Waiting for players."
			elseif dotCount == 2 then
				turnLabel.Text = "Waiting for players.."
			elseif dotCount == 3 then
				turnLabel.Text = "Waiting for players..."
			end
		end
	end)
end

local function stopWaitingAnimation()
	if waitingDotsConnection then
		waitingDotsConnection:Disconnect()
		waitingDotsConnection = nil
	end
end

-- Create game UI
local function createGameUI()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PokerGameUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Turn indicator at top (hidden by default)
	local turnFrame = Instance.new("Frame")
	turnFrame.Name = "TurnFrame"
	turnFrame.Size = UDim2.new(0, 300, 0, 60)
	turnFrame.Position = UDim2.new(0.5, -150, 0, 20)
	turnFrame.BackgroundTransparency = 1
	turnFrame.Visible = false -- Hidden by default
	turnFrame.Parent = screenGui
	
	turnLabel = Instance.new("TextLabel")
	turnLabel.Name = "TurnLabel"
	turnLabel.Size = UDim2.new(1, 0, 1, 0)
	turnLabel.BackgroundTransparency = 1
	turnLabel.Text = "Waiting for players"
	turnLabel.TextColor3 = Color3.new(1, 1, 1)
	turnLabel.TextScaled = true
	turnLabel.Font = Enum.Font.SourceSansBold
	turnLabel.Parent = turnFrame
	
	local turnStroke = Instance.new("UIStroke")
	turnStroke.Color = Color3.new(0, 0, 0)
	turnStroke.Thickness = 3
	turnStroke.Parent = turnLabel
	
	-- Status message (for game end)
	local statusFrame = Instance.new("Frame")
	statusFrame.Name = "StatusFrame"
	statusFrame.Size = UDim2.new(0, 400, 0, 100)
	statusFrame.Position = UDim2.new(0.5, -200, 0.5, -50)
	statusFrame.BackgroundTransparency = 1
	statusFrame.Visible = false
	statusFrame.Parent = screenGui
	
	statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 1, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.new(1, 1, 1)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.SourceSansBold
	statusLabel.Parent = statusFrame
	
	local statusStroke = Instance.new("UIStroke")
	statusStroke.Color = Color3.new(0, 0, 0)
	statusStroke.Thickness = 4
	statusStroke.Parent = statusLabel
	
	gameUI = screenGui
	return screenGui
end

-- Check if player is seated at the table
local function isSeatedAtTable()
	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
	if not humanoid then return false end
	
	local seatPart = humanoid.SeatPart
	return seatPart == player1Chair or seatPart == player2Chair
end

-- Create or get highlight for a card
local function getOrCreateHighlight(card)
	if cardHighlights[card] then
		return cardHighlights[card]
	end
	
	local highlight = Instance.new("Highlight")
	highlight.Parent = card
	highlight.Adornee = card
	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = false
	
	cardHighlights[card] = highlight
	return highlight
end

-- Update card highlighting based on game state
local function updateCardHighlighting()
	-- Quick exit if not in game
	if not gameActive or not isMyTurn then
		-- Disable all highlights except selected cards
		for card, highlight in pairs(cardHighlights) do
			if selectedCards[card] or flippedCards[card] then
				highlight.FillColor = SELECTED_CARD_COLOR
				highlight.OutlineColor = SELECTED_CARD_COLOR
				highlight.Enabled = true
			else
				highlight.Enabled = false
			end
		end
		return
	end
	
	-- Normal highlighting during turn
	for card, highlight in pairs(cardHighlights) do
		if selectedCards[card] or flippedCards[card] then
			-- Card is selected/flipped - show as gray
			highlight.FillColor = SELECTED_CARD_COLOR
			highlight.OutlineColor = SELECTED_CARD_COLOR
			highlight.Enabled = true
		elseif currentHoveredCard == card and not selectedCards[card] then
			-- Hovering over unselected card during my turn
			highlight.FillColor = HIGHLIGHT_COLOR
			highlight.OutlineColor = HIGHLIGHT_COLOR
			highlight.Enabled = true
		else
			highlight.Enabled = false
		end
	end
end

-- Store active flip tweens
local flipTweens = {}

-- Flip a card animation
local function flipCard(card)
	if flippedCards[card] then
		return
	end
	
	flippedCards[card] = true
	selectedCards[card] = true
	
	-- Cancel any existing flip tweens for this card
	if flipTweens[card] then
		for _, tween in ipairs(flipTweens[card]) do
			tween:Cancel()
		end
	end
	flipTweens[card] = {}
	
	-- Create flip animation with optimal settings for smoothness
	local flipTweenInfo = TweenInfo.new(
		FLIP_DURATION,
		Enum.EasingStyle.Back, -- Provides a nice "snap" feel
		Enum.EasingDirection.Out,
		0, -- RepeatCount
		false, -- Reverses
		0 -- DelayTime
	)
	
	-- Get current CFrame and calculate target
	local currentCFrame = card.CFrame
	local targetCFrame = currentCFrame * CFrame.Angles(math.rad(180), 0, 0)
	
	-- Create and play the flip animation
	local flipTween = TweenService:Create(card, flipTweenInfo, {
		CFrame = targetCFrame
	})
	
	table.insert(flipTweens[card], flipTween)
	
	-- Play the animation
	flipTween:Play()
	
	updateCardHighlighting()
end

-- Reset a card to face-down position
local function resetCard(card)
	print("[PokerGame DEBUG] resetCard called for", card.Name)
	
	-- Cancel any active tweens
	if flipTweens[card] then
		print("[PokerGame DEBUG] Cancelling", #flipTweens[card], "tweens for", card.Name)
		for _, tween in ipairs(flipTweens[card]) do
			tween:Cancel()
		end
		flipTweens[card] = nil
	end
	
		-- Reset to exact original CFrame (face-down position)
	local originalCFrame = originalCardCFrames[card]
	if originalCFrame then
		print("[PokerGame DEBUG] Resetting", card.Name, "to face-down")
		
		-- Use coroutine for smooth reset that survives character removal
		coroutine.wrap(function()
			local startCFrame = card.CFrame
			local targetCFrame = originalCFrame
			local duration = 0.3
			local elapsed = 0
			
			while elapsed < duration and card.Parent do
				elapsed = elapsed + game:GetService("RunService").Heartbeat:Wait()
				local alpha = math.min(elapsed / duration, 1)
				
				-- Use quad easing for smooth animation
				local easedAlpha = alpha * alpha * (3 - 2 * alpha)
				
				if card.Parent then -- Check card still exists
					card.CFrame = startCFrame:Lerp(targetCFrame, easedAlpha)
				end
			end
			
			-- Ensure final position
			if card.Parent then
				card.CFrame = targetCFrame
			end
		end)()
	else
		print("[PokerGame DEBUG] WARNING: No original CFrame for", card.Name)
		-- This shouldn't happen, but as a fallback...
		local currentPos = card.Position
		card.CFrame = CFrame.new(currentPos) * CFrame.Angles(math.rad(180), 0, 0)
	end
	
	-- Clear flip state
	flippedCards[card] = nil
	selectedCards[card] = nil
end

-- Handle mouse movement
local function onMouseMove()
	if not isSeatedAtTable() or not gameActive or not isMyTurn then
		currentHoveredCard = nil
		updateCardHighlighting()
		return
	end
	
	local target = mouse.Target
	
	if target and target.Parent == table1 and target:IsA("BasePart") then
		if currentHoveredCard ~= target then
			currentHoveredCard = target
			updateCardHighlighting()
			
			-- Play hover sound when entering a new card (not already selected)
			if soundsEnabled and not selectedCards[target] then
				SoundManager:PlayHoverSound(target.Position)
			end
		end
	else
		if currentHoveredCard then
			currentHoveredCard = nil
			updateCardHighlighting()
		end
	end
end

-- Handle mouse click
local function onMouseClick()
	if not gameActive or not isMyTurn or not currentHoveredCard or isCountdownActive then
		return
	end
	
	if selectedCards[currentHoveredCard] then
		return -- Card already selected
	end
	
	-- Play appropriate click sound
	if soundsEnabled then
		if currentHoveredCard.Name == "Poker" then
			SoundManager:PlayPokerClickSound(currentHoveredCard.Position)
		else
			SoundManager:PlayClickSound(currentHoveredCard.Position)
		end
	end
	
	-- Send card selection to server
	cardClickEvent:FireServer(currentHoveredCard)
end

-- Handle game state updates
gameStateEvent.OnClientEvent:Connect(function(state, data)
	if state == "countdown_start" then
		-- Countdown is starting, disable interactions
		isCountdownActive = true
		gameActive = false
		
		-- Hide turn UI during countdown
		if gameUI then
			gameUI.TurnFrame.Visible = false
		end
		
		-- Stop waiting animation
		stopWaitingAnimation()
		
		print("[PokerGame] Countdown started, hiding waiting UI")
		
	elseif state == "game_start" then
		-- Countdown is complete, game actually starts
		isCountdownActive = false
		gameActive = true
		selectedCards = {}
		flippedCards = {}
		
		-- Stop waiting animation
		stopWaitingAnimation()
		
		-- Show turn UI
		if gameUI then
			gameUI.TurnFrame.Visible = true
		end
		
		-- Update UI
		local isPlayer1 = data.player1 == player.Name
		local isPlayer2 = data.player2 == player.Name
		
		if isPlayer1 or isPlayer2 then
			turnLabel.Text = data.currentTurn == player.Name and "Your Turn" or "Opponent's Turn"
			isMyTurn = data.currentTurn == player.Name
		else
			turnLabel.Text = data.currentTurn .. "'s Turn"
		end
		
		-- Hide status
		if gameUI then
			gameUI.StatusFrame.Visible = false
		end
		
		-- Initialize highlights for all cards
		for _, card in ipairs(table1:GetChildren()) do
			if card:IsA("BasePart") then
				getOrCreateHighlight(card)
			end
		end
		
		updateCardHighlighting()
		
	elseif state == "game_end" then
		gameActive = false
		isMyTurn = false
		isCountdownActive = false -- Ensure countdown flag is reset
		
		-- Show winner/loser message FIRST
		if gameUI then
			local statusFrame = gameUI.StatusFrame
			statusFrame.Visible = true
			
			-- Update turn label to hide it
			turnLabel.Text = ""
			gameUI.TurnFrame.Visible = false
			
			if data.winner == player.Name then
				statusLabel.Text = "You Win!"
				statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				
				-- Add extra effect for winner
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
			
			-- Animate status appearance
			statusFrame.Size = UDim2.new(0, 0, 0, 0)
			statusFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
			
			local showTween = TweenService:Create(statusFrame,
				TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{
					Size = UDim2.new(0, 400, 0, 100),
					Position = UDim2.new(0.5, -200, 0.5, -50)
				}
			)
			showTween:Play()
			
			-- Use coroutine to handle the delayed hide and UI check
			coroutine.wrap(function()
				-- Hide after delay (shorter for winner since they'll be standing up)
				local hideDelay = data.winner == player.Name and 2 or 3
				task.wait(hideDelay)
				
				local hideTween = TweenService:Create(statusFrame,
					TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
					{
						Size = UDim2.new(0, 0, 0, 0),
						Position = UDim2.new(0.5, 0, 0.5, 0)
					}
				)
				hideTween:Play()
				
				-- After message disappears, check if we should show waiting UI
				hideTween.Completed:Connect(function()
					-- Check seating status is defined later, so we directly check here
					if player.Character then
						local humanoid = player.Character:FindFirstChild("Humanoid")
						if humanoid and humanoid.SeatPart and (humanoid.SeatPart == player1Chair or humanoid.SeatPart == player2Chair) then
							-- Still seated, show waiting UI
							if gameUI and gameUI.TurnFrame and not gameActive then
								gameUI.TurnFrame.Visible = true
								stopWaitingAnimation()
								startWaitingAnimation()
							end
						end
					end
				end)
			end)()
		end
		
		-- Disable all highlights
		for card, highlight in pairs(cardHighlights) do
			highlight.Enabled = false
		end
		
	elseif state == "cards_reset" then
		-- Reset all card states
		for _, card in ipairs(table1:GetChildren()) do
			if card:IsA("BasePart") then
				resetCard(card)
			end
		end
		
		-- Clear flip states (but keep original positions)
		selectedCards = {}
		flippedCards = {}
		
		-- Update highlighting
		updateCardHighlighting()
		
		print("[PokerGame] Cards reset received")
	end
end)

-- Handle turn updates
turnUpdateEvent.OnClientEvent:Connect(function(currentTurnPlayer)
	if not gameActive then return end
	
	isMyTurn = currentTurnPlayer == player.Name
	
	if turnLabel then
		if isSeatedAtTable() then
			turnLabel.Text = isMyTurn and "Your Turn" or "Opponent's Turn"
			
			-- Add pulse effect for turn change
			if isMyTurn then
				local pulseTween = TweenService:Create(turnLabel,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{TextTransparency = 0.3}
				)
				pulseTween:Play()
				pulseTween.Completed:Connect(function()
					local returnTween = TweenService:Create(turnLabel,
						TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{TextTransparency = 0}
					)
					returnTween:Play()
				end)
			end
		else
			turnLabel.Text = currentTurnPlayer .. "'s Turn"
		end
	end
	
	updateCardHighlighting()
end)

-- Handle card flip events from server
cardFlipEvent.OnClientEvent:Connect(function(cardOrAction)
	print("[PokerGame DEBUG] cardFlipEvent received:", cardOrAction)
	
	if cardOrAction == "reset_all_cards" then
		-- Reset all cards to face down
		for _, card in ipairs(table1:GetChildren()) do
			if card:IsA("BasePart") then
				resetCard(card)
			end
		end
		
		-- Clear flip states (but keep original positions)
		selectedCards = {}
		flippedCards = {}
		
		-- Cancel all active tweens
		for card, tweens in pairs(flipTweens) do
			for _, tween in ipairs(tweens) do
				tween:Cancel()
			end
		end
		flipTweens = {}
		
		-- Reset all highlights
		for card, highlight in pairs(cardHighlights) do
			highlight.Enabled = false
		end
		
		-- Clear any active game state
		gameActive = false
		isMyTurn = false
		currentHoveredCard = nil
		
		print("[PokerGame] All cards fully reset")
	else
		-- Normal card flip
		flipCard(cardOrAction)
	end
end)

-- Connect mouse events
mouse.Move:Connect(onMouseMove)
mouse.Button1Down:Connect(onMouseClick)

-- Monitor seating to show/hide UI
local function checkSeatingStatus()
	if not player.Character then return end
	
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	local isSeated = isSeatedAtTable()
	
	-- Ensure UI exists
	if not gameUI then
		createGameUI()
	end
	
	if gameUI and gameUI.TurnFrame then
		if isSeated and not gameActive and not isCountdownActive then
			-- Show waiting UI when seated but game hasn't started and countdown isn't active
			gameUI.TurnFrame.Visible = true
			stopWaitingAnimation() -- Stop any existing animation first
			startWaitingAnimation()
		elseif isSeated and gameActive then
			-- Keep UI visible during game
			gameUI.TurnFrame.Visible = true
			stopWaitingAnimation()
		elseif isCountdownActive then
			-- Hide during countdown
			gameUI.TurnFrame.Visible = false
			stopWaitingAnimation()
		else
			-- Hide UI when not seated
			gameUI.TurnFrame.Visible = false
			stopWaitingAnimation()
		end
	end
end

-- Set up character monitoring
local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	
	-- Check initial state
	task.wait(0.5) -- Longer delay to ensure UI is fully created
	checkSeatingStatus()
	
	-- Monitor seating changes
	humanoid.Seated:Connect(function()
		task.wait(0.1) -- Small delay for seat state to register
		checkSeatingStatus()
		updateCardHighlighting()
	end)
	
	-- Also monitor seat part changes
	humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		checkSeatingStatus()
	end)
end

-- Clean up on character removal
player.CharacterRemoving:Connect(function()
	stopWaitingAnimation()
	
	-- Reset all cards before leaving
	for _, card in ipairs(table1:GetChildren()) do
		if card:IsA("BasePart") then
			resetCard(card)
		end
	end
	
	-- Cancel all tweens
	for card, tweens in pairs(flipTweens) do
		for _, tween in ipairs(tweens) do
			tween:Cancel()
		end
	end
	flipTweens = {}
	
	if gameUI then
		gameUI:Destroy()
		gameUI = nil
	end
	
	-- Clean up highlights
	for card, highlight in pairs(cardHighlights) do
		highlight:Destroy()
	end
	cardHighlights = {}
	
	-- Clear all states (but keep original positions)
	selectedCards = {}
	flippedCards = {}
end)

-- Initialize
createGameUI()

-- Store original card positions at startup
storeOriginalCardPositions()

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Monitor seat occupancy changes to update UI consistently
player1Chair:GetPropertyChangedSignal("Occupant"):Connect(function()
	task.wait(0.1)
	checkSeatingStatus()
end)

player2Chair:GetPropertyChangedSignal("Occupant"):Connect(function()
	task.wait(0.1)
	checkSeatingStatus()
end)

-- Initial check after a short delay
task.wait(0.5)
checkSeatingStatus()

print("[PokerGame] Client initialized")