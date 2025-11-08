--[[
	CRATE SYSTEM - SERVER SCRIPT
	Place this Script in ServerScriptService
	
	Handles crate opening logic and gives swords to players
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get the crate part and prompt
local crateTemple = workspace:WaitForChild("CrateTemple")
local openCratePart = crateTemple:WaitForChild("OpenCratePart")
local proximityPrompt = openCratePart:WaitForChild("OpenSwordBox")

-- Get or create RemoteEvents
local crateRemotes = ReplicatedStorage:FindFirstChild("CrateRemotes")
if not crateRemotes then
	crateRemotes = Instance.new("Folder")
	crateRemotes.Name = "CrateRemotes"
	crateRemotes.Parent = ReplicatedStorage
end

local openCrateEvent = crateRemotes:FindFirstChild("OpenCrate")
if not openCrateEvent then
	openCrateEvent = Instance.new("RemoteEvent")
	openCrateEvent.Name = "OpenCrate"
	openCrateEvent.Parent = crateRemotes
end

local switchSwordEvent = crateRemotes:FindFirstChild("SwitchSword")
if not switchSwordEvent then
	switchSwordEvent = Instance.new("RemoteEvent")
	switchSwordEvent.Name = "SwitchSword"
	switchSwordEvent.Parent = crateRemotes
end

-- Load sword config from Modules folder
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local SwordConfig = require(modulesFolder:WaitForChild("SwordConfig"))

-- Table of all available swords
local availableSwords = {}
for swordName, _ in pairs(SwordConfig.Swords) do
	table.insert(availableSwords, swordName)
end

-- ========================================
-- CRATE OPENING LOGIC
-- ========================================

-- Function to choose a random sword
local function chooseRandomSword()
	local randomIndex = math.random(1, #availableSwords)
	return availableSwords[randomIndex]
end

-- Function to switch player's sword (integrates with MultiSwordSystem)
local function switchPlayerSword(player, swordName)
	-- Verify the sword exists
	local swordConfig = SwordConfig.Swords[swordName]
	if not swordConfig then
		warn("Sword config not found: " .. swordName)
		return false
	end

	-- Tell the client's MultiSwordSystem to switch to this sword
	switchSwordEvent:FireClient(player, swordName)

	return true
end

-- ========================================
-- EVENT HANDLERS
-- ========================================

-- When player interacts with chest
proximityPrompt.Triggered:Connect(function(player)
	-- Choose a random sword
	local chosenSword = chooseRandomSword()

	-- Send to client to show animation
	openCrateEvent:FireClient(player, chosenSword, availableSwords)

	print(player.Name .. " is opening a crate! Chosen sword: " .. chosenSword)
end)

-- Listen for when client wants to switch to the sword they won
switchSwordEvent.OnServerEvent:Connect(function(player, swordName)
	-- Verify the sword name is valid
	if not SwordConfig.Swords[swordName] then
		warn("Invalid sword switch attempt: " .. tostring(swordName))
		return
	end

	-- Tell the client's MultiSwordSystem to switch to this sword
	switchSwordEvent:FireClient(player, swordName)

	print("Switched " .. player.Name .. " to " .. swordName)
end)

print("Crate System Server loaded!")
