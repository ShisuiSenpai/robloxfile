--[[
	CRATE SYSTEM - CLIENT SCRIPT
	Place this LocalScript in StarterPlayerScripts
	
	Handles the crate opening UI and animation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local crateRemotes = ReplicatedStorage:WaitForChild("CrateRemotes")
local openCrateEvent = crateRemotes:WaitForChild("OpenCrate")
local switchSwordEvent = crateRemotes:WaitForChild("SwitchSword")

-- Load VF models folder and organized folders
local vfModelsFolder = ReplicatedStorage:WaitForChild("VFmodels")
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local toolSwordsFolder = ReplicatedStorage:WaitForChild("ToolSwords")
local holsteredModelsFolder = ReplicatedStorage:WaitForChild("HolsteredModels")

-- ========================================
-- UI SETTINGS
-- ========================================

local UI_SETTINGS = {
	-- Colors (dark theme)
	BackgroundColor = Color3.fromRGB(15, 15, 20),
	BackgroundTransparency = 0.3,

	ItemBackgroundColor = Color3.fromRGB(25, 25, 35),
	ItemBackgroundTransparency = 0.2,

	SelectedItemColor = Color3.fromRGB(45, 45, 60),

	TextColor = Color3.fromRGB(220, 220, 230),
	AccentColor = Color3.fromRGB(100, 100, 255),

	-- Animation settings
	ItemWidth = 220, -- Slightly wider for 3D models
	ItemSpacing = 20,
	SpinDuration = 5, -- How long the spin takes in seconds (higher = slower)
	SpinRepeats = 3, -- How many times to loop through all items

	-- ViewportFrame settings
	ViewportSize = 180, -- Size of the 3D model display
	CameraDistance = 0.9, -- How far the camera is from the model (lower = closer)
	ModelRotation = 20, -- Rotation angle for the model (degrees)

	-- Highlight effect settings (CS:GO style)
	-- Brightness settings (1.0 = normal brightness)
	CenteredBrightness = 1.1, -- How bright items are when under the indicator (1.0 = normal)
	DefaultBrightness = 0.5, -- How bright items are by default (0.7 = slightly dimmed)
}

-- ========================================
-- VARIABLES
-- ========================================

local isOpening = false
local currentGui = nil

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Function to disable player movement and UI
local function setPlayerMovement(enabled)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		if enabled then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
		else
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end

	-- Toggle Roblox UI (topbar) but ALWAYS keep backpack disabled
	local StarterGui = game:GetService("StarterGui")
	if enabled then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		-- But keep the backpack (hotbar) disabled always
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	else
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	end
end

-- Function to format sword name for display
local function formatSwordName(swordName)
	-- Convert "NormalSword" to "Normal Sword"
	local formatted = swordName:gsub("Sword$", "")
	formatted = formatted:gsub("(%u)", " %1"):gsub("^%s+", "")
	return formatted
end

-- ========================================
-- UI CREATION
-- ========================================

-- Function to create the crate opening UI
local function createCrateUI(chosenSword, allSwords)
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CrateOpeningUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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

	-- Make sure it covers the topbar area
	screenGui.IgnoreGuiInset = true

	-- Container for the spinning items
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 800, 0, 250) -- Taller to fit 3D models
	container.Position = UDim2.new(0.5, -400, 0.5, -125)
	container.BackgroundTransparency = 1
	container.ClipsDescendants = true
	container.Parent = overlay

	-- Selector line (vertical line in center - same height as items)
	local selector = Instance.new("Frame")
	selector.Name = "Selector"
	selector.Size = UDim2.new(0, 3, 1, -20) -- Same height as items (container height - 20)
	selector.Position = UDim2.new(0.5, -1.5, 0, 10) -- Same offset as items
	selector.BackgroundColor3 = UI_SETTINGS.AccentColor
	selector.BorderSizePixel = 0
	selector.ZIndex = 10
	selector.Parent = container

	-- Scrolling frame for items
	local scrollFrame = Instance.new("Frame")
	scrollFrame.Name = "ScrollFrame"
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.Position = UDim2.new(0, 0, 0, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.Parent = container

	-- Title text
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(0, 400, 0, 50)
	titleLabel.Position = UDim2.new(0.5, -200, 0.5, -250)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "OPENING CRATE"
	titleLabel.TextColor3 = UI_SETTINGS.TextColor
	titleLabel.TextSize = 32
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = overlay

	return screenGui, scrollFrame, titleLabel
end

-- Function to setup ViewportFrame camera
local function setupViewportCamera(viewport, model)
	-- Create camera
	local camera = Instance.new("Camera")
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	-- Get model CFrame and size (handle both Models and single parts like MeshParts)
	local modelCFrame, modelSize

	if model:IsA("Model") then
		-- It's a Model - use GetBoundingBox
		modelCFrame, modelSize = model:GetBoundingBox()
	elseif model:IsA("BasePart") then
		-- It's a single part (MeshPart, Part, etc.) - use CFrame and Size directly
		modelCFrame = model.CFrame
		modelSize = model.Size
	else
		warn("Unknown model type: " .. model.ClassName)
		return
	end

	-- Position camera to view the model
	local maxDimension = math.max(modelSize.X, modelSize.Y, modelSize.Z)
	local distance = maxDimension * UI_SETTINGS.CameraDistance

	-- Angle the camera for a nice view
	local cameraAngle = CFrame.Angles(math.rad(-15), math.rad(UI_SETTINGS.ModelRotation), 0)
	camera.CFrame = CFrame.new(modelCFrame.Position) * cameraAngle * CFrame.new(0, 0, distance)
	camera.CFrame = CFrame.new(camera.CFrame.Position, modelCFrame.Position)

	-- Add some rotation to the model for visual interest
	if model:IsA("Model") then
		model:PivotTo(modelCFrame * CFrame.Angles(0, math.rad(45), 0))
	elseif model:IsA("BasePart") then
		model.CFrame = modelCFrame * CFrame.Angles(0, math.rad(45), 0)
	end

	-- Camera setup complete (no dynamic zoom)
end

-- Function to create sword item UI element with ViewportFrame
local function createSwordItem(swordName, index)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = "Item_" .. index
	itemFrame.Size = UDim2.new(0, UI_SETTINGS.ItemWidth, 1, -20)
	-- Center anchor requires offsetting position by half width
	local posX = index * (UI_SETTINGS.ItemWidth + UI_SETTINGS.ItemSpacing) + (UI_SETTINGS.ItemWidth / 2)
	itemFrame.Position = UDim2.new(0, posX, 0.5, 0)
	itemFrame.BackgroundColor3 = UI_SETTINGS.ItemBackgroundColor
	itemFrame.BackgroundTransparency = UI_SETTINGS.ItemBackgroundTransparency
	itemFrame.BorderSizePixel = 0
	itemFrame.AnchorPoint = Vector2.new(0.5, 0.5) -- Anchor at center for perfect scaling from center

	-- Store original index for positioning
	itemFrame:SetAttribute("OriginalIndex", index)

	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = itemFrame

	-- ViewportFrame for 3D model
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Viewport"
	viewport.Size = UDim2.new(0, UI_SETTINGS.ViewportSize, 0, UI_SETTINGS.ViewportSize)
	viewport.Position = UDim2.new(0.5, -UI_SETTINGS.ViewportSize/2, 0, 10)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.Parent = itemFrame

	-- Try to load the 3D model
	local modelName = swordName .. "VF"
	local modelTemplate = vfModelsFolder:FindFirstChild(modelName)

	if modelTemplate then
		-- Clone the model into the viewport
		local model = modelTemplate:Clone()
		model.Parent = viewport

		-- Setup camera to view the model
		setupViewportCamera(viewport, model)
	else
		-- Fallback: Show warning text if model not found
		local warningLabel = Instance.new("TextLabel")
		warningLabel.Size = UDim2.new(1, 0, 1, 0)
		warningLabel.BackgroundTransparency = 1
		warningLabel.Text = "Model\nNot Found"
		warningLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		warningLabel.TextSize = 16
		warningLabel.Font = Enum.Font.GothamBold
		warningLabel.TextWrapped = true
		warningLabel.Parent = viewport
		warn("VF Model not found: " .. modelName)
	end

	-- Sword name text (below the viewport)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -20, 0, 30)
	nameLabel.Position = UDim2.new(0, 10, 1, -40)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = formatSwordName(swordName)
	nameLabel.TextColor3 = UI_SETTINGS.TextColor
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.TextYAlignment = Enum.TextYAlignment.Bottom
	nameLabel.Parent = itemFrame

	return itemFrame
end

-- ========================================
-- ANIMATION
-- ========================================

-- Function to animate the crate opening
local function animateCrateOpening(scrollFrame, chosenSword, allSwords)
	-- Create extended list of swords (repeat many times to ensure seamless looping)
	local swordList = {}

	-- Repeat the sword list MANY times to create continuous loop effect
	for i = 1, UI_SETTINGS.SpinRepeats * 2 do
		for _, swordName in ipairs(allSwords) do
			table.insert(swordList, swordName)
		end
	end

	-- Add many more random items to hide any "end"
	for i = 1, 20 do
		table.insert(swordList, allSwords[math.random(1, #allSwords)])
	end

	-- Insert chosen sword somewhere in the middle/end (not at the very end)
	local insertPosition = #swordList - math.random(5, 12)
	table.insert(swordList, insertPosition, chosenSword)

	-- Add even MORE items after to hide the end completely
	for i = 1, 15 do
		table.insert(swordList, allSwords[math.random(1, #allSwords)])
	end

	-- Find where the chosen sword ended up
	local chosenIndex = insertPosition

	-- Create UI elements for all swords
	local items = {}
	for index, swordName in ipairs(swordList) do
		local item = createSwordItem(swordName, index - 1)
		item.Parent = scrollFrame
		table.insert(items, item)
	end

	-- Calculate the target position (center the chosen sword at container center: 400px)
	-- With center anchor, item position is: index * (width + spacing) + (width / 2)
	local itemWidth = UI_SETTINGS.ItemWidth + UI_SETTINGS.ItemSpacing
	local chosenItemPos = (chosenIndex - 1) * itemWidth + (UI_SETTINGS.ItemWidth / 2)
	local targetPosition = 400 - chosenItemPos

	-- Animate the scroll with easing
	local tweenInfo = TweenInfo.new(
		UI_SETTINGS.SpinDuration,
		Enum.EasingStyle.Cubic,
		Enum.EasingDirection.Out
	)

	-- Start position (offset to show first few items, accounting for center anchor)
	scrollFrame.Position = UDim2.new(0, 400 - (UI_SETTINGS.ItemWidth / 2), 0, 0)

	-- Create and play tween
	local tween = TweenService:Create(scrollFrame, tweenInfo, {
		Position = UDim2.new(0, targetPosition, 0, 0)
	})

	-- Store active tweens for each item
	local activeTweens = {}

	-- Start highlight effect loop with smooth transitions
	local isAnimating = true
	task.spawn(function()
		while isAnimating do
			-- Update highlight effect for all items based on their distance from center
			local containerCenter = 400 -- Center X position of the container

			for _, item in pairs(items) do
				if item and item.Parent then
				-- Calculate distance from center
				-- Get item's position relative to scrollFrame
				local itemLocalX = item.Position.X.Offset
				-- Get scrollFrame's current position
				local scrollX = scrollFrame.Position.X.Offset
				-- Item's visual position on screen = scrollFrame offset + item's local position
				local itemScreenX = scrollX + itemLocalX
				-- Center is at 400px
				local distance = math.abs(itemScreenX - containerCenter)

				-- Calculate brightness based on distance (closer = brighter)
				local maxDistance = UI_SETTINGS.ItemWidth * 1.5
				local normalizedDistance = math.clamp(distance / maxDistance, 0, 1)

				-- Interpolate brightness (DefaultBrightness to CenteredBrightness)
				local targetBrightness = UI_SETTINGS.DefaultBrightness + 
					(UI_SETTINGS.CenteredBrightness - UI_SETTINGS.DefaultBrightness) * (1 - normalizedDistance)

				-- Cancel previous tween for this item if it exists
				if activeTweens[item] then
					for _, tween in pairs(activeTweens[item]) do
						tween:Cancel()
					end
				end
				activeTweens[item] = {}

				-- Create smooth tween for background color
				local targetColor = Color3.new(
					UI_SETTINGS.ItemBackgroundColor.R * targetBrightness,
					UI_SETTINGS.ItemBackgroundColor.G * targetBrightness,
					UI_SETTINGS.ItemBackgroundColor.B * targetBrightness
				)

				local colorTween = TweenService:Create(
					item,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						BackgroundColor3 = targetColor
					}
				)
				colorTween:Play()
				table.insert(activeTweens[item], colorTween)

				-- Apply brightness to viewport lighting smoothly
				local viewport = item:FindFirstChild("Viewport")
				if viewport then
					local targetAmbient = Color3.new(
						200 / 255 * targetBrightness,
						200 / 255 * targetBrightness,
						200 / 255 * targetBrightness
					)

					local lightTween = TweenService:Create(
						viewport,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{
							Ambient = targetAmbient
						}
					)
					lightTween:Play()
					table.insert(activeTweens[item], lightTween)
				end
				end
			end

			task.wait(0.05) -- Update ~20 times per second (smooth without being CPU intensive)
		end

		-- Cleanup tweens
		for _, tweenList in pairs(activeTweens) do
			for _, tween in pairs(tweenList) do
				tween:Cancel()
			end
		end
	end)

	tween:Play()

	-- Wait for animation to complete
	tween.Completed:Wait()

	-- Stop highlight effect
	isAnimating = false

	-- Wait a bit more to show result
	task.wait(1)

	return chosenSword
end

-- ========================================
-- MAIN CRATE OPENING FUNCTION
-- ========================================

-- Function to open the crate
local function openCrate(chosenSword, allSwords)
	if isOpening then return end
	isOpening = true

	-- Disable player movement
	setPlayerMovement(false)

	-- Create UI
	local gui, scrollFrame, titleLabel = createCrateUI(chosenSword, allSwords)
	currentGui = gui

	-- Animate
	local wonSword = animateCrateOpening(scrollFrame, chosenSword, allSwords)

	-- Update title to show result
	titleLabel.Text = "YOU GOT: " .. formatSwordName(wonSword):upper()
	titleLabel.TextColor3 = UI_SETTINGS.AccentColor

	-- Wait a moment
	task.wait(2)

	-- Cleanup UI
	if currentGui then
		currentGui:Destroy()
		currentGui = nil
	end

	-- Re-enable player movement
	setPlayerMovement(true)

	-- Fire event to switch sword (will be caught by MultiSwordSystem)
	switchSwordEvent:FireServer(wonSword)

	isOpening = false
end

-- ========================================
-- EVENT HANDLERS
-- ========================================

-- Listen for crate opening event from server
openCrateEvent.OnClientEvent:Connect(function(chosenSword, allSwords)
	openCrate(chosenSword, allSwords)
end)

-- Extra safety: Keep hotbar permanently disabled
task.spawn(function()
	while true do
		task.wait(1)
		pcall(function()
			local StarterGui = game:GetService("StarterGui")
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
	end
end)

print("Crate System Client loaded!")
