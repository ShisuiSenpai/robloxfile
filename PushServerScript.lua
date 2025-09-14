-- Push Server Script
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Configuration
local RAGDOLL_DURATION = 1.5 -- How long they stay ragdolled
local MAX_PUSH_DISTANCE = 10 -- Maximum allowed push distance (anti-exploit)
local PUSH_COOLDOWNS = {} -- Track cooldowns per player

-- Create RemoteEvent
local pushRemote = ReplicatedStorage:FindFirstChild("PushRemote")
if not pushRemote then
	pushRemote = Instance.new("RemoteEvent")
	pushRemote.Name = "PushRemote"
	pushRemote.Parent = ReplicatedStorage
end

-- Ragdoll Module Functions
local function createBallSocket(attachment0, attachment1, parent)
	local ballSocket = Instance.new("BallSocketConstraint")
	ballSocket.Attachment0 = attachment0
	ballSocket.Attachment1 = attachment1
	ballSocket.LimitsEnabled = true
	ballSocket.TwistLimitsEnabled = true
	ballSocket.UpperAngle = 90
	ballSocket.TwistUpperAngle = 90
	ballSocket.TwistLowerAngle = -90
	ballSocket.Parent = parent
	return ballSocket
end

local function ragdollCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Store original state
	local originalState = humanoid:GetState()
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.PlatformStand = true
	
	-- Store joints to restore later
	local joints = {}
	local constraints = {}
	
	-- Disable Motor6Ds and create ragdoll constraints
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("Motor6D") and part.Name ~= "RootJoint" then
			part.Enabled = false
			table.insert(joints, part)
			
			-- Create ball socket constraint
			local attachment0 = Instance.new("Attachment")
			local attachment1 = Instance.new("Attachment")
			
			attachment0.CFrame = part.C0
			attachment1.CFrame = part.C1
			attachment0.Parent = part.Part0
			attachment1.Parent = part.Part1
			
			local constraint = createBallSocket(attachment0, attachment1, part.Parent)
			table.insert(constraints, {constraint = constraint, att0 = attachment0, att1 = attachment1})
		end
	end
	
	-- Make sure all parts have proper physics
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part ~= character.HumanoidRootPart then
			part.CanCollide = true
		end
	end
	
	return joints, constraints
end

local function unragdollCharacter(character, joints, constraints)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Remove ragdoll constraints
	for _, constraintData in pairs(constraints) do
		if constraintData.constraint then
			constraintData.constraint:Destroy()
		end
		if constraintData.att0 then
			constraintData.att0:Destroy()
		end
		if constraintData.att1 then
			constraintData.att1:Destroy()
		end
	end
	
	-- Re-enable Motor6Ds
	for _, joint in pairs(joints) do
		if joint and joint.Parent then
			joint.Enabled = true
		end
	end
	
	-- Reset collision
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part ~= character.HumanoidRootPart then
			part.CanCollide = false
		end
	end
	
	-- Restore humanoid state
	humanoid.PlatformStand = false
	humanoid:ChangeState(Enum.HumanoidStateType.Running)
	
	-- Small upward impulse to help character stand
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.AssemblyLinearVelocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, 10, rootPart.AssemblyLinearVelocity.Z)
	end
end

-- Main push handler
local function handlePush(pusher, targetPlayer, direction, force)
	-- Validate players
	if not pusher.Character or not targetPlayer or not targetPlayer.Character then
		return
	end
	
	-- Anti-exploit checks
	local pusherRoot = pusher.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	
	if not pusherRoot or not targetRoot then return end
	
	-- Check distance (anti-exploit)
	local distance = (targetRoot.Position - pusherRoot.Position).Magnitude
	if distance > MAX_PUSH_DISTANCE then
		warn(pusher.Name .. " attempted to push from too far away!")
		return
	end
	
	-- Check cooldown
	local now = tick()
	if PUSH_COOLDOWNS[pusher] and now - PUSH_COOLDOWNS[pusher] < 1 then
		return -- Still on cooldown
	end
	PUSH_COOLDOWNS[pusher] = now
	
	-- Apply push force
	local pushDirection = direction or (targetRoot.Position - pusherRoot.Position).Unit
	local actualForce = math.min(force or 50, 100) -- Cap force to prevent exploits
	
	-- Create BodyVelocity for smooth push
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(4000, 2000, 4000)
	bodyVelocity.Velocity = (pushDirection + Vector3.new(0, 0.3, 0)).Unit * actualForce
	bodyVelocity.Parent = targetRoot
	
	-- Remove velocity after short time
	Debris:AddItem(bodyVelocity, 0.2)
	
	-- Ragdoll the target
	local joints, constraints = ragdollCharacter(targetPlayer.Character)
	
	-- Schedule unragdoll
	task.wait(RAGDOLL_DURATION)
	
	-- Make sure character still exists before unragdolling
	if targetPlayer.Character and targetPlayer.Character.Parent then
		unragdollCharacter(targetPlayer.Character, joints, constraints)
	end
end

-- Handle push requests
pushRemote.OnServerEvent:Connect(function(pusher, targetPlayer, direction, force)
	-- Validate that pusher has the Push tool equipped
	local character = pusher.Character
	if not character then return end
	
	local tool = character:FindFirstChild("Push")
	if not tool then
		-- Check if it's in the player's backpack (might be equipped differently)
		tool = pusher.Backpack:FindFirstChild("Push")
		if not tool then
			warn(pusher.Name .. " attempted to push without Push tool!")
			return
		end
	end
	
	-- Process the push in a new thread to prevent blocking
	task.spawn(function()
		handlePush(pusher, targetPlayer, direction, force)
	end)
end)

-- Clean up cooldowns when players leave
Players.PlayerRemoving:Connect(function(player)
	PUSH_COOLDOWNS[player] = nil
end)

print("Push Server Script loaded!")