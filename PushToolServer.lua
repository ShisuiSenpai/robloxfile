-- Push Tool Server Script (Rewritten with Reliable Push System)
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local RAGDOLL_DURATION = 2 -- How long the ragdoll effect lasts (seconds)
local MAX_PUSH_DISTANCE = 15 -- Maximum allowed push distance
local PUSH_COOLDOWN_PER_PLAYER = {} -- Track cooldowns per player
local DEBUG = true -- Set to true for debug messages

-- Debug print function
local function debugPrint(...)
	if DEBUG then
		print("[PUSH SERVER]", ...)
	end
end

debugPrint("Push server script starting...")

-- Create RemoteEvent
local pushRemote = Instance.new("RemoteEvent")
pushRemote.Name = "PushRemote"
pushRemote.Parent = ReplicatedStorage

debugPrint("RemoteEvent created")

-- Create proper ragdoll with constraints
local function createRagdoll(character)
	debugPrint("Creating ragdoll for:", character.Name)
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end
	
	-- Store original joint data
	local originalJoints = {}
	local createdConstraints = {}
	
	-- Prevent death from neck break
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	
	-- Make sure root part is unanchored
	rootPart.Anchored = false
	
	-- Find and replace Motor6D joints with BallSocketConstraints
	for _, descendant in pairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			local joint = descendant
			local part0 = joint.Part0
			local part1 = joint.Part1
			
			if part0 and part1 then
				-- Store original joint data
				table.insert(originalJoints, {
					Motor6D = joint,
					Part0 = part0,
					Part1 = part1,
					C0 = joint.C0,
					C1 = joint.C1,
					Parent = joint.Parent,
					Name = joint.Name
				})
				
				-- Make sure parts are unanchored
				part0.Anchored = false
				part1.Anchored = false
				
				-- Create BallSocketConstraint
				local socket = Instance.new("BallSocketConstraint")
				socket.Name = "RagdollSocket_" .. joint.Name
				socket.Attachment0 = Instance.new("Attachment", part0)
				socket.Attachment1 = Instance.new("Attachment", part1)
				socket.Attachment0.CFrame = joint.C0
				socket.Attachment1.CFrame = joint.C1
				socket.LimitsEnabled = true
				socket.TwistLimitsEnabled = true
				socket.UpperAngle = 45
				socket.TwistLowerAngle = -45
				socket.TwistUpperAngle = 45
				socket.Parent = part0
				
				table.insert(createdConstraints, socket)
				table.insert(createdConstraints, socket.Attachment0)
				table.insert(createdConstraints, socket.Attachment1)
				
				-- Disable the Motor6D
				joint.Enabled = false
			end
		end
	end
	
	-- Set humanoid to ragdoll state
	humanoid.PlatformStand = true
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	-- Enable collision on limbs
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = true
		end
	end
	
	debugPrint("Ragdoll created with", #createdConstraints, "constraints")
	
	-- Return cleanup function
	return function()
		debugPrint("Removing ragdoll for:", character.Name)
		
		if not character.Parent then return end
		
		-- STEP 1: Clean up any leftover push forces
		for _, descendant in pairs(character:GetDescendants()) do
			if descendant.Name == "PushForce" or descendant.Name == "PushAttachment" then
				descendant:Destroy()
				debugPrint("Removed leftover push force/attachment")
			end
		end
		
		-- Stop all movement and clear velocities
		if rootPart and rootPart.Parent then
			rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end
		
		-- Clear velocities from all body parts
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end
		end
		
		task.wait(0.05)
		
		-- STEP 2: Position check and ground detection
		if rootPart and rootPart.Parent then
			local rayOrigin = rootPart.Position + Vector3.new(0, 3, 0)
			local rayDirection = Vector3.new(0, -50, 0)
			
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {character}
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			
			local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
			
			if rayResult then
				-- Found ground, position player safely above it
				local groundPosition = rayResult.Position
				local safeHeight = groundPosition + Vector3.new(0, 5, 0)
				
				debugPrint("Ground found at:", groundPosition.Y, "Moving player to:", safeHeight.Y)
				
				-- Position root part upright and above ground
				rootPart.CFrame = CFrame.new(safeHeight) * CFrame.Angles(0, rootPart.CFrame.Rotation.Y, 0)
			else
				-- No ground found, just orient upright
				debugPrint("No ground detected, orienting upright")
				rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, rootPart.CFrame.Rotation.Y, 0)
			end
		end
		
		task.wait(0.05)
		
		-- STEP 3: Remove all created constraints
		for _, constraint in pairs(createdConstraints) do
			if constraint and constraint.Parent then
				constraint:Destroy()
			end
		end
		
		-- STEP 4: Restore original joints
		for _, jointData in pairs(originalJoints) do
			if jointData.Motor6D and jointData.Motor6D.Parent then
				jointData.Motor6D.Enabled = true
			end
		end
		
		task.wait(0.05)
		
		-- STEP 5: Reset collision on limbs
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.CanCollide = false
			end
		end
		
		-- STEP 6: Reset humanoid state carefully
		if humanoid and humanoid.Parent then
			humanoid.RequiresNeck = true
			humanoid.BreakJointsOnDeath = true
			humanoid.PlatformStand = false
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			
			-- Force to standing/freefall state (better than GettingUp)
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			
			task.wait(0.1)
			
			-- Give a gentle upward boost to help land properly
			if rootPart and rootPart.Parent then
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 8, 0)
			end
		end
		
		debugPrint("Ragdoll removed successfully with safety checks")
	end
end

-- Apply push force using LinearVelocity constraint
local function applyPushForce(character, direction, force)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	-- Make absolutely sure root is unanchored
	rootPart.Anchored = false
	
	-- Create attachment for LinearVelocity
	local attachment = Instance.new("Attachment")
	attachment.Name = "PushAttachment"
	attachment.Parent = rootPart
	
	-- Create LinearVelocity constraint (modern physics constraint)
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "PushForce"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = direction * force
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = rootPart
	
	debugPrint("Created LinearVelocity with force:", direction * force)
	
	-- Remove the force after a short duration to allow natural physics
	task.delay(0.3, function()
		if linearVelocity and linearVelocity.Parent then
			linearVelocity:Destroy()
		end
		if attachment and attachment.Parent then
			attachment:Destroy()
		end
		debugPrint("Push force removed, natural physics taking over")
	end)
end

-- Handle push request
pushRemote.OnServerEvent:Connect(function(pusher, targetPlayer, direction, force)
	debugPrint("=== PUSH REQUEST ===")
	debugPrint("From:", pusher.Name, "To:", targetPlayer and targetPlayer.Name or "nil")
	
	-- Check server-side cooldown (anti-exploit)
	local currentTime = tick()
	if PUSH_COOLDOWN_PER_PLAYER[pusher] and currentTime - PUSH_COOLDOWN_PER_PLAYER[pusher] < 1.5 then
		debugPrint("Player", pusher.Name, "is on cooldown")
		return
	end
	PUSH_COOLDOWN_PER_PLAYER[pusher] = currentTime
	
	-- Validate players and characters
	local pusherCharacter = pusher.Character
	if not pusherCharacter then 
		debugPrint("Pusher has no character")
		return 
	end
	
	local targetCharacter = targetPlayer and targetPlayer.Character
	if not targetCharacter then 
		debugPrint("Target has no character")
		return 
	end
	
	local pusherRoot = pusherCharacter:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	
	if not pusherRoot or not targetRoot or not targetHumanoid then 
		debugPrint("Missing root parts or humanoid")
		return 
	end
	
	-- Check distance (anti-exploit)
	local distance = (targetRoot.Position - pusherRoot.Position).Magnitude
	debugPrint("Distance:", distance)
	
	if distance > MAX_PUSH_DISTANCE then
		warn(pusher.Name, "attempted to push from too far:", distance)
		return
	end
	
	-- Check if target is alive
	if targetHumanoid.Health <= 0 then 
		debugPrint("Target is dead")
		return 
	end
	
	-- Store original health to prevent damage
	local originalHealth = targetHumanoid.Health
	
	debugPrint("Push accepted! Applying...")
	
	-- Calculate push direction with upward arc
	local normalizedDirection = direction.Unit
	local pushDirection = (normalizedDirection + Vector3.new(0, 0.3, 0)).Unit
	
	-- Adjust force based on distance
	local distanceMultiplier = math.clamp(1.1 - (distance / MAX_PUSH_DISTANCE) * 0.3, 0.8, 1.1)
	local actualForce = math.clamp((force or 65) * distanceMultiplier, 35, 60)
	
	debugPrint("Final push direction:", pushDirection)
	debugPrint("Final push force:", actualForce)
	
	-- Apply the push BEFORE ragdolling for maximum effect
	applyPushForce(targetCharacter, pushDirection, actualForce)
	
	-- Slight delay then ragdoll
	task.wait(0.1)
	
	-- Create ragdoll
	local removeRagdoll = createRagdoll(targetCharacter)
	
	if removeRagdoll then
		-- Health protection during ragdoll
		local healthCheck = task.spawn(function()
			while task.wait(0.1) do
				if not targetHumanoid or not targetHumanoid.Parent then break end
				if targetHumanoid.Health < originalHealth then
					targetHumanoid.Health = originalHealth
				end
			end
		end)
		
		-- Wait for ragdoll duration
		task.wait(RAGDOLL_DURATION)
		
		-- Clean up
		task.cancel(healthCheck)
		removeRagdoll()
		
		-- Final health restore
		if targetHumanoid and targetHumanoid.Parent then
			targetHumanoid.Health = originalHealth
		end
		
		debugPrint("Push complete!")
	end
end)

-- Clean up cooldowns when players leave
Players.PlayerRemoving:Connect(function(player)
	PUSH_COOLDOWN_PER_PLAYER[player] = nil
end)

debugPrint("Push server script loaded successfully!")
print("===========================================")
print("Push System Ready!")
print("Using LinearVelocity constraints for reliable pushing")
print("===========================================")
