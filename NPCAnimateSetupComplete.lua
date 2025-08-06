-- NPCAnimateSetupComplete Script
-- This script ensures NPCs have proper animation setup and handles server-side movement detection
-- Place in ServerScriptService

local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage:WaitForChild("NPCFollowModules"):WaitForChild("NPCFollowConfig"))

-- Table to track NPCs with animation handlers
local animationHandlers = {}

-- Function to create a movement handler for an NPC
local function createMovementHandler(npcModel, humanoid, animateScript)
	local handler = {
		humanoid = humanoid,
		animateScript = animateScript,
		rootPart = npcModel:FindFirstChild("HumanoidRootPart"),
		lastPosition = nil,
		currentAnim = "idle",
		connection = nil
	}
	
	if not handler.rootPart then
		print("[AnimateSetup] No HumanoidRootPart found for", npcModel.Name)
		return nil
	end
	
	handler.lastPosition = handler.rootPart.Position
	
	-- Create the movement monitoring connection
	handler.connection = RunService.Heartbeat:Connect(function()
		if not handler.humanoid.Parent or not handler.rootPart.Parent then
			handler.connection:Disconnect()
			animationHandlers[npcModel] = nil
			return
		end
		
		local currentPosition = handler.rootPart.Position
		local deltaPosition = currentPosition - handler.lastPosition
		local horizontalVelocity = Vector3.new(deltaPosition.X, 0, deltaPosition.Z) * 30
		local speed = horizontalVelocity.Magnitude
		
		-- Determine which animation should play based on speed
		local targetAnim = "idle"
		if speed > 0.5 then
			if speed < 10 then
				targetAnim = "walk"
			else
				targetAnim = "run"
			end
		end
		
		-- If animation state changed, update the Animate script
		if targetAnim ~= handler.currentAnim then
			handler.currentAnim = targetAnim
			
			-- The Animate script uses a StringValue called "msg" to trigger animations
			local msg = animateScript:FindFirstChild("msg")
			if msg then
				-- Trigger the appropriate animation by setting the msg value
				if targetAnim == "idle" then
					msg.Value = "" -- Empty string stops movement animations
				elseif targetAnim == "walk" then
					-- For walk/run, we need to ensure the humanoid state is correct
					-- The Animate script checks the humanoid's state
					if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
						humanoid:ChangeState(Enum.HumanoidStateType.Running)
					end
				elseif targetAnim == "run" then
					if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
						humanoid:ChangeState(Enum.HumanoidStateType.Running)
					end
				end
			end
			
			if Config.DEBUG_MODE then
				print("[AnimateSetup]", npcModel.Name, "animation changed to:", targetAnim, "speed:", speed)
			end
		end
		
		handler.lastPosition = currentPosition
	end)
	
	return handler
end

-- Function to setup an NPC with proper animation components
local function setupNPCAnimation(npcModel)
	print("[AnimateSetup] Setting up animations for:", npcModel.Name)
	
	-- Find required components
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		print("[AnimateSetup] No Humanoid found in", npcModel.Name)
		return
	end
	
	-- Find the Animate script
	local animateScript = npcModel:FindFirstChild("Animate")
	if not animateScript then
		print("[AnimateSetup] No Animate script found in", npcModel.Name)
		return
	end
	
	-- Ensure the script is a Script (not LocalScript) for server execution
	if animateScript:IsA("LocalScript") then
		print("[AnimateSetup] Warning: Animate is a LocalScript in", npcModel.Name)
		print("[AnimateSetup] Converting to Script for server-side execution...")
		
		-- Create a new Script with the same code
		local newScript = Instance.new("Script")
		newScript.Name = "Animate"
		newScript.Source = animateScript.Source
		
		-- Copy all children (animation StringValues)
		for _, child in pairs(animateScript:GetChildren()) do
			child:Clone().Parent = newScript
		end
		
		-- Replace the LocalScript
		animateScript:Destroy()
		newScript.Parent = npcModel
		animateScript = newScript
	end
	
	-- Ensure Animator exists
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
		print("[AnimateSetup] Created Animator for", npcModel.Name)
	end
	
	-- Ensure the msg StringValue exists (used by Animate script)
	local msg = animateScript:FindFirstChild("msg")
	if not msg then
		msg = Instance.new("StringValue")
		msg.Name = "msg"
		msg.Parent = animateScript
		print("[AnimateSetup] Created msg StringValue for", npcModel.Name)
	end
	
	-- Create movement handler for this NPC
	local handler = createMovementHandler(npcModel, humanoid, animateScript)
	if handler then
		animationHandlers[npcModel] = handler
		print("[AnimateSetup] Animation handler created for", npcModel.Name)
	end
	
	-- Ensure the Animate script is enabled
	animateScript.Disabled = false
	
	print("[AnimateSetup] Setup complete for", npcModel.Name)
end

-- Clean up handler when NPC is removed
local function cleanupNPC(npcModel)
	local handler = animationHandlers[npcModel]
	if handler then
		if handler.connection then
			handler.connection:Disconnect()
		end
		animationHandlers[npcModel] = nil
	end
end

-- Setup existing NPCs
task.wait(2) -- Wait for NPCs to load

local npcFolder = workspace:WaitForChild(Config.NPC_FOLDER_NAME, 10)
if npcFolder then
	-- Setup existing NPCs
	for _, npcModel in pairs(npcFolder:GetChildren()) do
		if npcModel:IsA("Model") then
			setupNPCAnimation(npcModel)
		end
	end
	
	-- Monitor new NPCs
	npcFolder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.wait(0.5) -- Give time for NPC to fully load
			setupNPCAnimation(child)
		end
	end)
	
	-- Clean up removed NPCs
	npcFolder.ChildRemoved:Connect(function(child)
		if child:IsA("Model") then
			cleanupNPC(child)
		end
	end)
end

print("[NPCAnimateSetupComplete] Animation setup system initialized")
print("[NPCAnimateSetupComplete] Note: Place the Animate script directly in each NPC model")
print("[NPCAnimateSetupComplete] The Animate script should contain animation StringValues as children")