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

-- Optional: Add click detection for cards
mouse.Button1Down:Connect(function()
	-- Only process clicks if seated at table
	if not isSeatedAtTable then return end
	
	if currentHoveredPart and isCard(currentHoveredPart) then
		-- Card was clicked, you can add your game logic here
		print("Clicked card:", currentHoveredPart.Name)
		
		-- Example: Add a little pulse effect
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
	
	-- Destroy all highlights
	for part, highlight in pairs(highlights) do
		highlight:Destroy()
	end
	highlights = {}
end)

print("[CardHighlight] Script loaded successfully! Highlights will activate when seated.")