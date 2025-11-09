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

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local mouse = player:GetMouse()

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

-- Get or create RemoteEvents folder for crate system integration
local crateRemotes = ReplicatedStorage:FindFirstChild("CrateRemotes")
if not crateRemotes then
	-- Wait a moment for server to create it
	crateRemotes = ReplicatedStorage:WaitForChild("CrateRemotes", 5)
end

local switchSwordEvent = nil
if crateRemotes then
	switchSwordEvent = crateRemotes:WaitForChild("SwitchSword", 5)
end

-- ========================================
-- VARIABLES
-- ========================================

local holsteredSwords = {} -- Table of all holstered sword instances {swordName = {model, weld}}
local currentSwordName = SwordConfig.DefaultSword
local currentSwordConfig = SwordConfig.Swords[currentSwordName]

local attackSword = nil
local isAttacking = false
local canAttack = true

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Function to set transparency of a model
local function setModelTransparency(model, transparency)
	if not model then return end

	for _, descendant in pairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = transparency
		end
	end
end

-- Function to get the correct body part for attachment
local function getAttachmentPart(partName)
	local attachPart = character:FindFirstChild(partName)

	-- Fallback to Torso if the specified part doesn't exist
	if not attachPart then
		attachPart = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	end

	return attachPart
end

-- ========================================
-- HOLSTERED SWORD MANAGEMENT
-- ========================================

-- Function to create a holstered sword
local function createHolsteredSword(swordName, config)
	-- Check if already exists
	if holsteredSwords[swordName] then return end

	-- Find the template in HolsteredModels folder
	local holsteredTemplate = holsteredModelsFolder:FindFirstChild(config.HolsteredModelName)
	if not holsteredTemplate then
		warn("Could not find holstered model: " .. config.HolsteredModelName .. " in HolsteredModels folder")
		return
	end

	local attachPart = getAttachmentPart(config.Holster.AttachmentPart)
	if not attachPart then 
		warn("Could not find attachment part for holster: " .. config.Holster.AttachmentPart)
		return 
	end

	-- Clone the HolsteredSword model
	local holsteredSword = holsteredTemplate:Clone()

	-- Find the main sword part to weld (using the SwordPartName from config)
	local swordPart = holsteredSword:FindFirstChild(config.SwordPartName)
	if not swordPart then
		warn("Could not find '" .. config.SwordPartName .. "' part in holstered model: " .. config.HolsteredModelName)
		holsteredSword:Destroy()
		return
	end

	-- Make all parts non-collidable and massless
	for _, descendant in pairs(holsteredSword:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.Massless = true
		end
	end

	-- Create weld to attach holstered sword to body part
	local holsterWeld = Instance.new("Weld")
	holsterWeld.Name = "HolsterWeld_" .. swordName
	holsterWeld.Part0 = attachPart
	holsterWeld.Part1 = swordPart

	-- Apply position and rotation offsets
	local rotationCFrame = CFrame.Angles(
		math.rad(config.Holster.RotationOffset.X),
		math.rad(config.Holster.RotationOffset.Y),
		math.rad(config.Holster.RotationOffset.Z)
	)

	holsterWeld.C0 = CFrame.new(config.Holster.PositionOffset) * rotationCFrame
	holsterWeld.Parent = swordPart

	holsteredSword.Parent = character

	-- Set initial visibility (visible if current sword or if ShowAllSwords is true)
	local shouldBeVisible = (swordName == currentSwordName) or SwordConfig.ShowAllSwords
	setModelTransparency(holsteredSword, shouldBeVisible and config.Holster.TransparencyValue or 1)

	-- Store reference
	holsteredSwords[swordName] = {
		model = holsteredSword,
		weld = holsterWeld,
		config = config
	}
end

-- Function to show a specific holstered sword
local function showHolster(swordName)
	local holsterData = holsteredSwords[swordName]
	if holsterData then
		setModelTransparency(holsterData.model, holsterData.config.Holster.TransparencyValue)
	end
end

-- Function to hide a specific holstered sword
local function hideHolster(swordName)
	local holsterData = holsteredSwords[swordName]
	if holsterData then
		setModelTransparency(holsterData.model, 1)
	end
end

-- Function to cleanup all holstered swords
local function cleanupAllHolsters()
	for swordName, holsterData in pairs(holsteredSwords) do
		if holsterData.model then
			holsterData.model:Destroy()
		end
	end
	holsteredSwords = {}
end

-- Function to initialize all holstered swords
local function initializeAllSwords()
	for swordName, config in pairs(SwordConfig.Swords) do
		createHolsteredSword(swordName, config)
	end
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

	-- Hide current sword (unless ShowAllSwords is true)
	if not SwordConfig.ShowAllSwords then
		hideHolster(currentSwordName)
	end

	-- Update current sword
	currentSwordName = swordName
	currentSwordConfig = SwordConfig.Swords[swordName]

	-- Show new sword
	showHolster(currentSwordName)

	print("Switched to: " .. swordName)
end

-- ========================================
-- VFX SYSTEM
-- ========================================

-- Function to play slash VFX on the sword
local function playSlashVFX(swordTool)
	if not swordTool then return end
	
	-- Find the Handle (middle of the sword)
	local handle = swordTool:FindFirstChild("Handle")
	if not handle then 
		warn("No Handle found in sword tool for VFX")
		return 
	end
	
	-- Clone the slash VFX attachment
	local slashVFX = slashVFXTemplate:Clone()
	slashVFX.Parent = handle
	
	-- Position at center of handle
	slashVFX.Position = Vector3.new(0, 0, 0)
	
	-- Emit all particle emitters and enable beams
	for _, descendant in pairs(slashVFX:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant:Emit(descendant:GetAttribute("EmitCount") or 20)
		elseif descendant:IsA("Beam") then
			descendant.Enabled = true
		end
	end
	
	-- Auto-cleanup after VFX duration
	task.delay(2, function()
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
-- ATTACK SYSTEM
-- ========================================

-- Function to perform attack with current sword
local function performAttack()
	if not canAttack or isAttacking then return end
	if not currentSwordConfig then return end

	canAttack = false
	isAttacking = true

	local attackConfig = currentSwordConfig.Attack

	-- Hide holstered version of current sword
	hideHolster(currentSwordName)

	-- Find the tool in ToolSwords folder
	local toolTemplate = toolSwordsFolder:FindFirstChild(currentSwordConfig.ToolName)
	if not toolTemplate then
		warn("Could not find tool: " .. currentSwordConfig.ToolName .. " in ToolSwords folder")
		showHolster(currentSwordName)
		isAttacking = false
		canAttack = true
		return
	end

	-- Clone the sword tool and equip it temporarily
	attackSword = toolTemplate:Clone()
	attackSword.Parent = character

	-- Equip the sword (simulates equipping to hand)
	humanoid:EquipTool(attackSword)

	-- Ensure hotbar doesn't appear when equipping
	task.wait()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	-- Load and play attack animation if provided
	if attackConfig.AnimationId ~= "rbxassetid://0" then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			local animation = Instance.new("Animation")
			animation.AnimationId = attackConfig.AnimationId
			local animTrack = animator:LoadAnimation(animation)
			animTrack:Play()
		end
	end

	-- Play slash VFX on the sword
	playSlashVFX(attackSword)

	-- Wait for attack duration
	task.wait(attackConfig.AttackDuration)

	-- Remove attack sword
	if attackSword then
		attackSword:Destroy()
		attackSword = nil
	end

	-- Show holstered sword again
	showHolster(currentSwordName)

	isAttacking = false

	-- Cooldown
	task.wait(attackConfig.AttackCooldown)
	canAttack = true
end

-- ========================================
-- INPUT HANDLING
-- ========================================

-- Mouse click handler for attacks
mouse.Button1Down:Connect(function()
	performAttack()
end)

-- Keyboard handler for sword switching
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not SwordConfig.AllowSwitching then return end

	-- Check if input matches any sword's keybind
	for swordName, config in pairs(SwordConfig.Swords) do
		if config.Keybind and input.KeyCode == config.Keybind then
			switchSword(swordName)
			break
		end
	end
end)

-- ========================================
-- CHARACTER MANAGEMENT
-- ========================================

-- Cleanup on character death
humanoid.Died:Connect(function()
	cleanupAllHolsters()
	if attackSword then
		attackSword:Destroy()
		attackSword = nil
	end
end)

-- Character respawn handler
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	cleanupAllHolsters()
	task.wait(0.5) -- Wait for character to fully load

	-- Reinitialize
	currentSwordName = SwordConfig.DefaultSword
	currentSwordConfig = SwordConfig.Swords[currentSwordName]
	initializeAllSwords()

	humanoid.Died:Connect(function()
		cleanupAllHolsters()
		if attackSword then
			attackSword:Destroy()
			attackSword = nil
		end
	end)
end)

-- ========================================
-- CRATE SYSTEM INTEGRATION
-- ========================================

-- Listen for sword switch from crate system
if switchSwordEvent then
	switchSwordEvent.OnClientEvent:Connect(function(swordName)
		print("Crate system switching to: " .. swordName)
		switchSword(swordName)
	end)
end

-- ========================================
-- INITIALIZATION
-- ========================================

-- Initialize all swords on startup
initializeAllSwords()

print("Multi-Sword System Loaded!")
print("Current Sword: " .. currentSwordName)
if SwordConfig.AllowSwitching then
	print("Press number keys to switch swords")
end
