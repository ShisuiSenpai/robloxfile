-- NPCSetupHelper Script
-- Place in: ServerScriptService > NPCSetupHelper
-- This script helps create test NPCs for the follow system

local function createTestNPC(position, name, appearance)
	local npc = Instance.new("Model")
	npc.Name = name or "FollowerNPC"
	
	-- Create Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = 16
	humanoid.Parent = npc
	
	-- Create HumanoidRootPart
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 1
	rootPart.Anchored = false
	rootPart.CanCollide = false
	rootPart.Position = position
	rootPart.Parent = npc
	
	-- Create Torso
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.BrickColor = appearance.TorsoColor or BrickColor.new("Bright blue")
	torso.TopSurface = Enum.SurfaceType.Smooth
	torso.BottomSurface = Enum.SurfaceType.Smooth
	torso.Parent = npc
	
	-- Create Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.BrickColor = appearance.HeadColor or BrickColor.new("Bright yellow")
	head.TopSurface = Enum.SurfaceType.Smooth
	head.BottomSurface = Enum.SurfaceType.Smooth
	head.Parent = npc
	
	-- Add face
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = appearance.FaceTexture or "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head
	
	-- Create Mesh for head
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = head
	
	-- Create Arms
	local leftArm = Instance.new("Part")
	leftArm.Name = "Left Arm"
	leftArm.Size = Vector3.new(1, 2, 1)
	leftArm.BrickColor = appearance.LimbColor or BrickColor.new("Bright yellow")
	leftArm.TopSurface = Enum.SurfaceType.Smooth
	leftArm.BottomSurface = Enum.SurfaceType.Smooth
	leftArm.Parent = npc
	
	local rightArm = Instance.new("Part")
	rightArm.Name = "Right Arm"
	rightArm.Size = Vector3.new(1, 2, 1)
	rightArm.BrickColor = appearance.LimbColor or BrickColor.new("Bright yellow")
	rightArm.TopSurface = Enum.SurfaceType.Smooth
	rightArm.BottomSurface = Enum.SurfaceType.Smooth
	rightArm.Parent = npc
	
	-- Create Legs
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1, 2, 1)
	leftLeg.BrickColor = appearance.LegColor or BrickColor.new("Dark green")
	leftLeg.TopSurface = Enum.SurfaceType.Smooth
	leftLeg.BottomSurface = Enum.SurfaceType.Smooth
	leftLeg.Parent = npc
	
	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1, 2, 1)
	rightLeg.BrickColor = appearance.LegColor or BrickColor.new("Dark green")
	rightLeg.TopSurface = Enum.SurfaceType.Smooth
	rightLeg.BottomSurface = Enum.SurfaceType.Smooth
	rightLeg.Parent = npc
	
	-- Position parts relative to root
	torso.CFrame = rootPart.CFrame
	head.CFrame = rootPart.CFrame * CFrame.new(0, 1.5, 0)
	leftArm.CFrame = rootPart.CFrame * CFrame.new(-1.5, 0, 0)
	rightArm.CFrame = rootPart.CFrame * CFrame.new(1.5, 0, 0)
	leftLeg.CFrame = rootPart.CFrame * CFrame.new(-0.5, -2, 0)
	rightLeg.CFrame = rootPart.CFrame * CFrame.new(0.5, -2, 0)
	
	-- Create Motor6D joints
	local rootJoint = Instance.new("Motor6D")
	rootJoint.Name = "RootJoint"
	rootJoint.Part0 = rootPart
	rootJoint.Part1 = torso
	rootJoint.C0 = CFrame.new(0, 0, 0)
	rootJoint.C1 = CFrame.new(0, 0, 0)
	rootJoint.Parent = rootPart
	
	local neck = Instance.new("Motor6D")
	neck.Name = "Neck"
	neck.Part0 = torso
	neck.Part1 = head
	neck.C0 = CFrame.new(0, 1, 0)
	neck.C1 = CFrame.new(0, -0.5, 0)
	neck.Parent = torso
	
	local leftShoulder = Instance.new("Motor6D")
	leftShoulder.Name = "Left Shoulder"
	leftShoulder.Part0 = torso
	leftShoulder.Part1 = leftArm
	leftShoulder.C0 = CFrame.new(-1, 0.5, 0)
	leftShoulder.C1 = CFrame.new(0.5, 0.5, 0)
	leftShoulder.Parent = torso
	
	local rightShoulder = Instance.new("Motor6D")
	rightShoulder.Name = "Right Shoulder"
	rightShoulder.Part0 = torso
	rightShoulder.Part1 = rightArm
	rightShoulder.C0 = CFrame.new(1, 0.5, 0)
	rightShoulder.C1 = CFrame.new(-0.5, 0.5, 0)
	rightShoulder.Parent = torso
	
	local leftHip = Instance.new("Motor6D")
	leftHip.Name = "Left Hip"
	leftHip.Part0 = torso
	leftHip.Part1 = leftLeg
	leftHip.C0 = CFrame.new(-0.5, -1, 0)
	leftHip.C1 = CFrame.new(0, 1, 0)
	leftHip.Parent = torso
	
	local rightHip = Instance.new("Motor6D")
	rightHip.Name = "Right Hip"
	rightHip.Part0 = torso
	rightHip.Part1 = rightLeg
	rightHip.C0 = CFrame.new(0.5, -1, 0)
	rightHip.C1 = CFrame.new(0, 1, 0)
	rightHip.Parent = torso
	
	-- Set primary part
	npc.PrimaryPart = rootPart
	
	-- Add BodyPosition to keep NPC upright
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
	bodyPosition.Position = rootPart.Position
	bodyPosition.Parent = rootPart
	
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(0, math.huge, 0)
	bodyGyro.CFrame = rootPart.CFrame
	bodyGyro.Parent = rootPart
	
	return npc
end

-- Function to spawn NPCs in different formations
local function spawnNPCFormation(formationType, centerPosition, npcCount)
	local npcs = {}
	
	if formationType == "circle" then
		local radius = 15
		for i = 1, npcCount do
			local angle = (i / npcCount) * math.pi * 2
			local x = centerPosition.X + math.cos(angle) * radius
			local z = centerPosition.Z + math.sin(angle) * radius
			local position = Vector3.new(x, centerPosition.Y + 5, z)
			
			local appearance = {
				TorsoColor = BrickColor.Random(),
				HeadColor = BrickColor.new("Light orange"),
				LimbColor = BrickColor.new("Light orange"),
				LegColor = BrickColor.new("Dark stone grey")
			}
			
			local npc = createTestNPC(position, "CircleNPC_" .. i, appearance)
			table.insert(npcs, npc)
		end
		
	elseif formationType == "line" then
		local spacing = 5
		for i = 1, npcCount do
			local offset = (i - (npcCount + 1) / 2) * spacing
			local position = centerPosition + Vector3.new(offset, 5, 0)
			
			local appearance = {
				TorsoColor = BrickColor.new("Bright red"),
				HeadColor = BrickColor.new("Light orange"),
				LimbColor = BrickColor.new("Light orange"),
				LegColor = BrickColor.new("Black")
			}
			
			local npc = createTestNPC(position, "LineNPC_" .. i, appearance)
			table.insert(npcs, npc)
		end
		
	elseif formationType == "grid" then
		local gridSize = math.ceil(math.sqrt(npcCount))
		local spacing = 5
		local npcIndex = 1
		
		for x = 1, gridSize do
			for z = 1, gridSize do
				if npcIndex <= npcCount then
					local offsetX = (x - (gridSize + 1) / 2) * spacing
					local offsetZ = (z - (gridSize + 1) / 2) * spacing
					local position = centerPosition + Vector3.new(offsetX, 5, offsetZ)
					
					local appearance = {
						TorsoColor = BrickColor.new("Navy blue"),
						HeadColor = BrickColor.new("Light orange"),
						LimbColor = BrickColor.new("Light orange"),
						LegColor = BrickColor.new("Black")
					}
					
					local npc = createTestNPC(position, "GridNPC_" .. npcIndex, appearance)
					table.insert(npcs, npc)
					npcIndex = npcIndex + 1
				end
			end
		end
	end
	
	return npcs
end

-- Create or get NPCS folder
local npcFolder = workspace:FindFirstChild("NPCS")
if not npcFolder then
	npcFolder = Instance.new("Folder")
	npcFolder.Name = "NPCS"
	npcFolder.Parent = workspace
	print("[NPCSetup] Created NPCS folder")
end

-- Wait for game to load
wait(3)

-- Get spawn position
local spawnLocation = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChildOfClass("SpawnLocation")
local centerPosition = spawnLocation and spawnLocation.Position or Vector3.new(0, 0, 0)

-- Configuration
local SPAWN_FORMATION = "circle" -- Options: "circle", "line", "grid"
local NPC_COUNT = 5
local AUTO_SPAWN = true -- Set to false to disable automatic spawning

-- Spawn NPCs automatically
if AUTO_SPAWN then
	print("[NPCSetup] Spawning", NPC_COUNT, "NPCs in", SPAWN_FORMATION, "formation...")
	local npcs = spawnNPCFormation(SPAWN_FORMATION, centerPosition, NPC_COUNT)
	
	-- Parent all NPCs to the folder
	for _, npc in pairs(npcs) do
		npc.Parent = npcFolder
	end
	
	print("[NPCSetup] Spawned", #npcs, "test NPCs!")
end

-- Commands for manual spawning (can be called from command bar)
_G.SpawnFollowerNPCs = function(count, formation)
	count = count or 5
	formation = formation or "circle"
	
	local npcs = spawnNPCFormation(formation, centerPosition, count)
	for _, npc in pairs(npcs) do
		npc.Parent = npcFolder
	end
	
	print("[NPCSetup] Spawned", #npcs, "NPCs in", formation, "formation!")
end

_G.ClearFollowerNPCs = function()
	for _, npc in pairs(npcFolder:GetChildren()) do
		if npc:IsA("Model") then
			npc:Destroy()
		end
	end
	print("[NPCSetup] Cleared all NPCs from folder")
end

print("[NPCSetup] Helper loaded! Commands available:")
print("  _G.SpawnFollowerNPCs(count, formation) - Spawn NPCs")
print("  _G.ClearFollowerNPCs() - Remove all NPCs")
print("  Formations: 'circle', 'line', 'grid'")