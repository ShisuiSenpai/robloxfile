-- ShopGUIMapper.lua
-- This script maps out the entire structure of the LimitedStoreGUI
-- Place this in StarterPlayer > StarterPlayerScripts
-- It will output the GUI structure to the console when you play the game

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Wait for PlayerGui to load
local playerGui = player:WaitForChild("PlayerGui")

-- Function to get the class type icon for better visualization
local function getClassIcon(instance)
	local classIcons = {
		ScreenGui = "📺",
		Frame = "🔲",
		TextLabel = "📝",
		TextButton = "🔘",
		ImageLabel = "🖼️",
		ImageButton = "🖱️",
		ScrollingFrame = "📜",
		TextBox = "📋",
		ViewportFrame = "🎬",
		UICorner = "⭕",
		UIStroke = "🔳",
		UIGradient = "🌈",
		UIListLayout = "📑",
		UIGridLayout = "⚏",
		UIPadding = "📐",
		UIScale = "🔍",
		UIAspectRatioConstraint = "📏",
		UITextSizeConstraint = "📏",
		LocalScript = "📄",
		Script = "📄",
		ModuleScript = "📦"
	}
	return classIcons[instance.ClassName] or "❓"
end

-- Function to get important properties of UI elements
local function getProperties(instance)
	local props = {}
	
	-- Common properties to check
	if instance:IsA("GuiObject") then
		-- Position and Size
		table.insert(props, string.format("Pos: {%.2f, %d, %.2f, %d}", 
			instance.Position.X.Scale, instance.Position.X.Offset,
			instance.Position.Y.Scale, instance.Position.Y.Offset))
		table.insert(props, string.format("Size: {%.2f, %d, %.2f, %d}", 
			instance.Size.X.Scale, instance.Size.X.Offset,
			instance.Size.Y.Scale, instance.Size.Y.Offset))
		
		-- Visibility
		table.insert(props, "Visible: " .. tostring(instance.Visible))
		
		-- Anchor Point if not default
		if instance.AnchorPoint ~= Vector2.new(0, 0) then
			table.insert(props, string.format("Anchor: (%.2f, %.2f)", instance.AnchorPoint.X, instance.AnchorPoint.Y))
		end
		
		-- ZIndex if not 1
		if instance.ZIndex ~= 1 then
			table.insert(props, "ZIndex: " .. tostring(instance.ZIndex))
		end
	end
	
	-- Text properties
	if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		table.insert(props, "Text: \"" .. instance.Text .. "\"")
		table.insert(props, "Font: " .. instance.Font.Name)
		table.insert(props, string.format("TextColor: (%.2f, %.2f, %.2f)", 
			instance.TextColor3.R, instance.TextColor3.G, instance.TextColor3.B))
	end
	
	-- Button properties
	if instance:IsA("TextButton") or instance:IsA("ImageButton") then
		table.insert(props, "Active: " .. tostring(instance.Active))
		table.insert(props, "AutoButtonColor: " .. tostring(instance.AutoButtonColor))
	end
	
	-- Image properties
	if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		if instance.Image ~= "" then
			table.insert(props, "Image: " .. instance.Image)
		end
	end
	
	-- ScrollingFrame properties
	if instance:IsA("ScrollingFrame") then
		table.insert(props, string.format("CanvasSize: {%.2f, %d, %.2f, %d}", 
			instance.CanvasSize.X.Scale, instance.CanvasSize.X.Offset,
			instance.CanvasSize.Y.Scale, instance.CanvasSize.Y.Offset))
		table.insert(props, "ScrollBarThickness: " .. tostring(instance.ScrollBarThickness))
	end
	
	-- Background properties
	if instance:IsA("GuiObject") then
		table.insert(props, string.format("BgTransparency: %.2f", instance.BackgroundTransparency))
		if instance.BackgroundTransparency < 1 then
			table.insert(props, string.format("BgColor: (%.2f, %.2f, %.2f)", 
				instance.BackgroundColor3.R, instance.BackgroundColor3.G, instance.BackgroundColor3.B))
		end
	end
	
	return props
end

-- Recursive function to map the GUI structure
local function mapGuiStructure(instance, indent, outputLines, includeProperties)
	indent = indent or 0
	outputLines = outputLines or {}
	
	local indentStr = string.rep("  ", indent)
	local icon = getClassIcon(instance)
	
	-- Create the main line
	local line = string.format("%s%s %s (%s)", indentStr, icon, instance.Name, instance.ClassName)
	table.insert(outputLines, line)
	
	-- Add properties if requested
	if includeProperties then
		local props = getProperties(instance)
		for _, prop in ipairs(props) do
			table.insert(outputLines, indentStr .. "    → " .. prop)
		end
	end
	
	-- Get children and sort them for consistent output
	local children = instance:GetChildren()
	table.sort(children, function(a, b)
		-- Sort by ClassName first, then by Name
		if a.ClassName == b.ClassName then
			return a.Name < b.Name
		end
		return a.ClassName < b.ClassName
	end)
	
	-- Recursively map children
	for _, child in ipairs(children) do
		mapGuiStructure(child, indent + 1, outputLines, includeProperties)
	end
	
	return outputLines
end

-- Function to analyze and output the shop GUI
local function analyzeShopGUI()
	print("\n" .. string.rep("=", 80))
	print("LIMITEDSTORE GUI STRUCTURE ANALYSIS")
	print(string.rep("=", 80))
	
	-- Wait for the GUI to load
	local shopGui = playerGui:WaitForChild("LimitedStoreGUI", 5)
	
	if not shopGui then
		warn("LimitedStoreGUI not found in PlayerGui!")
		return
	end
	
	print("\n✅ Found LimitedStoreGUI!")
	print(string.rep("-", 80))
	
	-- First pass: Simple structure without properties
	print("\n📊 HIERARCHY OVERVIEW (Simple):")
	print(string.rep("-", 40))
	local simpleLines = mapGuiStructure(shopGui, 0, {}, false)
	for _, line in ipairs(simpleLines) do
		print(line)
	end
	
	-- Second pass: Detailed structure with properties
	print("\n" .. string.rep("=", 80))
	print("📊 DETAILED STRUCTURE WITH PROPERTIES:")
	print(string.rep("-", 40))
	local detailedLines = mapGuiStructure(shopGui, 0, {}, true)
	for _, line in ipairs(detailedLines) do
		print(line)
	end
	
	-- Summary statistics
	print("\n" .. string.rep("=", 80))
	print("📈 SUMMARY STATISTICS:")
	print(string.rep("-", 40))
	
	local stats = {
		frames = 0,
		buttons = 0,
		labels = 0,
		images = 0,
		scrollingFrames = 0,
		uiElements = 0,
		scripts = 0,
		total = 0
	}
	
	local function countElements(instance)
		stats.total = stats.total + 1
		
		if instance:IsA("Frame") then
			stats.frames = stats.frames + 1
		elseif instance:IsA("TextButton") or instance:IsA("ImageButton") then
			stats.buttons = stats.buttons + 1
		elseif instance:IsA("TextLabel") then
			stats.labels = stats.labels + 1
		elseif instance:IsA("ImageLabel") then
			stats.images = stats.images + 1
		elseif instance:IsA("ScrollingFrame") then
			stats.scrollingFrames = stats.scrollingFrames + 1
		elseif instance.ClassName:sub(1, 2) == "UI" then
			stats.uiElements = stats.uiElements + 1
		elseif instance:IsA("LocalScript") or instance:IsA("Script") or instance:IsA("ModuleScript") then
			stats.scripts = stats.scripts + 1
		end
		
		for _, child in ipairs(instance:GetChildren()) do
			countElements(child)
		end
	end
	
	countElements(shopGui)
	
	print("Total Elements: " .. stats.total)
	print("  • Frames: " .. stats.frames)
	print("  • Buttons: " .. stats.buttons)
	print("  • Text Labels: " .. stats.labels)
	print("  • Images: " .. stats.images)
	print("  • Scrolling Frames: " .. stats.scrollingFrames)
	print("  • UI Elements: " .. stats.uiElements)
	print("  • Scripts: " .. stats.scripts)
	
	-- Find important elements for shop functionality
	print("\n" .. string.rep("=", 80))
	print("🎯 KEY ELEMENTS FOR SHOP FUNCTIONALITY:")
	print(string.rep("-", 40))
	
	local keyElements = {
		openButton = nil,
		closeButton = nil,
		mainFrame = nil,
		itemsContainer = nil,
		purchaseButtons = {},
		currencyDisplay = nil
	}
	
	local function findKeyElements(instance, path)
		path = path or instance.Name
		
		-- Look for open/close buttons
		if instance:IsA("TextButton") or instance:IsA("ImageButton") then
			local lowerName = instance.Name:lower()
			if lowerName:find("open") then
				keyElements.openButton = path
			elseif lowerName:find("close") or lowerName:find("exit") or lowerName == "x" then
				keyElements.closeButton = path
			elseif lowerName:find("buy") or lowerName:find("purchase") then
				table.insert(keyElements.purchaseButtons, path)
			end
		end
		
		-- Look for main frame
		if instance:IsA("Frame") then
			local lowerName = instance.Name:lower()
			if lowerName:find("main") or lowerName:find("shop") or lowerName:find("store") then
				if not keyElements.mainFrame then
					keyElements.mainFrame = path
				end
			end
			if lowerName:find("item") and (lowerName:find("container") or lowerName:find("list") or lowerName:find("scroll")) then
				keyElements.itemsContainer = path
			end
		end
		
		-- Look for scrolling frame (likely items container)
		if instance:IsA("ScrollingFrame") then
			if not keyElements.itemsContainer then
				keyElements.itemsContainer = path
			end
		end
		
		-- Look for currency display
		if instance:IsA("TextLabel") then
			local lowerName = instance.Name:lower()
			local lowerText = instance.Text:lower()
			if lowerName:find("coin") or lowerName:find("currency") or lowerName:find("money") or
			   lowerText:find("coin") or lowerText:find("$") then
				keyElements.currencyDisplay = path
			end
		end
		
		-- Recursive search
		for _, child in ipairs(instance:GetChildren()) do
			findKeyElements(child, path .. " > " .. child.Name)
		end
	end
	
	findKeyElements(shopGui)
	
	print("🔘 Open Button: " .. (keyElements.openButton or "Not found"))
	print("❌ Close Button: " .. (keyElements.closeButton or "Not found"))
	print("🔲 Main Frame: " .. (keyElements.mainFrame or "Not found"))
	print("📜 Items Container: " .. (keyElements.itemsContainer or "Not found"))
	print("💰 Currency Display: " .. (keyElements.currencyDisplay or "Not found"))
	
	if #keyElements.purchaseButtons > 0 then
		print("🛒 Purchase Buttons Found: " .. #keyElements.purchaseButtons)
		for i, btn in ipairs(keyElements.purchaseButtons) do
			if i <= 5 then -- Only show first 5 to avoid spam
				print("    • " .. btn)
			end
		end
		if #keyElements.purchaseButtons > 5 then
			print("    ... and " .. (#keyElements.purchaseButtons - 5) .. " more")
		end
	end
	
	print("\n" .. string.rep("=", 80))
	print("✅ GUI ANALYSIS COMPLETE!")
	print("You can now use this structure to create your shop functionality script.")
	print(string.rep("=", 80) .. "\n")
end

-- Run the analysis when the player's character loads
if player.Character then
	task.wait(1) -- Give GUI time to load
	analyzeShopGUI()
else
	player.CharacterAdded:Connect(function()
		task.wait(1) -- Give GUI time to load
		analyzeShopGUI()
	end)
end

print("[ShopGUIMapper] Script loaded - GUI structure will be analyzed when you spawn")