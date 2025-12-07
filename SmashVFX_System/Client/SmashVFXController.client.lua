--[[
	SmashVFXController (LocalScript)
	Location: StarterPlayerScripts/SmashVFXController
	
	Handles mouse input and spawns the SmashVfx on left-click
	when clicking on the ground within 20 studs.
	
	Press E to show ability preview on the ground.
	Includes hitbox system for player detection.
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
local HITBOX_DURATION = 0.3 -- How long the hitbox stays active (quick smash hit)
local DEBUG_HITBOX = true -- Set to false to hide hitbox in production

-- VFX Reference
local VFXFolder = ReplicatedStorage:WaitForChild("VFX")
local SmashVfxTemplate = VFXFolder:WaitForChild("SmashVfx")

-- State
local lastClickTime = 0
local isOnCooldown = false
local isPreviewActive = false
local previewPart = nil
local previewConnection = nil

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
	hitbox.Material = Enum.Material.ForceField -- Nice effect for hitbox visualization
	hitbox.Transparency = HITBOX_TRANSPARENCY
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanQuery = true -- Needed for spatial queries
	hitbox.CanTouch = true -- Needed for Touched events
	hitbox.CastShadow = false
	
	-- Position hitbox: bottom at ground level, extends upward
	-- The hitbox center is at half its height above the ground
	hitbox.CFrame = CFrame.new(position + Vector3.new(0, HITBOX_SIZE.Y / 2, 0))
	
	-- Add a SelectionBox for extra visibility (wireframe effect)
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

-- Check for players inside the hitbox using spatial query
local function getPlayersInHitbox(hitbox)
	local playersHit = {}
	
	-- Create OverlapParams to filter what we're looking for
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {hitbox, player.Character} -- Don't hit yourself
	
	-- Get all parts inside the hitbox
	local partsInBox = workspace:GetPartsInPart(hitbox, overlapParams)
	
	-- Find which players these parts belong to
	for _, part in ipairs(partsInBox) do
		local character = part.Parent
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local targetPlayer = Players:GetPlayerFromCharacter(character)
				if targetPlayer and targetPlayer ~= player then
					-- Avoid duplicates
					if not table.find(playersHit, targetPlayer) then
						table.insert(playersHit, targetPlayer)
					end
				end
			end
		end
	end
	
	return playersHit
end

-- Spawn hitbox and check for hits
local function spawnHitbox(position)
	local hitbox = createHitboxPart(position)
	hitbox.Parent = workspace
	
	-- Animate hitbox appearing (scale up from ground)
	local originalSize = hitbox.Size
	hitbox.Size = Vector3.new(HITBOX_SIZE.X, 0.5, HITBOX_SIZE.Z)
	hitbox.CFrame = CFrame.new(position + Vector3.new(0, 0.25, 0))
	
	local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(hitbox, tweenInfo, {
		Size = originalSize,
		CFrame = CFrame.new(position + Vector3.new(0, HITBOX_SIZE.Y / 2, 0))
	})
	tween:Play()
	
	-- Check for players hit (do this after a tiny delay so hitbox is fully formed)
	task.delay(0.05, function()
		if hitbox and hitbox.Parent then
			local playersHit = getPlayersInHitbox(hitbox)
			
			-- Log hits for testing (replace with actual damage logic later)
			for _, hitPlayer in ipairs(playersHit) do
				print("[SmashVFX] HIT: " .. hitPlayer.Name)
			end
			
			if #playersHit > 0 then
				print("[SmashVFX] Total players hit: " .. #playersHit)
			end
		end
	end)
	
	-- Fade out and destroy hitbox
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
	
	-- Safety cleanup
	Debris:AddItem(hitbox, HITBOX_DURATION + 1)
	
	return hitbox
end

-- ============================================
-- PREVIEW SYSTEM
-- ============================================

-- Create the preview circle part
local function createPreviewPart()
	local part = Instance.new("Part")
	part.Name = "SmashVFX_Preview"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.2, PREVIEW_SIZE, PREVIEW_SIZE) -- Cylinder: Height, Diameter, Diameter
	part.Color = PREVIEW_COLOR_VALID
	part.Material = Enum.Material.Neon
	part.Transparency = PREVIEW_TRANSPARENCY
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	
	-- Add a nice ring effect using a SelectionBox or UIStroke alternative
	-- We'll add a Highlight for extra visibility
	local highlight = Instance.new("Highlight")
	highlight.FillColor = PREVIEW_COLOR_VALID
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0.3
	highlight.Parent = part
	
	return part
end

-- Show the preview
local function showPreview()
	if isPreviewActive then return end
	isPreviewActive = true
	
	-- Create preview part
	previewPart = createPreviewPart()
	previewPart.Parent = workspace
	
	-- Animate in with a quick scale tween
	previewPart.Size = Vector3.new(0.2, 0.5, 0.5)
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(previewPart, tweenInfo, {
		Size = Vector3.new(0.2, PREVIEW_SIZE, PREVIEW_SIZE)
	})
	tween:Play()
	
	-- Update preview position every frame
	previewConnection = RunService.RenderStepped:Connect(function()
		if not previewPart or not previewPart.Parent then return end
		
		local position, normal, hitPart = getGroundPosition()
		
		if position then
			-- Position the cylinder flat on the ground
			-- Cylinder needs to be rotated 90 degrees on Z to lay flat
			previewPart.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
			
			-- Change color based on range
			local inRange = isWithinRange(position)
			local targetColor = inRange and PREVIEW_COLOR_VALID or PREVIEW_COLOR_INVALID
			
			previewPart.Color = targetColor
			
			-- Update highlight color too
			local highlight = previewPart:FindFirstChild("Highlight")
			if highlight then
				highlight.FillColor = targetColor
			end
		end
	end)
end

-- Hide the preview
local function hidePreview()
	if not isPreviewActive then return end
	isPreviewActive = false
	
	-- Disconnect update loop
	if previewConnection then
		previewConnection:Disconnect()
		previewConnection = nil
	end
	
	-- Animate out
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

-- Raycast parameters (ignore player character and other VFX)
local function createRaycastParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filterList = {player.Character, camera}
	if previewPart then
		table.insert(filterList, previewPart)
	end
	params.FilterDescendantsInstances = filterList
	params.IgnoreWater = true
	return params
end

-- Perform raycast from mouse position to find ground
function getGroundPosition()
	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	
	local raycastParams = createRaycastParams()
	
	-- Cast a ray from camera through mouse position
	local raycastResult = workspace:Raycast(
		ray.Origin,
		ray.Direction * 500, -- Long ray to hit distant surfaces
		raycastParams
	)
	
	if raycastResult then
		return raycastResult.Position, raycastResult.Normal, raycastResult.Instance
	end
	
	return nil, nil, nil
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
		-- Store original enabled state
		emitter.Enabled = false
		-- Emit a burst of particles
		emitter:Emit(emitCount or emitter:GetAttribute("EmitCount") or 15)
	end
end

-- Tween the VFX in (scale up from 0)
local function tweenIn(vfxPart, originalSize)
	-- Start from small size
	vfxPart.Size = Vector3.new(0.1, 0.1, 0.1)
	vfxPart.Transparency = 1 -- Keep part invisible, we only want particles
	
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
	-- Clone the VFX template
	local vfxClone = SmashVfxTemplate:Clone()
	
	-- Store original size for tweening
	local originalSize = vfxClone.Size
	
	-- Position the VFX at the hit point, slightly above ground
	-- Orient it flat on the ground (90, 0, 0 rotation)
	vfxClone.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(math.rad(90), 0, 0)
	
	-- Make the part non-collidable and anchored
	vfxClone.Anchored = true
	vfxClone.CanCollide = false
	vfxClone.CanQuery = false
	vfxClone.CanTouch = false
	vfxClone.Transparency = 1 -- Invisible part, only particles visible
	
	-- Parent to workspace (or a dedicated VFX folder if you have one)
	vfxClone.Parent = workspace
	
	-- Spawn the hitbox at the same position
	spawnHitbox(position)
	
	-- Tween in
	local tweenInObj = tweenIn(vfxClone, originalSize)
	
	-- Wait for tween to complete, then emit particles
	tweenInObj.Completed:Wait()
	
	-- Emit all particles
	emitAllParticles(vfxClone)
	
	-- Schedule fade out and cleanup
	task.delay(VFX_LIFETIME, function()
		if vfxClone and vfxClone.Parent then
			tweenOutAndDestroy(vfxClone)
		end
	end)
	
	-- Safety cleanup with Debris (backup in case something goes wrong)
	Debris:AddItem(vfxClone, VFX_LIFETIME + TWEEN_OUT_TIME + 1)
end

-- ============================================
-- INPUT HANDLING
-- ============================================

-- Handle input began
local function onInputBegan(input, gameProcessedEvent)
	-- Ignore if the game already processed this input (e.g., clicking on GUI)
	if gameProcessedEvent then return end
	
	-- Check for E key to show preview
	if input.KeyCode == Enum.KeyCode.E then
		showPreview()
		return
	end
	
	-- Check for left mouse button to spawn VFX
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Check cooldown
		if isOnCooldown then return end
		
		local currentTime = tick()
		if currentTime - lastClickTime < COOLDOWN then return end
		
		-- Get ground position
		local position, normal, hitPart = getGroundPosition()
		
		if not position then
			return
		end
		
		-- Check if within range
		if not isWithinRange(position) then
			return
		end
		
		-- Set cooldown
		isOnCooldown = true
		lastClickTime = currentTime
		
		-- Spawn the VFX
		spawnVFX(position, normal)
		
		-- Reset cooldown after delay
		task.delay(COOLDOWN, function()
			isOnCooldown = false
		end)
	end
end

-- Handle input ended
local function onInputEnded(input, gameProcessedEvent)
	-- Check for E key release to hide preview
	if input.KeyCode == Enum.KeyCode.E then
		hidePreview()
	end
end

-- Wait for character to load
local function onCharacterAdded(character)
	-- Hide preview when respawning
	hidePreview()
end

-- ============================================
-- INITIALIZATION
-- ============================================

local function init()
	-- Connect input handlers
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
	
	-- Handle character respawning
	player.CharacterAdded:Connect(onCharacterAdded)
	
	if player.Character then
		onCharacterAdded(player.Character)
	end
	
	print("[SmashVFX] Controller initialized!")
	print("  - Hold E to preview ability")
	print("  - Left-click on ground within " .. MAX_DISTANCE .. " studs to spawn VFX")
	print("  - Hitbox debug mode: " .. (DEBUG_HITBOX and "ON" or "OFF"))
end

-- Start the system
init()
