-- NPCAnimationFixer Script
-- Place in: ServerScriptService
-- This ensures NPC animations work by monitoring movement and firing appropriate events

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Wait for configuration
local NPCFollowModules = ReplicatedStorage:WaitForChild("NPCFollowModules")
local Config = require(NPCFollowModules:WaitForChild("NPCFollowConfig"))

local monitoredNPCs = {}

local function monitorNPCMovement(npcModel)
	-- Avoid duplicate monitoring
	if monitoredNPCs[npcModel] then return end
	
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	local rootPart = npcModel:FindFirstChild("HumanoidRootPart") or npcModel:FindFirstChild("Torso")
	
	if not humanoid or not rootPart then return end
	
	-- Ensure Animator exists
	if not humanoid:FindFirstChild("Animator") then
		local animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	
	-- Store monitoring data
	local monitorData = {
		lastPosition = rootPart.Position,
		lastVelocity = Vector3.new(0, 0, 0),
		isMoving = false,
		connection = nil
	}
	
	-- Monitor movement and fire events
	monitorData.connection = RunService.Heartbeat:Connect(function()
		if not rootPart.Parent or not humanoid.Parent then
			monitorData.connection:Disconnect()
			monitoredNPCs[npcModel] = nil
			return
		end
		
		local currentPosition = rootPart.Position
		local deltaPosition = currentPosition - monitorData.lastPosition
		
		-- Calculate horizontal speed (ignore Y for walking/running)
		local horizontalVelocity = Vector3.new(deltaPosition.X, 0, deltaPosition.Z) * 30 -- Convert to studs/second
		local speed = horizontalVelocity.Magnitude
		
		-- Check if NPC is actually trying to move (has a move destination)
		local isIntentionallyMoving = humanoid.MoveDirection.Magnitude > 0
		
		if isIntentionallyMoving and speed > 0.1 then
			-- NPC is moving
			if not monitorData.isMoving then
				monitorData.isMoving = true
			end
			
			-- Fire the Running event with current speed
			-- The Animate script expects this event to trigger walk/run animations
			humanoid.Running:Fire(speed)
			
		elseif not isIntentionallyMoving or speed < 0.1 then
			-- NPC stopped
			if monitorData.isMoving then
				monitorData.isMoving = false
				-- Fire Running event with 0 speed to trigger idle
				humanoid.Running:Fire(0)
			end
		end
		
		monitorData.lastPosition = currentPosition
		monitorData.lastVelocity = horizontalVelocity
	end)
	
	monitoredNPCs[npcModel] = monitorData
	
	-- Clean up when NPC is removed
	npcModel.AncestryChanged:Connect(function()
		if not npcModel.Parent and monitoredNPCs[npcModel] then
			monitoredNPCs[npcModel].connection:Disconnect()
			monitoredNPCs[npcModel] = nil
		end
	end)
	
	print("[AnimationFixer] Now monitoring animations for:", npcModel.Name)
end

-- Setup existing NPCs
wait(1) -- Wait for NPCs to load

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
			wait(0.1) -- Small delay to ensure NPC is fully loaded
			monitorNPCMovement(child)
		end
	end)
	
	print("[AnimationFixer] Animation fixer initialized for NPC folder:", Config.NPC_FOLDER_NAME)
else
	warn("[AnimationFixer] Could not find NPC folder:", Config.NPC_FOLDER_NAME)
end