--[[
	INVENTORY UI SYSTEM
	Place this LocalScript in StarterPlayerScripts
	
	Features:
	- Shows all unlocked swords in a grid layout
	- Click to equip swords
	- Hover effects and visual feedback
	- Green outline for equipped sword
	- Same aesthetic as crate opening UI
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load modules
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local SwordConfig = require(modulesFolder:WaitForChild("SwordConfig"))

-- Load folders
local vfModelsFolder = ReplicatedStorage:WaitForChild("VFmodels")

-- Get RemoteEvent for sword switching
local swordRemotes = ReplicatedStorage:WaitForChild("SwordRemotes")
local switchSwordRemote = swordRemotes:WaitForChild("SwitchSword")

-- Get inventory remotes
local inventoryRemotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local getInventoryRemote = inventoryRemotes:WaitForChild("GetInventory")
local inventoryUpdatedRemote = inventoryRemotes:WaitForChild("InventoryUpdated")

-- ========================================
-- UI SETTINGS
-- ========================================

local UI_SETTINGS = {
	-- Colors (dark minimalist theme)
	BackgroundColor = Color3.fromRGB(15, 15, 20),
	BackgroundTransparency = 0.2, -- Less transparent for main UI

	CardBackgroundColor = Color3.fromRGB(25, 25, 35),
	CardBackgroundTransparency = 0.15,

	TextColor = Color3.fromRGB(220, 220, 230),
	BorderColor = Color3.fromRGB(60, 60, 70), -- Subtle border
	EquippedColor = Color3.fromRGB(80, 255, 120), -- Green for equipped

	-- Sizes
	CardWidth = 180,
	CardHeight = 220,
	CardSpacing = 15,
	CardsPerRow = 3,

	-- ViewportFrame
	ViewportSize = 140,
	CameraDistance = 0.9,
	ModelRotation = 20,

	-- Corner radius
	CornerRadius = 10,

	-- Hover effect
	HoverBrightness = 1.2,
	DefaultBrightness = 0.8,
}

-- ========================================
-- VARIABLES
-- ========================================

local inventoryGui = nil
local isInventoryOpen = false
local currentEquippedSword = SwordConfig.DefaultSword
local cardFrames = {} -- Store all card frames for updating
local ownedSwords = {} -- Store which swords the player owns

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Format sword name for display
local function formatSwordName(swordName)
	local formatted = swordName:gsub("Sword$", "")
	formatted = formatted:gsub("(%u)", " %1"):gsub("^%s+", "")
	return formatted
end

-- Setup ViewportFrame camera (same as crate UI)
local function setupViewportCamera(viewport, model)
	local camera = Instance.new("Camera")
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local modelCFrame, modelSize

	if model:IsA("Model") then
		modelCFrame, modelSize = model:GetBoundingBox()
	elseif model:IsA("BasePart") then
		modelCFrame = model.CFrame
		modelSize = model.Size
	else
		warn("Unknown model type: " .. model.ClassName)
		return
	end

	local maxDimension = math.max(modelSize.X, modelSize.Y, modelSize.Z)
	local distance = maxDimension * UI_SETTINGS.CameraDistance

	local cameraAngle = CFrame.Angles(math.rad(-15), math.rad(UI_SETTINGS.ModelRotation), 0)
	camera.CFrame = CFrame.new(modelCFrame.Position) * cameraAngle * CFrame.new(0, 0, distance)
	camera.CFrame = CFrame.new(camera.CFrame.Position, modelCFrame.Position)

	if model:IsA("Model") then
		model:PivotTo(modelCFrame * CFrame.Angles(0, math.rad(45), 0))
	elseif model:IsA("BasePart") then
		model.CFrame = modelCFrame * CFrame.Angles(0, math.rad(45), 0)
	end
end

-- Update equipped outline for all cards
local function updateEquippedStates()
	for swordName, cardData in pairs(cardFrames) do
		local isEquipped = (swordName == currentEquippedSword)
		local stroke = cardData.frame:FindFirstChild("BorderStroke")

		if stroke then
			if isEquipped then
				-- Green outline for equipped
				TweenService:Create(stroke, TweenInfo.new(0.3), {
					Color = UI_SETTINGS.EquippedColor,
					Thickness = 3,
					Transparency = 0
				}):Play()
			else
				-- Default subtle outline
				TweenService:Create(stroke, TweenInfo.new(0.3), {
					Color = UI_SETTINGS.BorderColor,
					Thickness = 1.5,
					Transparency = 0.5
				}):Play()
			end
		end
	end
end

-- ========================================
-- CARD CREATION
-- ========================================

-- Create a sword card
local function createSwordCard(swordName, config)
	-- Main card frame
	local cardFrame = Instance.new("TextButton")
	cardFrame.Name = "Card_" .. swordName
	cardFrame.Size = UDim2.new(0, UI_SETTINGS.CardWidth, 0, UI_SETTINGS.CardHeight)
	cardFrame.BackgroundColor3 = UI_SETTINGS.CardBackgroundColor
	cardFrame.BackgroundTransparency = UI_SETTINGS.CardBackgroundTransparency
	cardFrame.BorderSizePixel = 0
	cardFrame.AutoButtonColor = false
	cardFrame.Text = ""

	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UI_SETTINGS.CornerRadius)
	corner.Parent = cardFrame

	-- Border stroke
	local stroke = Instance.new("UIStroke")
	stroke.Name = "BorderStroke"
	stroke.Color = UI_SETTINGS.BorderColor
	stroke.Thickness = 1.5
	stroke.Transparency = 0.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = cardFrame

	-- Get rarity info
	local rarity = config.Rarity or "Common"
	local rarityData = SwordConfig.Rarities[rarity]
	local rarityColor = rarityData and rarityData.Color or Color3.fromRGB(150, 150, 150)

	-- Image overlay (subtle background texture like crate UI)
	local imageOverlay = Instance.new("ImageLabel")
	imageOverlay.Name = "ImageOverlay"
	imageOverlay.Size = UDim2.new(1, 0, 1, 0)
	imageOverlay.Position = UDim2.new(0, 0, 0, 0)
	imageOverlay.BackgroundTransparency = 1
	imageOverlay.Image = "rbxassetid://126037341070816"
	imageOverlay.ImageTransparency = 0.85 -- Subtle transparency
	imageOverlay.ScaleType = Enum.ScaleType.Crop
	imageOverlay.ZIndex = 1 -- Behind other elements
	imageOverlay.Parent = cardFrame

	-- Corner radius for overlay to match frame
	local overlayCorner = Instance.new("UICorner")
	overlayCorner.CornerRadius = UDim.new(0, UI_SETTINGS.CornerRadius)
	overlayCorner.Parent = imageOverlay

	-- Gradient effect on overlay for extra depth
	local overlayGradient = Instance.new("UIGradient")
	overlayGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), -- Top: lighter
		ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150))  -- Bottom: darker
	})
	overlayGradient.Rotation = 90 -- Vertical gradient
	overlayGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3), -- Top: more visible
		NumberSequenceKeypoint.new(1, 0.6)  -- Bottom: more transparent
	})
	overlayGradient.Parent = imageOverlay

	-- Subtle rarity gradient (darker, more subtle than crate UI)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rarityColor),
		ColorSequenceKeypoint.new(1, Color3.new(rarityColor.R * 0.3, rarityColor.G * 0.3, rarityColor.B * 0.3))
	})
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7), -- Very transparent
		NumberSequenceKeypoint.new(1, 0.5)
	})
	gradient.Parent = cardFrame

	-- ViewportFrame for 3D model
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Viewport"
	viewport.Size = UDim2.new(0, UI_SETTINGS.ViewportSize, 0, UI_SETTINGS.ViewportSize)
	viewport.Position = UDim2.new(0.5, -UI_SETTINGS.ViewportSize/2, 0, 10)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.Parent = cardFrame

	-- Load 3D model
	local modelName = swordName .. "VF"
	local modelTemplate = vfModelsFolder:FindFirstChild(modelName)

	if modelTemplate then
		local model = modelTemplate:Clone()
		model.Parent = viewport
		setupViewportCamera(viewport, model)
	else
		-- Fallback text if model not found
		local warningLabel = Instance.new("TextLabel")
		warningLabel.Size = UDim2.new(1, 0, 1, 0)
		warningLabel.BackgroundTransparency = 1
		warningLabel.Text = "Model\nNot Found"
		warningLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		warningLabel.TextSize = 14
		warningLabel.Font = Enum.Font.GothamBold
		warningLabel.TextWrapped = true
		warningLabel.Parent = viewport
		warn("VF Model not found: " .. modelName)
	end

	-- Name background (bottom section)
	local nameBackground = Instance.new("Frame")
	nameBackground.Name = "NameBackground"
	nameBackground.Size = UDim2.new(1, 0, 0, 40)
	nameBackground.Position = UDim2.new(0, 0, 1, -40)
	nameBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	nameBackground.BackgroundTransparency = 0.7
	nameBackground.BorderSizePixel = 0
	nameBackground.Parent = cardFrame

	local nameCorner = Instance.new("UICorner")
	nameCorner.CornerRadius = UDim.new(0, UI_SETTINGS.CornerRadius)
	nameCorner.Parent = nameBackground

	-- Sword name text
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 1, 0)
	nameLabel.Position = UDim2.new(0, 5, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = formatSwordName(swordName)
	nameLabel.TextColor3 = UI_SETTINGS.TextColor
	nameLabel.TextSize = 15
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.Parent = nameBackground

	-- Rarity indicator (small text in top-right)
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(0, 80, 0, 20)
	rarityLabel.Position = UDim2.new(1, -85, 0, 5)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = rarity
	rarityLabel.TextColor3 = rarityColor
	rarityLabel.TextSize = 11
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextStrokeTransparency = 0.5
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Right
	rarityLabel.Parent = cardFrame
	
	-- Count indicator (top-left corner) - shows "2x", "3x", etc.
	local count = tonumber(ownedSwords[swordName]) or 1
	
	if count > 1 then
		local countLabel = Instance.new("TextLabel")
		countLabel.Name = "CountLabel"
		countLabel.Size = UDim2.new(0, 50, 0, 20)
		countLabel.Position = UDim2.new(0, 5, 0, 5)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = count .. "x"
		countLabel.TextColor3 = UI_SETTINGS.TextColor
		countLabel.TextSize = 13
		countLabel.Font = Enum.Font.GothamBold
		countLabel.TextStrokeTransparency = 0.5
		countLabel.TextXAlignment = Enum.TextXAlignment.Left
		countLabel.Parent = cardFrame
	end

	-- ========================================
	-- HOVER & CLICK EFFECTS
	-- ========================================

	-- Hover effect
	cardFrame.MouseEnter:Connect(function()
		TweenService:Create(cardFrame, TweenInfo.new(0.2), {
			BackgroundTransparency = UI_SETTINGS.CardBackgroundTransparency - 0.05
		}):Play()

		-- Brighten viewport
		TweenService:Create(viewport, TweenInfo.new(0.2), {
			Ambient = Color3.fromRGB(
				200 * UI_SETTINGS.HoverBrightness,
				200 * UI_SETTINGS.HoverBrightness,
				200 * UI_SETTINGS.HoverBrightness
			)
		}):Play()

		-- Slightly brighten border if not equipped
		if currentEquippedSword ~= swordName then
			TweenService:Create(stroke, TweenInfo.new(0.2), {
				Transparency = 0.3
			}):Play()
		end
	end)

	cardFrame.MouseLeave:Connect(function()
		TweenService:Create(cardFrame, TweenInfo.new(0.2), {
			BackgroundTransparency = UI_SETTINGS.CardBackgroundTransparency
		}):Play()

		-- Reset viewport brightness
		TweenService:Create(viewport, TweenInfo.new(0.2), {
			Ambient = Color3.fromRGB(
				200 * UI_SETTINGS.DefaultBrightness,
				200 * UI_SETTINGS.DefaultBrightness,
				200 * UI_SETTINGS.DefaultBrightness
			)
		}):Play()

		-- Reset border if not equipped
		if currentEquippedSword ~= swordName then
			TweenService:Create(stroke, TweenInfo.new(0.2), {
				Transparency = 0.5
			}):Play()
		end
	end)

	-- Click to equip
	cardFrame.MouseButton1Click:Connect(function()
		-- Request sword switch from server
		switchSwordRemote:FireServer(swordName)
	end)

	-- Store reference
	cardFrames[swordName] = {
		frame = cardFrame,
		viewport = viewport,
	}

	return cardFrame
end

-- ========================================
-- INVENTORY GUI CREATION
-- ========================================

-- Create the main inventory GUI
local function createInventoryGUI()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true -- Cover entire screen including topbar
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Background overlay (darkens screen)
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = UI_SETTINGS.BackgroundColor
	overlay.BackgroundTransparency = UI_SETTINGS.BackgroundTransparency
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(0, 600, 0, 50)
	titleBar.Position = UDim2.new(0.5, -300, 0, 40)
	titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	titleBar.BackgroundTransparency = 0.3
	titleBar.BorderSizePixel = 0
	titleBar.Parent = overlay

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, UI_SETTINGS.CornerRadius)
	titleCorner.Parent = titleBar

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = UI_SETTINGS.BorderColor
	titleStroke.Thickness = 1.5
	titleStroke.Transparency = 0.5
	titleStroke.Parent = titleBar

	-- Title text
	local titleText = Instance.new("TextLabel")
	titleText.Name = "TitleText"
	titleText.Size = UDim2.new(1, -20, 1, 0)
	titleText.Position = UDim2.new(0, 10, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = "SWORD INVENTORY"
	titleText.TextColor3 = UI_SETTINGS.TextColor
	titleText.TextSize = 20
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Parent = titleBar

	-- Close hint text
	local closeHint = Instance.new("TextLabel")
	closeHint.Name = "CloseHint"
	closeHint.Size = UDim2.new(0, 150, 1, 0)
	closeHint.Position = UDim2.new(1, -160, 0, 0)
	closeHint.BackgroundTransparency = 1
	closeHint.Text = "Press [TAB] to close"
	closeHint.TextColor3 = Color3.fromRGB(150, 150, 160)
	closeHint.TextSize = 12
	closeHint.Font = Enum.Font.GothamMedium
	closeHint.TextXAlignment = Enum.TextXAlignment.Right
	closeHint.Parent = titleBar

	-- Container for cards (scrolling frame)
	local container = Instance.new("ScrollingFrame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 600, 0, 450)
	container.Position = UDim2.new(0.5, -300, 0, 110)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ScrollBarThickness = 8
	container.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
	container.ScrollBarImageTransparency = 0.3
	container.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will auto-size
	container.AutomaticCanvasSize = Enum.AutomaticSize.Y
	container.Parent = overlay

	-- Grid layout for cards
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, UI_SETTINGS.CardWidth, 0, UI_SETTINGS.CardHeight)
	gridLayout.CellPadding = UDim2.new(0, UI_SETTINGS.CardSpacing, 0, UI_SETTINGS.CardSpacing)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = container

	-- Padding
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 15)
	padding.PaddingBottom = UDim.new(0, 15)
	padding.PaddingLeft = UDim.new(0, 15)
	padding.PaddingRight = UDim.new(0, 15)
	padding.Parent = container

	-- Create cards only for owned swords (sorted by rarity)
	local swordList = {}
	for swordName, config in pairs(SwordConfig.Swords) do
		-- Only add if player owns this sword (check if count exists and is > 0)
		local count = tonumber(ownedSwords[swordName])
		if count and count > 0 then
			table.insert(swordList, {name = swordName, config = config})
		end
	end

	-- Sort by rarity (highest to lowest)
	table.sort(swordList, function(a, b)
		local rarityA = SwordConfig.Rarities[a.config.Rarity] or {SortOrder = 999}
		local rarityB = SwordConfig.Rarities[b.config.Rarity] or {SortOrder = 999}
		return rarityA.SortOrder > rarityB.SortOrder
	end)

	-- Create cards
	for i, swordData in ipairs(swordList) do
		local card = createSwordCard(swordData.name, swordData.config)
		card.LayoutOrder = i
		card.Parent = container
	end
	
	-- Show message if no swords owned (shouldn't happen since players start with Nightward)
	if #swordList == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 100)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No swords owned yet!\nOpen crates to get swords."
		emptyLabel.TextColor3 = UI_SETTINGS.TextColor
		emptyLabel.TextSize = 16
		emptyLabel.Font = Enum.Font.GothamMedium
		emptyLabel.TextWrapped = true
		emptyLabel.Parent = container
	end

	return screenGui
end

-- ========================================
-- INVENTORY MANAGEMENT
-- ========================================

-- Refresh inventory (rebuild UI with current owned swords)
local function refreshInventory()
	if inventoryGui then
		inventoryGui:Destroy()
		inventoryGui = nil
		cardFrames = {}
	end
	
	-- Rebuild if currently open
	if isInventoryOpen then
		inventoryGui = createInventoryGUI()
		inventoryGui.Enabled = true
		updateEquippedStates()
	end
end

-- Toggle inventory visibility
local function toggleInventory()
	-- Request latest inventory from server
	local success, inventory = pcall(function()
		return getInventoryRemote:InvokeServer()
	end)
	
	if success and inventory then
		-- Ensure all counts are numbers
		local cleanedInventory = {}
		for name, count in pairs(inventory) do
			cleanedInventory[name] = tonumber(count) or 1
		end
		ownedSwords = cleanedInventory
	end
	
	-- Create GUI if doesn't exist
	if not inventoryGui then
		inventoryGui = createInventoryGUI()
	end

	isInventoryOpen = not isInventoryOpen
	inventoryGui.Enabled = isInventoryOpen

	-- Update equipped states when opening
	if isInventoryOpen then
		updateEquippedStates()
	end
end

-- ========================================
-- INPUT HANDLING
-- ========================================

-- Listen for TAB key to open/close inventory
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Tab then
		toggleInventory()
	end
end)

-- ========================================
-- INVENTORY BUTTON
-- ========================================

-- Create inventory button UI
local function createInventoryButton()
	-- Create ScreenGui for button
	local buttonGui = Instance.new("ScreenGui")
	buttonGui.Name = "InventoryButtonUI"
	buttonGui.ResetOnSpawn = false
	buttonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	buttonGui.IgnoreGuiInset = true
	buttonGui.Parent = playerGui

	-- Button frame (square, right middle)
	local button = Instance.new("TextButton")
	button.Name = "InventoryButton"
	button.Size = UDim2.new(0, 80, 0, 80) -- Square
	button.Position = UDim2.new(1, -90, 0.5, -40) -- Right middle
	button.AnchorPoint = Vector2.new(0, 0.5) -- Center vertically
	button.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	button.BackgroundTransparency = 0.3
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = "Inventory"
	button.TextColor3 = Color3.fromRGB(220, 220, 230)
	button.TextSize = 13
	button.Font = Enum.Font.GothamBold
	button.TextWrapped = true
	button.Parent = buttonGui

	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	-- Border
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 60, 70)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button

	-- Hover effects
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.15
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {
			Transparency = 0.3
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.3
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {
			Transparency = 0.5
		}):Play()
	end)

	-- Click handler
	button.MouseButton1Click:Connect(function()
		toggleInventory()
	end)

	return buttonGui
end

-- ========================================
-- SWORD SWITCH LISTENER
-- ========================================

-- Listen for sword switch confirmation from server
switchSwordRemote.OnClientEvent:Connect(function(swordName)
	currentEquippedSword = swordName
	updateEquippedStates()
end)

-- Listen for inventory updates from server
inventoryUpdatedRemote.OnClientEvent:Connect(function(inventory)
	-- Ensure all counts are numbers
	local cleanedInventory = {}
	for name, count in pairs(inventory) do
		cleanedInventory[name] = tonumber(count) or 1
	end
	ownedSwords = cleanedInventory
	
	-- Refresh inventory UI if open
	refreshInventory()
end)

-- Request initial inventory
task.spawn(function()
	task.wait(1) -- Wait for server to initialize
	local success, inventory = pcall(function()
		return getInventoryRemote:InvokeServer()
	end)
	
	if success and inventory then
		-- Ensure all counts are numbers
		local cleanedInventory = {}
		for name, count in pairs(inventory) do
			cleanedInventory[name] = tonumber(count) or 1
		end
		ownedSwords = cleanedInventory
	end
end)

-- Create inventory button
createInventoryButton()

print("Inventory UI loaded!")
