-- ShopController.lua
-- Complete shop functionality with tweening animations (FULLY FIXED VERSION)
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

-- Store original properties for ALL elements (FIXED - no GetDebugId)
local originalTransparencies = {}
local originalProperties = {}
local elementCounter = 0

-- Function to store original transparencies
local function storeOriginalTransparencies()
	debugPrint("Storing original transparencies...")
	
	for _, descendant in ipairs(mainFrame:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			-- Use a unique key based on hierarchy instead of GetDebugId
			elementCounter = elementCounter + 1
			local key = tostring(elementCounter) .. "_" .. descendant.Name .. "_" .. descendant.ClassName
			
			originalTransparencies[descendant] = {
				BackgroundTransparency = descendant.BackgroundTransparency,
				TextTransparency = nil,
				ImageTransparency = nil,
				TextStrokeTransparency = nil,
				ScrollBarImageTransparency = nil
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
			if descendant.Name == "Container" or descendant.Name == "BGFrame" or descendant.Name == "CloseButton" then
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
	
	-- Count stored elements
	local count = 0
	for _ in pairs(originalTransparencies) do
		count = count + 1
	end
	
	debugPrint("Stored", count, "element transparencies")
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
	local isHovering = false
	
	local hoverConnection = button.MouseEnter:Connect(function()
		if not isAnimating and not isHovering then
			isHovering = true
			local hoverTween = TweenService:Create(button, TweenInfo.new(0.1), {
				Size = UDim2.new(
					originalSize.X.Scale * 1.05,
					originalSize.X.Offset,
					originalSize.Y.Scale * 1.05,
					originalSize.Y.Offset
				)
			})
			hoverTween:Play()
		end
	end)
	
	local leaveConnection = button.MouseLeave:Connect(function()
		if isHovering then
			isHovering = false
			local leaveTween = TweenService:Create(button, TweenInfo.new(0.1), {
				Size = originalSize
			})
			leaveTween:Play()
		end
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
		
		task.wait(FAST_TWEEN.Time)
		
		isOpen = true
		isAnimating = false
		debugPrint("Shop fully opened")
		
		-- Test scrolling
		debugPrint("Container CanvasSize:", container.CanvasSize)
		debugPrint("Container AbsoluteSize:", container.AbsoluteSize)
		debugPrint("Container ScrollingEnabled:", container.ScrollingEnabled)
		debugPrint("Container ScrollBarThickness:", container.ScrollBarThickness)
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
	task.wait(FAST_TWEEN.Time)
	
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
	else
		debugPrint("No buy button found for", itemFrame.Name)
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
	else
		debugPrint("No gift button found for", itemFrame.Name)
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
			
			-- Create and play audio (replace with actual sound ID)
			--[[
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://1234567890" -- Replace with actual sound ID
			sound.Volume = 0.5
			sound.Parent = SoundService
			sound:Play()
			
			currentPlayingAudio = sound
			
			sound.Ended:Connect(function()
				playButton.Visible = true
				pauseButton.Visible = false
				sound:Destroy()
				if currentPlayingAudio == sound then
					currentPlayingAudio = nil
				end
			end)
			--]]
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
		debugPrint("Found audio container with", #audioContainer:GetChildren(), "children")
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
		debugPrint("Found cards container with", #cardsContainer:GetChildren(), "children")
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

-- Connect main buttons
debugPrint("Setting up main buttons...")

-- Setup open button
setupButtonHoverEffect(openButton)
openButton.MouseButton1Click:Connect(function()
	debugPrint("Open button clicked")
	openShop()
end)

-- Setup close button
setupButtonHoverEffect(closeButton)
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
print("[Shop] Open button found:", openButton and "YES" or "NO")
print("[Shop] Close button found:", closeButton and "YES" or "NO")