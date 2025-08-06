-- NPCAnimationDiagnostic Script
-- Place in: ServerScriptService
-- This will help diagnose why animations aren't working

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Wait for configuration
local NPCFollowModules = ReplicatedStorage:WaitForChild("NPCFollowModules")
local Config = require(NPCFollowModules:WaitForChild("NPCFollowConfig"))

local function diagnoseNPC(npcModel)
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	local animateScript = npcModel:FindFirstChild("Animate")
	local rootPart = npcModel:FindFirstChild("HumanoidRootPart") or npcModel:FindFirstChild("Torso")
	
	if not humanoid then
		warn("[Diagnostic] NPC", npcModel.Name, "missing Humanoid!")
		return
	end
	
	if not animateScript then
		warn("[Diagnostic] NPC", npcModel.Name, "missing Animate script!")
		return
	end
	
	if not rootPart then
		warn("[Diagnostic] NPC", npcModel.Name, "missing HumanoidRootPart/Torso!")
		return
	end
	
	print("[Diagnostic] Checking NPC:", npcModel.Name)
	print("  - Humanoid WalkSpeed:", humanoid.WalkSpeed)
	print("  - Humanoid State:", humanoid:GetState())
	
	-- Create an Animator if it doesn't exist
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
		print("  - Created Animator for", npcModel.Name)
	end
	
	-- Monitor movement
	local lastPosition = rootPart.Position
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not rootPart.Parent then
			connection:Disconnect()
			return
		end
		
		local currentPosition = rootPart.Position
		local velocity = (currentPosition - lastPosition) / (1/30)
		local speed = velocity.Magnitude
		
		if speed > 0.1 then
			print("[Diagnostic]", npcModel.Name, "is moving at speed:", speed)
			print("  - Velocity:", velocity)
			print("  - Humanoid MoveDirection:", humanoid.MoveDirection)
			print("  - Humanoid Moving:", humanoid.MoveDirection.Magnitude > 0)
			
			-- Force fire the Running event
			print("  - Manually firing Running event with speed:", speed)
			humanoid.Running:Fire(speed)
		end
		
		lastPosition = currentPosition
	end)
	
	-- Store connection for cleanup
	npcModel.AncestryChanged:Connect(function()
		if not npcModel.Parent then
			connection:Disconnect()
		end
	end)
end

-- Wait for NPCs
wait(2)

local npcFolder = workspace:WaitForChild(Config.NPC_FOLDER_NAME, 10)
if npcFolder then
	for _, npcModel in pairs(npcFolder:GetChildren()) do
		if npcModel:IsA("Model") then
			diagnoseNPC(npcModel)
		end
	end
	
	npcFolder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			wait(0.5)
			diagnoseNPC(child)
		end
	end)
end

print("[NPCAnimationDiagnostic] Diagnostic system running...")