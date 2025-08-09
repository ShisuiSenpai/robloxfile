-- QuizUI Debug Script
-- This script analyzes all UI elements and their properties to help with responsive design

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for QuizUI
local quizGui = playerGui:WaitForChild("QuizUI")

-- Colors for debug output
local function colorPrint(text, r, g, b)
	print(string.format('<font color="rgb(%d,%d,%d)">%s</font>', r*255, g*255, b*255, text))
end

-- Function to analyze UDim2 values
local function analyzeUDim2(name, udim2)
	local scaleX, offsetX = udim2.X.Scale, udim2.X.Offset
	local scaleY, offsetY = udim2.Y.Scale, udim2.Y.Offset
	
	local analysis = string.format("  %s: {%.3f, %d}, {%.3f, %d}", name, scaleX, offsetX, scaleY, offsetY)
	
	-- Highlight potential issues
	if offsetX ~= 0 or offsetY ~= 0 then
		analysis = analysis .. " ⚠️ USES OFFSET"
	end
	
	return analysis
end

-- Function to check for constraint objects
local function checkConstraints(element)
	local constraints = {}
	
	for _, child in pairs(element:GetChildren()) do
		if child:IsA("UIAspectRatioConstraint") then
			table.insert(constraints, string.format("    - AspectRatio: %.3f (Type: %s)", 
				child.AspectRatio, child.AspectType.Name))
		elseif child:IsA("UISizeConstraint") then
			table.insert(constraints, string.format("    - SizeConstraint: Min(%s), Max(%s)", 
				tostring(child.MinSize), tostring(child.MaxSize)))
		elseif child:IsA("UITextSizeConstraint") then
			table.insert(constraints, string.format("    - TextSizeConstraint: Min(%d), Max(%d)", 
				child.MinTextSize, child.MaxTextSize))
		elseif child:IsA("UIScale") then
			table.insert(constraints, string.format("    - UIScale: %.3f", child.Scale))
		end
	end
	
	return constraints
end

-- Function to analyze a GUI element
local function analyzeElement(element, depth)
	local indent = string.rep("  ", depth)
	
	-- Element header
	colorPrint(indent .. "📦 " .. element.Name .. " (" .. element.ClassName .. ")", 0.3, 0.7, 1)
	
	-- Position and Size
	if element:IsA("GuiObject") then
		print(indent .. analyzeUDim2("Position", element.Position))
		print(indent .. analyzeUDim2("Size", element.Size))
		
		-- Anchor Point (important for responsive design)
		if element.AnchorPoint ~= Vector2.new(0, 0) then
			print(indent .. string.format("  AnchorPoint: (%.2f, %.2f) ⚠️ NON-ZERO", 
				element.AnchorPoint.X, element.AnchorPoint.Y))
		end
		
		-- Check AbsoluteSize and AbsolutePosition
		print(indent .. string.format("  AbsoluteSize: %d x %d pixels", 
			element.AbsoluteSize.X, element.AbsoluteSize.Y))
		print(indent .. string.format("  AbsolutePosition: (%d, %d)", 
			element.AbsolutePosition.X, element.AbsolutePosition.Y))
	end
	
	-- Text-specific properties
	if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
		print(indent .. "  Text Properties:")
		print(indent .. string.format("    - TextScaled: %s", tostring(element.TextScaled)))
		if not element.TextScaled then
			print(indent .. string.format("    - TextSize: %d ⚠️ FIXED SIZE", element.TextSize))
		end
		print(indent .. string.format("    - Font: %s", element.Font.Name))
		print(indent .. string.format("    - TextWrapped: %s", tostring(element.TextWrapped)))
	end
	
	-- Frame/ScreenGui specific
	if element:IsA("Frame") then
		print(indent .. string.format("  BorderSizePixel: %d", element.BorderSizePixel))
		if element.BorderSizePixel > 0 then
			print(indent .. "    ⚠️ Uses pixel border (not responsive)")
		end
	end
	
	if element:IsA("ScreenGui") then
		print(indent .. "  ScreenGui Properties:")
		print(indent .. string.format("    - IgnoreGuiInset: %s", tostring(element.IgnoreGuiInset)))
		print(indent .. string.format("    - ZIndexBehavior: %s", element.ZIndexBehavior.Name))
	end
	
	-- Check for constraint objects
	local constraints = checkConstraints(element)
	if #constraints > 0 then
		colorPrint(indent .. "  🔧 Constraints:", 0.9, 0.6, 0.2)
		for _, constraint in ipairs(constraints) do
			print(indent .. constraint)
		end
	end
	
	-- Special UI modifiers
	local hasCorner = element:FindFirstChildOfClass("UICorner")
	local hasStroke = element:FindFirstChildOfClass("UIStroke")
	local hasGradient = element:FindFirstChildOfClass("UIGradient")
	local hasPadding = element:FindFirstChildOfClass("UIPadding")
	local hasListLayout = element:FindFirstChildOfClass("UIListLayout") or element:FindFirstChildOfClass("UIGridLayout")
	
	if hasCorner or hasStroke or hasGradient or hasPadding or hasListLayout then
		colorPrint(indent .. "  🎨 UI Modifiers:", 0.9, 0.6, 0.2)
		if hasCorner then
			local corner = element:FindFirstChildOfClass("UICorner")
			print(indent .. string.format("    - UICorner: %s", tostring(corner.CornerRadius)))
		end
		if hasStroke then
			local stroke = element:FindFirstChildOfClass("UIStroke")
			print(indent .. string.format("    - UIStroke: Thickness=%d, Transparency=%.2f", 
				stroke.Thickness, stroke.Transparency))
			if stroke.Thickness > 0 then
				print(indent .. "      ⚠️ Fixed pixel thickness")
			end
		end
		if hasPadding then
			local padding = element:FindFirstChildOfClass("UIPadding")
			print(indent .. string.format("    - UIPadding: T:%s, B:%s, L:%s, R:%s", 
				tostring(padding.PaddingTop), tostring(padding.PaddingBottom),
				tostring(padding.PaddingLeft), tostring(padding.PaddingRight)))
		end
		if hasListLayout then
			local layout = element:FindFirstChildOfClass("UIListLayout") or element:FindFirstChildOfClass("UIGridLayout")
			print(indent .. string.format("    - %s: Padding=%s", 
				layout.ClassName, tostring(layout.Padding)))
		end
	end
	
	print(indent .. "  ---")
end

-- Main analysis function
local function analyzeQuizUI()
	print("\n" .. string.rep("=", 50))
	colorPrint("🔍 QUIZUI RESPONSIVE DESIGN ANALYSIS", 0.2, 0.8, 0.2)
	print(string.rep("=", 50))
	
	-- Get current viewport size
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	print(string.format("\n📱 Current Viewport: %d x %d pixels", viewportSize.X, viewportSize.Y))
	print(string.format("   Aspect Ratio: %.2f:1", viewportSize.X / viewportSize.Y))
	
	-- Analyze QuizUI
	print("\n🎮 ANALYZING QUIZUI STRUCTURE:")
	print(string.rep("-", 50))
	
	-- Recursive analysis
	local function analyzeRecursive(element, depth)
		analyzeElement(element, depth)
		
		-- Get children (but skip UI constraint objects for cleaner output)
		local children = {}
		for _, child in pairs(element:GetChildren()) do
			if child:IsA("GuiObject") then
				table.insert(children, child)
			end
		end
		
		-- Sort children by name for consistent output
		table.sort(children, function(a, b) return a.Name < b.Name end)
		
		for _, child in ipairs(children) do
			analyzeRecursive(child, depth + 1)
		end
	end
	
	analyzeRecursive(quizGui, 0)
	
	-- Summary of potential issues
	print("\n" .. string.rep("=", 50))
	colorPrint("⚠️ RESPONSIVE DESIGN RECOMMENDATIONS:", 1, 0.5, 0)
	print(string.rep("=", 50))
	
	local issues = {}
	
	-- Check all elements for common issues
	local function checkIssues(element)
		-- Check for offset usage
		if element:IsA("GuiObject") then
			local pos = element.Position
			local size = element.Size
			
			if pos.X.Offset ~= 0 or pos.Y.Offset ~= 0 then
				table.insert(issues, {
					element = element.Name,
					issue = "Uses offset positioning",
					fix = "Consider using scale values (0-1) instead of pixel offsets"
				})
			end
			
			if size.X.Offset ~= 0 or size.Y.Offset ~= 0 then
				table.insert(issues, {
					element = element.Name,
					issue = "Uses offset sizing",
					fix = "Consider using scale values or UIAspectRatioConstraint"
				})
			end
		end
		
		-- Check for fixed text sizes
		if (element:IsA("TextLabel") or element:IsA("TextButton")) and not element.TextScaled then
			table.insert(issues, {
				element = element.Name,
				issue = "Fixed text size",
				fix = "Enable TextScaled or use UITextSizeConstraint"
			})
		end
		
		-- Recursively check children
		for _, child in pairs(element:GetChildren()) do
			if child:IsA("GuiObject") then
				checkIssues(child)
			end
		end
	end
	
	checkIssues(quizGui)
	
	-- Print issues
	if #issues > 0 then
		for i, issue in ipairs(issues) do
			print(string.format("\n%d. %s", i, issue.element))
			print("   Issue: " .. issue.issue)
			print("   Fix: " .. issue.fix)
		end
	else
		colorPrint("\n✅ No major responsive design issues found!", 0.2, 0.8, 0.2)
	end
	
	-- Best practices reminder
	print("\n" .. string.rep("=", 50))
	colorPrint("📚 RESPONSIVE DESIGN BEST PRACTICES:", 0.2, 0.6, 1)
	print(string.rep("=", 50))
	print("1. Use Scale (0-1) for positioning and sizing")
	print("2. Use UIAspectRatioConstraint for maintaining proportions")
	print("3. Enable TextScaled for text elements")
	print("4. Use UIPadding with Scale values instead of offset borders")
	print("5. Test on multiple screen sizes (phone, tablet, desktop)")
	print("6. Consider using AnchorPoint = (0.5, 0.5) for centered elements")
	print("7. Use UIScale for global scaling if needed")
	
	print("\n" .. string.rep("=", 50))
	print("Debug analysis complete!")
end

-- Function to monitor size changes
local function monitorSizeChanges()
	local camera = workspace.CurrentCamera
	local lastSize = camera.ViewportSize
	
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		local newSize = camera.ViewportSize
		if newSize ~= lastSize then
			print(string.format("\n📱 VIEWPORT CHANGED: %dx%d → %dx%d", 
				lastSize.X, lastSize.Y, newSize.X, newSize.Y))
			lastSize = newSize
			
			-- Re-analyze on size change
			analyzeQuizUI()
		end
	end)
end

-- Run the analysis
analyzeQuizUI()

-- Start monitoring size changes
monitorSizeChanges()

print("\n💡 TIP: Resize your viewport to see how elements respond!")