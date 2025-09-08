-- ShopControllerWithProximity.lua
-- Enhanced shop controller that supports both button and proximity opening
-- REPLACE your existing ShopController with this version
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

-- Check if player is within bounds
local function isPlayerInBounds()
	local character = player.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	local partCFrame = openShopPart.CFrame
	local partSize = openShopPart.Size
	local relativePosition = partCFrame:PointToObjectSpace(humanoidRootPart.Position)
	local halfSize = partSize / 2
	
	local withinX = math.abs(relativePosition.X) <= halfSize.X
	local withinZ = math.abs(relativePosition.Z) <= halfSize.Z
	local onSurface = relativePosition.Y >= -1 and relativePosition.Y <= halfSize.Y + 10
	
	return withinX and withinZ and onSurface
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

-- Proximity checking
local function startProximityCheck()
	proximityConnection = RunService.Heartbeat:Connect(function()
		local inBounds = isPlayerInBounds()
		
		if inBounds and not isInZone then
			-- Entered zone
			isInZone = true
			openButton.Visible = false
			if not isOpen then
				openShop(true)
			end
		elseif not inBounds and isInZone then
			-- Left zone
			isInZone = false
			if openedViaProximity then
				closeShop(true)
			end
			openButton.Visible = true
		end
	end)
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
			-- Add purchase logic
		end)
	end
	
	if giftButton then
		setupButtonHoverEffect(giftButton)
		giftButton.MouseButton1Click:Connect(function()
			debugPrint("Gift clicked:", itemFrame.Name)
			-- Add gift logic
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

openButton.MouseButton1Click:Connect(function()
	toggleShop()
end)

closeButton.MouseButton1Click:Connect(function()
	closeShop(false)
end)

-- Setup items
setupAllItems()

-- Start proximity detection
startProximityCheck()

-- Handle character respawn
player.CharacterAdded:Connect(function()
	wait(1)
	startProximityCheck()
end)

player.CharacterRemoving:Connect(function()
	if proximityConnection then
		proximityConnection:Disconnect()
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

print("[Shop] Shop controller with proximity support initialized!")
print("[Shop] Walk into the shop area to auto-open!")