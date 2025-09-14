-- Test Script for Push Tool
-- Run this in the command bar to create a test Push tool if you don't have one

local StarterPack = game:GetService("StarterPack")
local Players = game:GetService("Players")

-- Create the Push tool if it doesn't exist
local pushTool = StarterPack:FindFirstChild("Push")

if not pushTool then
	print("Creating Push tool...")
	
	pushTool = Instance.new("Tool")
	pushTool.Name = "Push"
	pushTool.RequiresHandle = false -- No handle needed
	pushTool.CanBeDropped = true
	
	-- Optional: Add a handle part for visual
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 2)
	handle.BrickColor = BrickColor.new("Bright blue")
	handle.Material = Enum.Material.Neon
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.CanCollide = false
	handle.Parent = pushTool
	
	-- Add the tool to StarterPack
	pushTool.Parent = StarterPack
	
	print("Push tool created in StarterPack!")
	
	-- Give to all current players
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			local toolClone = pushTool:Clone()
			toolClone.Parent = player.Backpack
			print("Gave Push tool to", player.Name)
		end
	end
else
	print("Push tool already exists in StarterPack")
end

print([[
=================================
PUSH TOOL TEST SETUP COMPLETE
=================================

NEXT STEPS:
1. Add the LocalScript (PushToolLocalScript.lua) as a LocalScript inside the Push tool
2. Add the ServerScript (PushToolServerScript.lua) to ServerScriptService
3. Test with 2 players (or 1 player and an NPC)

DEBUG MODE IS ON - Check output for detailed logs!

To test:
- Equip the Push tool
- Face another player within 10 studs
- Click to push them

=================================
]])