-- NPCAnimateHelper Script
-- Place in: ServerScriptService > NPCAnimateHelper
-- This helps you use the default Animate LocalScript with NPCs

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Wait for configuration
local NPCFollowModules = ReplicatedStorage:WaitForChild("NPCFollowModules")
local Config = require(NPCFollowModules:WaitForChild("NPCFollowConfig"))

print([[
[NPCAnimateHelper] Instructions for using Roblox's default Animate script with NPCs:

METHOD 1: Copy from a Player Character
1. Join the game as a player
2. In Explorer, find your character in Workspace
3. Copy the "Animate" LocalScript from your character
4. Convert it to a regular Script (right-click > Convert to Script)
5. Place it in your NPC model

METHOD 2: Use the Template
1. Create a Script (not LocalScript) named "Animate" in your NPC
2. Copy the animation code from a player's Animate script
3. Replace any LocalPlayer references with script.Parent

METHOD 3: Use Pre-made Animate Script
1. Use the NPCAnimateSetup script that automatically adds animations
]])

-- Alternative: Get Animate script from a player when they join
local animateScriptTemplate = nil

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		wait(0.5) -- Wait for Animate script to load
		
		local animateScript = character:FindFirstChild("Animate")
		if animateScript and animateScript:IsA("LocalScript") and not animateScriptTemplate then
			-- Clone the script for use as a template
			animateScriptTemplate = animateScript:Clone()
			print("[NPCAnimateHelper] Captured Animate script template from", player.Name)
			
			-- Convert to server script
			local serverScript = Instance.new("Script")
			serverScript.Name = "Animate"
			
			-- Store in ServerStorage for later use
			local folder = ServerStorage:FindFirstChild("NPCTemplates") or Instance.new("Folder")
			folder.Name = "NPCTemplates"
			folder.Parent = ServerStorage
			
			serverScript.Parent = folder
			print("[NPCAnimateHelper] Animate template saved to ServerStorage > NPCTemplates")
		end
	end)
end

-- Helper function to add Animate script to NPC
local function addAnimateToNPC(npcModel)
	if not npcModel:FindFirstChild("Animate") then
		if animateScriptTemplate then
			local animateClone = animateScriptTemplate:Clone()
			animateClone.Parent = npcModel
			print("[NPCAnimateHelper] Added Animate script to", npcModel.Name)
		else
			warn("[NPCAnimateHelper] No Animate template available yet. Wait for a player to join.")
		end
	end
end

-- Connect player added event
Players.PlayerAdded:Connect(onPlayerAdded)

-- Export helper function
_G.AddAnimateToNPC = addAnimateToNPC

print("[NPCAnimateHelper] Helper loaded. Use _G.AddAnimateToNPC(npcModel) to add animations.")