--[[
	SmashVFXController (LocalScript)
	Location: StarterPlayerScripts/SmashVFXController
	
	SINGLE-PLAYER VERSION (for testing)
	- All logic runs on client
	- Use Multiplayer version for real games
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Player references
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Configuration
local MAX_DISTANCE = 40
local VFX_LIFETIME = 2
local TWEEN_IN_TIME = 0.15
local TWEEN_OUT_TIME = 0.4
local COOLDOWN = 1.5

-- Preview Configuration
local PREVIEW_SIZE = 7
local PREVIEW_COLOR_VALID = Color3.fromRGB(100, 255, 100)
local PREVIEW_COLOR_INVALID = Color3.fromRGB(255, 100, 100)
local PREVIEW_TRANSPARENCY = 0.5

-- Hitbox Configuration
local HITBOX_SIZE = Vector3.new(7, 8, 7)
local HITBOX_COLOR = Color3.fromRGB(255, 0, 0)
local HITBOX_TRANSPARENCY = 0.7
local HITBOX_DURATION = 0.3
local DEBUG_HITBOX = true

-- Knockback & Ragdoll Configuration
local KNOCKBACK_UP_VELOCITY = 50
local KNOCKBACK_BACK_VELOCITY = 40
local RAGDOLL_DURATION = 1.5

-- Ground Detection
local MIN_GROUND_NORMAL_Y = 0.7

-- VFX Reference
local VFXFolder = ReplicatedStorage:WaitForChild("VFX")
local SmashVfxTemplate = VFXFolder:WaitForChild("SmashVfx")

-- State
local lastClickTime = 0
local isOnCooldown = false
local isPreviewActive = false
local previewPart = nil
local previewConnection = nil
local ragdolledCharacters = {}

-- ============================================
-- RAGDOLL SYSTEM
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
	
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.PlatformStand = true
	
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
	
	-- Step 1: Clean up all constraints first
	for _, constraint in ipairs(ragdollData.constraints) do
		if constraint and constraint.Parent then
			constraint:Destroy()
		end
	end
	
	-- Step 2: Stop all movement immediately
	if rootPart then
		rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end
	
	-- Stop velocity on all parts
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end
	end
	
	-- Step 3: Disable collision on all parts BEFORE re-enabling motors
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = false
		end
	end
	
	-- Step 4: Position character upright before re-enabling motors
	if rootPart then
		-- Get current position but make character upright
		local currentPos = rootPart.Position
		
		-- Raycast down to find ground
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {character}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local rayResult = workspace:Raycast(currentPos, Vector3.new(0, -10, 0), raycastParams)
		local groundY = rayResult and rayResult.Position.Y or (currentPos.Y - 3)
		
		-- Position character slightly above ground, upright
		local hipHeight = humanoid and humanoid.HipHeight or 2
		local newY = groundY + hipHeight + 1
		
		-- Set upright position (keep X and Z, fix Y and rotation)
		rootPart.CFrame = CFrame.new(currentPos.X, newY, currentPos.Z)
		
		-- Zero out velocity again after repositioning
		rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end
	
	-- Step 5: Clean up ragdoll sockets
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
	
	-- Step 6: Re-enable motors
	for _, motorData in ipairs(ragdollData.motors) do
		if motorData.motor and motorData.motor.Parent then
			motorData.motor.Enabled = true
		end
	end
	
	-- Step 7: Re-enable humanoid control
	if humanoid then
		humanoid.PlatformStand = false
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	
	ragdolledCharacters[character] = nil
end

local function applyKnockback(character, hitPosition, ragdollData)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local direction = (rootPart.Position - hitPosition)
	direction = Vector3.new(direction.X, 0, direction.Z)
	
	if direction.Magnitude > 0.1 then
		direction = direction.Unit
	else
		local angle = math.random() * math.pi * 2
		direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
	end
	
	local knockbackVelocity = Vector3.new(
		direction.X * KNOCKBACK_BACK_VELOCITY,
		KNOCKBACK_UP_VELOCITY,
		direction.Z * KNOCKBACK_BACK_VELOCITY
	)
	
	local attachment = Instance.new("Attachment")
	attachment.Name = "KnockbackAttachment"
	attachment.Parent = rootPart
	
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "KnockbackVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = knockbackVelocity
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = rootPart
	
	if ragdollData then
		table.insert(ragdollData.constraints, linearVelocity)
		table.insert(ragdollData.attachments, attachment)
	end
	
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
	
	task.spawn(function()
		local duration = 0.3
		local startTime = tick()
		local startVelocity = knockbackVelocity
		
		while tick() - startTime < duration do
			local alpha = (tick() - startTime) / duration
			local easedAlpha = 1 - math.pow(1 - alpha, 2)
			
			if linearVelocity and linearVelocity.Parent then
				local currentVelocity = startVelocity * (1 - easedAlpha)
				linearVelocity.VectorVelocity = currentVelocity
			else
				break
			end
			
			task.wait()
		end
		
		if linearVelocity and linearVelocity.Parent then
			linearVelocity.MaxForce = 0
		end
		
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
	
	local success = enableRagdoll(character)
	if not success then return end
	
	local ragdollData = ragdolledCharacters[character]
	applyKnockback(character, hitPosition, ragdollData)
	
	task.delay(RAGDOLL_DURATION, function()
		if character and character.Parent then
			disableRagdoll(character)
		end
	end)
end

-- ============================================
-- HITBOX SYSTEM
-- ============================================

local function createHitboxPart(position)
	local hitbox = Instance.new("Part")
	hitbox.Name = "SmashVFX_Hitbox"
	hitbox.Shape = Enum.PartType.Block
	hitbox.Size = HITBOX_SIZE
	hitbox.Color = HITBOX_COLOR
	hitbox.Material = Enum.Material.ForceField
	hitbox.Transparency = HITBOX_TRANSPARENCY
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanQuery = true
	hitbox.CanTouch = true
	hitbox.CastShadow = false
	
	hitbox.CFrame = CFrame.new(position + Vector3.new(0, HITBOX_SIZE.Y / 2, 0))
	
	if DEBUG_HITBOX then
		local selectionBox = Instance.new("SelectionBox")
		selectionBox.Adornee = hitbox
		selectionBox.Color3 = HITBOX_COLOR
		selectionBox.LineThickness = 0.05
		selectionBox.Transparency = 0.3
		selectionBox.Parent = hitbox
	end
	
	return hitbox
end

local function getCharactersInHitbox(hitbox, sourceCharacter)
	local charactersHit = {}
	local charactersChecked = {}
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {hitbox, sourceCharacter}
	
	local partsInBox = workspace:GetPartsInPart(hitbox, overlapParams)
	
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

local function spawnHitbox(position)
	local hitbox = createHitboxPart(position)
	hitbox.Parent = workspace
	
	local originalSize = hitbox.Size
	hitbox.Size = Vector3.new(HITBOX_SIZE.X, 0.5, HITBOX_SIZE.Z)
	hitbox.CFrame = CFrame.new(position + Vector3.new(0, 0.25, 0))
	
	local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(hitbox, tweenInfo, {
		Size = originalSize,
		CFrame = CFrame.new(position + Vector3.new(0, HITBOX_SIZE.Y / 2, 0))
	})
	tween:Play()
	
	task.delay(0.05, function()
		if hitbox and hitbox.Parent then
			local charactersHit = getCharactersInHitbox(hitbox, player.Character)
			
			for _, character in ipairs(charactersHit) do
				local targetPlayer = Players:GetPlayerFromCharacter(character)
				local name = targetPlayer and targetPlayer.Name or character.Name
				print("[SmashVFX] HIT: " .. name)
				
				knockbackAndRagdoll(character, position)
			end
			
			if #charactersHit > 0 then
				print("[SmashVFX] Total hit: " .. #charactersHit)
			end
		end
	end)
	
	task.delay(HITBOX_DURATION, function()
		if hitbox and hitbox.Parent then
			local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			local fadeTween = TweenService:Create(hitbox, fadeInfo, {
				Transparency = 1,
				Size = Vector3.new(HITBOX_SIZE.X, 0.5, HITBOX_SIZE.Z)
			})
			fadeTween:Play()
			fadeTween.Completed:Connect(function()
				hitbox:Destroy()
			end)
		end
	end)
	
	Debris:AddItem(hitbox, HITBOX_DURATION + 1)
	return hitbox
end

-- ============================================
-- PREVIEW SYSTEM
-- ============================================

local function createPreviewPart()
	local part = Instance.new("Part")
	part.Name = "SmashVFX_Preview"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.2, PREVIEW_SIZE, PREVIEW_SIZE)
	part.Color = PREVIEW_COLOR_VALID
	part.Material = Enum.Material.Neon
	part.Transparency = PREVIEW_TRANSPARENCY
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	
	local highlight = Instance.new("Highlight")
	highlight.FillColor = PREVIEW_COLOR_VALID
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0.3
	highlight.Parent = part
	
	return part
end

local function showPreview()
	if isPreviewActive then return end
	isPreviewActive = true
	
	previewPart = createPreviewPart()
	previewPart.Parent = workspace
	
	previewPart.Size = Vector3.new(0.2, 0.5, 0.5)
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(previewPart, tweenInfo, {
		Size = Vector3.new(0.2, PREVIEW_SIZE, PREVIEW_SIZE)
	})
	tween:Play()
	
	previewConnection = RunService.RenderStepped:Connect(function()
		if not previewPart or not previewPart.Parent then return end
		
		local position, normal, hitPart, isValidGround = getGroundPosition()
		
		if position and isValidGround then
			previewPart.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
			
			local inRange = isWithinRange(position)
			local targetColor = inRange and PREVIEW_COLOR_VALID or PREVIEW_COLOR_INVALID
			
			previewPart.Color = targetColor
			previewPart.Transparency = PREVIEW_TRANSPARENCY
			
			local highlight = previewPart:FindFirstChild("Highlight")
			if highlight then
				highlight.FillColor = targetColor
			end
		else
			previewPart.Color = Color3.fromRGB(100, 100, 100)
			previewPart.Transparency = 0.8
			
			local highlight = previewPart:FindFirstChild("Highlight")
			if highlight then
				highlight.FillColor = Color3.fromRGB(100, 100, 100)
			end
		end
	end)
end

local function hidePreview()
	if not isPreviewActive then return end
	isPreviewActive = false
	
	if previewConnection then
		previewConnection:Disconnect()
		previewConnection = nil
	end
	
	if previewPart and previewPart.Parent then
		local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local tween = TweenService:Create(previewPart, tweenInfo, {
			Size = Vector3.new(0.2, 0.5, 0.5),
			Transparency = 1
		})
		tween:Play()
		tween.Completed:Connect(function()
			if previewPart then
				previewPart:Destroy()
				previewPart = nil
			end
		end)
	end
end

-- ============================================
-- VFX SYSTEM
-- ============================================

local function createRaycastParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	
	local filterList = {camera}
	
	if previewPart then
		table.insert(filterList, previewPart)
	end
	
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(filterList, p.Character)
		end
	end
	
	for _, child in ipairs(workspace:GetChildren()) do
		if child:FindFirstChildOfClass("Humanoid") then
			table.insert(filterList, child)
		end
	end
	
	params.FilterDescendantsInstances = filterList
	params.IgnoreWater = true
	return params
end

local function isValidGroundSurface(normal)
	return normal.Y >= MIN_GROUND_NORMAL_Y
end

function getGroundPosition()
	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	local raycastParams = createRaycastParams()
	
	local raycastResult = workspace:Raycast(
		ray.Origin,
		ray.Direction * 500,
		raycastParams
	)
	
	if raycastResult then
		local isValidGround = isValidGroundSurface(raycastResult.Normal)
		return raycastResult.Position, raycastResult.Normal, raycastResult.Instance, isValidGround
	end
	
	return nil, nil, nil, false
end

function isWithinRange(position)
	local character = player.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	return (position - humanoidRootPart.Position).Magnitude <= MAX_DISTANCE
end

local function getAllParticleEmitters(parent)
	local emitters = {}
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			table.insert(emitters, descendant)
		end
	end
	return emitters
end

local function emitAllParticles(vfxPart, emitCount)
	local emitters = getAllParticleEmitters(vfxPart)
	for _, emitter in ipairs(emitters) do
		emitter.Enabled = false
		emitter:Emit(emitCount or emitter:GetAttribute("EmitCount") or 15)
	end
end

local function tweenIn(vfxPart, originalSize)
	vfxPart.Size = Vector3.new(0.1, 0.1, 0.1)
	vfxPart.Transparency = 1
	
	local tweenInfo = TweenInfo.new(
		TWEEN_IN_TIME,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	)
	
	local tween = TweenService:Create(vfxPart, tweenInfo, {
		Size = originalSize
	})
	
	tween:Play()
	return tween
end

local function tweenOutAndDestroy(vfxPart)
	local tweenInfo = TweenInfo.new(
		TWEEN_OUT_TIME,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In
	)
	
	local tween = TweenService:Create(vfxPart, tweenInfo, {
		Size = Vector3.new(0.1, 0.1, 0.1)
	})
	
	tween:Play()
	tween.Completed:Connect(function()
		vfxPart:Destroy()
	end)
end

local function spawnVFX(position, normal)
	local vfxClone = SmashVfxTemplate:Clone()
	local originalSize = vfxClone.Size
	
	vfxClone.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(math.rad(90), 0, 0)
	
	vfxClone.Anchored = true
	vfxClone.CanCollide = false
	vfxClone.CanQuery = false
	vfxClone.CanTouch = false
	vfxClone.Transparency = 1
	vfxClone.Parent = workspace
	
	-- Spawn hitbox
	spawnHitbox(position)
	
	-- Animate
	local tweenInObj = tweenIn(vfxClone, originalSize)
	tweenInObj.Completed:Wait()
	emitAllParticles(vfxClone)
	
	-- Cleanup
	task.delay(VFX_LIFETIME, function()
		if vfxClone and vfxClone.Parent then
			tweenOutAndDestroy(vfxClone)
		end
	end)
	
	Debris:AddItem(vfxClone, VFX_LIFETIME + TWEEN_OUT_TIME + 1)
end

-- ============================================
-- INPUT HANDLING
-- ============================================

local function onInputBegan(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	
	if input.KeyCode == Enum.KeyCode.E then
		showPreview()
		return
	end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isOnCooldown then return end
		
		local currentTime = tick()
		if currentTime - lastClickTime < COOLDOWN then return end
		
		local position, normal, hitPart, isValidGround = getGroundPosition()
		
		if not position or not isValidGround then
			return
		end
		
		if not isWithinRange(position) then
			return
		end
		
		isOnCooldown = true
		lastClickTime = currentTime
		
		spawnVFX(position, normal)
		
		task.delay(COOLDOWN, function()
			isOnCooldown = false
		end)
	end
end

local function onInputEnded(input, gameProcessedEvent)
	if input.KeyCode == Enum.KeyCode.E then
		hidePreview()
	end
end

local function onCharacterAdded(character)
	hidePreview()
end

-- ============================================
-- INITIALIZATION
-- ============================================

local function init()
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
	
	player.CharacterAdded:Connect(onCharacterAdded)
	
	if player.Character then
		onCharacterAdded(player.Character)
	end
	
	print("[SmashVFX] Controller initialized (Single-Player)")
	print("  - Max Distance: " .. MAX_DISTANCE .. " studs")
	print("  - Cooldown: " .. COOLDOWN .. " seconds")
	print("  - Hold E to preview")
end

init()
