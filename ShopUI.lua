-- Shop UI - Client Script
-- Place this as a LocalScript in StarterPlayer > StarterPlayerScripts
-- Handles shop display and gamepass purchases

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[SHOP] Loading Shop UI...")

-- ==================== CONFIGURATION ====================

-- Placeholder gamepass data (replace with real IDs later)
local GAMEPASSES = {
	{
		id = 0, -- Replace with real gamepass ID
		name = "VIP Pass",
		description = "Access to VIP perks and exclusive benefits",
		price = 299,
		icon = "rbxassetid://0" -- Placeholder icon
	},
	{
		id = 0,
		name = "2x Wins",
		description = "Double win rewards for every victory",
		price = 199,
		icon = "rbxassetid://0"
	},
	{
		id = 0,
		name = "Speed Boost",
		description = "Move 25% faster during rounds",
		price = 149,
		icon = "rbxassetid://0"
	},
	{
		id = 0,
		name = "Glow Effect",
		description = "Stand out with a special glow effect",
		price = 99,
		icon = "rbxassetid://0"
	}
}

-- ==================== UI CREATION ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

-- Shop Button (left side, middle-ish)
local shopButton = Instance.new("TextButton")
shopButton.Name = "ShopButton"
shopButton.AnchorPoint = Vector2.new(0, 0.5)
shopButton.Position = UDim2.new(0, 15, 0.45, 0)
shopButton.Size = UDim2.new(0, 90, 0, 90)
shopButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
shopButton.BackgroundTransparency = 0.05
shopButton.BorderSizePixel = 0
shopButton.Font = Enum.Font.GothamBold
shopButton.Text = ""
shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopButton.TextSize = 18
shopButton.AutoButtonColor = false
shopButton.Parent = screenGui

local buttonScale = Instance.new("UIScale")
buttonScale.Parent = shopButton

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0.25, 0)
buttonCorner.Parent = shopButton

local buttonStroke = Instance.new("UIStroke")
buttonStroke.Color = Color3.fromRGB(200, 220, 255)
buttonStroke.Thickness = 3
buttonStroke.Transparency = 0.2
buttonStroke.Parent = shopButton

local buttonGradient = Instance.new("UIGradient")
buttonGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 130, 235))
})
buttonGradient.Rotation = 45
buttonGradient.Parent = shopButton

-- Shop icon/text
local shopIcon = Instance.new("TextLabel")
shopIcon.Size = UDim2.new(1, 0, 0.5, 0)
shopIcon.Position = UDim2.new(0, 0, 0, 8)
shopIcon.BackgroundTransparency = 1
shopIcon.Font = Enum.Font.GothamBold
shopIcon.Text = "??"
shopIcon.TextSize = 36
shopIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
shopIcon.Parent = shopButton

local shopText = Instance.new("TextLabel")
shopText.Size = UDim2.new(1, 0, 0.35, 0)
shopText.Position = UDim2.new(0, 0, 0.6, 0)
shopText.BackgroundTransparency = 1
shopText.Font = Enum.Font.GothamBold
shopText.Text = "SHOP"
shopText.TextSize = 16
shopText.TextColor3 = Color3.fromRGB(255, 255, 255)
shopText.Parent = shopButton

-- Shop Frame (main container)
local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
shopFrame.Size = UDim2.new(0, 700, 0, 500)
shopFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
shopFrame.BackgroundTransparency = 0.1
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.Parent = screenGui

local shopScale = Instance.new("UIScale")
shopScale.Parent = shopFrame

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 15)
shopCorner.Parent = shopFrame

local shopStroke = Instance.new("UIStroke")
shopStroke.Color = Color3.fromRGB(100, 150, 255)
shopStroke.Thickness = 2
shopStroke.Transparency = 0.4
shopStroke.Parent = shopFrame

-- Removed dim background as per user request

-- Shop Header
local shopHeader = Instance.new("Frame")
shopHeader.Name = "Header"
shopHeader.Size = UDim2.new(1, 0, 0, 60)
shopHeader.Position = UDim2.new(0, 0, 0, 0)
shopHeader.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
shopHeader.BackgroundTransparency = 0.3
shopHeader.BorderSizePixel = 0
shopHeader.Parent = shopFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 15)
headerCorner.Parent = shopHeader

-- Fix corner by adding a cover
local headerCover = Instance.new("Frame")
headerCover.Size = UDim2.new(1, 0, 0, 30)
headerCover.Position = UDim2.new(0, 0, 1, -30)
headerCover.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
headerCover.BackgroundTransparency = 0.3
headerCover.BorderSizePixel = 0
headerCover.Parent = shopHeader

local shopTitle = Instance.new("TextLabel")
shopTitle.Name = "Title"
shopTitle.Size = UDim2.new(1, -120, 1, 0)
shopTitle.Position = UDim2.new(0, 20, 0, 0)
shopTitle.BackgroundTransparency = 1
shopTitle.Font = Enum.Font.GothamBold
shopTitle.Text = "SHOP"
shopTitle.TextColor3 = Color3.fromRGB(100, 180, 255)
shopTitle.TextSize = 28
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.Parent = shopHeader

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -15, 0.5, 0)
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeButton.BackgroundTransparency = 0.1
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 20
closeButton.AutoButtonColor = false
closeButton.Parent = shopHeader

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0.25, 0)
closeCorner.Parent = closeButton

-- Scrolling Frame for items
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ItemsScroll"
scrollFrame.Position = UDim2.new(0, 15, 0, 75)
scrollFrame.Size = UDim2.new(1, -30, 1, -90)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = shopFrame

local scrollLayout = Instance.new("UIGridLayout")
scrollLayout.CellPadding = UDim2.new(0, 15, 0, 15)
scrollLayout.CellSize = UDim2.new(0, 320, 0, 180)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
scrollLayout.Parent = scrollFrame

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingTop = UDim.new(0, 5)
scrollPadding.PaddingBottom = UDim.new(0, 5)
scrollPadding.Parent = scrollFrame

-- ==================== CREATE GAMEPASS CARDS ====================

local function createGamepassCard(data, index)
	local card = Instance.new("Frame")
	card.Name = "GamepassCard_" .. index
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	card.BackgroundTransparency = 0.2
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.Parent = scrollFrame
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(80, 120, 200)
	cardStroke.Thickness = 1.5
	cardStroke.Transparency = 0.5
	cardStroke.Parent = card
	
	-- Icon placeholder
	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "Icon"
	iconFrame.Position = UDim2.new(0, 12, 0, 12)
	iconFrame.Size = UDim2.new(0, 60, 0, 60)
	iconFrame.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
	iconFrame.BackgroundTransparency = 0.3
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = card
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0.2, 0)
	iconCorner.Parent = iconFrame
	
	-- Item Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ItemName"
	nameLabel.Position = UDim2.new(0, 82, 0, 12)
	nameLabel.Size = UDim2.new(1, -92, 0, 25)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = data.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card
	
	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Position = UDim2.new(0, 82, 0, 38)
	descLabel.Size = UDim2.new(1, -92, 0, 34)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.Text = data.description
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	descLabel.TextSize = 13
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.TextWrapped = true
	descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	descLabel.Parent = card
	
	-- Divider line
	local divider = Instance.new("Frame")
	divider.Position = UDim2.new(0, 12, 0, 85)
	divider.Size = UDim2.new(1, -24, 0, 1)
	divider.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
	divider.BackgroundTransparency = 0.7
	divider.BorderSizePixel = 0
	divider.Parent = card
	
	-- Price label
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Position = UDim2.new(0, 12, 0, 95)
	priceLabel.Size = UDim2.new(0.5, -12, 0, 30)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Text = data.price .. " R$"
	priceLabel.TextColor3 = Color3.fromRGB(120, 200, 120)
	priceLabel.TextSize = 20
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Parent = card
	
	-- Buy Button
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Position = UDim2.new(0, 12, 0, 135)
	buyButton.Size = UDim2.new(1, -24, 0, 35)
	buyButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
	buyButton.BackgroundTransparency = 0.1
	buyButton.BorderSizePixel = 0
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Text = "PURCHASE"
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.TextSize = 16
	buyButton.AutoButtonColor = false
	buyButton.Parent = card
	
	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 8)
	buyCorner.Parent = buyButton
	
	-- Button hover effect
	buyButton.MouseEnter:Connect(function()
		local hoverTween = TweenService:Create(
			buyButton,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(120, 170, 255)}
		)
		hoverTween:Play()
	end)
	
	buyButton.MouseLeave:Connect(function()
		local leaveTween = TweenService:Create(
			buyButton,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(100, 150, 255)}
		)
		leaveTween:Play()
	end)
	
	-- Purchase logic
	buyButton.MouseButton1Click:Connect(function()
		if data.id == 0 then
			warn("[SHOP] Placeholder gamepass - replace with real ID!")
			-- Show notification
			return
		end
		
		-- Attempt purchase
		local success, errorMsg = pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, data.id)
		end)
		
		if not success then
			warn("[SHOP] Failed to prompt purchase:", errorMsg)
		end
	end)
	
	return card
end

-- Create all gamepass cards
for i, gamepass in ipairs(GAMEPASSES) do
	createGamepassCard(gamepass, i)
end

-- ==================== MOBILE SCALING ====================

local function updateUIScale()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local baseScale = math.min(viewportSize.X / 1920, viewportSize.Y / 1080)
	local scale = math.clamp(baseScale, 0.85, 1.3)
	
	buttonScale.Scale = scale
	shopScale.Scale = scale
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale)
updateUIScale()

-- ==================== SHOP OPEN/CLOSE LOGIC ====================

local shopOpen = false

local function openShop()
	if shopOpen then return end
	shopOpen = true
	
	-- Show frame
	shopFrame.Visible = true
	
	-- Reset scale for animation
	shopFrame.Size = UDim2.new(0, 0, 0, 0)
	
	-- Animate shop frame opening (bounce effect)
	local openTween = TweenService:Create(
		shopFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 700, 0, 500)}
	)
	openTween:Play()
	
	-- Button press effect
	local buttonTween = TweenService:Create(
		shopButton,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 85, 0, 85)}
	)
	buttonTween:Play()
	
	-- Rotate button slightly
	local rotateTween = TweenService:Create(
		shopButton,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Rotation = 5}
	)
	rotateTween:Play()
end

local function closeShop()
	if not shopOpen then return end
	shopOpen = false
	
	-- Animate shop frame closing
	local closeTween = TweenService:Create(
		shopFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Size = UDim2.new(0, 0, 0, 0)}
	)
	closeTween:Play()
	
	closeTween.Completed:Connect(function()
		shopFrame.Visible = false
	end)
	
	-- Button reset
	local buttonTween = TweenService:Create(
		shopButton,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 90, 0, 90), Rotation = 0}
	)
	buttonTween:Play()
end

-- Button click handlers
shopButton.MouseButton1Click:Connect(function()
	if shopOpen then
		closeShop()
	else
		openShop()
	end
end)

closeButton.MouseButton1Click:Connect(function()
	closeShop()
end)

-- Shop button hover effect
shopButton.MouseEnter:Connect(function()
	if not shopOpen then
		local hoverTween = TweenService:Create(
			shopButton,
			TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 95, 0, 95)}
		)
		hoverTween:Play()
		
		-- Slight rotation on hover
		local rotateTween = TweenService:Create(
			shopButton,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Rotation = -3}
		)
		rotateTween:Play()
	end
end)

shopButton.MouseLeave:Connect(function()
	if not shopOpen then
		local leaveTween = TweenService:Create(
			shopButton,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 90, 0, 90), Rotation = 0}
		)
		leaveTween:Play()
	end
end)

-- Close button hover
closeButton.MouseEnter:Connect(function()
	local hoverTween = TweenService:Create(
		closeButton,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundColor3 = Color3.fromRGB(255, 100, 100)}
	)
	hoverTween:Play()
end)

closeButton.MouseLeave:Connect(function()
	local leaveTween = TweenService:Create(
		closeButton,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundColor3 = Color3.fromRGB(255, 80, 80)}
	)
	leaveTween:Play()
end)

print("========================================")
print("Shop UI Ready!")
print("Total Gamepasses:", #GAMEPASSES)
print("========================================")
