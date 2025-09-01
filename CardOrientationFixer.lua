-- CardOrientationFixer.lua
-- This script ensures all cards start in the face-down position

local RunService = game:GetService("RunService")

-- Wait for workspace to load
if not game:IsLoaded() then
	game.Loaded:Wait()
end

wait(0.1) -- Small delay to ensure everything is loaded

local table1Folder = workspace:WaitForChild("Table1Folder")
local table1 = table1Folder:WaitForChild("Table1")

-- Define what face-down orientation should be
-- Based on your logs, cards start at CFrame: -1, 0, 0, 0, -1, 0, 0, 0, 1
-- This appears to be a 180-degree rotation around X and Y axes
-- For face-down, we want no rotation (or a specific rotation)

local FACE_DOWN_ROTATION = CFrame.Angles(math.rad(180), 0, 0) -- Adjust this based on your card models

print("[CardOrientationFixer] Starting card orientation check...")

-- Fix all card orientations
for _, card in ipairs(table1:GetChildren()) do
	if card:IsA("BasePart") then
		local originalPos = card.Position
		
		-- Set card to face-down orientation
		card.CFrame = CFrame.new(originalPos) * FACE_DOWN_ROTATION
		
		-- Add an attribute to track card state
		card:SetAttribute("IsFaceUp", false)
		card:SetAttribute("OriginalCFrame", tostring(card.CFrame))
		
		print("[CardOrientationFixer] Fixed orientation for card:", card.Name)
	end
end

print("[CardOrientationFixer] All cards set to face-down position")

-- This script only needs to run once at startup
script:Destroy()