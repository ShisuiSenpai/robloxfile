--[[
	SmashVFXController_Multiplayer (LocalScript)
	Location: StarterPlayerScripts/SmashVFXController
	
	MULTIPLAYER VERSION - Use this if you want other players to see the VFX.
	Works with SmashVFXHandler on the server.
	
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
local MAX_DISTANCE = 20
local VFX_LIFETIME = 2
local TWEEN_IN_TIME = 0.15
local TWEEN_OUT_TIME = 0.4
local COOLDOWN = 0.3

-- Preview Configuration
local PREVIEW_SIZE = 7
local PREVIEW_COLOR_VALID = Color3.fromRGB(100, 255, 100)
local PREVIEW_COLOR_INVALID = Color3.fromRGB(255, 100, 100)
local PREVIEW_TRANSPARENCY = 0.5

-- Hitbox Configuration
local HITBOX_SIZE = Vector3.new(7, 8, 7) -- Width, Height, Depth
local HITBOX_COLOR = Color3.fromRGB(255, 0, 0)
local HITBOX_TRANSPARENCY = 0.7
local HITBOX_DURATION = 0.3
local DEBUG_HITBOX = true -- Set to false in production

-- References
local VFXFolder = ReplicatedStorage:WaitForChild("VFX")
local SmashVfxTemplate = VFXFolder:WaitForChild("SmashVfx")
local smashVFXEvent = ReplicatedStorage:WaitForChild("SmashVFXEvent")

-- State
local lastClickTime = 0
local isOnCooldown = false
local isPreviewActive = false
local previewPart = nil
local previewConnection = nil

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

local function getPlayersInHitbox(hitbox, sourcePlayer)
	local playersHit = {}
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {hitbox}
	if sourcePlayer and sourcePlayer.Character then
		overlapParams.FilterDescendantsInstances = {hitbox, sourcePlayer.Character}
	end
	
	local partsInBox = workspace:GetPartsInPart(hitbox, overlapParams)
	
	for _, part in ipairs(partsInBox) do
		local character = part.Parent
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local targetPlayer = Players:GetPlayerFromCharacter(character)
				if targetPlayer and targetPlayer ~= sourcePlayer then
					if not table.find(playersHit, targetPlayer) then
						table.insert(playersHit, targetPlayer)
					end
				end
			end
		end
	end
	
	return playersHit
end

local function spawnHitbox(position, sourcePlayer)
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
			local playersHit = getPlayersInHitbox(hitbox, sourcePlayer)
			
			for _, hitPlayer in ipairs(playersHit) do
				print("[SmashVFX] HIT: " .. hitPlayer.Name)
			end
			
			if #playersHit > 0 then
				print("[SmashVFX] Total players hit: " .. #playersHit)
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
		
		local position, normal, hitPart = getGroundPosition()
		
		if position then
			previewPart.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
			
			local inRange = isWithinRange(position)
			local targetColor = inRange and PREVIEW_COLOR_VALID or PREVIEW_COLOR_INVALID
			
			previewPart.Color = targetColor
			
			local highlight = previewPart:FindFirstChild("Highlight")
			if highlight then
				highlight.FillColor = targetColor
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
	local filterList = {player.Character, camera}
	if previewPart then
		table.insert(filterList, previewPart)
	end
	params.FilterDescendantsInstances = filterList
	params.IgnoreWater = true
	return params
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
		return raycastResult.Position, raycastResult.Normal, raycastResult.Instance
	end
	
	return nil, nil, nil
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

local function spawnVFX(position, normal, sourcePlayer)
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
	spawnHitbox(position, sourcePlayer)
	
	local tweenInObj = tweenIn(vfxClone, originalSize)
	tweenInObj.Completed:Wait()
	emitAllParticles(vfxClone)
	
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
		
		local position, normal, hitPart = getGroundPosition()
		if not position then return end
		if not isWithinRange(position) then return end
		
		isOnCooldown = true
		lastClickTime = currentTime
		
		smashVFXEvent:FireServer(position, normal)
		
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

local function onVFXReceived(sourcePlayer, position, normal)
	spawnVFX(position, normal, sourcePlayer)
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
	smashVFXEvent.OnClientEvent:Connect(onVFXReceived)
	
	player.CharacterAdded:Connect(onCharacterAdded)
	
	if player.Character then
		onCharacterAdded(player.Character)
	end
	
	print("[SmashVFX] Multiplayer controller initialized!")
	print("  - Hold E to preview ability")
	print("  - Left-click on ground within " .. MAX_DISTANCE .. " studs to spawn VFX")
	print("  - Hitbox debug mode: " .. (DEBUG_HITBOX and "ON" or "OFF"))
end

init()
