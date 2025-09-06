-- ShopController.lua
-- Complete shop functionality with tweening animations
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shop GUI
local shopGui = playerGui:WaitForChild("LimitedStoreGUI")
local mainFrame = shopGui:WaitForChild("MainFrame")
local openButton = shopGui:WaitForChild("OpenShopbtn")

-- Get UI elements
local uiLabel = mainFrame:WaitForChild("UiLabel")
local closeButton = uiLabel:WaitForChild("CloseButton")
local bgFrame = uiLabel:WaitForChild("BGFrame")
local container = bgFrame:WaitForChild("Container")

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

-- Store original properties for animation
local originalProperties = {
	mainFrame = {
		size = mainFrame.Size,
		position = mainFrame.Position,
		visible = mainFrame.Visible
	}
}

-- Hide shop initially
mainFrame.Visible = false

-- Sound effects (optional - create these if you want)
local function playSound(soundId)
	-- You can add sound effects here
	-- Example:
	-- local sound = Instance.new("Sound")
	-- sound.SoundId = soundId
	-- sound.Volume = 0.5
	-- sound.Parent = SoundService
	-- sound:Play()
	-- sound.Ended:Connect(function() sound:Destroy() end)
end

-- Button hover effects
local function setupButtonHoverEffect(button)
	local originalSize = button.Size
	local hoverSize = UDim2.new(
		originalSize.X.Scale * 1.05,
		originalSize.X.Offset,
		originalSize.Y.Scale * 1.05,
		originalSize.Y.Offset
	)
	
	button.MouseEnter:Connect(function()
		if not isAnimating then
			local tween = TweenService:Create(button, FAST_TWEEN, {
				Size = hoverSize
			})
			tween:Play()
		end
	end)
	
	button.MouseLeave:Connect(function()
		local tween = TweenService:Create(button, FAST_TWEEN, {
			Size = originalSize
		})
		tween:Play()
	end)
	
	-- Click effect
	button.MouseButton1Down:Connect(function()
		local clickSize = UDim2.new(
			originalSize.X.Scale * 0.95,
			originalSize.X.Offset,
			originalSize.Y.Scale * 0.95,
			originalSize.Y.Offset
		)
		local tween = TweenService:Create(button, TweenInfo.new(0.1), {
			Size = clickSize
		})
		tween:Play()
	end)
	
	button.MouseButton1Up:Connect(function()
		local tween = TweenService:Create(button, TweenInfo.new(0.1), {
			Size = originalSize
		})
		tween:Play()
	end)
end

-- Open shop animation
local function openShop()
	if isOpen or isAnimating then return end
	isAnimating = true
	
	print("[Shop] Opening shop...")
	
	-- Setup for animation
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	
	-- Make contents initially transparent
	for _, descendant in ipairs(mainFrame:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			descendant.BackgroundTransparency = 1
			if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
				descendant.TextTransparency = 1
			elseif descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
				descendant.ImageTransparency = 1
			end
		end
	end
	
	-- Animate main frame scaling up
	local openTween = TweenService:Create(mainFrame, BOUNCE_TWEEN, {
		Size = originalProperties.mainFrame.size
	})
	
	openTween:Play()
	
	-- Fade in contents after frame opens
	openTween.Completed:Connect(function()
		-- Fade in all elements
		for _, descendant in ipairs(mainFrame:GetDescendants()) do
			if descendant:IsA("GuiObject") then
				-- Store original transparency
				local originalBgTransparency = descendant.BackgroundTransparency
				local originalTextTransparency = nil
				local originalImageTransparency = nil
				
				if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
					originalTextTransparency = descendant.TextTransparency
				elseif descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
					originalImageTransparency = descendant.ImageTransparency
				end
				
				-- Animate fade in
				local fadeIn = TweenService:Create(descendant, FAST_TWEEN, {
					BackgroundTransparency = descendant.Name == "Fade" and 0.5 or 
						(descendant.Name == "GrayFade" and 0.7 or 0)
				})
				fadeIn:Play()
				
				if originalTextTransparency then
					local textFade = TweenService:Create(descendant, FAST_TWEEN, {
						TextTransparency = 0
					})
					textFade:Play()
				end
				
				if originalImageTransparency then
					local imageFade = TweenService:Create(descendant, FAST_TWEEN, {
						ImageTransparency = 0
					})
					imageFade:Play()
				end
			end
		end
		
		isOpen = true
		isAnimating = false
		playSound("rbxasset://sounds/uuhhh.mp3") -- Open sound
	end)
end

-- Close shop animation
local function closeShop()
	if not isOpen or isAnimating then return end
	isAnimating = true
	
	print("[Shop] Closing shop...")
	
	-- Stop any playing audio
	if currentPlayingAudio then
		currentPlayingAudio:Stop()
		currentPlayingAudio = nil
	end
	
	-- Fade out contents first
	for _, descendant in ipairs(mainFrame:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			local fadeOut = TweenService:Create(descendant, FAST_TWEEN, {
				BackgroundTransparency = 1
			})
			fadeOut:Play()
			
			if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
				local textFade = TweenService:Create(descendant, FAST_TWEEN, {
					TextTransparency = 1
				})
				textFade:Play()
			elseif descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
				local imageFade = TweenService:Create(descendant, FAST_TWEEN, {
					ImageTransparency = 1
				})
				imageFade:Play()
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
	
	closeTween.Completed:Connect(function()
		mainFrame.Visible = false
		isOpen = false
		isAnimating = false
		playSound("rbxasset://sounds/swoosh.mp3") -- Close sound
	end)
end

-- Setup gamepass functionality
local function setupGamepassItem(itemFrame, categoryType)
	local buyButton = itemFrame:FindFirstChild("BuyButton")
	local giftButton = itemFrame:FindFirstChild("GiftButton")
	local playButton = itemFrame:FindFirstChild("PlayButton")
	local pauseButton = itemFrame:FindFirstChild("PauseButton")
	local priceLabel = itemFrame:FindFirstChild("Price1")
	
	-- Setup buy button
	if buyButton then
		setupButtonHoverEffect(buyButton)
		
		buyButton.MouseButton1Click:Connect(function()
			print("[Shop] Buy button clicked for", itemFrame.Name)
			-- Add your purchase logic here
			-- Example: MarketplaceService:PromptGamePassPurchase(player, gamepassId)
			
			-- Visual feedback
			local originalColor = buyButton.BackgroundColor3
			buyButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			wait(0.2)
			buyButton.BackgroundColor3 = originalColor
		end)
	end
	
	-- Setup gift button
	if giftButton then
		setupButtonHoverEffect(giftButton)
		
		giftButton.MouseButton1Click:Connect(function()
			print("[Shop] Gift button clicked for", itemFrame.Name)
			-- Add your gift logic here
			
			-- Visual feedback
			local originalColor = giftButton.BackgroundColor3
			giftButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			wait(0.2)
			giftButton.BackgroundColor3 = originalColor
		end)
	end
	
	-- Setup audio controls (for audio items)
	if playButton and pauseButton then
		setupButtonHoverEffect(playButton)
		setupButtonHoverEffect(pauseButton)
		
		-- Initially hide pause button
		pauseButton.Visible = false
		
		playButton.MouseButton1Click:Connect(function()
			print("[Shop] Play button clicked for", itemFrame.Name)
			
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
			
			-- Create and play audio
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://1234567890" -- Replace with actual sound ID
			sound.Volume = 0.5
			sound.Parent = SoundService
			sound:Play()
			
			currentPlayingAudio = sound
			playButton.Visible = false
			pauseButton.Visible = true
			
			sound.Ended:Connect(function()
				playButton.Visible = true
				pauseButton.Visible = false
				sound:Destroy()
				if currentPlayingAudio == sound then
					currentPlayingAudio = nil
				end
			end)
		end)
		
		pauseButton.MouseButton1Click:Connect(function()
			print("[Shop] Pause button clicked for", itemFrame.Name)
			
			if currentPlayingAudio then
				currentPlayingAudio:Pause()
				playButton.Visible = true
				pauseButton.Visible = false
			end
		end)
	end
end

-- Setup all gamepass items
local function setupAllItems()
	-- Setup audio items
	local audioContainer = container:FindFirstChild("GamepassesContainer_Audio")
	if audioContainer then
		for _, item in ipairs(audioContainer:GetChildren()) do
			if item:IsA("ImageLabel") and item.Name:match("Gamepass") then
				setupGamepassItem(item, "Audio")
			end
		end
	end
	
	-- Setup card items
	local cardsContainer = container:FindFirstChild("GamepassesContainer_Cards")
	if cardsContainer then
		for _, item in ipairs(cardsContainer:GetChildren()) do
			if item:IsA("ImageLabel") and item.Name:match("Gamepass") then
				setupGamepassItem(item, "Cards")
			end
		end
	end
end

-- Smooth scroll animation for container
local function setupSmoothScroll()
	local scrolling = false
	local targetPosition = container.CanvasPosition
	
	container:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if not scrolling then
			targetPosition = container.CanvasPosition
		end
	end)
	
	RunService.RenderStepped:Connect(function()
		if container.CanvasPosition ~= targetPosition then
			scrolling = true
			container.CanvasPosition = container.CanvasPosition:Lerp(targetPosition, 0.2)
			
			if (container.CanvasPosition - targetPosition).Magnitude < 1 then
				container.CanvasPosition = targetPosition
				scrolling = false
			end
		end
	end)
end

-- Connect buttons
setupButtonHoverEffect(openButton)
setupButtonHoverEffect(closeButton)

openButton.MouseButton1Click:Connect(openShop)
closeButton.MouseButton1Click:Connect(closeShop)

-- Setup all items
setupAllItems()
setupSmoothScroll()

-- Optional: Keyboard shortcut (P for shop)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.P then
		if isOpen then
			closeShop()
		else
			openShop()
		end
	end
end)

print("[Shop] Shop controller initialized! Press 'P' to toggle shop.")