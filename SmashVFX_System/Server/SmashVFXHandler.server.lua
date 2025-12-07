--[[
	SmashVFXHandler (Script)
	Location: ServerScriptService/SmashVFXHandler
	
	Server-side handler for SmashVFX system.
	- Validates client requests
	- Handles hit detection
	- Applies knockback & ragdoll
	- Broadcasts VFX to all clients
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Configuration
local MAX_DISTANCE = 40
local COOLDOWN = 1.5

-- Hitbox Configuration
local HITBOX_SIZE = Vector3.new(7, 8, 7)
local HITBOX_DURATION = 0.3

-- Knockback & Ragdoll Configuration
local KNOCKBACK_UP_VELOCITY = 50 -- Smooth upward explosion
local KNOCKBACK_BACK_VELOCITY = 40 -- Smooth backward push
local RAGDOLL_DURATION = 1.5

-- Player cooldowns
local playerCooldowns = {}

-- Track ragdolled characters
local ragdolledCharacters = {}

-- Create RemoteEvents
local smashVFXEvent = Instance.new("RemoteEvent")
smashVFXEvent.Name = "SmashVFXEvent"
smashVFXEvent.Parent = ReplicatedStorage

-- ============================================
-- RAGDOLL SYSTEM (Server-Side)
-- ============================================

local function getMotor6Ds(character)
	local motors = {}
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			table.insert(motors, descendant)
		end
	end
	return motors
end

local function createRagdollConstraint(motor)
	local socket = Instance.new("BallSocketConstraint")
	socket.Name = "RagdollSocket_" .. motor.Name
	socket.LimitsEnabled = true
	socket.TwistLimitsEnabled = true
	socket.UpperAngle = 50
	socket.TwistLowerAngle = -50
	socket.TwistUpperAngle = 50
	
	local att0 = Instance.new("Attachment")
	att0.Name = "RagdollAtt0"
	att0.CFrame = motor.C0
	att0.Parent = motor.Part0
	
	local att1 = Instance.new("Attachment")
	att1.Name = "RagdollAtt1"
	att1.CFrame = motor.C1
	att1.Parent = motor.Part1
	
	socket.Attachment0 = att0
	socket.Attachment1 = att1
	socket.Parent = motor.Part0
	
	return socket, att0, att1
end

local function enableRagdoll(character)
	if ragdolledCharacters[character] then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	
	local ragdollData = {
		motors = {},
		sockets = {},
		attachments = {},
		constraints = {}
	}
	
	-- Disable humanoid states
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	-- Set PlatformStand to prevent character from trying to stand
	humanoid.PlatformStand = true
	
	-- Process motors
	local motors = getMotor6Ds(character)
	
	for _, motor in ipairs(motors) do
		if motor.Name ~= "RootJoint" and motor.Name ~= "Root" then
			table.insert(ragdollData.motors, {
				motor = motor,
				enabled = motor.Enabled
			})
			
			local socket, att0, att1 = createRagdollConstraint(motor)
			table.insert(ragdollData.sockets, socket)
			table.insert(ragdollData.attachments, att0)
			table.insert(ragdollData.attachments, att1)
			
			motor.Enabled = false
		end
	end
	
	-- Enable collision on parts for physics
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end
	
	ragdolledCharacters[character] = ragdollData
	return true
end

local function disableRagdoll(character)
	local ragdollData = ragdolledCharacters[character]
	if not ragdollData then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Clean up any knockback constraints
	for _, constraint in ipairs(ragdollData.constraints) do
		if constraint and constraint.Parent then
			constraint:Destroy()
		end
	end
	
	-- Clean up sockets
	for _, socket in ipairs(ragdollData.sockets) do
		if socket and socket.Parent then
			socket:Destroy()
		end
	end
	
	-- Clean up attachments
	for _, att in ipairs(ragdollData.attachments) do
		if att and att.Parent then
			att:Destroy()
		end
	end
	
	-- Re-enable motors
	for _, motorData in ipairs(ragdollData.motors) do
		if motorData.motor and motorData.motor.Parent then
			motorData.motor.Enabled = true
		end
	end
	
	-- Re-enable humanoid states
	if humanoid then
		humanoid.PlatformStand = false
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	
	-- Reset collision
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = false
		end
	end
	
	-- Reset velocity gently
	if rootPart then
		rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end
	
	ragdolledCharacters[character] = nil
end

-- Apply smooth knockback using LinearVelocity constraint
local function applyKnockback(character, hitPosition, ragdollData)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	-- Calculate direction away from hit (horizontal only)
	local direction = (rootPart.Position - hitPosition)
	direction = Vector3.new(direction.X, 0, direction.Z)
	
	if direction.Magnitude > 0.1 then
		direction = direction.Unit
	else
		-- If too close, push in a random direction
		local angle = math.random() * math.pi * 2
		direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
	end
	
	-- Create knockback velocity (up and back)
	local knockbackVelocity = Vector3.new(
		direction.X * KNOCKBACK_BACK_VELOCITY,
		KNOCKBACK_UP_VELOCITY,
		direction.Z * KNOCKBACK_BACK_VELOCITY
	)
	
	-- Create attachment for LinearVelocity
	local attachment = Instance.new("Attachment")
	attachment.Name = "KnockbackAttachment"
	attachment.Parent = rootPart
	
	-- Use LinearVelocity for smooth, consistent knockback
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "KnockbackVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = math.huge -- Ensure it applies fully
	linearVelocity.VectorVelocity = knockbackVelocity
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = rootPart
	
	-- Store for cleanup
	if ragdollData then
		table.insert(ragdollData.constraints, linearVelocity)
		table.insert(ragdollData.attachments, attachment)
	end
	
	-- Add some angular velocity for tumbling effect
	local angularVelocity = Instance.new("AngularVelocity")
	angularVelocity.Name = "KnockbackSpin"
	angularVelocity.Attachment0 = attachment
	angularVelocity.MaxTorque = math.huge
	angularVelocity.AngularVelocity = Vector3.new(
		math.random(-8, 8),
		math.random(-4, 4),
		math.random(-8, 8)
	)
	angularVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	angularVelocity.Parent = rootPart
	
	if ragdollData then
		table.insert(ragdollData.constraints, angularVelocity)
	end
	
	-- Smoothly reduce the knockback force over time
	task.spawn(function()
		local duration = 0.3 -- Knockback applies for 0.3 seconds
		local startTime = tick()
		local startVelocity = knockbackVelocity
		
		while tick() - startTime < duration do
			local alpha = (tick() - startTime) / duration
			local easedAlpha = 1 - math.pow(1 - alpha, 2) -- Ease out
			
			if linearVelocity and linearVelocity.Parent then
				-- Gradually reduce velocity, but keep some upward initially
				local currentVelocity = startVelocity * (1 - easedAlpha)
				linearVelocity.VectorVelocity = currentVelocity
			else
				break
			end
			
			task.wait()
		end
		
		-- Remove the linear velocity constraint (let physics take over)
		if linearVelocity and linearVelocity.Parent then
			linearVelocity.MaxForce = 0
		end
		
		-- Remove angular velocity after a bit
		task.delay(0.2, function()
			if angularVelocity and angularVelocity.Parent then
				angularVelocity.MaxTorque = 0
			end
		end)
	end)
end

local function knockbackAndRagdoll(character, hitPosition)
	if ragdolledCharacters[character] then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	-- Enable ragdoll first
	local success = enableRagdoll(character)
	if not success then return end
	
	-- Apply knockback (pass ragdollData for cleanup tracking)
	local ragdollData = ragdolledCharacters[character]
	applyKnockback(character, hitPosition, ragdollData)
	
	-- Schedule recovery
	task.delay(RAGDOLL_DURATION, function()
		if character and character.Parent then
			disableRagdoll(character)
		end
	end)
end

-- ============================================
-- HITBOX SYSTEM (Server-Side)
-- ============================================

local function getCharactersInHitbox(position, sourceCharacter)
	local charactersHit = {}
	local charactersChecked = {}
	
	local hitboxCFrame = CFrame.new(position + Vector3.new(0, HITBOX_SIZE.Y / 2, 0))
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {sourceCharacter}
	
	local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, HITBOX_SIZE, overlapParams)
	
	for _, part in ipairs(partsInBox) do
		local character = part.Parent
		
		if character and not charactersChecked[character] then
			charactersChecked[character] = true
			
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				table.insert(charactersHit, character)
			end
		end
	end
	
	return charactersHit
end

local function processHits(position, sourcePlayer)
	local sourceCharacter = sourcePlayer.Character
	if not sourceCharacter then return end
	
	local charactersHit = getCharactersInHitbox(position, sourceCharacter)
	
	for _, character in ipairs(charactersHit) do
		local targetPlayer = Players:GetPlayerFromCharacter(character)
		local name = targetPlayer and targetPlayer.Name or character.Name
		print("[SmashVFX Server] HIT: " .. name .. " by " .. sourcePlayer.Name)
		
		-- Apply knockback and ragdoll
		knockbackAndRagdoll(character, position)
	end
	
	if #charactersHit > 0 then
		print("[SmashVFX Server] Total hit by " .. sourcePlayer.Name .. ": " .. #charactersHit)
	end
end

-- ============================================
-- REQUEST VALIDATION
-- ============================================

local function validateRequest(player, position, normal)
	local character = player.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	if typeof(position) ~= "Vector3" then return false end
	if typeof(normal) ~= "Vector3" then return false end
	
	-- Check distance (with buffer for latency)
	local distance = (position - humanoidRootPart.Position).Magnitude
	if distance > MAX_DISTANCE + 10 then
		return false
	end
	
	-- Check cooldown
	local lastTime = playerCooldowns[player.UserId] or 0
	if tick() - lastTime < COOLDOWN then
		return false
	end
	
	-- Check ground normal
	if normal.Y < 0.7 then
		return false
	end
	
	return true
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

local function onSmashVFXRequested(player, position, normal)
	if not validateRequest(player, position, normal) then
		return
	end
	
	-- Set cooldown
	playerCooldowns[player.UserId] = tick()
	
	-- Process hits
	processHits(position, player)
	
	-- Broadcast VFX to all clients
	smashVFXEvent:FireAllClients(player, position, normal)
	
	print("[SmashVFX Server] VFX spawned by " .. player.Name)
end

local function onPlayerRemoving(player)
	playerCooldowns[player.UserId] = nil
end

local function onCharacterRemoving(character)
	if ragdolledCharacters[character] then
		ragdolledCharacters[character] = nil
	end
end

local function onPlayerAdded(player)
	player.CharacterRemoving:Connect(onCharacterRemoving)
end

-- ============================================
-- INITIALIZATION
-- ============================================

smashVFXEvent.OnServerEvent:Connect(onSmashVFXRequested)
Players.PlayerRemoving:Connect(onPlayerRemoving)
Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("[SmashVFX] Server initialized!")
print("  - Max Distance: " .. MAX_DISTANCE .. " studs")
print("  - Cooldown: " .. COOLDOWN .. " seconds")
print("  - Knockback: UP=" .. KNOCKBACK_UP_VELOCITY .. ", BACK=" .. KNOCKBACK_BACK_VELOCITY)
