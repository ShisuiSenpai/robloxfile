--[[
	SmashVFXController (LocalScript)
	Location: StarterPlayerScripts/SmashVFXController
	
	Handles mouse input and spawns the SmashVfx on left-click
	when clicking on the ground within 20 studs.
	
	Press E to show ability preview on the ground.
	Includes hitbox system with knockback and ragdoll.
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
local MAX_DISTANCE = 20 -- Maximum distance in studs
local VFX_LIFETIME = 2 -- How long the VFX stays before fading
local TWEEN_IN_TIME = 0.15 -- Time to scale in
local TWEEN_OUT_TIME = 0.4 -- Time to fade out
local COOLDOWN = 0.3 -- Prevent spam clicking

-- Preview Configuration
local PREVIEW_SIZE = 7 -- Diameter of preview circle in studs
local PREVIEW_COLOR_VALID = Color3.fromRGB(100, 255, 100) -- Green when in range
local PREVIEW_COLOR_INVALID = Color3.fromRGB(255, 100, 100) -- Red when out of range
local PREVIEW_TRANSPARENCY = 0.5

-- Hitbox Configuration
local HITBOX_SIZE = Vector3.new(7, 8, 7) -- Width, Height, Depth (extends upward)
local HITBOX_COLOR = Color3.fromRGB(255, 0, 0) -- Red for visibility
local HITBOX_TRANSPARENCY = 0.7 -- Semi-transparent to see through
local HITBOX_DURATION = 0.3 -- How long the hitbox stays active
local DEBUG_HITBOX = true -- Set to false to hide hitbox in production

-- Knockback & Ragdoll Configuration
local KNOCKBACK_FORCE_UP = 35 -- Upward force (goofy explosion up)
local KNOCKBACK_FORCE_BACK = 25 -- Backward force
local RAGDOLL_DURATION = 1.5 -- How long they stay ragdolled
local RECOVERY_TIME = 0.5 -- How long the smooth recovery takes

-- Ground Detection Configuration
local MIN_GROUND_NORMAL_Y = 0.7 -- Surface must be mostly horizontal (0.7 = ~45 degree angle max)

-- VFX Reference
local VFXFolder = ReplicatedStorage:WaitForChild("VFX")
local SmashVfxTemplate = VFXFolder:WaitForChild("SmashVfx")

-- State
local lastClickTime = 0
local isOnCooldown = false
local isPreviewActive = false
local previewPart = nil
local previewConnection = nil

-- Track ragdolled characters to prevent stacking
local ragdolledCharacters = {}

-- ============================================
-- RAGDOLL SYSTEM
-- ============================================

-- Store original motor data for recovery
local function getMotor6Ds(character)
	local motors = {}
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			table.insert(motors, descendant)
		end
	end
	return motors
end

-- Create a socket constraint to replace motor (for ragdoll effect)
local function createRagdollConstraint(motor)
	local socket = Instance.new("BallSocketConstraint")
	socket.Name = "RagdollSocket_" .. motor.Name
	socket.LimitsEnabled = true
	socket.TwistLimitsEnabled = true
	socket.UpperAngle = 45
	socket.TwistLowerAngle = -45
	socket.TwistUpperAngle = 45
	
	-- Create attachments
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

-- Enable ragdoll on a character
local function enableRagdoll(character)
	if ragdolledCharacters[character] then return end -- Already ragdolled
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Store data for recovery
	local ragdollData = {
		motors = {},
		sockets = {},
		attachments = {},
		originalState = humanoid:GetState()
	}
	
	-- Disable humanoid states that interfere with ragdoll
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	-- Get all motors and disable them
	local motors = getMotor6Ds(character)
	
	for _, motor in ipairs(motors) do
		-- Skip the root joint (keeps character together)
		if motor.Name ~= "RootJoint" and motor.Name ~= "Root" then
			-- Store motor data
			table.insert(ragdollData.motors, {
				motor = motor,
				enabled = motor.Enabled
			})
			
			-- Create ragdoll constraint
			local socket, att0, att1 = createRagdollConstraint(motor)
			table.insert(ragdollData.sockets, socket)
			table.insert(ragdollData.attachments, att0)
			table.insert(ragdollData.attachments, att1)
			
			-- Disable the motor
			motor.Enabled = false
		end
	end
	
	-- Make all parts able to collide for physics
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end
	
	ragdolledCharacters[character] = ragdollData
	return true
end

-- Disable ragdoll and recover smoothly
local function disableRagdoll(character)
	local ragdollData = ragdolledCharacters[character]
	if not ragdollData then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Clean up sockets and attachments
	for _, socket in ipairs(ragdollData.sockets) do
		if socket and socket.Parent then
			socket:Destroy()
		end
	end
	
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
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	
	-- Reset collision on parts
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = false
		end
	end
	
	ragdolledCharacters[character] = nil
end

-- Apply knockback force to a character
local function applyKnockback(character, hitPosition)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	-- Calculate direction away from hit position
	local direction = (rootPart.Position - hitPosition).Unit
	direction = Vector3.new(direction.X, 0, direction.Z).Unit -- Keep horizontal
	
	-- Create the knockback velocity (up and back)
	local knockbackVelocity = Vector3.new(
		direction.X * KNOCKBACK_FORCE_BACK,
		KNOCKBACK_FORCE_UP, -- Goofy upward explosion
		direction.Z * KNOCKBACK_FORCE_BACK
	)
	
	-- Apply velocity to root part
	rootPart.AssemblyLinearVelocity = knockbackVelocity
	
	-- Add some random spin for goofy effect
	rootPart.AssemblyAngularVelocity = Vector3.new(
		math.random(-5, 5),
		math.random(-3, 3),
		math.random(-5, 5)
	)
end

-- Full knockback + ragdoll sequence
local function knockbackAndRagdoll(character, hitPosition)
	-- Skip if already ragdolled
	if ragdolledCharacters[character] then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	-- Enable ragdoll
	local success = enableRagdoll(character)
	if not success then return end
	
	-- Apply knockback force
	applyKnockback(character, hitPosition)
	
	-- Schedule recovery
	task.delay(RAGDOLL_DURATION, function()
		if character and character.Parent then
			-- Smooth recovery
			disableRagdoll(character)
		end
	end)
end

-- ============================================
-- HITBOX SYSTEM
-- ============================================

-- Create a visible hitbox part
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

-- Get all characters (players + NPCs) in hitbox
local function getCharactersInHitbox(hitbox, sourceCharacter)
	local charactersHit = {}
	local charactersChecked = {}
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {hitbox, sourceCharacter}
	
	local partsInBox = workspace:GetPartsInPart(hitbox, overlapParams)
	
	for _, part in ipairs(partsInBox) do
		local character = part.Parent
		
		-- Check if it's a character with humanoid (player or NPC)
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

-- Spawn hitbox and check for hits
local function spawnHitbox(position)
	local hitbox = createHitboxPart(position)
	hitbox.Parent = workspace
	
	-- Animate hitbox appearing
	local originalSize = hitbox.Size
	hitbox.Size = Vector3.new(HITBOX_SIZE.X, 0.5, HITBOX_SIZE.Z)
	hitbox.CFrame = CFrame.new(position + Vector3.new(0, 0.25, 0))
	
	local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(hitbox, tweenInfo, {
		Size = originalSize,
		CFrame = CFrame.new(position + Vector3.new(0, HITBOX_SIZE.Y / 2, 0))
	})
	tween:Play()
	
	-- Check for hits after hitbox is formed
	task.delay(0.05, function()
		if hitbox and hitbox.Parent then
			local charactersHit = getCharactersInHitbox(hitbox, player.Character)
			
			for _, character in ipairs(charactersHit) do
				local targetPlayer = Players:GetPlayerFromCharacter(character)
				local name = targetPlayer and targetPlayer.Name or character.Name
				print("[SmashVFX] HIT: " .. name)
				
				-- Apply knockback and ragdoll!
				knockbackAndRagdoll(character, position)
			end
			
			if #charactersHit > 0 then
				print("[SmashVFX] Total hit: " .. #charactersHit)
			end
		end
	end)
	
	-- Fade out hitbox
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
			
			local highlight = previewPart:FindFirstChild("Highlight")
			if highlight then
				highlight.FillColor = targetColor
			end
			
			previewPart.Transparency = PREVIEW_TRANSPARENCY
		else
			-- Invalid surface - make preview dim/grey
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

-- Raycast parameters - exclude characters and camera
local function createRaycastParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	
	local filterList = {camera}
	
	-- Add preview part to filter
	if previewPart then
		table.insert(filterList, previewPart)
	end
	
	-- Add all player characters to filter (don't spawn VFX on players)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(filterList, p.Character)
		end
	end
	
	-- Also filter out any NPCs/models with humanoids in workspace
	for _, child in ipairs(workspace:GetChildren()) do
		if child:FindFirstChildOfClass("Humanoid") then
			table.insert(filterList, child)
		end
	end
	
	params.FilterDescendantsInstances = filterList
	params.IgnoreWater = true
	return params
end

-- Check if surface is valid ground (horizontal enough)
local function isValidGroundSurface(normal, hitPart)
	-- Check if normal is pointing mostly upward (ground-like surface)
	if normal.Y < MIN_GROUND_NORMAL_Y then
		return false -- Too steep (wall-like)
	end
	
	-- Optional: Additional checks for specific part types
	-- You can add more conditions here if needed
	
	return true
end

-- Perform raycast from mouse position to find ground
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
		local isValidGround = isValidGroundSurface(raycastResult.Normal, raycastResult.Instance)
		return raycastResult.Position, raycastResult.Normal, raycastResult.Instance, isValidGround
	end
	
	return nil, nil, nil, false
end

-- Check if position is within max distance from player
function isWithinRange(position)
	local character = player.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	local distance = (position - humanoidRootPart.Position).Magnitude
	return distance <= MAX_DISTANCE
end

-- Get all ParticleEmitters recursively from a part/model
local function getAllParticleEmitters(parent)
	local emitters = {}
	
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			table.insert(emitters, descendant)
		end
	end
	
	return emitters
end

-- Emit all particles in the VFX
local function emitAllParticles(vfxPart, emitCount)
	local emitters = getAllParticleEmitters(vfxPart)
	
	for _, emitter in ipairs(emitters) do
		emitter.Enabled = false
		emitter:Emit(emitCount or emitter:GetAttribute("EmitCount") or 15)
	end
end

-- Tween the VFX in (scale up from 0)
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

-- Tween the VFX out and cleanup
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

-- Spawn the VFX at the given position
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
	
	-- Tween in
	local tweenInObj = tweenIn(vfxClone, originalSize)
	tweenInObj.Completed:Wait()
	
	-- Emit particles
	emitAllParticles(vfxClone)
	
	-- Schedule cleanup
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
	
	-- E key for preview
	if input.KeyCode == Enum.KeyCode.E then
		showPreview()
		return
	end
	
	-- Left click to spawn VFX
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isOnCooldown then return end
		
		local currentTime = tick()
		if currentTime - lastClickTime < COOLDOWN then return end
		
		-- Get ground position with validation
		local position, normal, hitPart, isValidGround = getGroundPosition()
		
		-- Must hit valid ground
		if not position or not isValidGround then
			return
		end
		
		-- Must be in range
		if not isWithinRange(position) then
			return
		end
		
		-- Set cooldown
		isOnCooldown = true
		lastClickTime = currentTime
		
		-- Spawn VFX
		spawnVFX(position, normal)
		
		-- Reset cooldown
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
	
	print("[SmashVFX] Controller initialized!")
	print("  - Hold E to preview ability")
	print("  - Left-click on GROUND within " .. MAX_DISTANCE .. " studs to spawn VFX")
	print("  - VFX only spawns on horizontal surfaces (not walls/players)")
	print("  - Hitbox debug mode: " .. (DEBUG_HITBOX and "ON" or "OFF"))
	print("  - Knockback & Ragdoll: ENABLED")
end

init()
