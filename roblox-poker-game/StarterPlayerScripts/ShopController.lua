-- ShopController.lua
-- Complete shop functionality with smooth slide animations (TOGGLE VERSION)
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

-- Animation settings (SIMPLIFIED)
local SLIDE_TIME = 0.4
local SLIDE_TWEEN = TweenInfo.new(
	SLIDE_TIME,
	Enum.EasingStyle.Quint,  -- Smooth acceleration/deceleration
	Enum.EasingDirection.Out,
	0,
	false,
	0
)

local FAST_TWEEN = TweenInfo.new(
	0.15,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out,
	0,
	false,
	0
)

-- Store original position
local originalPosition = mainFrame.Position
local originalSize = mainFrame.Size

-- Animation style choice (change this to switch animation type)
local ANIMATION_STYLE = "SLIDE_RIGHT" -- Options: "SLIDE_RIGHT", "SLIDE_LEFT", "SLIDE_TOP", "SLIDE_BOTTOM", "SCALE_CENTER"

-- Hide shop initially
mainFrame.Visible = false
debugPrint("Shop hidden initially")

-- Button hover effects
local function setupButtonHoverEffect(button)
	if not button then 
		debugPrint("Warning: Tried to setup hover for nil button")
		return 
	end
	
	local originalButtonSize = button.Size
	local isHovering = false
	
	button.MouseEnter:Connect(function()
		if not isAnimating and not isHovering then
			isHovering = true
			local hoverTween = TweenService:Create(button, FAST_TWEEN, {
				Size = UDim2.new(
					originalButtonSize.X.Scale * 1.05,
					originalButtonSize.X.Offset,
					originalButtonSize.Y.Scale * 1.05,
					originalButtonSize.Y.Offset
				)
			})
			hoverTween:Play()
		end
	end)
	
	button.MouseLeave:Connect(function()
		if isHovering then
			isHovering = false
			local leaveTween = TweenService:Create(button, FAST_TWEEN, {
				Size = originalButtonSize
			})
			leaveTween:Play()
		end
	end)
	
	debugPrint("Setup hover effect for button:", button.Name)
end

-- Open shop animation (SIMPLIFIED - NO FADE)
local function openShop()
	if isOpen or isAnimating then 
		debugPrint("Shop already open or animating, returning")
		return 
	end
	
	isAnimating = true
	debugPrint("Opening shop with style:", ANIMATION_STYLE)
	
	-- Set anchor point for proper animation
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	
	-- Set starting position based on animation style
	if ANIMATION_STYLE == "SLIDE_RIGHT" then
		-- Start from left side of screen
		mainFrame.Position = UDim2.new(-0.5, 0, 0.5, 0)
		mainFrame.Size = originalSize
		
	elseif ANIMATION_STYLE == "SLIDE_LEFT" then
		-- Start from right side of screen
		mainFrame.Position = UDim2.new(1.5, 0, 0.5, 0)
		mainFrame.Size = originalSize
		
	elseif ANIMATION_STYLE == "SLIDE_TOP" then
		-- Start from bottom of screen
		mainFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
		mainFrame.Size = originalSize
		
	elseif ANIMATION_STYLE == "SLIDE_BOTTOM" then
		-- Start from top of screen
		mainFrame.Position = UDim2.new(0.5, 0, -0.5, 0)
		mainFrame.Size = originalSize
		
	elseif ANIMATION_STYLE == "SCALE_CENTER" then
		-- Start scaled down in center
		mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
	end
	
	-- Make visible
	mainFrame.Visible = true
	
	-- Animate to final position
	local openTween
	if ANIMATION_STYLE == "SCALE_CENTER" then
		openTween = TweenService:Create(mainFrame, SLIDE_TWEEN, {
			Size = originalSize
		})
	else
		openTween = TweenService:Create(mainFrame, SLIDE_TWEEN, {
			Position = UDim2.new(0.5, 0, 0.5, 0)
		})
	end
	
	openTween:Play()
	debugPrint("Started open animation")
	
	openTween.Completed:Connect(function()
		isOpen = true
		isAnimating = false
		debugPrint("Shop fully opened")
		
		-- Debug scrolling info
		debugPrint("Container CanvasSize:", container.CanvasSize)
		debugPrint("Container AbsoluteSize:", container.AbsoluteSize)
		debugPrint("Container ScrollingEnabled:", container.ScrollingEnabled)
		debugPrint("Container ScrollBarThickness:", container.ScrollBarThickness)
	end)
end

-- Close shop animation (SIMPLIFIED - NO FADE)
local function closeShop()
	if not isOpen or isAnimating then 
		debugPrint("Shop not open or animating, returning")
		return 
	end
	
	isAnimating = true
	debugPrint("Closing shop with style:", ANIMATION_STYLE)
	
	-- Stop any playing audio
	if currentPlayingAudio then
		currentPlayingAudio:Stop()
		currentPlayingAudio = nil
	end
	
	-- Determine end position based on animation style
	local endPosition
	local endSize = originalSize
	
	if ANIMATION_STYLE == "SLIDE_RIGHT" then
		-- Exit to right side
		endPosition = UDim2.new(1.5, 0, 0.5, 0)
		
	elseif ANIMATION_STYLE == "SLIDE_LEFT" then
		-- Exit to left side
		endPosition = UDim2.new(-0.5, 0, 0.5, 0)
		
	elseif ANIMATION_STYLE == "SLIDE_TOP" then
		-- Exit to top
		endPosition = UDim2.new(0.5, 0, -0.5, 0)
		
	elseif ANIMATION_STYLE == "SLIDE_BOTTOM" then
		-- Exit to bottom
		endPosition = UDim2.new(0.5, 0, 1.5, 0)
		
	elseif ANIMATION_STYLE == "SCALE_CENTER" then
		-- Scale down in center
		endPosition = UDim2.new(0.5, 0, 0.5, 0)
		endSize = UDim2.new(0, 0, 0, 0)
	end
	
	-- Animate close
	local closeTween
	if ANIMATION_STYLE == "SCALE_CENTER" then
		closeTween = TweenService:Create(mainFrame, SLIDE_TWEEN, {
			Size = endSize
		})
	else
		closeTween = TweenService:Create(mainFrame, SLIDE_TWEEN, {
			Position = endPosition
		})
	end
	
	closeTween:Play()
	debugPrint("Started close animation")
	
	closeTween.Completed:Connect(function()
		mainFrame.Visible = false
		isOpen = false
		isAnimating = false
		debugPrint("Shop fully closed")
	end)
end

-- Toggle shop (open if closed, close if open)
local function toggleShop()
	if isAnimating then
		debugPrint("Shop is animating, cannot toggle")
		return
	end
	
	if isOpen then
		debugPrint("Toggling shop: closing")
		closeShop()
	else
		debugPrint("Toggling shop: opening")
		openShop()
	end
end

-- Setup gamepass functionality
local function setupGamepassItem(itemFrame, categoryType)
	local buyButton = itemFrame:FindFirstChild("BuyButton")
	local giftButton = itemFrame:FindFirstChild("GiftButton")
	local playButton = itemFrame:FindFirstChild("PlayButton")
	local pauseButton = itemFrame:FindFirstChild("PauseButton")
	
	debugPrint("Setting up gamepass:", itemFrame.Name, "Category:", categoryType)
	
	-- Setup buy button
	if buyButton then
		setupButtonHoverEffect(buyButton)
		
		buyButton.MouseButton1Click:Connect(function()
			debugPrint("Buy button clicked for", itemFrame.Name)
			-- Visual feedback
			local originalColor = buyButton.BackgroundColor3
			buyButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			task.wait(0.2)
			buyButton.BackgroundColor3 = originalColor
			
			-- Add your purchase logic here
			-- Example: MarketplaceService:PromptGamePassPurchase(player, gamepassId)
		end)
	end
	
	-- Setup gift button
	if giftButton then
		setupButtonHoverEffect(giftButton)
		
		giftButton.MouseButton1Click:Connect(function()
			debugPrint("Gift button clicked for", itemFrame.Name)
			-- Visual feedback
			local originalColor = giftButton.BackgroundColor3
			giftButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			task.wait(0.2)
			giftButton.BackgroundColor3 = originalColor
			
			-- Add your gift logic here
		end)
	end
	
	-- Setup audio controls
	if categoryType == "Audio" and playButton and pauseButton then
		setupButtonHoverEffect(playButton)
		setupButtonHoverEffect(pauseButton)
		
		-- Initially hide pause button
		pauseButton.Visible = false
		
		playButton.MouseButton1Click:Connect(function()
			debugPrint("Play button clicked for", itemFrame.Name)
			
			-- Stop any other playing audio
			if currentPlayingAudio then
				currentPlayingAudio:Stop()
				-- Reset all pause/play buttons
				for _, audioContainer in ipairs(container:GetChildren()) do
					if audioContainer.Name == "GamepassesContainer_Audio" then
						for _, gamepass in ipairs(audioContainer:GetChildren()) do
							if gamepass:IsA("ImageLabel") then
								local play = gamepass:FindFirstChild("PlayButton")
								local pause = gamepass:FindFirstChild("PauseButton")
								if play then play.Visible = true end
								if pause then pause.Visible = false end
							end
						end
					end
				end
			end
			
			playButton.Visible = false
			pauseButton.Visible = true
			
			-- Audio playback code here
		end)
		
		pauseButton.MouseButton1Click:Connect(function()
			debugPrint("Pause button clicked for", itemFrame.Name)
			
			if currentPlayingAudio then
				currentPlayingAudio:Pause()
			end
			
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
			end
		end
	end
	
	-- Setup card items
	local cardsContainer = container:FindFirstChild("GamepassesContainer_Cards")
	if cardsContainer then
		debugPrint("Found cards container")
		for _, item in ipairs(cardsContainer:GetChildren()) do
			if item:IsA("ImageLabel") and item.Name:match("Gamepass") then
				setupGamepassItem(item, "Cards")
			end
		end
	end
end

-- Connect main buttons
debugPrint("Setting up main buttons...")

-- Setup open button (NOW TOGGLES)
setupButtonHoverEffect(openButton)
openButton.MouseButton1Click:Connect(function()
	debugPrint("Open/Toggle button clicked - Current state:", isOpen and "open" or "closed")
	toggleShop()
end)

-- Setup close button (still just closes)
setupButtonHoverEffect(closeButton)
closeButton.MouseButton1Click:Connect(function()
	debugPrint("Close button clicked")
	closeShop()
end)

-- Setup all items
setupAllItems()

-- Optional: Keyboard shortcut (P for shop - also toggles)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.P then
		debugPrint("P key pressed - toggling shop")
		toggleShop()
	end
end)

print("[Shop] Shop controller initialized! Press 'P' or click shop button to toggle.")
print("[Shop] Animation style:", ANIMATION_STYLE)
print("[Shop] Debug mode is", DEBUG_MODE and "ON" or "OFF")
print("[Shop] Shop button now TOGGLES the shop (opens/closes)")