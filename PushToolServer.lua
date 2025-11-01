-- Push Tool Server Script (Improved)
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

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

-- FUNNY RAGDOLL: Actually breaks joints for ragdoll effect
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

	-- Store joint information for restoration - we'll recreate them
	local joints = {}

	-- Actually BREAK (destroy) Motor6D joints for funny ragdoll effect (except RootJoint)
	for _, joint in pairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") and joint.Name ~= "RootJoint" then
			-- Store joint info before breaking
			joints[joint] = {
				part0 = joint.Part0,
				part1 = joint.Part1,
				c0 = joint.C0,
				c1 = joint.C1,
				name = joint.Name,
				parent = joint.Parent
			}
			-- Actually break the joint!
			joint:Destroy()
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
		debugPrint("Recovering from ragdoll - recreating joints:", character.Name)

		if not character.Parent then 
			debugPrint("Character no longer exists")
			return 
		end

		-- Stop health protection
		task.cancel(healthProtection)

		-- RECREATE all broken joints
		for brokenJoint, jointInfo in pairs(joints) do
			if jointInfo.part0 and jointInfo.part0.Parent and jointInfo.part1 and jointInfo.part1.Parent then
				-- Recreate the Motor6D joint
				local newJoint = Instance.new("Motor6D")
				newJoint.Name = jointInfo.name
				newJoint.Part0 = jointInfo.part0
				newJoint.Part1 = jointInfo.part1
				newJoint.C0 = jointInfo.c0
				newJoint.C1 = jointInfo.c1
				newJoint.Parent = jointInfo.parent
				debugPrint("Recreated joint:", jointInfo.name)
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

		debugPrint("Character recovered from ragdoll successfully - joints recreated")
	end
end

-- Handle push request
pushRemote.OnServerEvent:Connect(function(pusher, targetPlayer, direction, force)
	debugPrint("Push request from:", pusher.Name, "to:", targetPlayer and targetPlayer.Name or "nil")

	-- Check server-side cooldown
	local currentTime = tick()
	if PUSH_COOLDOWN_PER_PLAYER[pusher] and currentTime - PUSH_COOLDOWN_PER_PLAYER[pusher] < 2 then
		debugPrint("Player", pusher.Name, "is on cooldown")
		return
	end
	PUSH_COOLDOWN_PER_PLAYER[pusher] = currentTime

	-- Validate
	if not pusher.Character then
		debugPrint("Pusher has no character")
		return
	end

	if not targetPlayer or not targetPlayer.Character then
		debugPrint("Invalid target player or character")
		return
	end

	local pusherRoot = pusher.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")

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

	-- IMPROVED: Calculate proper push force
	-- Normalize direction and add slight upward component for natural arc
	local normalizedDirection = direction.Unit
	local pushDirection = (normalizedDirection + Vector3.new(0, 0.3, 0)).Unit -- Slight upward arc
	
	-- Calculate force based on distance (closer = stronger push)
	local distanceMultiplier = 1 - (distance / MAX_PUSH_DISTANCE) * 0.3 -- Reduce force slightly with distance
	local actualForce = math.clamp((force or 50) * distanceMultiplier, 30, 80) -- Increased base force
	
	-- Calculate push velocity
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
		local recover = ragdollCharacter(targetPlayer.Character)

		-- Continuously apply velocity to maintain push during ragdoll
		-- This ensures the character keeps moving while ragdolled
		local velocityApplication = task.spawn(function()
			local startTime = tick()
			local duration = 0.5 -- Apply velocity for 0.5 seconds
			
			while tick() - startTime < duration do
				if targetRoot and targetRoot.Parent then
					-- Apply velocity with slight decay over time
					local elapsed = tick() - startTime
					local decayFactor = 1 - (elapsed / duration) * 0.5 -- Decay to 50% by end
					targetRoot.AssemblyLinearVelocity = pushVelocity * decayFactor
					task.wait(0.05) -- Update every frame
				else
					break
				end
			end
			debugPrint("Velocity application complete")
		end)

		-- Additional health protection during ragdoll
		local extraProtection = task.spawn(function()
			local protectionTime = 0
			while protectionTime < RAGDOLL_DURATION + 1 do
				if targetHumanoid and targetHumanoid.Parent then
					if targetHumanoid.Health < originalHealth then
						targetHumanoid.Health = originalHealth
						debugPrint("Health protected during ragdoll")
					end
				else
					break
				end
				task.wait(0.1)
				protectionTime = protectionTime + 0.1
			end
		end)

		-- Wait for ragdoll duration
		task.wait(RAGDOLL_DURATION)

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
print("Push tool: NO DAMAGE, improved physics push with ragdoll")
