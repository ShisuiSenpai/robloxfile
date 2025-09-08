-- ShopGUIMapper.lua
-- This script maps out the entire structure of the LimitedStoreGUI (simplified version)
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

-- Recursive function to map the GUI structure
local function mapGuiStructure(instance, indent, outputLines)
	indent = indent or 0
	outputLines = outputLines or {}
	
	local indentStr = string.rep("  ", indent)
	local icon = getClassIcon(instance)
	
	-- Create the main line with just name and class
	local line = string.format("%s%s %s (%s)", indentStr, icon, instance.Name, instance.ClassName)
	table.insert(outputLines, line)
	
	-- Get children
	local children = instance:GetChildren()
	
	-- Recursively map children
	for _, child in ipairs(children) do
		mapGuiStructure(child, indent + 1, outputLines)
	end
	
	return outputLines
end

-- Function to analyze and output the shop GUI
local function analyzeShopGUI()
	print("\n" .. string.rep("=", 80))
	print("LIMITEDSTORE GUI STRUCTURE")
	print(string.rep("=", 80))
	
	-- Wait for the GUI to load
	local shopGui = playerGui:WaitForChild("LimitedStoreGUI", 5)
	
	if not shopGui then
		warn("LimitedStoreGUI not found in PlayerGui!")
		return
	end
	
	print("\n✅ Found LimitedStoreGUI!\n")
	print("HIERARCHY:")
	print(string.rep("-", 40))
	
	-- Map the structure
	local lines = mapGuiStructure(shopGui, 0, {})
	for _, line in ipairs(lines) do
		print(line)
	end
	
	-- Count statistics
	print("\n" .. string.rep("-", 40))
	print("SUMMARY:")
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
	
	print("\n" .. string.rep("=", 80))
	print("✅ GUI STRUCTURE MAPPED!")
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