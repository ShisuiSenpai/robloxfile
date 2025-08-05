-- TestDummySpawner Script
-- Place in: ServerScriptService > TestDummySpawner
-- This creates test dummies to lock onto

local function createTestDummy(position, name)
	local dummy = Instance.new("Model")
	dummy.Name = name or "TestDummy"
	
	-- Create humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.Parent = dummy
	
	-- Create root part
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Anchored = true
	rootPart.CanCollide = false
	rootPart.Transparency = 0.5
	rootPart.BrickColor = BrickColor.new("Bright blue")
	rootPart.Position = position
	rootPart.Parent = dummy
	
	-- Create head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.Anchored = true
	head.CanCollide = false
	head.BrickColor = BrickColor.new("Bright yellow")
	head.Position = position + Vector3.new(0, 2, 0)
	head.Parent = dummy
	
	-- Create torso
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Anchored = true
	torso.CanCollide = false
	torso.BrickColor = BrickColor.new("Bright blue")
	torso.Position = position + Vector3.new(0, 0.5, 0)
	torso.Parent = dummy
	
	-- Add a face to make it more visible
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head
	
	-- Set primary part
	dummy.PrimaryPart = rootPart
	
	-- Parent to workspace
	dummy.Parent = workspace
	
	return dummy
end

-- Wait a moment for the game to load
wait(2)

-- Get spawn location (near the spawn point)
local spawnLocation = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChildOfClass("SpawnLocation")
local basePosition = spawnLocation and spawnLocation.Position or Vector3.new(0, 5, 0)

-- Create multiple test dummies in a circle
local dummyCount = 5
local radius = 20

for i = 1, dummyCount do
	local angle = (i / dummyCount) * math.pi * 2
	local x = basePosition.X + math.cos(angle) * radius
	local z = basePosition.Z + math.sin(angle) * radius
	local position = Vector3.new(x, basePosition.Y, z)
	
	local dummy = createTestDummy(position, "TestDummy" .. i)
	print("Created test dummy at:", position)
end

print("Test dummies spawned! You should now be able to lock onto them with F key.")