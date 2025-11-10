--[[
	MULTI-SWORD SYSTEM (BLADE BALL STYLE)
	Place this LocalScript in StarterPlayerScripts
	
	Features:
	- Support for multiple swords with unique settings
	- Easy configuration through SwordConfig module
	- Switch between swords with keybinds
	- Each sword has custom positioning, attack speed, and stats
	
	Setup:
	1. Put SwordConfig module in ReplicatedStorage
	2. Put this LocalScript in StarterPlayerScripts
	3. Add your sword models to ReplicatedStorage
	4. Configure swords in the SwordConfig module
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

-- Detect if player is on mobile
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- Load sword configuration from Modules folder
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local SwordConfig = require(modulesFolder:WaitForChild("SwordConfig"))

-- Get folders for organized assets
local toolSwordsFolder = ReplicatedStorage:WaitForChild("ToolSwords")
local holsteredModelsFolder = ReplicatedStorage:WaitForChild("HolsteredModels")

-- Load VFX assets
local assetsFolder = ReplicatedStorage:WaitForChild("Assets")
local swordVFXFolder = assetsFolder:WaitForChild("SwordVFX")
local slashVFXTemplate = swordVFXFolder:WaitForChild("SlashAttach")

-- Disable the hotbar/inventory UI
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Keep checking to make sure hotbar stays disabled (some actions try to re-enable it)
task.spawn(function()
	while true do
		task.wait(0.5)
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
	end
end)

-- Get RemoteEvents for sword system
local swordRemotes = ReplicatedStorage:WaitForChild("SwordRemotes", 10)
local attackRemote = swordRemotes:WaitForChild("Attack")
local switchSwordRemote = swordRemotes:WaitForChild("SwitchSword")
local initializeSwordRemote = swordRemotes:WaitForChild("InitializeSword")

-- Get crate system remotes
local crateRemotes = ReplicatedStorage:FindFirstChild("CrateRemotes")
if not crateRemotes then
	crateRemotes = ReplicatedStorage:WaitForChild("CrateRemotes", 5)
end

local crateSwitchEvent = nil
if crateRemotes then
	crateSwitchEvent = crateRemotes:WaitForChild("SwitchSword", 5)
end

-- ========================================
-- VARIABLES
-- ========================================

local currentSwordName = SwordConfig.DefaultSword
local currentSwordConfig = SwordConfig.Swords[currentSwordName]

local isAttacking = false
local canAttack = true
local serverInitialized = false

-- Cooldown UI references
local cooldownUI = nil
local cooldownOverlay = nil

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Function to get any character (not just local player)
local function getCharacterFromPlayer(targetPlayer)
	return targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
end

-- ========================================
-- COOLDOWN UI
-- ========================================

-- Create cooldown indicator UI
local function createCooldownUI()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CooldownIndicatorUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 50
	screenGui.Parent = playerGui
	
	-- Main container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 90, 0, 90) -- Small square
	container.Position = UDim2.new(0, 15, 1, -105) -- Bottom left, slightly above bottom
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	container.BackgroundTransparency = 0.2
	container.BorderSizePixel = 0
	container.Parent = screenGui
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = container
	
	-- Border
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(252, 252, 252)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.6
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = container
	
	-- Label text
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = isMobile and "TAP\nto Attack" or "M1\nto Attack"
	label.TextColor3 = Color3.fromRGB(244, 244, 255)
	label.TextSize = 13
	label.Font = Enum.Font.GothamBold
	label.TextWrapped = true
	label.Parent = container
	
	-- Cooldown overlay (black transparent frame that fills from top)
	local cooldownFrame = Instance.new("Frame")
	cooldownFrame.Name = "CooldownOverlay"
	cooldownFrame.Size = UDim2.new(1, 0, 0, 0) -- Start at 0 height
	cooldownFrame.Position = UDim2.new(0, 0, 0, 0) -- Top of container
	cooldownFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	cooldownFrame.BackgroundTransparency = 0.3 -- Semi-transparent black
	cooldownFrame.BorderSizePixel = 0
	cooldownFrame.ZIndex = 2
	cooldownFrame.Parent = container
	
	-- Rounded corners for overlay
	local overlayCorner = Instance.new("UICorner")
	overlayCorner.CornerRadius = UDim.new(0, 10)
	overlayCorner.Parent = cooldownFrame
	
	-- Store reference
	cooldownUI = container
	cooldownOverlay = cooldownFrame
	
	return screenGui
end

-- Function to play cooldown animation
local function playCooldownAnimation(duration)
	if not cooldownOverlay or not cooldownUI then return end
	
	-- Reset overlay to full height
	cooldownOverlay.Size = UDim2.new(1, 0, 1, 0)
	
	-- Animate overlay shrinking from top to bottom
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tween = TweenService:Create(cooldownOverlay, tweenInfo, {
		Size = UDim2.new(1, 0, 0, 0) -- Shrink to 0 height
	})
	tween:Play()
	
	-- Flash white when ready
	tween.Completed:Connect(function()
		-- Flash the container white
		local originalColor = cooldownUI.BackgroundColor3
		cooldownUI.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		
		-- Quick fade back to original
		TweenService:Create(cooldownUI, TweenInfo.new(0.15), {
			BackgroundColor3 = originalColor
		}):Play()
	end)
end

-- ========================================
-- VFX SYSTEM
-- ========================================

-- Function to play slash VFX from any character's HumanoidRootPart
local function playSlashVFX(targetCharacter)
	if not targetCharacter then return end

	local hrp = targetCharacter:FindFirstChild("HumanoidRootPart")
	if not hrp then 
		warn("No HumanoidRootPart found for VFX")
		return 
	end

	-- Clone the slash VFX attachment
	local slashVFX = slashVFXTemplate:Clone()
	slashVFX.Parent = hrp

	-- ⚙️ ADJUST VFX POSITION HERE ⚙️
	-- X = Left/Right (positive = right, negative = left)
	-- Y = Up/Down (positive = up, negative = down)
	-- Z = Forward/Back (positive = back, negative = forward)
	slashVFX.Position = Vector3.new(0.3, 0, -1.1) -- Default: 2.5 studs in front

	-- Emit all particle emitters and enable beams
	for _, descendant in pairs(slashVFX:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant:Emit(descendant:GetAttribute("EmitCount") or 20)
		elseif descendant:IsA("Beam") then
			descendant.Enabled = true
		end
	end

	-- ⚙️ ADJUST VFX DURATION HERE ⚙️
	-- How long the VFX stays before cleaning up (in seconds)
	local vfxDuration = 2

	-- Auto-cleanup after VFX duration
	task.delay(vfxDuration, function()
		if slashVFX then
			-- Disable beams before destroying
			for _, descendant in pairs(slashVFX:GetDescendants()) do
				if descendant:IsA("Beam") then
					descendant.Enabled = false
				end
			end
			slashVFX:Destroy()
		end
	end)
end

-- ========================================
-- ANIMATION SYSTEM
-- ========================================

-- Function to play attack animation for any character
local function playAttackAnimation(targetCharacter, swordName)
	if not targetCharacter then return end

	local config = SwordConfig.Swords[swordName]
	if not config then return end

	local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local attackConfig = config.Attack

	-- Play animation if provided
	if attackConfig.AnimationId ~= "rbxassetid://0" then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			local animation = Instance.new("Animation")
			animation.AnimationId = attackConfig.AnimationId
			local animTrack = animator:LoadAnimation(animation)
			animTrack:Play()
		end
	end
end

-- ========================================
-- ATTACK SYSTEM (CLIENT-TO-SERVER)
-- ========================================

-- Function to request attack from server
local function requestAttack()
	-- Only local player can request their own attacks
	if not canAttack or isAttacking then return end
	if not serverInitialized then 
		warn("Sword system not initialized yet")
		return 
	end

	-- Set local cooldown to prevent spam
	canAttack = false
	isAttacking = true

	-- Request attack from server
	attackRemote:FireServer()

	-- Ensure hotbar stays disabled
	task.wait()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	-- Local cooldown (server validates actual cooldown)
	local attackConfig = currentSwordConfig.Attack
	local totalCooldown = attackConfig.AttackDuration + attackConfig.AttackCooldown
	
	-- Play cooldown animation
	playCooldownAnimation(totalCooldown)

	task.wait(totalCooldown)
	isAttacking = false
	canAttack = true
end

-- ========================================
-- SWORD SWITCHING
-- ========================================

-- Function to switch to a different sword
local function switchSword(swordName)
	if not SwordConfig.Swords[swordName] then
		warn("Sword not found: " .. swordName)
		return
	end

	if swordName == currentSwordName then return end

	if not serverInitialized then
		warn("Sword system not initialized yet")
		return
	end

	-- Request sword switch from server
	switchSwordRemote:FireServer(swordName)
end

-- Listen for successful switch confirmation from server
switchSwordRemote.OnClientEvent:Connect(function(swordName)
	currentSwordName = swordName
	currentSwordConfig = SwordConfig.Swords[swordName]
	print("Switched to: " .. swordName)
end)

-- ========================================
-- INPUT HANDLING
-- ========================================

if isMobile then
	-- Mobile: Smart tap detection (attack on tap, not on camera drag)
	local activeTouches = {} -- Track touch start positions
	
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- Only track screen touches
		if input.UserInputType == Enum.UserInputType.Touch then
			-- Don't process if touching GUI
			if gameProcessed then return end
			
			-- Store touch start position
			activeTouches[input] = input.Position
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.Touch then
			-- Check if this touch started on the game screen
			local startPosition = activeTouches[input]
			if startPosition then
				-- Calculate how far the touch moved
				local endPosition = input.Position
				local dragDistance = (endPosition - startPosition).Magnitude
				
				-- If touch barely moved (< 20 pixels), it's a tap - attack!
				-- If it moved a lot, it was camera dragging - don't attack
				if dragDistance < 20 then
					requestAttack()
				end
				
				-- Clean up
				activeTouches[input] = nil
			end
		end
	end)
else
	-- PC: Use mouse click for attacks
	mouse.Button1Down:Connect(function()
		requestAttack()
	end)
end

-- Keybind switching disabled - swords can only be equipped from inventory UI

-- ========================================
-- SERVER EVENT HANDLERS
-- ========================================

-- Listen for server telling us to play attack animation/VFX for ANY player
initializeSwordRemote.OnClientEvent:Connect(function(action, targetPlayer, swordName)
	if action == "PlayAttack" then
		-- Play attack animation and VFX for the target player
		local targetCharacter = targetPlayer.Character
		if targetCharacter then
			playAttackAnimation(targetCharacter, swordName)
			playSlashVFX(targetCharacter)
		end
	elseif type(action) == "string" and not targetPlayer then
		-- Server initialization message (action is the default sword name)
		serverInitialized = true
		currentSwordName = action
		currentSwordConfig = SwordConfig.Swords[action]
		print("✅ Sword system initialized! Current sword: " .. action)
	end
end)

-- ========================================
-- CRATE SYSTEM INTEGRATION
-- ========================================

-- Listen for sword switch from crate system
if crateSwitchEvent then
	crateSwitchEvent.OnClientEvent:Connect(function(swordName)
		print("Crate system switching to: " .. swordName)
		switchSword(swordName)
	end)
end

-- ========================================
-- CHARACTER RESPAWN HANDLING
-- ========================================

-- Reset on character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	mouse = player:GetMouse()

	-- Reset variables
	serverInitialized = false
	isAttacking = false
	canAttack = true

	-- Wait for server to initialize
	print("⏳ Waiting for server to initialize sword system...")
end)

-- ========================================
-- INITIALIZATION
-- ========================================

-- Create cooldown UI
createCooldownUI()

print("🗡️ Multi-Sword System (Client) Loaded!")
print("⏳ Waiting for server initialization...")

-- Server will send initialization event when ready
