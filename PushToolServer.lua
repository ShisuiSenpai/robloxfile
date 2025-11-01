-- Push Tool Server Script (Optimized)
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local RAGDOLL_DURATION = 1.5 -- How long the ragdoll effect lasts
local MAX_PUSH_DISTANCE = 15 -- Maximum allowed push distance
local PUSH_COOLDOWN_PER_PLAYER = {} -- Track cooldowns per player
local USE_RAGDOLL = true -- Use ragdoll physics

-- Debug mode
local DEBUG = true -- Set to false to hide debug messages

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

-- PROPER RAGDOLL: Joints break but parts stay together
local function ragdollCharacter(character)
	debugPrint("Starting ragdoll (breaking joints) for:", character.Name)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then 
		debugPrint("No humanoid found!")
		return 
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
	if not rootPart then
		debugPrint("No root part found!")
		return
	end

	-- Store original health
	local originalHealth = humanoid.Health
	local originalMaxHealth = humanoid.MaxHealth

	-- CRITICAL: Prevent death
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false

	-- Store joint information - DISABLE them (not destroy) so parts stay together
	local joints = {}

	-- Break joints by disabling them (parts stay attached but joints don't work)
	for _, joint in pairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") and joint.Name ~= "RootJoint" then
			joints[joint] = joint.Enabled
			joint.Enabled = false -- Break the joint (disable it)
			debugPrint("Broke joint:", joint.Name)
		end
	end

	-- Enable physics on all parts
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
			part.Anchored = false
		end
	end

	-- Set humanoid to ragdoll state
	humanoid.PlatformStand = true
	if humanoid:GetState() ~= Enum.HumanoidStateType.Ragdoll then
		humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	end

	-- Health protection loop
	local healthProtection = task.spawn(function()
		while humanoid and humanoid.Parent and character.Parent do
			if humanoid.Health < originalHealth then
				humanoid.Health = originalHealth
			end
			task.wait(0.1)
		end
	end)

	debugPrint("Ragdoll applied successfully - joints broken")

	-- Return recovery function
	return function()
		debugPrint("Recovering from ragdoll - restoring joints:", character.Name)

		if not character.Parent then 
			debugPrint("Character no longer exists")
			return 
		end

		-- Stop health protection
		task.cancel(healthProtection)

		-- RESTORE all broken joints (re-enable them)
		for joint, wasEnabled in pairs(joints) do
			if joint and joint.Parent then
				joint.Enabled = wasEnabled
			end
		end

		-- Reset collision
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part ~= rootPart then
				part.CanCollide = false
			end
		end

		-- Restore humanoid state
		if humanoid and humanoid.Parent then
			humanoid.RequiresNeck = true
			humanoid.BreakJointsOnDeath = true
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			
			-- Restore health
			humanoid.Health = originalHealth
			humanoid.MaxHealth = originalMaxHealth

			-- Help them stand up with a small upward boost
			if rootPart then
				rootPart.AssemblyLinearVelocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, 5, rootPart.AssemblyLinearVelocity.Z)
			end
		end

		debugPrint("Character recovered from ragdoll successfully - joints restored")
	end
end

-- Handle push request (OPTIMIZED)
pushRemote.OnServerEvent:Connect(function(pusher, targetPlayer, direction, force)
	debugPrint("Push request from:", pusher.Name, "to:", targetPlayer and targetPlayer.Name or "nil")

	-- Check server-side cooldown
	local currentTime = tick()
	if PUSH_COOLDOWN_PER_PLAYER[pusher] and currentTime - PUSH_COOLDOWN_PER_PLAYER[pusher] < 2 then
		debugPrint("Player", pusher.Name, "is on cooldown")
		return
	end
	PUSH_COOLDOWN_PER_PLAYER[pusher] = currentTime

	-- Validate and cache references
	local pusherCharacter = pusher.Character
	if not pusherCharacter then
		debugPrint("Pusher has no character")
		return
	end

	local targetCharacter = targetPlayer and targetPlayer.Character
	if not targetCharacter then
		debugPrint("Invalid target player or character")
		return
	end

	local pusherRoot = pusherCharacter:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")

	if not pusherRoot or not targetRoot or not targetHumanoid then
		debugPrint("Missing HumanoidRootPart or Humanoid")
		return
	end

	-- Check distance
	local distance = (targetRoot.Position - pusherRoot.Position).Magnitude
	debugPrint("Push distance:", distance)

	if distance > MAX_PUSH_DISTANCE then
		debugPrint("Distance too far:", distance, ">", MAX_PUSH_DISTANCE)
		warn(pusher.Name, "attempted to push from too far!")
		return
	end

	-- Check if target is alive
	if targetHumanoid.Health <= 0 then
		debugPrint("Target is already dead, can't push")
		return
	end

	-- Store health to ensure no damage
	local originalHealth = targetHumanoid.Health

	debugPrint("Applying push force...")

	-- OPTIMIZED: Calculate push force (cached calculations)
	local normalizedDirection = direction.Unit
	local pushDirection = (normalizedDirection + Vector3.new(0, 0.3, 0)).Unit -- Slight upward arc
	
	-- Calculate force based on distance (closer = stronger push)
	local distanceMultiplier = 1 - (distance / MAX_PUSH_DISTANCE) * 0.3
	local actualForce = math.clamp((force or 50) * distanceMultiplier, 30, 80)
	local pushVelocity = pushDirection * actualForce
	
	debugPrint("Calculated push velocity:", pushVelocity, "Force:", actualForce)

	-- Ensure health protection
	targetHumanoid.Health = originalHealth

	if USE_RAGDOLL then
		debugPrint("Applying ragdoll physics")

		-- Apply push velocity FIRST before ragdoll
		targetRoot.AssemblyLinearVelocity = pushVelocity
		debugPrint("Applied initial push velocity")

		-- Apply ragdoll (breaks joints)
		local recover = ragdollCharacter(targetCharacter)

		-- OPTIMIZED: Use RunService.Heartbeat for smooth velocity application
		local velocityConnection
		local startTime = tick()
		local duration = 0.5 -- Apply velocity for 0.5 seconds
		
		velocityConnection = RunService.Heartbeat:Connect(function()
			local elapsed = tick() - startTime
			if elapsed < duration and targetRoot and targetRoot.Parent then
				-- Apply velocity with decay over time
				local decayFactor = 1 - (elapsed / duration) * 0.5 -- Decay to 50% by end
				targetRoot.AssemblyLinearVelocity = pushVelocity * decayFactor
			else
				velocityConnection:Disconnect()
				debugPrint("Velocity application complete")
			end
		end)

		-- OPTIMIZED: Combined health protection (single loop)
		local protectionConnection
		local protectionStartTime = tick()
		local protectionDuration = RAGDOLL_DURATION + 1
		
		protectionConnection = RunService.Heartbeat:Connect(function()
			local elapsed = tick() - protectionStartTime
			if elapsed < protectionDuration and targetHumanoid and targetHumanoid.Parent then
				if targetHumanoid.Health < originalHealth then
					targetHumanoid.Health = originalHealth
				end
			else
				protectionConnection:Disconnect()
			end
		end)

		-- Wait for ragdoll duration
		task.wait(RAGDOLL_DURATION)

		-- Cleanup connections
		if velocityConnection then
			velocityConnection:Disconnect()
		end
		if protectionConnection then
			protectionConnection:Disconnect()
		end

		-- Recover from ragdoll
		if recover then
			recover()
		end

		-- Final health check
		if targetHumanoid and targetHumanoid.Parent then
			targetHumanoid.Health = originalHealth
		end
	else
		debugPrint("Simple push without ragdoll")
		-- Just apply push velocity
		targetRoot.AssemblyLinearVelocity = pushVelocity
		targetHumanoid.Health = originalHealth
	end
end)

-- Clean up cooldowns when players leave
Players.PlayerRemoving:Connect(function(player)
	PUSH_COOLDOWN_PER_PLAYER[player] = nil
end)

debugPrint("Push server script loaded successfully!")
print("Push System Ready! Debug mode is ON - check output for detailed logs")
print("Push tool: NO DAMAGE, optimized physics push with ragdoll")
