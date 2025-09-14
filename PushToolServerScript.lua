-- Push Tool Server Script
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Configuration
local RAGDOLL_DURATION = 1.5 -- How long the ragdoll effect lasts
local MAX_PUSH_DISTANCE = 15 -- Maximum allowed push distance
local PUSH_COOLDOWN_PER_PLAYER = {} -- Track cooldowns per player
local USE_RAGDOLL = true -- Use ragdoll physics (set to false for simple push)

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

-- PROPER RAGDOLL: Safe ragdoll with BallSocketConstraints
local function ragdollCharacter(character)
	debugPrint("Starting safe ragdoll for:", character.Name)

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

	-- CRITICAL: Prevent death
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	local originalHealth = humanoid.Health
	local originalMaxHealth = humanoid.MaxHealth

	-- Change state to ragdoll (use Ragdoll state if available, otherwise Physics)
	humanoid.PlatformStand = true
	if Enum.HumanoidStateType.Ragdoll then
		humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	else
		humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
	end

	-- Store joints and create constraints
	local joints = {}
	local constraints = {}

	-- Process each Motor6D joint
	for _, joint in pairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") then
			-- Skip RootJoint to keep character together
			if joint.Name == "RootJoint" then
				continue
			end

			-- Store joint info
			local jointInfo = {
				joint = joint,
				part0 = joint.Part0,
				part1 = joint.Part1,
				c0 = joint.C0,
				c1 = joint.C1,
				enabled = joint.Enabled
			}
			table.insert(joints, jointInfo)

			-- Create attachments for BallSocketConstraint
			local attachment0 = Instance.new("Attachment")
			attachment0.CFrame = joint.C0
			attachment0.Parent = joint.Part0

			local attachment1 = Instance.new("Attachment")
			attachment1.CFrame = joint.C1
			attachment1.Parent = joint.Part1

			-- Create BallSocketConstraint
			local ballSocket = Instance.new("BallSocketConstraint")
			ballSocket.Attachment0 = attachment0
			ballSocket.Attachment1 = attachment1
			ballSocket.LimitsEnabled = true
			ballSocket.TwistLimitsEnabled = true
			ballSocket.UpperAngle = 45
			ballSocket.TwistUpperAngle = 45
			ballSocket.TwistLowerAngle = -45
			ballSocket.Restitution = 0.5
			ballSocket.Parent = joint.Parent

			-- Store constraint info for cleanup
			table.insert(constraints, {
				constraint = ballSocket,
				attachment0 = attachment0,
				attachment1 = attachment1
			})

			-- Disable the Motor6D (don't destroy it!)
			joint.Enabled = false

			debugPrint("Created ragdoll constraint for:", joint.Name)
		end
	end

	-- Make limbs collidable
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part ~= rootPart then
			part.CanCollide = true
		end
	end

	-- Continuously protect health
	local healthProtection = task.spawn(function()
		while humanoid and humanoid.Parent do
			humanoid.Health = originalHealth
			humanoid.MaxHealth = originalMaxHealth
			task.wait(0.1)
		end
	end)

	debugPrint("Ragdoll applied with", #constraints, "constraints")

	-- Return recovery function
	return function()
		debugPrint("Recovering from ragdoll:", character.Name)

		if not character.Parent then 
			debugPrint("Character no longer exists")
			return 
		end

		-- Stop health protection
		task.cancel(healthProtection)

		-- Remove constraints and attachments
		for _, constraintInfo in pairs(constraints) do
			if constraintInfo.constraint then
				constraintInfo.constraint:Destroy()
			end
			if constraintInfo.attachment0 then
				constraintInfo.attachment0:Destroy()
			end
			if constraintInfo.attachment1 then
				constraintInfo.attachment1:Destroy()
			end
		end

		-- Re-enable Motor6Ds
		for _, jointInfo in pairs(joints) do
			if jointInfo.joint and jointInfo.joint.Parent then
				jointInfo.joint.Enabled = true
			end
		end

		-- Reset limb collision
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part ~= rootPart then
				part.CanCollide = false
			end
		end

		-- Restore humanoid
		if humanoid and humanoid.Parent then
			humanoid.RequiresNeck = true
			humanoid.BreakJointsOnDeath = true
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
			humanoid.Health = originalHealth
			humanoid.MaxHealth = originalMaxHealth

			-- Help them stand
			if rootPart then
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 10, 0)
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

	-- Check if target is alive (but we won't damage them)
	if targetHumanoid.Health <= 0 then
		debugPrint("Target is already dead, can't push")
		return
	end

	-- Store health to ensure no damage
	local originalHealth = targetHumanoid.Health

	debugPrint("Applying push force...")

	-- Apply push force (reduced for shorter distance)
	local actualForce = math.clamp(force or 30, 10, 40) -- Much lower max force
	local pushVelocity = (direction + Vector3.new(0, 0.2, 0)).Unit * actualForce -- Less upward force too

	-- Apply push velocity
	-- Method 1: Using AssemblyLinearVelocity (newer, more reliable)
	targetRoot.AssemblyLinearVelocity = pushVelocity

	-- Method 2: Using BodyVelocity for controlled push
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(2000, 1000, 2000) -- Reduced max force
	bodyVelocity.Velocity = pushVelocity
	bodyVelocity.Parent = targetRoot

	-- Remove BodyVelocity quickly for shorter push
	Debris:AddItem(bodyVelocity, 0.2) -- Shorter duration

	-- Add friction to stop sliding (creates drag effect)
	task.wait(0.2)
	if targetRoot and targetRoot.Parent then
		-- Apply counter-force to stop sliding
		local dragVelocity = Instance.new("BodyVelocity")
		dragVelocity.MaxForce = Vector3.new(3000, 0, 3000) -- Only horizontal drag
		dragVelocity.Velocity = Vector3.new(0, 0, 0) -- Stop movement
		dragVelocity.Parent = targetRoot

		-- Remove drag after brief moment
		Debris:AddItem(dragVelocity, 0.3)
		debugPrint("Applied drag to limit push distance")
	end

	debugPrint("Push force applied with distance limiting")

	-- Ensure health protection
	targetHumanoid.Health = originalHealth

	if USE_RAGDOLL then
		debugPrint("Applying ragdoll physics")

		-- Apply proper ragdoll with BallSocketConstraints
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
print("Push tool: NO DAMAGE, just physics push with ragdoll")

