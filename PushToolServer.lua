-- Push Tool Server Script (Improved with Proper Ragdoll)
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local RAGDOLL_DURATION = 2 -- How long the ragdoll effect lasts (seconds)
local MAX_PUSH_DISTANCE = 15 -- Maximum allowed push distance
local PUSH_COOLDOWN_PER_PLAYER = {} -- Track cooldowns per player
local DEBUG = false -- Set to true for debug messages

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

-- Create proper ragdoll with constraints (joints stay connected)
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
				
				-- Create BallSocketConstraint to keep parts connected but allow rotation
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
				
				-- Disable the Motor6D (don't destroy it)
				joint.Enabled = false
				
				debugPrint("Replaced joint:", joint.Name)
			end
		end
	end
	
	-- Set humanoid to ragdoll state
	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	-- Enable collision on limbs for realistic falling
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = true
			part.CollisionGroup = "Ragdoll"
		end
	end
	
	debugPrint("Ragdoll created with", #createdConstraints, "constraints")
	
	-- Return cleanup function
	return function()
		debugPrint("Removing ragdoll for:", character.Name)
		
		if not character.Parent then return end
		
		-- Remove all created constraints
		for _, constraint in pairs(createdConstraints) do
			if constraint and constraint.Parent then
				constraint:Destroy()
			end
		end
		
		-- Restore original joints
		for _, jointData in pairs(originalJoints) do
			if jointData.Motor6D and jointData.Motor6D.Parent then
				jointData.Motor6D.Enabled = true
			end
		end
		
		-- Reset humanoid state
		if humanoid and humanoid.Parent then
			humanoid.RequiresNeck = true
			humanoid.BreakJointsOnDeath = true
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			
			-- Give a small upward boost to help stand
			if rootPart and rootPart.Parent then
				rootPart.AssemblyLinearVelocity = Vector3.new(
					rootPart.AssemblyLinearVelocity.X * 0.3,
					8,
					rootPart.AssemblyLinearVelocity.Z * 0.3
				)
			end
		end
		
		-- Reset collision
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.CanCollide = false
				part.CollisionGroup = "Default"
			end
		end
		
		debugPrint("Ragdoll removed successfully")
	end
end

-- Handle push request
pushRemote.OnServerEvent:Connect(function(pusher, targetPlayer, direction, force)
	debugPrint("Push request from:", pusher.Name, "to:", targetPlayer and targetPlayer.Name or "nil")
	
	-- Check server-side cooldown (anti-exploit)
	local currentTime = tick()
	if PUSH_COOLDOWN_PER_PLAYER[pusher] and currentTime - PUSH_COOLDOWN_PER_PLAYER[pusher] < 1.5 then
		debugPrint("Player", pusher.Name, "is on cooldown")
		return
	end
	PUSH_COOLDOWN_PER_PLAYER[pusher] = currentTime
	
	-- Validate players and characters
	local pusherCharacter = pusher.Character
	if not pusherCharacter then return end
	
	local targetCharacter = targetPlayer and targetPlayer.Character
	if not targetCharacter then return end
	
	local pusherRoot = pusherCharacter:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	
	if not pusherRoot or not targetRoot or not targetHumanoid then return end
	
	-- Check distance (anti-exploit)
	local distance = (targetRoot.Position - pusherRoot.Position).Magnitude
	if distance > MAX_PUSH_DISTANCE then
		warn(pusher.Name, "attempted to push from too far:", distance)
		return
	end
	
	-- Check if target is alive
	if targetHumanoid.Health <= 0 then return end
	
	-- Store original health to prevent damage
	local originalHealth = targetHumanoid.Health
	
	debugPrint("Applying push to", targetPlayer.Name)
	
	-- Calculate push direction with upward arc
	local normalizedDirection = direction.Unit
	local pushDirection = (normalizedDirection + Vector3.new(0, 0.35, 0)).Unit
	
	-- Adjust force based on distance (closer = stronger, but not too strong)
	local distanceMultiplier = math.clamp(1.1 - (distance / MAX_PUSH_DISTANCE) * 0.3, 0.8, 1.1)
	local actualForce = math.clamp((force or 65) * distanceMultiplier, 45, 75)
	
	debugPrint("Push force:", actualForce, "Distance multiplier:", distanceMultiplier)
	
	-- Create ragdoll FIRST
	local removeRagdoll = createRagdoll(targetCharacter)
	
	-- Wait a tiny bit for ragdoll to initialize
	task.wait(0.05)
	
	-- Apply impulse to multiple body parts for reliable push
	local partsToApplyForce = {
		targetRoot,
		targetCharacter:FindFirstChild("UpperTorso") or targetCharacter:FindFirstChild("Torso"),
		targetCharacter:FindFirstChild("Head")
	}
	
	for _, part in pairs(partsToApplyForce) do
		if part and part:IsA("BasePart") then
			-- Use ApplyImpulse for more reliable physics
			local impulse = pushDirection * actualForce * part.AssemblyMass
			part:ApplyImpulse(impulse)
			debugPrint("Applied impulse to", part.Name)
		end
	end
	
	if removeRagdoll then
		-- Health protection during ragdoll
		local healthCheck = task.spawn(function()
			for i = 1, RAGDOLL_DURATION * 10 do
				task.wait(0.1)
				if targetHumanoid and targetHumanoid.Parent and targetHumanoid.Health < originalHealth then
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
		
		debugPrint("Push complete for", targetPlayer.Name)
	end
end)

-- Clean up cooldowns when players leave
Players.PlayerRemoving:Connect(function(player)
	PUSH_COOLDOWN_PER_PLAYER[player] = nil
end)

debugPrint("Push server script loaded successfully!")
print("Push System Ready! Players will be pushed with realistic ragdoll physics.")
