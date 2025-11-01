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

-- IMPROVED RAGDOLL: Simpler and more reliable
local function ragdollCharacter(character)
	debugPrint("Starting ragdoll for:", character.Name)

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

	-- Store joint information for restoration
	local joints = {}

	-- Disable Motor6D joints (except RootJoint to keep character together)
	for _, joint in pairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") and joint.Name ~= "RootJoint" then
			joints[joint] = joint.Enabled
			joint.Enabled = false
		end
	end

	-- Enable physics on all parts
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
			-- Make sure parts can move
			if part ~= rootPart then
				part.Anchored = false
			end
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

	debugPrint("Ragdoll applied successfully")

	-- Return recovery function
	return function()
		debugPrint("Recovering from ragdoll:", character.Name)

		if not character.Parent then 
			debugPrint("Character no longer exists")
			return 
		end

		-- Stop health protection
		task.cancel(healthProtection)

		-- Re-enable Motor6D joints
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

		debugPrint("Character recovered from ragdoll successfully")
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
	local actualForce = math.clamp((force or 50) * distanceMultiplier, 25, 75) -- Increased base force
	
	-- Apply push velocity using AssemblyLinearVelocity (modern, reliable method)
	local pushVelocity = pushDirection * actualForce
	targetRoot.AssemblyLinearVelocity = pushVelocity
	
	debugPrint("Applied push velocity:", pushVelocity, "Force:", actualForce)

	-- Ensure health protection
	targetHumanoid.Health = originalHealth

	if USE_RAGDOLL then
		debugPrint("Applying ragdoll physics")

		-- Apply ragdoll
		local recover = ragdollCharacter(targetPlayer.Character)

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
		-- Just the push, no ragdoll
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
