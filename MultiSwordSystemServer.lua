--[[
	MULTI-SWORD SYSTEM - SERVER
	Place this Script in ServerScriptService
	
	Handles:
	- Server-side sword state management
	- Replicating sword visuals to all players
	- Managing holstered and equipped swords
	- Attack validation and replication
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Load configuration
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local SwordConfig = require(modulesFolder:WaitForChild("SwordConfig"))

-- Get asset folders
local toolSwordsFolder = ReplicatedStorage:WaitForChild("ToolSwords")
local holsteredModelsFolder = ReplicatedStorage:WaitForChild("HolsteredModels")

-- Create RemoteEvents for sword system
local swordRemotes = ReplicatedStorage:FindFirstChild("SwordRemotes")
if not swordRemotes then
	swordRemotes = Instance.new("Folder")
	swordRemotes.Name = "SwordRemotes"
	swordRemotes.Parent = ReplicatedStorage
end

-- Remote Events
local attackRemote = swordRemotes:FindFirstChild("Attack") or Instance.new("RemoteEvent")
attackRemote.Name = "Attack"
attackRemote.Parent = swordRemotes

local switchSwordRemote = swordRemotes:FindFirstChild("SwitchSword") or Instance.new("RemoteEvent")
switchSwordRemote.Name = "SwitchSword"
switchSwordRemote.Parent = swordRemotes

local initializeSwordRemote = swordRemotes:FindFirstChild("InitializeSword") or Instance.new("RemoteEvent")
initializeSwordRemote.Name = "InitializeSword"
initializeSwordRemote.Parent = swordRemotes

-- Player data storage
local playerSwordData = {} -- {[userId] = {currentSword = "SwordName", isAttacking = false, lastAttackTime = tick()}}

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Get attachment part safely
local function getAttachmentPart(character, partName)
	local attachPart = character:FindFirstChild(partName)
	if not attachPart then
		attachPart = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	end
	return attachPart
end

-- Set model transparency
local function setModelTransparency(model, transparency)
	if not model then return end
	for _, descendant in pairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = transparency
		end
	end
end

-- ========================================
-- HOLSTERED SWORD MANAGEMENT
-- ========================================

-- Create holstered sword on character
local function createHolsteredSword(character, swordName, config)
	-- Check if already exists
	local existingFolder = character:FindFirstChild("HolsteredSwords")
	if existingFolder then
		local existing = existingFolder:FindFirstChild("Holstered_" .. swordName)
		if existing then
			existing:Destroy()
		end
	end
	
	-- Create folder for holstered swords if doesn't exist
	local holsterFolder = character:FindFirstChild("HolsteredSwords")
	if not holsterFolder then
		holsterFolder = Instance.new("Folder")
		holsterFolder.Name = "HolsteredSwords"
		holsterFolder.Parent = character
	end
	
	-- Find template
	local holsteredTemplate = holsteredModelsFolder:FindFirstChild(config.HolsteredModelName)
	if not holsteredTemplate then
		warn("Could not find holstered model: " .. config.HolsteredModelName)
		return
	end
	
	local attachPart = getAttachmentPart(character, config.Holster.AttachmentPart)
	if not attachPart then
		warn("Could not find attachment part: " .. config.Holster.AttachmentPart)
		return
	end
	
	-- Clone holstered sword
	local holsteredSword = holsteredTemplate:Clone()
	holsteredSword.Name = "Holstered_" .. swordName
	
	-- Find main sword part
	local swordPart = holsteredSword:FindFirstChild(config.SwordPartName)
	if not swordPart then
		warn("Could not find sword part: " .. config.SwordPartName)
		holsteredSword:Destroy()
		return
	end
	
	-- Make parts non-collidable and massless
	for _, descendant in pairs(holsteredSword:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.Massless = true
		end
	end
	
	-- Create weld
	local holsterWeld = Instance.new("Weld")
	holsterWeld.Name = "HolsterWeld"
	holsterWeld.Part0 = attachPart
	holsterWeld.Part1 = swordPart
	
	-- Apply position and rotation
	local rotationCFrame = CFrame.Angles(
		math.rad(config.Holster.RotationOffset.X),
		math.rad(config.Holster.RotationOffset.Y),
		math.rad(config.Holster.RotationOffset.Z)
	)
	holsterWeld.C0 = CFrame.new(config.Holster.PositionOffset) * rotationCFrame
	holsterWeld.Parent = swordPart
	
	holsteredSword.Parent = holsterFolder
	
	return holsteredSword
end

-- Show specific holstered sword
local function showHolster(character, swordName)
	local holsterFolder = character:FindFirstChild("HolsteredSwords")
	if not holsterFolder then return end
	
	local holsteredSword = holsterFolder:FindFirstChild("Holstered_" .. swordName)
	if holsteredSword then
		local config = SwordConfig.Swords[swordName]
		if config then
			setModelTransparency(holsteredSword, config.Holster.TransparencyValue)
		end
	end
end

-- Hide specific holstered sword
local function hideHolster(character, swordName)
	local holsterFolder = character:FindFirstChild("HolsteredSwords")
	if not holsterFolder then return end
	
	local holsteredSword = holsterFolder:FindFirstChild("Holstered_" .. swordName)
	if holsteredSword then
		setModelTransparency(holsteredSword, 1)
	end
end

-- ========================================
-- EQUIPPED SWORD MANAGEMENT
-- ========================================

-- Create equipped sword (visible to all)
local function equipSword(character, swordName, config)
	-- Remove any existing equipped sword
	local existingEquipped = character:FindFirstChild("EquippedSword")
	if existingEquipped then
		existingEquipped:Destroy()
	end
	
	-- Find tool template
	local toolTemplate = toolSwordsFolder:FindFirstChild(config.ToolName)
	if not toolTemplate then
		warn("Could not find tool: " .. config.ToolName)
		return
	end
	
	-- Clone and parent to character
	local equippedSword = toolTemplate:Clone()
	equippedSword.Name = "EquippedSword"
	equippedSword.Parent = character
	
	-- Find humanoid
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Equip the tool (attaches to hand)
		humanoid:EquipTool(equippedSword)
	end
	
	return equippedSword
end

-- Remove equipped sword
local function unequipSword(character)
	local equippedSword = character:FindFirstChild("EquippedSword")
	if equippedSword then
		equippedSword:Destroy()
	end
end

-- ========================================
-- PLAYER INITIALIZATION
-- ========================================

-- Initialize player's sword system
local function initializePlayer(player)
	local character = player.Character
	if not character then return end
	
	local userId = player.UserId
	
	-- Initialize player data
	playerSwordData[userId] = {
		currentSword = SwordConfig.DefaultSword,
		isAttacking = false,
		lastAttackTime = 0,
	}
	
	-- Create all holstered swords
	for swordName, config in pairs(SwordConfig.Swords) do
		createHolsteredSword(character, swordName, config)
	end
	
	-- Show only the current sword (or all if ShowAllSwords is true)
	for swordName, config in pairs(SwordConfig.Swords) do
		if SwordConfig.ShowAllSwords or swordName == SwordConfig.DefaultSword then
			showHolster(character, swordName)
		else
			hideHolster(character, swordName)
		end
	end
	
	-- Tell client initialization is complete
	initializeSwordRemote:FireClient(player, SwordConfig.DefaultSword)
end

-- ========================================
-- ATTACK HANDLING
-- ========================================

-- Handle attack request from client
attackRemote.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character then return end
	
	local userId = player.UserId
	local playerData = playerSwordData[userId]
	if not playerData then return end
	
	-- Validate attack (cooldown check)
	local currentTime = tick()
	local config = SwordConfig.Swords[playerData.currentSword]
	if not config then return end
	
	local totalCooldown = config.Attack.AttackDuration + config.Attack.AttackCooldown
	if currentTime - playerData.lastAttackTime < totalCooldown then
		return -- Still on cooldown
	end
	
	-- Check if already attacking
	if playerData.isAttacking then return end
	
	-- Mark as attacking
	playerData.isAttacking = true
	playerData.lastAttackTime = currentTime
	
	-- Hide holstered sword
	hideHolster(character, playerData.currentSword)
	
	-- Equip attack sword
	equipSword(character, playerData.currentSword, config)
	
	-- Tell ALL clients to play animation and VFX for this player
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		initializeSwordRemote:FireClient(otherPlayer, "PlayAttack", player, playerData.currentSword)
	end
	
	-- Wait for attack duration
	task.wait(config.Attack.AttackDuration)
	
	-- Remove equipped sword
	unequipSword(character)
	
	-- Show holstered sword again
	showHolster(character, playerData.currentSword)
	
	-- Mark attack as complete
	playerData.isAttacking = false
end)

-- ========================================
-- SWORD SWITCHING
-- ========================================

-- Handle sword switch request
switchSwordRemote.OnServerEvent:Connect(function(player, swordName)
	local character = player.Character
	if not character then return end
	
	local userId = player.UserId
	local playerData = playerSwordData[userId]
	if not playerData then return end
	
	-- Validate sword exists
	if not SwordConfig.Swords[swordName] then return end
	
	-- Don't switch if already on this sword
	if playerData.currentSword == swordName then return end
	
	-- Don't switch while attacking
	if playerData.isAttacking then return end
	
	-- Hide old sword (unless ShowAllSwords)
	if not SwordConfig.ShowAllSwords then
		hideHolster(character, playerData.currentSword)
	end
	
	-- Update current sword
	playerData.currentSword = swordName
	
	-- Show new sword
	showHolster(character, swordName)
	
	-- Tell client switch was successful
	switchSwordRemote:FireClient(player, swordName)
end)

-- ========================================
-- PLAYER MANAGEMENT
-- ========================================

-- Player added handler
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Wait for character to load
		character:WaitForChild("Humanoid")
		task.wait(0.5)
		
		-- Initialize sword system
		initializePlayer(player)
	end)
end)

-- Player removing handler
Players.PlayerRemoving:Connect(function(player)
	playerSwordData[player.UserId] = nil
end)

-- Initialize existing players
for _, player in pairs(Players:GetPlayers()) do
	if player.Character then
		task.spawn(function()
			initializePlayer(player)
		end)
	end
end

print("Multi-Sword System Server Loaded!")
