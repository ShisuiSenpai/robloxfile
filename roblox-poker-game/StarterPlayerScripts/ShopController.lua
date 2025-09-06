-- ShopController.lua
-- Complete shop functionality with tweening animations (FIXED VERSION)
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Debug mode
local DEBUG_MODE = true -- Set to false to disable debug prints

local function debugPrint(...)
	if DEBUG_MODE then
		print("[Shop Debug]", ...)
	end
end

-- Wait for shop GUI
debugPrint("Waiting for LimitedStoreGUI...")
local shopGui = playerGui:WaitForChild("LimitedStoreGUI")
local mainFrame = shopGui:WaitForChild("MainFrame")
local openButton = shopGui:WaitForChild("OpenShopbtn")

debugPrint("Found main elements")

-- Get UI elements
local uiLabel = mainFrame:WaitForChild("UiLabel")
local closeButton = uiLabel:WaitForChild("CloseButton")
local bgFrame = uiLabel:WaitForChild("BGFrame")
local container = bgFrame:WaitForChild("Container")

debugPrint("All UI elements loaded")

-- Shop state
local isOpen = false
local isAnimating = false
local currentPlayingAudio = nil

-- Animation settings
local TWEEN_TIME = 0.5
local BOUNCE_TWEEN = TweenInfo.new(
	TWEEN_TIME,
	Enum.EasingStyle.Back,
	Enum.EasingDirection.Out,
	0,
	false,
	0
)

local SMOOTH_TWEEN = TweenInfo.new(
	TWEEN_TIME,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.InOut,
	0,
	false,
	0
)

local FAST_TWEEN = TweenInfo.new(
	0.2,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out,
	0,
	false,
	0
)

-- Store original properties for ALL elements (CRITICAL FIX)
local originalTransparencies = {}
local originalProperties = {}

-- Function to store original transparencies
local function storeOriginalTransparencies()
	debugPrint("Storing original transparencies...")
	
	for _, descendant in ipairs(mainFrame:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			local id = descendant:GetDebugId()
			originalTransparencies[descendant] = {
				BackgroundTransparency = descendant.BackgroundTransparency,
				TextTransparency = nil,
				ImageTransparency = nil,
				TextStrokeTransparency = nil
			}
			
			if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
				originalTransparencies[descendant].TextTransparency = descendant.TextTransparency
				originalTransparencies[descendant].TextStrokeTransparency = descendant.TextStrokeTransparency
			end
			
			if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
				originalTransparencies[descendant].ImageTransparency = descendant.ImageTransparency
			end
			
			if descendant:IsA("ScrollingFrame") then
				originalTransparencies[descendant].ScrollBarImageTransparency = descendant.ScrollBarImageTransparency
			end
			
			-- Debug specific important elements
			if descendant.Name == "Container" or descendant.Name == "BGFrame" then
				debugPrint("Stored transparency for", descendant.Name, "- BG:", descendant.BackgroundTransparency)
			end
		end
	end
	
	-- Store mainFrame properties
	originalProperties.mainFrame = {
		size = mainFrame.Size,
		position = mainFrame.Position,
		visible = mainFrame.Visible
	}
	
	debugPrint("Stored", #originalTransparencies, "element transparencies")
end

-- Initialize by storing transparencies
storeOriginalTransparencies()

-- Hide shop initially
mainFrame.Visible = false
debugPrint("Shop hidden initially")

-- Button hover effects (simplified to avoid issues)
local function setupButtonHoverEffect(button)
	if not button then 
		debugPrint("Warning: Tried to setup hover for nil button")
		return 
	end
	
	local originalSize = button.Size
	
	button.MouseEnter:Connect(function()
		if not isAnimating then
			button.Size = UDim2.new(
				originalSize.X.Scale * 1.05,
				originalSize.X.Offset,
				originalSize.Y.Scale * 1.05,
				originalSize.Y.Offset
			)
		end
	end)
	
	button.MouseLeave:Connect(function()
		button.Size = originalSize
	end)
	
	debugPrint("Setup hover effect for button:", button.Name)
end

-- Open shop animation (FIXED)
local function openShop()
	if isOpen or isAnimating then 
		debugPrint("Shop already open or animating, returning")
		return 
	end
	
	isAnimating = true
	debugPrint("Opening shop...")
	
	-- Setup for animation
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	
	-- Make contents initially transparent (but keep UI structure)
	for descendant, transparencies in pairs(originalTransparencies) do
		if descendant and descendant.Parent then
			-- Set to fully transparent
			descendant.BackgroundTransparency = 1
			
			if transparencies.TextTransparency ~= nil then
				descendant.TextTransparency = 1
			end
			
			if transparencies.ImageTransparency ~= nil then
				descendant.ImageTransparency = 1
			end
			
			if transparencies.ScrollBarImageTransparency ~= nil then
				descendant.ScrollBarImageTransparency = 1
			end
		end
	end
	
	debugPrint("Set all elements to transparent")
	
	-- Animate main frame scaling up
	local openTween = TweenService:Create(mainFrame, BOUNCE_TWEEN, {
		Size = originalProperties.mainFrame.size
	})
	
	openTween:Play()
	debugPrint("Started main frame scale animation")
	
	-- Fade in contents after frame opens
	openTween.Completed:Connect(function()
		debugPrint("Main frame animation complete, fading in contents...")
		
		-- Restore all original transparencies
		for descendant, transparencies in pairs(originalTransparencies) do
			if descendant and descendant.Parent then
				-- Create tweens to restore original transparency
				local props = {}
				
				-- Only add properties that need to be changed
				if transparencies.BackgroundTransparency ~= nil then
					props.BackgroundTransparency = transparencies.BackgroundTransparency
				end
				
				-- Create and play the tween if there are properties to animate
				if next(props) ~= nil then
					local fadeTween = TweenService:Create(descendant, FAST_TWEEN, props)
					fadeTween:Play()
				end
				
				-- Handle text transparency separately
				if transparencies.TextTransparency ~= nil then
					local textTween = TweenService:Create(descendant, FAST_TWEEN, {
						TextTransparency = transparencies.TextTransparency
					})
					textTween:Play()
				end
				
				-- Handle image transparency
				if transparencies.ImageTransparency ~= nil then
					local imageTween = TweenService:Create(descendant, FAST_TWEEN, {
						ImageTransparency = transparencies.ImageTransparency
					})
					imageTween:Play()
				end
				
				-- Handle scrollbar
				if transparencies.ScrollBarImageTransparency ~= nil then
					local scrollTween = TweenService:Create(descendant, FAST_TWEEN, {
						ScrollBarImageTransparency = transparencies.ScrollBarImageTransparency
					})
					scrollTween:Play()
				end
			end
		end
		
		wait(FAST_TWEEN.Time)
		
		isOpen = true
		isAnimating = false
		debugPrint("Shop fully opened")
		
		-- Test scrolling
		debugPrint("Container CanvasSize:", container.CanvasSize)
		debugPrint("Container AbsoluteSize:", container.AbsoluteSize)
		debugPrint("Container ScrollingEnabled:", container.ScrollingEnabled)
	end)
end

-- Close shop animation (FIXED)
local function closeShop()
	if not isOpen or isAnimating then 
		debugPrint("Shop not open or animating, returning")
		return 
	end
	
	isAnimating = true
	debugPrint("Closing shop...")
	
	-- Stop any playing audio
	if currentPlayingAudio then
		currentPlayingAudio:Stop()
		currentPlayingAudio = nil
	end
	
	-- Fade out contents first
	for descendant, _ in pairs(originalTransparencies) do
		if descendant and descendant.Parent then
			local fadeOut = TweenService:Create(descendant, FAST_TWEEN, {
				BackgroundTransparency = 1
			})
			fadeOut:Play()
			
			if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
				local textFade = TweenService:Create(descendant, FAST_TWEEN, {
					TextTransparency = 1
				})
				textFade:Play()
			end
			
			if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
				local imageFade = TweenService:Create(descendant, FAST_TWEEN, {
					ImageTransparency = 1
				})
				imageFade:Play()
			end
			
			if descendant:IsA("ScrollingFrame") then
				local scrollFade = TweenService:Create(descendant, FAST_TWEEN, {
					ScrollBarImageTransparency = 1
				})
				scrollFade:Play()
			end
		end
	end
	
	-- Wait for fade out then scale down
	wait(FAST_TWEEN.Time)
	
	-- Animate main frame scaling down
	local closeTween = TweenService:Create(mainFrame, SMOOTH_TWEEN, {
		Size = UDim2.new(0, 0, 0, 0)
	})
	
	closeTween:Play()
	debugPrint("Started close animation")
	
	closeTween.Completed:Connect(function()
		mainFrame.Visible = false
		isOpen = false
		isAnimating = false
		debugPrint("Shop fully closed")
	end)
end

-- Setup gamepass functionality
local function setupGamepassItem(itemFrame, categoryType)
	local buyButton = itemFrame:FindFirstChild("BuyButton")
	local giftButton = itemFrame:FindFirstChild("GiftButton")
	local playButton = itemFrame:FindFirstChild("PlayButton")
	local pauseButton = itemFrame:FindFirstChild("PauseButton")
	
	-- Setup buy button
	if buyButton then
		setupButtonHoverEffect(buyButton)
		
		buyButton.MouseButton1Click:Connect(function()
			debugPrint("Buy button clicked for", itemFrame.Name)
			-- Add your purchase logic here
		end)
	end
	
	-- Setup gift button
	if giftButton then
		setupButtonHoverEffect(giftButton)
		
		giftButton.MouseButton1Click:Connect(function()
			debugPrint("Gift button clicked for", itemFrame.Name)
			-- Add your gift logic here
		end)
	end
	
	-- Setup audio controls
	if playButton and pauseButton then
		setupButtonHoverEffect(playButton)
		setupButtonHoverEffect(pauseButton)
		
		-- Initially hide pause button
		pauseButton.Visible = false
		
		playButton.MouseButton1Click:Connect(function()
			debugPrint("Play button clicked for", itemFrame.Name)
			playButton.Visible = false
			pauseButton.Visible = true
		end)
		
		pauseButton.MouseButton1Click:Connect(function()
			debugPrint("Pause button clicked for", itemFrame.Name)
			playButton.Visible = true
			pauseButton.Visible = false
		end)
	end
end

-- Setup all gamepass items
local function setupAllItems()
	debugPrint("Setting up all shop items...")
	
	-- Setup audio items
	local audioContainer = container:FindFirstChild("GamepassesContainer_Audio")
	if audioContainer then
		debugPrint("Found audio container")
		for _, item in ipairs(audioContainer:GetChildren()) do
			if item:IsA("ImageLabel") and item.Name:match("Gamepass") then
				setupGamepassItem(item, "Audio")
				debugPrint("Setup audio item:", item.Name)
			end
		end
	else
		debugPrint("Audio container not found")
	end
	
	-- Setup card items
	local cardsContainer = container:FindFirstChild("GamepassesContainer_Cards")
	if cardsContainer then
		debugPrint("Found cards container")
		for _, item in ipairs(cardsContainer:GetChildren()) do
			if item:IsA("ImageLabel") and item.Name:match("Gamepass") then
				setupGamepassItem(item, "Cards")
				debugPrint("Setup card item:", item.Name)
			end
		end
	else
		debugPrint("Cards container not found")
	end
end

-- Connect buttons
setupButtonHoverEffect(openButton)
setupButtonHoverEffect(closeButton)

openButton.MouseButton1Click:Connect(function()
	debugPrint("Open button clicked")
	openShop()
end)

closeButton.MouseButton1Click:Connect(function()
	debugPrint("Close button clicked")
	closeShop()
end)

-- Setup all items
setupAllItems()

-- Optional: Keyboard shortcut (P for shop)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.P then
		debugPrint("P key pressed")
		if isOpen then
			closeShop()
		else
			openShop()
		end
	end
end)

print("[Shop] Shop controller initialized! Press 'P' to toggle shop.")
print("[Shop] Debug mode is", DEBUG_MODE and "ON" or "OFF")