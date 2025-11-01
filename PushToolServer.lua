-- Push Tool Server Script (Optimized for Smoothness)
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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
		
		-- Clean up any leftover push forces
		for _, descendant in pairs(character:GetDescendants()) do
			if descendant.Name == "PushForce" or descendant.Name == "PushAttachment" then
				descendant:Destroy()
			end
		end
		
		-- Gradually slow down velocities (smoother than instant stop)
		if rootPart and rootPart.Parent then
			local currentVel = rootPart.AssemblyLinearVelocity
			rootPart.AssemblyLinearVelocity = Vector3.new(
				currentVel.X * 0.3,
				math.max(currentVel.Y * 0.5, 0),
				currentVel.Z * 0.3
			)
		end
		
		-- Ground detection and smooth repositioning
		if rootPart and rootPart.Parent then
			local rayOrigin = rootPart.Position + Vector3.new(0, 3, 0)
			local rayDirection = Vector3.new(0, -50, 0)
			
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {character}
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			
			local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
			
			if rayResult then
				-- Found ground - smoothly position above it
				local groundPosition = rayResult.Position
				local targetPosition = groundPosition + Vector3.new(0, 4.5, 0)
				local currentPosition = rootPart.Position
				
				-- Only adjust if player is too close to ground or below it
				if currentPosition.Y < targetPosition.Y then
					-- Smooth upward adjustment with tween
					local targetCFrame = CFrame.new(
						currentPosition.X,
						targetPosition.Y,
						currentPosition.Z
					) * CFrame.Angles(0, math.atan2(rootPart.CFrame.LookVector.X, rootPart.CFrame.LookVector.Z), 0)
					
					local tween = TweenService:Create(
						rootPart,
						TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{CFrame = targetCFrame}
					)
					tween:Play()
					tween.Completed:Wait()
				else
					-- Just orient upright smoothly
					local targetCFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.atan2(rootPart.CFrame.LookVector.X, rootPart.CFrame.LookVector.Z), 0)
					local tween = TweenService:Create(
						rootPart,
						TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{CFrame = targetCFrame}
					)
					tween:Play()
					tween.Completed:Wait()
				end
			end
		end
		
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
		
		-- Reset collision on limbs
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.CanCollide = false
			end
		end
		
		-- Reset humanoid state
		if humanoid and humanoid.Parent then
			humanoid.RequiresNeck = true
			humanoid.BreakJointsOnDeath = true
			humanoid.PlatformStand = false
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			
			-- Use Freefall state for smooth transition
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			
			-- Small upward velocity for natural landing
			task.wait(0.05)
			if rootPart and rootPart.Parent then
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 6, 0)
			end
		end
		
		debugPrint("Ragdoll removed successfully")
	end
end

-- Apply push force using LinearVelocity constraint (INSTANT, NO DELAYS)
local function applyPushForce(character, direction, force)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	-- Make absolutely sure root is unanchored
	rootPart.Anchored = false
	
	-- Create attachment for LinearVelocity
	local attachment = Instance.new("Attachment")
	attachment.Name = "PushAttachment"
	attachment.Parent = rootPart
	
	-- Create LinearVelocity constraint
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "PushForce"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = direction * force
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = rootPart
	
	debugPrint("Applied LinearVelocity force:", direction * force)
	
	-- Remove force after short duration for natural physics
	task.delay(0.25, function()
		if linearVelocity and linearVelocity.Parent then
			linearVelocity:Destroy()
		end
		if attachment and attachment.Parent then
			attachment:Destroy()
		end
	end)
end

-- Handle push request
pushRemote.OnServerEvent:Connect(function(pusher, targetPlayer, direction, force)
	debugPrint("=== PUSH REQUEST ===")
	debugPrint("From:", pusher.Name, "To:", targetPlayer and targetPlayer.Name or "nil")
	
	-- Check server-side cooldown
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
	
	-- Check distance
	local distance = (targetRoot.Position - pusherRoot.Position).Magnitude
	debugPrint("Distance:", distance)
	
	if distance > MAX_PUSH_DISTANCE then
		warn(pusher.Name, "attempted to push from too far:", distance)
		return
	end
	
	-- Check if target is alive
	if targetHumanoid.Health <= 0 then return end
	
	-- Store original health
	local originalHealth = targetHumanoid.Health
	
	debugPrint("Push accepted! Applying...")
	
	-- Calculate push direction with upward arc
	local normalizedDirection = direction.Unit
	local pushDirection = (normalizedDirection + Vector3.new(0, 0.3, 0)).Unit
	
	-- Adjust force based on distance
	local distanceMultiplier = math.clamp(1.1 - (distance / MAX_PUSH_DISTANCE) * 0.3, 0.8, 1.1)
	local actualForce = math.clamp((force or 65) * distanceMultiplier, 35, 60)
	
	debugPrint("Final push force:", actualForce)
	
	-- INSTANT APPLICATION - No delays for smooth feel
	-- Apply force and ragdoll simultaneously
	applyPushForce(targetCharacter, pushDirection, actualForce)
	local removeRagdoll = createRagdoll(targetCharacter)
	
	if removeRagdoll then
		-- Lightweight health protection (no heavy loops)
		local healthProtected = true
		task.spawn(function()
			while healthProtected and targetHumanoid and targetHumanoid.Parent do
				if targetHumanoid.Health < originalHealth then
					targetHumanoid.Health = originalHealth
				end
				task.wait(0.2) -- Less frequent checks for better performance
			end
		end)
		
		-- Wait for ragdoll duration
		task.wait(RAGDOLL_DURATION)
		
		-- Stop health protection
		healthProtected = false
		
		-- Recover from ragdoll
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
print("Push System Ready! Optimized for smooth performance")
print("===========================================")
