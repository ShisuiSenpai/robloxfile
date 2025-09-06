-- CardOrientationFixerMulti.lua
-- This script runs once at server startup to ensure all cards on all tables are in a consistent face-down orientation.
-- Place this in ServerScriptService

local Workspace = game:GetService("Workspace")

-- Table configurations
local TABLE_CONFIGS = {
	{
		folderName = "Table1Folder",
		tableName = "Table1",
		cameraPart = "CameraPartTable1"
	},
	{
		folderName = "Table2Folder",
		tableName = "Table2",
		cameraPart = "CameraPartTable2"
	},
	{
		folderName = "Table3Folder",
		tableName = "Table3",
		cameraPart = "CameraPartTable3"
	},
	{
		folderName = "Table4Folder",
		tableName = "Table4",
		cameraPart = "CameraPartTable4"
	},
	{
		folderName = "Table5Folder",
		tableName = "Table5",
		cameraPart = "CameraPartTable5"
	},
	{
		folderName = "Table6Folder",
		tableName = "Table6",
		cameraPart = "CameraPartTable6"
	},
	{
		folderName = "Table7Folder",
		tableName = "Table7",
		cameraPart = "CameraPartTable7"
	},
	{
		folderName = "Table8Folder",
		tableName = "Table8",
		cameraPart = "CameraPartTable8"
	},
	{
		folderName = "Table9Folder",
		tableName = "Table9",
		cameraPart = "CameraPartTable9"
	},
	{
		folderName = "Table10Folder",
		tableName = "Table10",
		cameraPart = "CameraPartTable10"
	}
}

-- Define the desired face-down rotation.
-- You might need to adjust this based on your card models' default orientation.
-- Common rotations:
-- CFrame.Angles(0, 0, 0) -- No rotation (flat, top face up)
-- CFrame.Angles(math.rad(180), 0, 0) -- Flipped 180 degrees on X axis
-- CFrame.Angles(0, math.rad(180), 0) -- Flipped 180 degrees on Y axis
-- CFrame.Angles(0, 0, math.rad(180)) -- Flipped 180 degrees on Z axis
local FACE_DOWN_ROTATION = CFrame.Angles(math.rad(180), 0, 0) -- Assuming cards need to be flipped 180 on X to show back

local function fixCardOrientations()
	print("[CardOrientationFixer] Fixing card orientations for all tables...")

	for _, config in ipairs(TABLE_CONFIGS) do
		local folder = Workspace:FindFirstChild(config.folderName)
		if folder then
			local tablePart = folder:FindFirstChild(config.tableName)
			if tablePart then
				print("[CardOrientationFixer] Processing table:", config.tableName)

				for _, child in ipairs(tablePart:GetChildren()) do
					if child:IsA("BasePart") and child.Name ~= config.cameraPart then
						-- Preserve current position, apply face-down rotation
						local currentPos = child.Position
						local newCFrame = CFrame.new(currentPos) * FACE_DOWN_ROTATION
						child.CFrame = newCFrame
					end
				end
			else
				warn("[CardOrientationFixer] Table not found:", config.tableName)
			end
		else
			warn("[CardOrientationFixer] Folder not found:", config.folderName)
		end
	end

	print("[CardOrientationFixer] All card orientations fixed.")
end

-- Run the fixer once at startup
fixCardOrientations()