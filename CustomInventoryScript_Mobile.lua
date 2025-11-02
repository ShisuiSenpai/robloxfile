-- services
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- references
local player = game:GetService("Players").LocalPlayer
local backpack = player:WaitForChild("Backpack")
local camera = workspace.CurrentCamera

-- DISABLE BASIC ROBLOX HOTBAR
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Mobile detection
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isConsole = UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled

local CustomInventoryGUI = script.Parent
local hotBar = CustomInventoryGUI.hotBar
local Inventory = CustomInventoryGUI.Inventory
local toolButton = script.toolButton

local inventoryHandler = require(script.SETTINGS)

local function showSlots()
	for index = 1, inventoryHandler.slotAmount do
		local toolObject = inventoryHandler.OBJECTS.HotBar[index]
		if not toolObject and not hotBar:FindFirstChild(index) and index <= inventoryHandler.slotAmount then
			local frame = toolButton:Clone()
			frame.toolName.Text = ""
			frame.toolAmount.Text = ""
			frame.toolNumber.Text = index
			frame.Name = index
			frame.Parent = hotBar
		end
	end
end

local function removeEmptySlots()
	for index = 1, 9 do
		local toolObject = inventoryHandler.OBJECTS.HotBar[index]
		local toolFrame = hotBar:FindFirstChild(index)
		if not toolObject and toolFrame then
			toolFrame:Destroy()
			if hotBar:FindFirstChild(index) then
				removeEmptySlots()
			end
		end
	end
end

local function manageInventory (_, inputState)
	if inputState == Enum.UserInputState.Begin then
		Inventory.Visible = not Inventory.Visible
		local currentState = Inventory.Visible

		inventoryHandler:removeCurrentDescription()
		if currentState then
			showSlots()
			
			-- Mobile-friendly positioning
			if isMobile then
				-- Center on mobile, accounting for safe areas
				CustomInventoryGUI.openButton.Position = UDim2.new(0.5, 0, 0.5, 0)
				CustomInventoryGUI.openButton.info.Text = "Close"
			else
				CustomInventoryGUI.openButton.Position = UDim2.fromScale(0.5,0.5)
				CustomInventoryGUI.openButton.info.Text = "(') close inventory"
			end
		else
			if not inventoryHandler.SETTINGS.SHOW_EMPTY_TOOL_FRAMES_IN_HOTBAR then
				removeEmptySlots()
			end
			
			-- Mobile-friendly positioning when closed
			if isMobile then
				-- Position higher on mobile to avoid mobile controls
				CustomInventoryGUI.openButton.Position = UDim2.new(0.5, 0, 1, -120)
				CustomInventoryGUI.openButton.info.Text = "Open"
			else
				CustomInventoryGUI.openButton.Position = UDim2.fromScale(0.5,0.909)
				CustomInventoryGUI.openButton.info.Text = "(') open inventory"
			end
		end
	elseif not inputState then
		for index = inventoryHandler.slotAmount + 1, inventoryHandler.slotAmount do
			local toolObject = inventoryHandler.OBJECTS.HotBar[index]
			local toolFrame = hotBar:FindFirstChild(index)
			if toolObject then
				local tool = toolObject.Tool
				toolObject:DisconnectAll()
				tool:SetAttribute("toolAdded", nil)
				inventoryHandler:newTool(tool)
			elseif toolFrame then
				toolFrame:Destroy()
			end
		end
	end
end

local function searchTool()
	inventoryHandler:searchTool()
end

local function newTool(tool)
	if tool:IsA("Tool") then
		inventoryHandler:newTool(tool)
	end
end

local function reloadInventory(character)
	inventoryHandler.currentlyEquipped = nil
	backpack = player:WaitForChild("Backpack")

	for _, tool in pairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			newTool(tool)
		end
	end
	backpack.ChildAdded:Connect(newTool)
	character.ChildAdded:Connect(newTool)
end

local function updateHudPosition()
	local viewPortSize = camera.ViewportSize
	local guiInset = GuiService:GetGuiInset()
	
	-- Calculate safe area (accounting for notches, home indicators, mobile controls)
	local topInset = guiInset.Y
	local bottomInset = 0
	
	-- Mobile adjustments
	if isMobile then
		-- Account for Roblox mobile controls at bottom (jump button, etc)
		bottomInset = 100 -- Extra space for mobile controls
		
		-- Scale UI for mobile
		local scale = math.min(viewPortSize.X / 1920, viewPortSize.Y / 1080)
		scale = math.clamp(scale, 0.7, 1.2) -- Clamp for mobile
		
		-- Apply scaling to hotbar and inventory
		if not hotBar:FindFirstChild("MobileScale") then
			local hotbarScale = Instance.new("UIScale")
			hotbarScale.Name = "MobileScale"
			hotbarScale.Scale = scale
			hotbarScale.Parent = hotBar
		else
			hotBar.MobileScale.Scale = scale
		end
		
		if not Inventory:FindFirstChild("MobileScale") then
			local invScale = Instance.new("UIScale")
			invScale.Name = "MobileScale"
			invScale.Scale = scale
			invScale.Parent = Inventory
		else
			Inventory.MobileScale.Scale = scale
		end
		
		-- Position hotbar higher on mobile to avoid controls
		hotBar.Position = UDim2.new(
			hotBar.Position.X.Scale,
			hotBar.Position.X.Offset,
			1,
			-bottomInset - 10
		)
		
		-- Make open button more accessible on mobile
		if CustomInventoryGUI.openButton.Visible then
			CustomInventoryGUI.openButton.Size = UDim2.fromOffset(80, 80) -- Bigger for touch
		end
	else
		-- Desktop positioning (original)
		hotBar.Position = UDim2.new(
			hotBar.Position.X.Scale,
			hotBar.Position.X.Offset,
			1,
			-10
		)
	end
	
	-- Update slot sizes
	local slotSize = UDim2.fromOffset(hotBar.AbsoluteSize.Y, hotBar.AbsoluteSize.Y)
	
	if Inventory.Frame and Inventory.Frame:FindFirstChild("Grid") then
		Inventory.Frame.Grid.CellSize = slotSize
	end
	if hotBar:FindFirstChild("Grid") then
		hotBar.Grid.CellSize = slotSize
	end

	manageInventory()
end

updateHudPosition(); updateHudPosition()
reloadInventory(player.Character or player.CharacterAdded:Wait())
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateHudPosition)
player.CharacterAdded:Connect(reloadInventory)
Inventory.SearchBox:GetPropertyChangedSignal("Text"):Connect(searchTool)

if inventoryHandler.SETTINGS.SHOW_EMPTY_TOOL_FRAMES_IN_HOTBAR then 
	showSlots() 
end

if inventoryHandler.SETTINGS.INVENTORY_KEYBIND and not isMobile then 
	ContextActionService:BindAction("manageInventory", manageInventory, false, inventoryHandler.SETTINGS.INVENTORY_KEYBIND) 
end

if inventoryHandler.SETTINGS.OPEN_BUTTON or isMobile then
	-- Always show button on mobile for accessibility
	CustomInventoryGUI.openButton.Visible = true
	
	CustomInventoryGUI.openButton.MouseButton1Down:Connect(function()
		Inventory.Visible = not Inventory.Visible
		local currentState = Inventory.Visible
		
		inventoryHandler:removeCurrentDescription()
		if currentState then
			showSlots()
			
			-- Mobile-friendly positioning
			if isMobile then
				CustomInventoryGUI.openButton.Position = UDim2.new(0.5, 0, 0.5, 0)
				CustomInventoryGUI.openButton.info.Text = "Close"
			else
				CustomInventoryGUI.openButton.Position = UDim2.fromScale(0.5,0.5)
				CustomInventoryGUI.openButton.info.Text = "(') close inventory"
			end
		else
			if not inventoryHandler.SETTINGS.SHOW_EMPTY_TOOL_FRAMES_IN_HOTBAR then
				removeEmptySlots()
			end
			
			-- Mobile-friendly positioning when closed
			if isMobile then
				CustomInventoryGUI.openButton.Position = UDim2.new(0.5, 0, 1, -120)
				CustomInventoryGUI.openButton.info.Text = "Open"
			else
				CustomInventoryGUI.openButton.Position = UDim2.fromScale(0.5,0.909)
				CustomInventoryGUI.openButton.info.Text = "(') open inventory"
			end
		end
	end)
else
	CustomInventoryGUI.openButton.Visible = false
end

local function getToolEquipped()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Tool")
end

-- Mouse wheel scrolling (only on desktop/devices with mouse)
if not isMobile then
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel and inventoryHandler.SETTINGS.SCROLL_HOTBAR_WITH_WHEEL then
			local direction = input.Position.Z
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")

			local toolEquipped = getToolEquipped()
			local toolPosition = inventoryHandler:getToolPosition(toolEquipped) or 0
			
			for i=toolPosition + direction, direction < 0 and 1 or inventoryHandler.slotAmount, direction do
				local toolObject = inventoryHandler.OBJECTS.HotBar[i]
				if toolObject and humanoid then
					humanoid:EquipTool(toolObject.Tool)
					break
				end
			end
		end
	end)
end

-- Monitor safe area changes (for device rotation on mobile)
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(updateHudPosition)

-- Extra mobile optimizations
if isMobile then
	-- Make inventory frame respect safe areas
	Inventory.Position = UDim2.new(0.5, 0, 0, 50) -- Add top padding
	Inventory.AnchorPoint = Vector2.new(0.5, 0)
	
	-- Ensure searchbox is accessible on mobile
	if Inventory:FindFirstChild("SearchBox") then
		Inventory.SearchBox.TextSize = 18 -- Bigger text for mobile
		Inventory.SearchBox.Size = UDim2.new(Inventory.SearchBox.Size.X.Scale, Inventory.SearchBox.Size.X.Offset, 0, 50) -- Taller for touch
	end
	
	print("[INVENTORY] Mobile mode enabled - UI optimized for touch")
else
	print("[INVENTORY] Desktop mode - using keyboard controls")
end
