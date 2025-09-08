-- ShopControllerWithProximity.lua
-- Enhanced shop controller with flexible proximity detection
-- Place this in StarterPlayer > StarterPlayerScripts (rename to ShopController.lua)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Debug mode
local DEBUG_MODE = true
local function debugPrint(...)
	if DEBUG_MODE then
		print("[Shop]", ...)
	end
end

-- Get shop elements
local shopGui = playerGui:WaitForChild("LimitedStoreGUI")
local mainFrame = shopGui:WaitForChild("MainFrame")
local openButton = shopGui:WaitForChild("OpenShopbtn")
local uiLabel = mainFrame:WaitForChild("UiLabel")
local closeButton = uiLabel:WaitForChild("CloseButton")
local bgFrame = uiLabel:WaitForChild("BGFrame")
local container = bgFrame:WaitForChild("Container")

-- Get proximity trigger
local map = workspace:WaitForChild("Map")
local shop = map:WaitForChild("Shop")
local openShopPart = shop:WaitForChild("OpenShopPart")

-- CONFIGURATION: Adjust detection zone
local DETECTION_HEIGHT_ABOVE = 15  -- How many studs above the part to detect
local DETECTION_HEIGHT_BELOW = 2   -- How many studs below the part to detect
local USE_XZ_ONLY = false          -- Set to true to ignore Y axis completely (infinite height)

-- Shop state
local isOpen = false
local isAnimating = false
local openedViaProximity = false
local currentPlayingAudio = nil

-- Proximity state
local isInZone = false
local proximityConnection = nil

-- Animation settings
local SLIDE_TIME = 0.4
local SLIDE_TWEEN = TweenInfo.new(
	SLIDE_TIME,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

local FAST_TWEEN = TweenInfo.new(
	0.15,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

-- Store original properties
local originalPosition = mainFrame.Position
local originalSize = mainFrame.Size

-- Animation style
local ANIMATION_STYLE = "SLIDE_RIGHT"

-- Hide shop initially
mainFrame.Visible = false
openShopPart.Transparency = 1
openShopPart.CanCollide = false

-- IMPROVED: Flexible bounds detection
local function isPlayerInBounds()
	local character = player.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	-- Get the part's world-space properties
	local partCFrame = openShopPart.CFrame
	local partSize = openShopPart.Size
	local partPosition = openShopPart.Position
	
	-- Get player position
	local playerPosition = humanoidRootPart.Position
	
	-- Convert to part's local space for X and Z checking
	local relativePosition = partCFrame:PointToObjectSpace(playerPosition)
	
	-- Get half extents
	local halfSizeX = partSize.X / 2
	local halfSizeZ = partSize.Z / 2
	
	-- Check X and Z bounds (horizontal area)
	local withinX = math.abs(relativePosition.X) <= halfSizeX
	local withinZ = math.abs(relativePosition.Z) <= halfSizeZ
	
	-- Check Y bounds with extended range
	local withinY = true -- Default to true
	
	if not USE_XZ_ONLY then
		-- Calculate Y difference from part's center
		local yDifference = playerPosition.Y - partPosition.Y
		
		-- Check if player is within the extended Y range
		local minY = -(partSize.Y / 2) - DETECTION_HEIGHT_BELOW
		local maxY = (partSize.Y / 2) + DETECTION_HEIGHT_ABOVE
		
		withinY = yDifference >= minY and yDifference <= maxY
		
		-- Debug Y specifically
		if DEBUG_MODE and math.random() > 0.98 then
			debugPrint(string.format(
				"Y Check: Player Y=%.1f, Part Y=%.1f, Diff=%.1f, Range=[%.1f to %.1f] %s",
				playerPosition.Y, partPosition.Y, yDifference, minY, maxY,
				withinY and "✓" or "✗"
			))
		end
	end
	
	-- Player must be within X, Z, and Y (if Y checking is enabled)
	local isInside = withinX and withinZ and withinY
	
	-- Detailed debug output (less frequent to reduce spam)
	if DEBUG_MODE and math.random() > 0.97 then
		debugPrint(string.format(
			"Bounds: X=%s Z=%s Y=%s = %s",
			withinX and "✓" or "✗",
			withinZ and "✓" or "✗",
			withinY and "✓" or "✗",
			isInside and "INSIDE" or "OUTSIDE"
		))
	end
	
	return isInside
end

-- Alternative: Simple distance-based detection
local function isPlayerInRange()
	local character = player.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	-- Calculate horizontal distance only (ignoring Y)
	local partPos = openShopPart.Position
	local playerPos = humanoidRootPart.Position
	
	local horizontalDistance = math.sqrt(
		(partPos.X - playerPos.X)^2 + 
		(partPos.Z - playerPos.Z)^2
	)
	
	-- Use the average of X and Z size as radius
	local detectionRadius = (openShopPart.Size.X + openShopPart.Size.Z) / 4
	
	return horizontalDistance <= detectionRadius
end

-- Button hover effect
local function setupButtonHoverEffect(button)
	if not button then return end
	
	local originalButtonSize = button.Size
	local isHovering = false
	
	button.MouseEnter:Connect(function()
		if not isAnimating and not isHovering then
			isHovering = true
			TweenService:Create(button, FAST_TWEEN, {
				Size = UDim2.new(
					originalButtonSize.X.Scale * 1.05,
					originalButtonSize.X.Offset,
					originalButtonSize.Y.Scale * 1.05,
					originalButtonSize.Y.Offset
				)
			}):Play()
		end
	end)
	
	button.MouseLeave:Connect(function()
		if isHovering then
			isHovering = false
			TweenService:Create(button, FAST_TWEEN, {
				Size = originalButtonSize
			}):Play()
		end
	end)
end

-- Open shop
local function openShop(viaProximity)
	if isOpen or isAnimating then return end
	
	isAnimating = true
	openedViaProximity = viaProximity or false
	
	debugPrint("Opening shop", openedViaProximity and "(via proximity)" or "(via button)")
	
	-- Hide open button if opened via proximity
	if openedViaProximity then
		openButton.Visible = false
	end
	
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	
	-- Set starting position
	if ANIMATION_STYLE == "SLIDE_RIGHT" then
		mainFrame.Position = UDim2.new(-0.5, 0, 0.5, 0)
	elseif ANIMATION_STYLE == "SLIDE_LEFT" then
		mainFrame.Position = UDim2.new(1.5, 0, 0.5, 0)
	elseif ANIMATION_STYLE == "SLIDE_TOP" then
		mainFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
	elseif ANIMATION_STYLE == "SLIDE_BOTTOM" then
		mainFrame.Position = UDim2.new(0.5, 0, -0.5, 0)
	elseif ANIMATION_STYLE == "SCALE_CENTER" then
		mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
	end
	
	mainFrame.Visible = true
	
	-- Animate open
	local openTween
	if ANIMATION_STYLE == "SCALE_CENTER" then
		openTween = TweenService:Create(mainFrame, SLIDE_TWEEN, {Size = originalSize})
	else
		openTween = TweenService:Create(mainFrame, SLIDE_TWEEN, {Position = UDim2.new(0.5, 0, 0.5, 0)})
	end
	
	openTween:Play()
	
	openTween.Completed:Connect(function()
		isOpen = true
		isAnimating = false
		debugPrint("Shop opened")
	end)
end

-- Close shop
local function closeShop(forced)
	if not isOpen or isAnimating then return end
	
	-- Don't close if in proximity zone unless forced
	if not forced and openedViaProximity and isInZone then
		debugPrint("Prevented close - still in proximity zone")
		return
	end
	
	isAnimating = true
	debugPrint("Closing shop")
	
	-- Stop audio
	if currentPlayingAudio then
		currentPlayingAudio:Stop()
		currentPlayingAudio = nil
	end
	
	-- Determine end position
	local endPosition
	local endSize = originalSize
	
	if ANIMATION_STYLE == "SLIDE_RIGHT" then
		endPosition = UDim2.new(1.5, 0, 0.5, 0)
	elseif ANIMATION_STYLE == "SLIDE_LEFT" then
		endPosition = UDim2.new(-0.5, 0, 0.5, 0)
	elseif ANIMATION_STYLE == "SLIDE_TOP" then
		endPosition = UDim2.new(0.5, 0, -0.5, 0)
	elseif ANIMATION_STYLE == "SLIDE_BOTTOM" then
		endPosition = UDim2.new(0.5, 0, 1.5, 0)
	elseif ANIMATION_STYLE == "SCALE_CENTER" then
		endPosition = UDim2.new(0.5, 0, 0.5, 0)
		endSize = UDim2.new(0, 0, 0, 0)
	end
	
	-- Animate close
	local closeTween
	if ANIMATION_STYLE == "SCALE_CENTER" then
		closeTween = TweenService:Create(mainFrame, SLIDE_TWEEN, {Size = endSize})
	else
		closeTween = TweenService:Create(mainFrame, SLIDE_TWEEN, {Position = endPosition})
	end
	
	closeTween:Play()
	
	closeTween.Completed:Connect(function()
		mainFrame.Visible = false
		isOpen = false
		isAnimating = false
		openedViaProximity = false
		
		-- Show open button again if not in zone
		if not isInZone then
			openButton.Visible = true
		end
		
		debugPrint("Shop closed")
	end)
end

-- Toggle shop
local function toggleShop()
	if isAnimating then return end
	
	if isOpen then
		closeShop(false)
	else
		openShop(false)
	end
end

-- Create debug visualization
local debugPart = nil
local function createDebugVisualization()
	if not DEBUG_MODE then return end
	
	-- Remove old debug part
	if debugPart and debugPart.Parent then
		debugPart:Destroy()
	end
	
	-- Create visualization that shows actual detection zone
	debugPart = Instance.new("Part")
	debugPart.Name = "ShopZoneDebug"
	
	-- Adjust size to show the extended detection area
	if USE_XZ_ONLY then
		-- Show infinite height (make it very tall)
		debugPart.Size = Vector3.new(
			openShopPart.Size.X,
			100, -- Very tall to show infinite height
			openShopPart.Size.Z
		)
		debugPart.CFrame = openShopPart.CFrame
	else
		-- Show actual detection zone with extended Y
		local extendedHeight = openShopPart.Size.Y + DETECTION_HEIGHT_ABOVE + DETECTION_HEIGHT_BELOW
		debugPart.Size = Vector3.new(
			openShopPart.Size.X,
			extendedHeight,
			openShopPart.Size.Z
		)
		-- Position it to account for the extended range
		local yOffset = (DETECTION_HEIGHT_ABOVE - DETECTION_HEIGHT_BELOW) / 2
		debugPart.CFrame = openShopPart.CFrame * CFrame.new(0, yOffset, 0)
	end
	
	debugPart.Anchored = true
	debugPart.CanCollide = false
	debugPart.Transparency = 0.8
	debugPart.BrickColor = BrickColor.new("Lime green")
	debugPart.Material = Enum.Material.ForceField
	debugPart.Parent = workspace
	
	-- Add selection box
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Adornee = debugPart
	selectionBox.Color3 = Color3.new(0, 1, 0)
	selectionBox.LineThickness = 0.1
	selectionBox.Transparency = 0.5
	selectionBox.Parent = debugPart
	
	debugPrint("Debug visualization created - Green box shows actual detection zone")
	debugPrint("Detection settings: Height Above =", DETECTION_HEIGHT_ABOVE, "Height Below =", DETECTION_HEIGHT_BELOW)
end

-- Proximity checking with debounce
local lastZoneState = false
local function startProximityCheck()
	if proximityConnection then
		proximityConnection:Disconnect()
	end
	
	proximityConnection = RunService.Heartbeat:Connect(function()
		local inBounds = isPlayerInBounds()
		
		-- Only act on state changes
		if inBounds ~= lastZoneState then
			lastZoneState = inBounds
			
			if inBounds then
				-- Entered zone
				isInZone = true
				openButton.Visible = false
				if not isOpen then
					openShop(true)
				end
				debugPrint("Entered shop zone")
			else
				-- Left zone
				isInZone = false
				if openedViaProximity then
					closeShop(true)
				end
				openButton.Visible = true
				debugPrint("Left shop zone")
			end
		end
		
		-- Update debug visualization
		if DEBUG_MODE and debugPart and debugPart.Parent then
			-- Update position if part moves
			if USE_XZ_ONLY then
				debugPart.CFrame = openShopPart.CFrame
			else
				local yOffset = (DETECTION_HEIGHT_ABOVE - DETECTION_HEIGHT_BELOW) / 2
				debugPart.CFrame = openShopPart.CFrame * CFrame.new(0, yOffset, 0)
			end
			
			-- Change color based on state
			debugPart.BrickColor = inBounds and BrickColor.new("Lime green") or BrickColor.new("Really red")
		end
	end)
	
	debugPrint("Proximity checking started")
end

-- Setup gamepass items
local function setupGamepassItem(itemFrame, categoryType)
	local buyButton = itemFrame:FindFirstChild("BuyButton")
	local giftButton = itemFrame:FindFirstChild("GiftButton")
	local playButton = itemFrame:FindFirstChild("PlayButton")
	local pauseButton = itemFrame:FindFirstChild("PauseButton")
	
	if buyButton then
		setupButtonHoverEffect(buyButton)
		buyButton.MouseButton1Click:Connect(function()
			debugPrint("Buy clicked:", itemFrame.Name)
		end)
	end
	
	if giftButton then
		setupButtonHoverEffect(giftButton)
		giftButton.MouseButton1Click:Connect(function()
			debugPrint("Gift clicked:", itemFrame.Name)
		end)
	end
	
	if categoryType == "Audio" and playButton and pauseButton then
		setupButtonHoverEffect(playButton)
		setupButtonHoverEffect(pauseButton)
		pauseButton.Visible = false
		
		playButton.MouseButton1Click:Connect(function()
			playButton.Visible = false
			pauseButton.Visible = true
		end)
		
		pauseButton.MouseButton1Click:Connect(function()
			playButton.Visible = true
			pauseButton.Visible = false
		end)
	end
end

-- Setup all items
local function setupAllItems()
	local audioContainer = container:FindFirstChild("GamepassesContainer_Audio")
	if audioContainer then
		for _, item in ipairs(audioContainer:GetChildren()) do
			if item:IsA("ImageLabel") and item.Name:match("Gamepass") then
				setupGamepassItem(item, "Audio")
			end
		end
	end
	
	local cardsContainer = container:FindFirstChild("GamepassesContainer_Cards")
	if cardsContainer then
		for _, item in ipairs(cardsContainer:GetChildren()) do
			if item:IsA("ImageLabel") and item.Name:match("Gamepass") then
				setupGamepassItem(item, "Cards")
			end
		end
	end
end

-- Connect buttons
setupButtonHoverEffect(openButton)
setupButtonHoverEffect(closeButton)

openButton.MouseButton1Click:Connect(toggleShop)
closeButton.MouseButton1Click:Connect(function() closeShop(false) end)

-- Setup items
setupAllItems()

-- Create debug visualization
createDebugVisualization()

-- Start proximity detection
startProximityCheck()

-- Handle character respawn
player.CharacterAdded:Connect(function()
	wait(1)
	isInZone = false
	lastZoneState = false
	if openedViaProximity then
		mainFrame.Visible = false
		isOpen = false
		openedViaProximity = false
	end
	openButton.Visible = true
	startProximityCheck()
	if DEBUG_MODE then
		createDebugVisualization()
	end
end)

player.CharacterRemoving:Connect(function()
	if proximityConnection then
		proximityConnection:Disconnect()
		proximityConnection = nil
	end
	if openedViaProximity then
		closeShop(true)
	end
end)

-- Keyboard shortcut
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.P then
		toggleShop()
	end
end)

-- Info printout
print("[Shop] Shop controller initialized!")
print("[Shop] Detection Mode:", USE_XZ_ONLY and "XZ Only (Infinite Height)" or "Full 3D Volume")
print("[Shop] Detection Height: +" .. DETECTION_HEIGHT_ABOVE .. " / -" .. DETECTION_HEIGHT_BELOW .. " studs")
print("[Shop] Debug Mode:", DEBUG_MODE and "ON (green/red box shows zone)" or "OFF")
print("[Shop] Part Size:", openShopPart.Size)