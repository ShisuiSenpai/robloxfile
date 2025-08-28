-- Card Highlight Script
-- Adds smooth highlight effects to playing cards on hover when seated

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Configuration
local HIGHLIGHT_COLOR = Color3.fromRGB(255, 255, 100) -- Yellow highlight
local OUTLINE_COLOR = Color3.fromRGB(255, 200, 50) -- Golden outline
local FILL_TRANSPARENCY = 0.5 -- How transparent the fill is (0 = opaque, 1 = invisible)
local OUTLINE_TRANSPARENCY = 0 -- How transparent the outline is
local TWEEN_TIME = 0.2 -- Time for highlight fade in/out
local FLIP_DURATION = 0.4 -- Time for card flip animation
local CARD_DISPLAY_TIME = 3 -- Time to show flipped card before flipping back

-- References
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- Wait for table to load
local table1Folder = workspace:WaitForChild("Table1Folder")
local table1 = table1Folder:WaitForChild("Table1")
local player1Chair = table1Folder:WaitForChild("Player1Chair"):WaitForChild("Seat")
local player2Chair = table1Folder:WaitForChild("Player2Chair"):WaitForChild("Seat")

-- Store highlight instances and tweens
local highlights = {}
local activeTweens = {}
local currentHoveredPart = nil
local isSeatedAtTable = false
local mouseConnection = nil

-- Card flipping state
local flippingCards = {} -- Track which cards are currently flipping
local cardFlipTweens = {} -- Store flip animation tweens
local originalCFrames = {} -- Store original CFrames for cards

-- Create tween info for smooth transitions
local tweenInfo = TweenInfo.new(
	TWEEN_TIME,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

-- Function to create or get highlight for a part
local function getOrCreateHighlight(part)
	if highlights[part] then
		return highlights[part]
	end
	
	-- Create new highlight
	local highlight = Instance.new("Highlight")
	highlight.Parent = part
	highlight.Adornee = part
	highlight.FillColor = HIGHLIGHT_COLOR
	highlight.OutlineColor = OUTLINE_COLOR
	highlight.FillTransparency = 1 -- Start invisible
	highlight.OutlineTransparency = 1 -- Start invisible
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = true
	
	highlights[part] = highlight
	return highlight
end

-- Function to show highlight with tween
local function showHighlight(part)
	local highlight = getOrCreateHighlight(part)
	
	-- Cancel any existing tween for this part
	if activeTweens[part] then
		activeTweens[part]:Cancel()
		activeTweens[part] = nil
	end
	
	-- Create fade in tween
	local tween = TweenService:Create(highlight, tweenInfo, {
		FillTransparency = FILL_TRANSPARENCY,
		OutlineTransparency = OUTLINE_TRANSPARENCY
	})
	
	activeTweens[part] = tween
	tween:Play()
	
	tween.Completed:Connect(function()
		activeTweens[part] = nil
	end)
end

-- Function to hide highlight with tween
local function hideHighlight(part)
	local highlight = highlights[part]
	if not highlight then return end
	
	-- Cancel any existing tween for this part
	if activeTweens[part] then
		activeTweens[part]:Cancel()
		activeTweens[part] = nil
	end
	
	-- Create fade out tween
	local tween = TweenService:Create(highlight, tweenInfo, {
		FillTransparency = 1,
		OutlineTransparency = 1
	})
	
	activeTweens[part] = tween
	tween:Play()
	
	tween.Completed:Connect(function()
		activeTweens[part] = nil
	end)
end

-- Function to check if a part is a card (child of Table1)
local function isCard(part)
	return part and part.Parent == table1 and part:IsA("BasePart")
end

-- Function to flip a card
local function flipCard(card)
	-- Don't flip if already flipping
	if flippingCards[card] then
		return
	end
	
	flippingCards[card] = true
	
	-- Store original CFrame if not already stored
	if not originalCFrames[card] then
		originalCFrames[card] = card.CFrame
	end
	
	-- Cancel any existing flip tweens for this card
	if cardFlipTweens[card] then
		for _, tween in ipairs(cardFlipTweens[card]) do
			tween:Cancel()
		end
		cardFlipTweens[card] = nil
	end
	
	cardFlipTweens[card] = {}
	
	-- Create flip animation
	local flipTweenInfo = TweenInfo.new(
		FLIP_DURATION / 2,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.In
	)
	
	local flipBackTweenInfo = TweenInfo.new(
		FLIP_DURATION / 2,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	)
	
	-- Calculate flip rotations
	local originalCFrame = originalCFrames[card]
	local halfFlipCFrame = originalCFrame * CFrame.Angles(math.rad(90), 0, 0)
	local fullFlipCFrame = originalCFrame * CFrame.Angles(math.rad(180), 0, 0)
	
	-- First half of flip (0 to 90 degrees)
	local flipTween1 = TweenService:Create(card, flipTweenInfo, {
		CFrame = halfFlipCFrame
	})
	
	-- Second half of flip (90 to 180 degrees)
	local flipTween2 = TweenService:Create(card, flipBackTweenInfo, {
		CFrame = fullFlipCFrame
	})
	
	table.insert(cardFlipTweens[card], flipTween1)
	table.insert(cardFlipTweens[card], flipTween2)
	
	-- Play the flip animation
	flipTween1:Play()
	flipTween1.Completed:Connect(function()
		flipTween2:Play()
		flipTween2.Completed:Connect(function()
			-- Schedule flip back after display time
			task.delay(CARD_DISPLAY_TIME, function()
				-- Make sure card wasn't removed
				if not card.Parent then
					flippingCards[card] = nil
					cardFlipTweens[card] = nil
					return
				end
				
				-- Flip back animation
				local flipBackTween1 = TweenService:Create(card, flipTweenInfo, {
					CFrame = halfFlipCFrame
				})
				
				local flipBackTween2 = TweenService:Create(card, flipBackTweenInfo, {
					CFrame = originalCFrame
				})
				
				table.insert(cardFlipTweens[card], flipBackTween1)
				table.insert(cardFlipTweens[card], flipBackTween2)
				
				flipBackTween1:Play()
				flipBackTween1.Completed:Connect(function()
					flipBackTween2:Play()
					flipBackTween2.Completed:Connect(function()
						-- Clean up
						flippingCards[card] = nil
						cardFlipTweens[card] = nil
					end)
				end)
			end)
		end)
	end)
end

-- Function to check if player is seated at the table
local function checkIfSeated()
	local character = player.Character
	if not character then return false end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return false end
	
	local seatPart = humanoid.SeatPart
	return seatPart == player1Chair or seatPart == player2Chair
end

-- Mouse movement handler
local function onMouseMove()
	-- Only process if seated at table
	if not isSeatedAtTable then return end
	
	local target = mouse.Target
	
	-- Check if we're hovering over a different part
	if target ~= currentHoveredPart then
		-- Hide highlight on previous part
		if currentHoveredPart and isCard(currentHoveredPart) then
			hideHighlight(currentHoveredPart)
		end
		
		-- Show highlight on new part if it's a card
		if isCard(target) then
			showHighlight(target)
			currentHoveredPart = target
		else
			currentHoveredPart = nil
		end
	end
end

-- Function to enable highlights when seated
local function enableHighlights()
	isSeatedAtTable = true
	if not mouseConnection then
		mouseConnection = mouse.Move:Connect(onMouseMove)
	end
	print("[CardHighlight] Highlights enabled - player seated at table")
end

-- Function to disable highlights when not seated
local function disableHighlights()
	isSeatedAtTable = false
	
	-- Hide any active highlight
	if currentHoveredPart then
		hideHighlight(currentHoveredPart)
		currentHoveredPart = nil
	end
	
	-- Disconnect mouse tracking
	if mouseConnection then
		mouseConnection:Disconnect()
		mouseConnection = nil
	end
	
	print("[CardHighlight] Highlights disabled - player not seated at table")
end

-- Monitor seating changes
local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	
	-- Check initial seating state
	if checkIfSeated() then
		enableHighlights()
	else
		disableHighlights()
	end
	
	-- Monitor seating changes
	humanoid.Seated:Connect(function(isSeated, seatPart)
		if isSeated and (seatPart == player1Chair or seatPart == player2Chair) then
			enableHighlights()
		else
			disableHighlights()
		end
	end)
end

-- Connect character spawning
if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Clean up highlights when parts are removed
table1.ChildRemoved:Connect(function(child)
	if highlights[child] then
		if activeTweens[child] then
			activeTweens[child]:Cancel()
			activeTweens[child] = nil
		end
		highlights[child]:Destroy()
		highlights[child] = nil
	end
end)

-- Click detection for cards
mouse.Button1Down:Connect(function()
	-- Only process clicks if seated at table
	if not isSeatedAtTable then return end
	
	if currentHoveredPart and isCard(currentHoveredPart) then
		-- Card was clicked
		print("Clicked card:", currentHoveredPart.Name)
		
		-- Flip the card
		coroutine.wrap(function()
			flipCard(currentHoveredPart)
		end)()
		
		-- Add a little pulse effect to the highlight
		local highlight = highlights[currentHoveredPart]
		if highlight then
			-- Quick pulse
			local pulseTween = TweenService:Create(highlight, 
				TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
				{
					FillTransparency = 0.2,
					OutlineTransparency = 0
				}
			)
			pulseTween:Play()
			
			pulseTween.Completed:Connect(function()
				-- Return to hover state
				local returnTween = TweenService:Create(highlight, 
					TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
					{
						FillTransparency = FILL_TRANSPARENCY,
						OutlineTransparency = OUTLINE_TRANSPARENCY
					}
				)
				returnTween:Play()
			end)
		end
	end
end)

-- Clean up on character removal
player.CharacterRemoving:Connect(function()
	-- Disable highlights
	disableHighlights()
	
	-- Cancel all active tweens
	for part, tween in pairs(activeTweens) do
		tween:Cancel()
	end
	activeTweens = {}
	
	-- Cancel all flip tweens
	for card, tweens in pairs(cardFlipTweens) do
		for _, tween in ipairs(tweens) do
			tween:Cancel()
		end
	end
	cardFlipTweens = {}
	flippingCards = {}
	
	-- Restore original CFrames for flipped cards
	for card, originalCFrame in pairs(originalCFrames) do
		if card.Parent then
			card.CFrame = originalCFrame
		end
	end
	originalCFrames = {}
	
	-- Destroy all highlights
	for part, highlight in pairs(highlights) do
		highlight:Destroy()
	end
	highlights = {}
end)

print("[CardHighlight] Script loaded successfully! Highlights will activate when seated.")