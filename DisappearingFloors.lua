-- Disappearing Floors System
-- Place this script in ServerScriptService

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Configuration
local MIN_TIME_BETWEEN_DISAPPEAR = 3 -- Minimum seconds between parts disappearing
local MAX_TIME_BETWEEN_DISAPPEAR = 8 -- Maximum seconds between parts disappearing
local WARNING_TIME = 2 -- How long the warning phase lasts (color changing)
local DISAPPEAR_TIME = 3 -- How long the part stays invisible
local RESPAWN_FADE_TIME = 1 -- How long it takes to fade back in

-- Color sequence for warning (goes through these colors before disappearing)
local WARNING_COLORS = {
	BrickColor.new("Lime green"),
	BrickColor.new("Yellow"),
	BrickColor.new("Orange"),
	BrickColor.new("Really red")
}

-- Get the Map folder
local mapFolder = workspace:WaitForChild("Map")
local parts = {}

-- Function to collect all parts from the Map folder
local function collectParts()
	parts = {}
	for _, child in pairs(mapFolder:GetChildren()) do
		if child:IsA("BasePart") and child.Name == "Part" then
			table.insert(parts, child)
			-- Store original properties
			if not child:GetAttribute("OriginalTransparency") then
				child:SetAttribute("OriginalTransparency", child.Transparency)
				child:SetAttribute("OriginalColor", child.BrickColor.Name)
				child:SetAttribute("IsDisappearing", false)
			end
		end
	end
	print("DisappearingFloors: Found", #parts, "parts in Map folder")
end

-- Initial collection
collectParts()

-- Re-collect parts if new ones are added
mapFolder.ChildAdded:Connect(function(child)
	wait(0.1) -- Small delay to ensure part is fully loaded
	if child:IsA("BasePart") and child.Name == "Part" then
		collectParts()
	end
end)

mapFolder.ChildRemoved:Connect(function(child)
	if child:IsA("BasePart") and child.Name == "Part" then
		collectParts()
	end
end)

-- Function to make a part flash warning colors
local function flashWarning(part)
	if not part or not part.Parent then return end
	
	part:SetAttribute("IsDisappearing", true)
	
	-- Calculate time for each color
	local timePerColor = WARNING_TIME / #WARNING_COLORS
	
	-- Go through each warning color
	for i, color in ipairs(WARNING_COLORS) do
		if part and part.Parent then
			-- Tween to the warning color
			local colorTween = TweenService:Create(
				part,
				TweenInfo.new(timePerColor / 2, Enum.EasingStyle.Linear),
				{Color = color.Color}
			)
			colorTween:Play()
			
			-- Also change BrickColor for compatibility
			part.BrickColor = color
			
			-- Add a slight glow effect
			if i == #WARNING_COLORS then
				-- Last color - make it glow more
				part.Material = Enum.Material.Neon
			end
			
			wait(timePerColor)
		end
	end
end

-- Function to make a part disappear
local function disappearPart(part)
	if not part or not part.Parent then return end
	
	-- Store original properties
	local originalTransparency = part:GetAttribute("OriginalTransparency") or 0
	local originalColor = BrickColor.new(part:GetAttribute("OriginalColor") or "Medium stone grey")
	local originalMaterial = part.Material
	local originalCanCollide = part.CanCollide
	
	-- Create disappear effect with tween
	local disappearTween = TweenService:Create(
		part,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Transparency = 1,
			Color = Color3.new(1, 1, 1) -- Fade to white as it disappears
		}
	)
	
	disappearTween:Play()
	
	-- Wait for tween to complete
	wait(0.5)
	
	-- Make it non-collidable so players fall through
	part.CanCollide = false
	
	-- Keep it invisible for the specified time
	wait(DISAPPEAR_TIME)
	
	-- Respawn the part
	if part and part.Parent then
		-- Make it collidable again first
		part.CanCollide = originalCanCollide
		
		-- Reset material
		part.Material = originalMaterial
		
		-- Create reappear effect
		local reappearTween = TweenService:Create(
			part,
			TweenInfo.new(RESPAWN_FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Transparency = originalTransparency,
				Color = originalColor.Color
			}
		)
		
		reappearTween:Play()
		
		-- Reset the BrickColor
		part.BrickColor = originalColor
		
		-- Mark as no longer disappearing
		part:SetAttribute("IsDisappearing", false)
	end
end

-- Main function to handle a single part disappearing
local function processPart(part)
	if not part or not part.Parent then return end
	
	-- Check if part is already disappearing
	if part:GetAttribute("IsDisappearing") then
		return
	end
	
	-- Flash warning colors
	flashWarning(part)
	
	-- Make it disappear
	disappearPart(part)
end

-- Function to randomly select and disappear a part
local function selectAndDisappearPart()
	if #parts == 0 then
		warn("DisappearingFloors: No parts found in Map folder")
		return
	end
	
	-- Filter out parts that are already disappearing
	local availableParts = {}
	for _, part in ipairs(parts) do
		if part and part.Parent and not part:GetAttribute("IsDisappearing") then
			table.insert(availableParts, part)
		end
	end
	
	if #availableParts == 0 then
		print("DisappearingFloors: All parts are currently disappearing, waiting...")
		return
	end
	
	-- Select a random part
	local randomIndex = math.random(1, #availableParts)
	local selectedPart = availableParts[randomIndex]
	
	print("DisappearingFloors: Making part disappear at position", selectedPart.Position)
	
	-- Process the part in a new thread so we don't block
	task.spawn(function()
		processPart(selectedPart)
	end)
end

-- Main loop
task.spawn(function()
	wait(3) -- Initial delay before starting
	
	while true do
		-- Make a part disappear
		selectAndDisappearPart()
		
		-- Wait random time before next one
		local waitTime = math.random(MIN_TIME_BETWEEN_DISAPPEAR, MAX_TIME_BETWEEN_DISAPPEAR)
		wait(waitTime)
	end
end)

-- Optional: Multiple parts disappearing at once for harder difficulty
local HARD_MODE = false -- Set to true for multiple parts disappearing
local MAX_SIMULTANEOUS = 3 -- Maximum parts that can disappear at once

if HARD_MODE then
	task.spawn(function()
		wait(10) -- Wait 10 seconds before starting hard mode
		
		while true do
			local numParts = math.random(1, MAX_SIMULTANEOUS)
			for i = 1, numParts do
				task.spawn(function()
					selectAndDisappearPart()
				end)
				wait(0.5) -- Small delay between each part
			end
			
			local waitTime = math.random(MIN_TIME_BETWEEN_DISAPPEAR * 2, MAX_TIME_BETWEEN_DISAPPEAR * 2)
			wait(waitTime)
		end
	end)
end

print("DisappearingFloors: System initialized!")
print("DisappearingFloors: Parts will disappear every", MIN_TIME_BETWEEN_DISAPPEAR, "-", MAX_TIME_BETWEEN_DISAPPEAR, "seconds")
print("DisappearingFloors: Warning time:", WARNING_TIME, "seconds")
print("DisappearingFloors: Disappear time:", DISAPPEAR_TIME, "seconds")