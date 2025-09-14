-- Push Tool Server Script
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Configuration
local RAGDOLL_DURATION = 1.5 -- How long they stay ragdolled
local MAX_PUSH_DISTANCE = 15 -- Maximum allowed push distance

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

-- Simple ragdoll function
local function ragdollCharacter(character)
	debugPrint("Starting ragdoll for:", character.Name)
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then 
		debugPrint("No humanoid found!")
		return 
	end
	
	-- Change humanoid state
	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	-- Store original values
	local joints = {}
	local originalCanCollide = {}
	
	-- Disable all Motor6Ds
	for _, descendant in pairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			descendant.Enabled = false
			table.insert(joints, descendant)
			debugPrint("Disabled Motor6D:", descendant.Name)
		elseif descendant:IsA("BasePart") and descendant ~= character.HumanoidRootPart then
			originalCanCollide[descendant] = descendant.CanCollide
			descendant.CanCollide = true
		end
	end
	
	debugPrint("Ragdoll applied, joints disabled:", #joints)
	
	-- Return function to unragdoll
	return function()
		debugPrint("Unragdolling character:", character.Name)
		
		if not character.Parent then 
			debugPrint("Character no longer exists")
			return 
		end
		
		-- Re-enable all Motor6Ds
		for _, joint in pairs(joints) do
			if joint and joint.Parent then
				joint.Enabled = true
			end
		end
		
		-- Restore CanCollide
		for part, canCollide in pairs(originalCanCollide) do
			if part and part.Parent then
				part.CanCollide = canCollide
			end
		end
		
		-- Restore humanoid
		if humanoid and humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
			
			-- Small upward impulse to help stand
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 10, 0)
			end
		end
		
		debugPrint("Character unragdolled successfully")
	end
end

-- Handle push request
pushRemote.OnServerEvent:Connect(function(pusher, targetPlayer, direction, force)
	debugPrint("Push request from:", pusher.Name, "to:", targetPlayer and targetPlayer.Name or "nil")
	
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
		debugPrint("Target is dead")
		return
	end
	
	debugPrint("Applying push force...")
	
	-- Apply push force
	local actualForce = math.clamp(force or 50, 10, 100)
	local pushVelocity = (direction + Vector3.new(0, 0.3, 0)).Unit * actualForce
	
	-- Method 1: Using AssemblyLinearVelocity (newer, more reliable)
	targetRoot.AssemblyLinearVelocity = pushVelocity
	
	-- Method 2: Using BodyVelocity (backup method)
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyVelocity.Velocity = pushVelocity
	bodyVelocity.Parent = targetRoot
	
	-- Remove BodyVelocity after short time
	Debris:AddItem(bodyVelocity, 0.3)
	
	debugPrint("Push force applied successfully")
	
	-- Apply ragdoll
	local unragdoll = ragdollCharacter(targetPlayer.Character)
	
	-- Schedule unragdoll
	task.wait(RAGDOLL_DURATION)
	
	if unragdoll then
		unragdoll()
	end
end)

debugPrint("Push server script loaded successfully!")
print("Push System Ready! Debug mode is ON - check output for detailed logs")