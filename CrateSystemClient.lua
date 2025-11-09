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

-- Load assets folder for VFX
local assetsFolder = ReplicatedStorage:WaitForChild("Assets")
local explosionVFXFolder = assetsFolder:WaitForChild("ExplosionVFX")

-- Load config modules
local SwordConfig = require(modulesFolder:WaitForChild("SwordConfig"))
local SoundConfig = require(modulesFolder:WaitForChild("SoundConfig"))

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

-- Function to play VFX effect on player's torso based on rarity
local function playRarityVFX(rarity)
	-- Get player's character and torso
	local character = player.Character
	if not character then 
		warn("Character not found for VFX")
		return 
	end
	
	-- Find torso (works for both R6 and R15)
	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	if not torso then
		warn("Torso not found for VFX")
		return
	end
	
	-- Find the VFX template for this rarity
	local vfxTemplate = explosionVFXFolder:FindFirstChild(rarity)
	if not vfxTemplate then
		warn("VFX not found for rarity: " .. rarity)
		return
	end
	
	-- Play explosion sound IMMEDIATELY (synced with VFX start)
	local explosionSoundConfig = SoundConfig.ExplosionSounds[rarity]
	if explosionSoundConfig then
		local explosionSound = SoundConfig.CreateSound(explosionSoundConfig, torso)
		if explosionSound then
			explosionSound:Play()
			
			-- Auto-cleanup when sound naturally finishes
			explosionSound.Ended:Connect(function()
				task.wait(0.1)
				if explosionSound then
					explosionSound:Destroy()
				end
			end)
		end
	else
		warn("Explosion sound not configured for rarity: " .. rarity)
	end
	
	-- Clone the VFX attachment
	local vfxClone = vfxTemplate:Clone()
	vfxClone.Parent = torso
	
	-- Play all particle emitters and beams in the attachment
	for _, effect in pairs(vfxClone:GetDescendants()) do
		if effect:IsA("ParticleEmitter") then
			effect:Emit(effect:GetAttribute("EmitCount") or 20)
		elseif effect:IsA("Beam") then
			effect.Enabled = true
		end
	end
	
	-- Also enable any direct particle emitters in the attachment itself
	for _, effect in pairs(vfxClone:GetChildren()) do
		if effect:IsA("ParticleEmitter") then
			effect:Emit(effect:GetAttribute("EmitCount") or 20)
		elseif effect:IsA("Beam") then
			effect.Enabled = true
		end
	end
	
	-- Cleanup after VFX finishes (wait for longest particle lifetime)
	task.delay(3, function()
		if vfxClone then
			vfxClone:Destroy()
		end
	end)
	
	print("Playing VFX and sound for rarity: " .. rarity)
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
	
	-- Clone and setup selected sword UI (shows current sword under indicator)
	local selectedSwordUI = game:GetService("StarterGui"):FindFirstChild("SelectedSwordUI")
	local swordNameLabel = nil
	
	if selectedSwordUI then
		local clonedUI = selectedSwordUI:Clone()
		clonedUI.Parent = overlay
		
		-- Position at top center (mobile compatible)
		clonedUI.Enabled = true
		clonedUI.ResetOnSpawn = false
		
		-- Find the SwordName label to update dynamically
		swordNameLabel = clonedUI:FindFirstChild("SwordName")
		
		-- Set initial text
		if swordNameLabel then
			swordNameLabel.Text = "..."
		end
		
		-- Ensure "Sword: " label is correct
		local swordLabel = clonedUI:FindFirstChild("SwordLabel")
		if swordLabel then
			swordLabel.Text = "Sword: "
		end
	else
		warn("SelectedSwordUI not found in StarterGui")
	end

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

	return screenGui, scrollFrame, swordNameLabel
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

	-- Get rarity info
	local swordConfig = SwordConfig.Swords[swordName]
	local rarity = swordConfig and swordConfig.Rarity or "Common"
	local rarityData = SwordConfig.Rarities[rarity]
	local rarityColor = rarityData and rarityData.Color or Color3.fromRGB(150, 150, 150)
	
	-- Store rarity for later reference
	itemFrame:SetAttribute("Rarity", rarity)
	itemFrame:SetAttribute("RarityColorR", rarityColor.R)
	itemFrame:SetAttribute("RarityColorG", rarityColor.G)
	itemFrame:SetAttribute("RarityColorB", rarityColor.B)
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = itemFrame
	
	-- Image overlay (subtle background texture)
	local imageOverlay = Instance.new("ImageLabel")
	imageOverlay.Name = "ImageOverlay"
	imageOverlay.Size = UDim2.new(1, 0, 1, 0)
	imageOverlay.Position = UDim2.new(0, 0, 0, 0)
	imageOverlay.BackgroundTransparency = 1
	imageOverlay.Image = "rbxassetid://0" -- REPLACE WITH YOUR IMAGE ID
	imageOverlay.ImageTransparency = 0.75 -- Subtle transparency (ADJUST: 0 = solid, 1 = invisible)
	imageOverlay.ScaleType = Enum.ScaleType.Crop -- Fits image nicely
	imageOverlay.ZIndex = 1 -- Behind other elements
	imageOverlay.Parent = itemFrame
	
	-- Corner radius for overlay to match frame
	local overlayCorner = Instance.new("UICorner")
	overlayCorner.CornerRadius = UDim.new(0, 8)
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
		NumberSequenceKeypoint.new(1, 0.6)  -- Bottom: more transparent (fades out)
	})
	overlayGradient.Parent = imageOverlay
	
	-- Add gradient for smooth rarity color effect (top to bottom, darker to lighter)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rarityColor), -- Top: full rarity color
		ColorSequenceKeypoint.new(1, Color3.new(rarityColor.R * 0.4, rarityColor.G * 0.4, rarityColor.B * 0.4)) -- Bottom: darker
	})
	gradient.Rotation = 90 -- Vertical gradient
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4), -- Top: more transparent (ADJUST HERE for rarity color visibility)
		NumberSequenceKeypoint.new(1, 0.3)  -- Bottom: less transparent (ADJUST HERE for rarity color visibility)
	})
	gradient.Parent = itemFrame

	-- ViewportFrame for 3D model
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Viewport"
	viewport.Size = UDim2.new(0, UI_SETTINGS.ViewportSize, 0, UI_SETTINGS.ViewportSize)
	viewport.Position = UDim2.new(0.5, -UI_SETTINGS.ViewportSize/2, 0, 10)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.ZIndex = 2 -- Above overlay
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
	
	-- Percentage label in top-right corner (shows rarity drop chance)
	local percentLabel = Instance.new("TextLabel")
	percentLabel.Name = "PercentLabel"
	percentLabel.Size = UDim2.new(0, 40, 0, 20)
	percentLabel.Position = UDim2.new(1, -45, 0, 5) -- Top-right corner with 5px padding
	percentLabel.BackgroundTransparency = 1
	percentLabel.Text = rarityData.Chance .. "%"
	percentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	percentLabel.TextSize = 12
	percentLabel.Font = Enum.Font.GothamBold
	percentLabel.TextStrokeTransparency = 0.5 -- Subtle outline for readability
	percentLabel.TextXAlignment = Enum.TextXAlignment.Right
	percentLabel.ZIndex = 3 -- Above overlay
	percentLabel.Parent = itemFrame

	-- Background frame for name (semi-transparent black for readability)
	local nameBackground = Instance.new("Frame")
	nameBackground.Name = "NameBackground"
	nameBackground.Size = UDim2.new(1, 0, 0, 35)
	nameBackground.Position = UDim2.new(0, 0, 1, -35)
	nameBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	nameBackground.BackgroundTransparency = 0.6 -- ADJUST HERE for name background transparency (0 = solid, 1 = invisible)
	nameBackground.BorderSizePixel = 0
	nameBackground.ZIndex = 3 -- Above overlay
	nameBackground.Parent = itemFrame
	
	-- Corner radius for name background (only bottom corners)
	local nameCorner = Instance.new("UICorner")
	nameCorner.CornerRadius = UDim.new(0, 8)
	nameCorner.Parent = nameBackground
	
	-- Sword name text (on top of background)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 1, 0)
	nameLabel.Position = UDim2.new(0, 5, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = formatSwordName(swordName)
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Pure white for contrast
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.Parent = nameBackground

	return itemFrame
end

-- ========================================
-- ANIMATION
-- ========================================

-- Function to animate the crate opening
local function animateCrateOpening(scrollFrame, chosenSword, allSwords, swordNameLabel)
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
	
	-- ========================================
	-- SPINNING CLICK SOUND SYSTEM
	-- ========================================
	
	-- Create click sound from SoundConfig
	local character = player.Character
	local soundEmitter = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
	
	local clickSound = nil
	if soundEmitter then
		clickSound = SoundConfig.CreateSound(SoundConfig.CrateSounds.SpinClick, soundEmitter)
	end
	
	-- Track which items have already triggered a click (to avoid double-clicks)
	local clickedItems = {}
	
	-- Track start time for pitch calculation
	local startTime = tick()
	
	-- Start click sound system
	local isSoundPlaying = true
	task.spawn(function()
		local containerCenter = 400
		local lastClosestItem = nil
		
		while isSoundPlaying do
			-- Find the item closest to center
			local closestItem = nil
			local closestDistance = math.huge
			
			for _, item in pairs(items) do
				if item and item.Parent then
					-- Calculate distance from center
					local itemLocalX = item.Position.X.Offset
					local scrollX = scrollFrame.Position.X.Offset
					local itemScreenX = scrollX + itemLocalX
					local distance = math.abs(itemScreenX - containerCenter)
					
					if distance < closestDistance then
						closestDistance = distance
						closestItem = item
					end
				end
			end
			
			-- If we switched to a new closest item, update UI and play click sound
			if closestItem and closestItem ~= lastClosestItem then
				-- Update sword name UI with the sword under the indicator
				if swordNameLabel and closestItem.Name then
					local itemIndex = tonumber(closestItem.Name:match("Item_(%d+)"))
					if itemIndex and swordList[itemIndex + 1] then
						local swordName = swordList[itemIndex + 1]
						swordNameLabel.Text = formatSwordName(swordName)
					end
				end
				
				if not clickedItems[closestItem] then
					-- Play click sound
					if clickSound then
						-- Calculate pitch based on animation progress (starts fast, slows down)
						local elapsedTime = tick() - (startTime or tick())
						local progress = math.clamp(elapsedTime / UI_SETTINGS.SpinDuration, 0, 1)
						
						-- Pitch variation: starts at 1.1, goes down to 0.9 (natural slowdown feel)
						local pitchMultiplier = 1.1 - (progress * 0.2)
						
						-- Play sound
						clickSound.PlaybackSpeed = pitchMultiplier
						clickSound:Play()
					end
					
					-- Mark as clicked
					clickedItems[closestItem] = true
				end
				
				lastClosestItem = closestItem
			end
			
			task.wait(0.01) -- Check very frequently for smooth sound timing
		end
	end)

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

				-- Update gradient transparency based on highlight
				local gradient = item:FindFirstChildOfClass("UIGradient")
				if gradient then
					-- Calculate target transparency (more opaque when highlighted)
					local topTransparency = 0.4 - ((1 - normalizedDistance) * 0.2) -- 0.4 to 0.2
					local bottomTransparency = 0.3 - ((1 - normalizedDistance) * 0.2) -- 0.3 to 0.1
					
					-- Set transparency directly (can't tween NumberSequence)
					gradient.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, topTransparency),
						NumberSequenceKeypoint.new(1, bottomTransparency)
					})
				end

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

	-- Stop highlight effect and sound system
	isAnimating = false
	isSoundPlaying = false
	
	-- Cleanup sound
	if clickSound and clickSound.Parent then
		task.delay(0.5, function()
			clickSound:Destroy()
		end)
	end

	-- Brief pause to see final result
	task.wait(0.3)

	return chosenSword
end

-- ========================================
-- MAIN CRATE OPENING FUNCTION
-- ========================================

-- Function to open the crate
local function openCrate(chosenSword, allSwords)
	-- Prevent opening multiple crates at once
	if isOpening then 
		warn("Cannot open crate - already opening one!")
		return 
	end
	isOpening = true

	-- Disable player movement
	setPlayerMovement(false)
	
	-- Play crate open sound (plays independently, no interruption)
	local character = player.Character
	local soundEmitter = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
	if soundEmitter then
		local crateOpenSound = SoundConfig.CreateSound(SoundConfig.CrateSounds.CrateOpen, soundEmitter)
		if crateOpenSound then
			crateOpenSound:Play()
			
			-- Auto-cleanup when sound naturally finishes
			crateOpenSound.Ended:Connect(function()
				task.wait(0.1)
				if crateOpenSound then
					crateOpenSound:Destroy()
				end
			end)
		end
	end

	-- Create UI
	local gui, scrollFrame, swordNameLabel = createCrateUI(chosenSword, allSwords)
	currentGui = gui

	-- Animate
	local wonSword = animateCrateOpening(scrollFrame, chosenSword, allSwords, swordNameLabel)

	-- Get the rarity of the won sword
	local wonSwordConfig = SwordConfig.Swords[wonSword]
	local wonRarity = wonSwordConfig and wonSwordConfig.Rarity or "Common"
	
	-- Play VFX effect on player's torso
	playRarityVFX(wonRarity)

	-- Brief wait for VFX/sound to start, then close UI
	task.wait(0.5)

	-- Cleanup UI
	if currentGui then
		currentGui:Destroy()
		currentGui = nil
	end

	-- Re-enable player movement
	setPlayerMovement(true)

	-- Fire event to switch sword (will be caught by MultiSwordSystem)
	switchSwordEvent:FireServer(wonSword)

	-- Allow opening crates again
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
