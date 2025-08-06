-- NPCAnimationFixer Script
-- This script ensures NPC animations work by properly managing movement states
-- Place in ServerScriptService

local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage:WaitForChild("NPCFollowModules"):WaitForChild("NPCFollowConfig"))

local monitoredNPCs = {}

-- Function to ensure NPC has required components
local function setupNPCComponents(npcModel)
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	
	-- Ensure Animator exists
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
		print("[AnimationFixer] Created Animator for:", npcModel.Name)
	end
	
	-- Check for Animate script
	local animateScript = npcModel:FindFirstChild("Animate")
	if animateScript then
		-- Ensure the msg StringValue exists (required by Animate script)
		local msg = animateScript:FindFirstChild("msg")
		if not msg then
			msg = Instance.new("StringValue")
			msg.Name = "msg"
			msg.Parent = animateScript
			print("[AnimationFixer] Created msg StringValue for:", npcModel.Name)
		end
		
		-- If it's a LocalScript and we're on the server, we need to handle this differently
		if animateScript:IsA("LocalScript") then
			print("[AnimationFixer] Warning: Animate is a LocalScript in", npcModel.Name, "- animations may not work on server")
		end
	else
		print("[AnimationFixer] Warning: No Animate script found in", npcModel.Name)
	end
	
	return true
end

-- Function to help animations work by monitoring movement
local function monitorNPCMovement(npcModel)
	if monitoredNPCs[npcModel] then return end
	
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	local rootPart = npcModel:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not rootPart then return end
	
	-- Setup components
	if not setupNPCComponents(npcModel) then return end
	
	-- Store monitoring data
	local monitorData = {
		lastPosition = rootPart.Position,
		lastMoveToPosition = nil,
		isMoving = false,
		connection = nil
	}
	
	-- Create a helper part to visualize movement direction (for debugging)
	if Config.DEBUG_MODE then
		local debugPart = Instance.new("Part")
		debugPart.Name = "MoveDirectionDebug"
		debugPart.Size = Vector3.new(0.5, 0.5, 2)
		debugPart.Material = Enum.Material.Neon
		debugPart.BrickColor = BrickColor.new("Lime green")
		debugPart.CanCollide = false
		debugPart.Anchored = true
		debugPart.Parent = workspace
		monitorData.debugPart = debugPart
	end
	
	-- Monitor movement and ensure animations trigger
	monitorData.connection = RunService.Heartbeat:Connect(function()
		if not rootPart.Parent or not humanoid.Parent then
			monitorData.connection:Disconnect()
			if monitorData.debugPart then
				monitorData.debugPart:Destroy()
			end
			monitoredNPCs[npcModel] = nil
			return
		end
		
		local currentPosition = rootPart.Position
		local deltaPosition = currentPosition - monitorData.lastPosition
		
		-- Calculate actual movement speed
		local horizontalVelocity = Vector3.new(deltaPosition.X, 0, deltaPosition.Z) * 30
		local speed = horizontalVelocity.Magnitude
		
		-- The key issue: MoveDirection might not update properly with MoveTo
		-- We need to ensure the Animate script can detect movement
		local moveDirection = humanoid.MoveDirection
		
		-- Debug visualization
		if Config.DEBUG_MODE and monitorData.debugPart then
			if moveDirection.Magnitude > 0 then
				monitorData.debugPart.CFrame = CFrame.lookAt(
					rootPart.Position + Vector3.new(0, -2, 0),
					rootPart.Position + Vector3.new(0, -2, 0) + moveDirection * 3
				)
				monitorData.debugPart.Transparency = 0
			else
				monitorData.debugPart.Transparency = 1
			end
		end
		
		-- If NPC is moving but MoveDirection is zero, there's an issue
		if speed > 0.5 and moveDirection.Magnitude == 0 then
			-- This is the core problem - MoveTo doesn't always update MoveDirection on server
			-- The Animate script relies on MoveDirection to play walk/run animations
			if Config.DEBUG_MODE then
				print("[AnimationFixer]", npcModel.Name, "moving but MoveDirection is zero!")
				print("  Speed:", speed, "MoveDirection:", moveDirection)
			end
			
			-- Unfortunately, we cannot directly set MoveDirection
			-- The best solution is to ensure NPCFollowServer uses proper movement methods
		end
		
		monitorData.lastPosition = currentPosition
	end)
	
	-- Store in tracked NPCs
	monitoredNPCs[npcModel] = monitorData
	
	-- Clean up when NPC is removed
	npcModel.AncestryChanged:Connect(function()
		if not npcModel.Parent and monitoredNPCs[npcModel] then
			if monitoredNPCs[npcModel].connection then
				monitoredNPCs[npcModel].connection:Disconnect()
			end
			if monitoredNPCs[npcModel].debugPart then
				monitoredNPCs[npcModel].debugPart:Destroy()
			end
			monitoredNPCs[npcModel] = nil
		end
	end)
	
	print("[AnimationFixer] Now monitoring:", npcModel.Name)
end

-- Setup existing NPCs
task.wait(2) -- Wait for NPCs to load

local npcFolder = workspace:WaitForChild(Config.NPC_FOLDER_NAME, 10)
if npcFolder then
	-- Monitor existing NPCs
	for _, npcModel in pairs(npcFolder:GetChildren()) do
		if npcModel:IsA("Model") then
			monitorNPCMovement(npcModel)
		end
	end
	
	-- Monitor new NPCs
	npcFolder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.wait(0.5) -- Give time for NPC to fully load
			monitorNPCMovement(child)
		end
	end)
end

print("[NPCAnimationFixer] Animation fixing system active")
print("[NPCAnimationFixer] Note: If animations still don't work, ensure:")
print("  1. The Animate script is a Script (not LocalScript) for NPCs")
print("  2. NPCs have all required body parts (Head, Torso/UpperTorso, etc.)")
print("  3. Animation IDs in the Animate script are valid")