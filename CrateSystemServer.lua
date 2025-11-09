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

-- ========================================
-- PROXIMITY PROMPT STYLING
-- ========================================

-- Configure the ProximityPrompt to look modern and always visible
proximityPrompt.ObjectText = "Relic" -- Main label
proximityPrompt.ActionText = "Open" -- Action text
proximityPrompt.RequiresLineOfSight = false -- Always visible when in range (no obstruction check)
proximityPrompt.MaxActivationDistance = 10 -- Distance in studs (adjust as needed)
proximityPrompt.HoldDuration = 0 -- Instant activation (set to 0.5+ for hold duration)
proximityPrompt.Style = Enum.ProximityPromptStyle.Custom -- Use custom styling
proximityPrompt.Enabled = true
proximityPrompt.ClickablePrompt = false -- Disable click-to-activate (use key/button only)

-- Visual settings (modern look)
proximityPrompt.UIOffset = Vector2.new(0, 1) -- Offset above the part (adjust Y for height)

print("✅ ProximityPrompt configured: " .. proximityPrompt.ObjectText)

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

-- Function to choose a random sword based on rarity weights
local function chooseRandomSword()
	-- Build a weighted pool based on rarities
	local weightedPool = {}
	local totalWeight = 0
	
	for swordName, swordConfig in pairs(SwordConfig.Swords) do
		local rarity = swordConfig.Rarity or "Common"
		local rarityData = SwordConfig.Rarities[rarity]
		
		if rarityData then
			local weight = rarityData.Chance
			totalWeight = totalWeight + weight
			
			table.insert(weightedPool, {
				name = swordName,
				weight = weight,
				cumulativeWeight = totalWeight
			})
		end
	end
	
	-- Pick a random value between 0 and totalWeight
	local roll = math.random() * totalWeight
	
	-- Find which sword the roll landed on
	for _, entry in ipairs(weightedPool) do
		if roll <= entry.cumulativeWeight then
			return entry.name
		end
	end
	
	-- Fallback (should never happen)
	return availableSwords[1]
end

-- Function to switch player's sword (integrates with MultiSwordSystem)
local function switchPlayerSword(player, swordName)
	-- Verify the sword exists
	local swordConfig = SwordConfig.Swords[swordName]
	if not swordConfig then
		warn("Sword config not found: " .. swordName)
		return false
	end

	-- Tell the client to switch swords (client will request from server)
	-- The client's crate system listener will call switchSword() which uses the server
	switchSwordEvent:FireClient(player, swordName)

	return true
end

-- ========================================
-- EVENT HANDLERS
-- ========================================

-- Track players currently opening crates (prevent spam)
local playersOpening = {}

-- When player interacts with chest
proximityPrompt.Triggered:Connect(function(player)
	-- Check if player is already opening a crate
	if playersOpening[player.UserId] then
		warn(player.Name .. " tried to open crate while already opening one")
		return
	end
	
	-- Mark player as opening
	playersOpening[player.UserId] = true
	
	-- Choose a random sword
	local chosenSword = chooseRandomSword()

	-- Send to client to show animation
	openCrateEvent:FireClient(player, chosenSword, availableSwords)

	print(player.Name .. " is opening a crate! Chosen sword: " .. chosenSword)
	
	-- Clear opening flag after animation completes (6 seconds = safe estimate)
	task.delay(6, function()
		playersOpening[player.UserId] = nil
	end)
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

-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(player)
	playersOpening[player.UserId] = nil
end)

print("Crate System Server loaded!")
