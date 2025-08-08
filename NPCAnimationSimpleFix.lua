-- NPCAnimationSimpleFix Script
-- A simpler approach to fix NPC animations
-- Place in ServerScriptService

local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage:WaitForChild("NPCFollowModules"):WaitForChild("NPCFollowConfig"))

local activeNPCs = {}

-- Function to create animation controller for NPC
local function setupNPCAnimation(npcModel)
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	local rootPart = npcModel:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not rootPart then return end
	
	-- Ensure Animator exists
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	
	-- Track NPC data
	local npcData = {
		Model = npcModel,
		Humanoid = humanoid,
		RootPart = rootPart,
		Animator = animator,
		LastPosition = rootPart.Position,
		LastVelocity = Vector3.zero,
		AnimateScript = npcModel:FindFirstChild("Animate")
	}
	
	-- The key fix: Use a BodyVelocity to ensure proper physics simulation
	-- This makes the Humanoid detect movement properly
	local bodyVelocity = rootPart:FindFirstChild("AnimationFixVelocity")
	if not bodyVelocity then
		bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Name = "AnimationFixVelocity"
		bodyVelocity.MaxForce = Vector3.new(0, 0, 0) -- Start with no force
		bodyVelocity.Velocity = Vector3.zero
		bodyVelocity.Parent = rootPart
	end
	npcData.BodyVelocity = bodyVelocity
	
	-- Monitor movement
	npcData.Connection = RunService.Heartbeat:Connect(function()
		if not rootPart.Parent then
			npcData.Connection:Disconnect()
			activeNPCs[npcModel] = nil
			return
		end
		
		local currentPos = rootPart.Position
		local deltaPos = currentPos - npcData.LastPosition
		local horizontalVelocity = Vector3.new(deltaPos.X, 0, deltaPos.Z) * 30 -- Convert to studs/second
		local speed = horizontalVelocity.Magnitude
		
		-- If moving but MoveDirection is zero, we need to help the Humanoid
		if speed > 0.5 then
			-- Apply a tiny force to trigger physics updates
			-- This helps the Humanoid realize it's moving
			bodyVelocity.MaxForce = Vector3.new(100, 0, 100)
			bodyVelocity.Velocity = horizontalVelocity * 0.1 -- Small velocity to not interfere
			
			-- Also ensure WalkSpeed matches movement
			if speed > 20 and humanoid.WalkSpeed < 20 then
				humanoid.WalkSpeed = math.min(speed, 50)
			end
			
			-- For the Animate script to work, it needs to see the Humanoid as "Running"
			-- We can help by ensuring the root part has velocity
			if rootPart.AssemblyLinearVelocity.Magnitude < 0.1 then
				-- The assembly isn't registering movement, apply impulse
				rootPart.AssemblyLinearVelocity = horizontalVelocity
			end
		else
			-- Not moving, disable helper velocity
			bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
			bodyVelocity.Velocity = Vector3.zero
		end
		
		npcData.LastPosition = currentPos
		npcData.LastVelocity = horizontalVelocity
	end)
	
	activeNPCs[npcModel] = npcData
	
	-- Clean up on removal
	npcModel.AncestryChanged:Connect(function()
		if not npcModel.Parent and activeNPCs[npcModel] then
			if activeNPCs[npcModel].Connection then
				activeNPCs[npcModel].Connection:Disconnect()
			end
			if activeNPCs[npcModel].BodyVelocity then
				activeNPCs[npcModel].BodyVelocity:Destroy()
			end
			activeNPCs[npcModel] = nil
		end
	end)
	
	print("[AnimationSimpleFix] Setup animation fix for:", npcModel.Name)
end

-- Wait for NPCs to load
task.wait(2)

local npcFolder = workspace:WaitForChild(Config.NPC_FOLDER_NAME, 10)
if npcFolder then
	-- Setup existing NPCs
	for _, npcModel in pairs(npcFolder:GetChildren()) do
		if npcModel:IsA("Model") then
			setupNPCAnimation(npcModel)
		end
	end
	
	-- Setup new NPCs
	npcFolder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.wait(0.5) -- Let NPC fully load
			setupNPCAnimation(child)
		end
	end)
end

print("[NPCAnimationSimpleFix] Animation fix system active")
print("[NPCAnimationSimpleFix] This ensures NPCs have proper physics for animations")