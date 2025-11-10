--[[
	INVENTORY MANAGER - SERVER
	Place this Script in ServerScriptService
	
	⚠️ IMPORTANT: This script MUST load FIRST! 
	   Named "1_InventoryManager" to ensure it loads before other sword scripts.
	
	Handles:
	- Player sword ownership tracking
	- Adding swords to inventory when won from crates
	- Syncing inventory to client
	- Ensuring players always have Nightward as starter
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Load configuration
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local SwordConfig = require(modulesFolder:WaitForChild("SwordConfig"))

-- Create RemoteEvents for inventory system
local inventoryRemotes = ReplicatedStorage:FindFirstChild("InventoryRemotes")
if not inventoryRemotes then
	inventoryRemotes = Instance.new("Folder")
	inventoryRemotes.Name = "InventoryRemotes"
	inventoryRemotes.Parent = ReplicatedStorage
end

local getInventoryRemote = inventoryRemotes:FindFirstChild("GetInventory")
if not getInventoryRemote then
	getInventoryRemote = Instance.new("RemoteFunction")
	getInventoryRemote.Name = "GetInventory"
	getInventoryRemote.Parent = inventoryRemotes
end

local inventoryUpdatedRemote = inventoryRemotes:FindFirstChild("InventoryUpdated")
if not inventoryUpdatedRemote then
	inventoryUpdatedRemote = Instance.new("RemoteEvent")
	inventoryUpdatedRemote.Name = "InventoryUpdated"
	inventoryUpdatedRemote.Parent = inventoryRemotes
end

-- Create BindableEvent for server-to-server communication (when sword is added)
local swordAddedBindable = ReplicatedStorage:FindFirstChild("SwordAddedBindable")
if not swordAddedBindable then
	swordAddedBindable = Instance.new("BindableEvent")
	swordAddedBindable.Name = "SwordAddedBindable"
	swordAddedBindable.Parent = ReplicatedStorage
end

-- ========================================
-- PLAYER INVENTORY DATA
-- ========================================

-- Structure: {[userId] = {swords = {swordName = count, ...}, equippedSword = "SwordName"}}
local playerInventories = {}

-- ========================================
-- INVENTORY FUNCTIONS
-- ========================================

-- Initialize player inventory (gives starter sword)
local function initializeInventory(player)
	local userId = player.UserId

	-- Create new inventory with starter sword (count = 1)
	playerInventories[userId] = {
		swords = {
			[SwordConfig.DefaultSword] = 1 -- Start with 1 Nightward
		},
		equippedSword = SwordConfig.DefaultSword
	}

	print("📦 [INVENTORY] Initialized inventory for " .. player.Name .. " with " .. SwordConfig.DefaultSword)

	-- Notify client of inventory
	inventoryUpdatedRemote:FireClient(player, playerInventories[userId].swords)
end

-- Add a sword to player's inventory
local function addSwordToInventory(player, swordName)
	local userId = player.UserId

	-- Validate sword exists
	if not SwordConfig.Swords[swordName] then
		warn("[INVENTORY] Attempted to add invalid sword: " .. swordName)
		return false
	end

	-- Ensure player has inventory
	if not playerInventories[userId] then
		initializeInventory(player)
	end

	-- Check if player already has this sword
	local isNewSword = false
	local currentCount = playerInventories[userId].swords[swordName]

	if currentCount and currentCount > 0 then
		-- Increment count (DUPLICATE)
		playerInventories[userId].swords[swordName] = currentCount + 1
		print("✅ [INVENTORY] Added DUPLICATE " .. swordName .. " to " .. player.Name .. "'s inventory (now x" .. playerInventories[userId].swords[swordName] .. ")")
		isNewSword = false
	else
		-- First time getting this sword (NEW)
		playerInventories[userId].swords[swordName] = 1
		isNewSword = true
		print("✅ [INVENTORY] Added NEW " .. swordName .. " to " .. player.Name .. "'s inventory (x1)")
	end

	-- Notify client of updated inventory
	inventoryUpdatedRemote:FireClient(player, playerInventories[userId].swords)

	-- Only create holster if it's a new sword (not a duplicate)
	if isNewSword then
		local swordAddedBindable = ReplicatedStorage:FindFirstChild("SwordAddedBindable")
		if swordAddedBindable then
			swordAddedBindable:Fire(player, swordName)
		end
	end

	return true
end

-- Check if player owns a sword
local function playerOwnsSword(player, swordName)
	local userId = player.UserId

	if not playerInventories[userId] then
		return false
	end

	-- Check if count is greater than 0
	return playerInventories[userId].swords[swordName] and playerInventories[userId].swords[swordName] > 0
end

-- Get player's full inventory
local function getPlayerInventory(player)
	local userId = player.UserId

	if not playerInventories[userId] then
		initializeInventory(player)
	end

	return playerInventories[userId].swords
end

-- ========================================
-- REMOTE FUNCTION HANDLERS
-- ========================================

-- Client requests inventory list
getInventoryRemote.OnServerInvoke = function(player)
	return getPlayerInventory(player)
end

-- ========================================
-- PLAYER MANAGEMENT
-- ========================================

-- Player added handler
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Wait for character to load
		character:WaitForChild("Humanoid")
		task.wait(0.5)

		-- Initialize inventory if first time
		if not playerInventories[player.UserId] then
			initializeInventory(player)
		else
			-- Player rejoined - send existing inventory
			inventoryUpdatedRemote:FireClient(player, playerInventories[player.UserId].swords)
		end
	end)
end)

-- Player removing handler
Players.PlayerRemoving:Connect(function(player)
	-- Keep inventory data for now (in production, save to DataStore here)
	-- playerInventories[player.UserId] = nil
end)

-- Initialize existing players
for _, player in pairs(Players:GetPlayers()) do
	if player.Character then
		task.spawn(function()
			initializeInventory(player)
		end)
	end
end

-- ========================================
-- PUBLIC API (for other scripts)
-- ========================================

-- Expose functions for other server scripts to use
local InventoryManager = {}

InventoryManager.AddSword = addSwordToInventory
InventoryManager.PlayerOwnsSword = playerOwnsSword
InventoryManager.GetInventory = getPlayerInventory

-- Make globally accessible
_G.InventoryManager = InventoryManager

print("✅ Inventory Manager Server loaded!")

return InventoryManager
