-- NPCAnimateSetupComplete Script
-- Place in: ServerScriptService
-- This ensures the Animate script in NPCs has everything it needs

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for configuration
local NPCFollowModules = ReplicatedStorage:WaitForChild("NPCFollowModules")
local Config = require(NPCFollowModules:WaitForChild("NPCFollowConfig"))

local function setupAnimateScript(npcModel)
	local animateScript = npcModel:FindFirstChild("Animate")
	if not animateScript then
		warn("[AnimateSetup] No Animate script found in", npcModel.Name)
		return
	end
	
	-- Check if the script needs the msg StringValue (for emotes)
	if not animateScript:FindFirstChild("msg") then
		local msgValue = Instance.new("StringValue")
		msgValue.Name = "msg"
		msgValue.Value = ""
		msgValue.Parent = animateScript
		print("[AnimateSetup] Added msg StringValue to", npcModel.Name)
	end
	
	-- Ensure the NPC has an Animator
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	if humanoid and not humanoid:FindFirstChild("Animator") then
		local animator = Instance.new("Animator")
		animator.Parent = humanoid
		print("[AnimateSetup] Added Animator to", npcModel.Name)
	end
	
	-- Add animation configuration folders if you want custom animations
	-- This is optional - the script will use default animations if these don't exist
	local animNames = {"idle", "walk", "run", "jump", "fall", "climb", "sit"}
	for _, animName in ipairs(animNames) do
		if not animateScript:FindFirstChild(animName) then
			-- Create a folder for custom animations (optional)
			-- The Animate script will check these first before using defaults
			-- local folder = Instance.new("Configuration")
			-- folder.Name = animName
			-- folder.Parent = animateScript
		end
	end
	
	print("[AnimateSetup] Animate script setup complete for", npcModel.Name)
end

-- Wait for NPCs to load
wait(1)

local npcFolder = workspace:WaitForChild(Config.NPC_FOLDER_NAME, 10)
if npcFolder then
	-- Setup existing NPCs
	for _, npcModel in pairs(npcFolder:GetChildren()) do
		if npcModel:IsA("Model") then
			setupAnimateScript(npcModel)
		end
	end
	
	-- Setup new NPCs
	npcFolder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			wait(0.1)
			setupAnimateScript(child)
		end
	end)
	
	print("[AnimateSetup] Complete setup initialized")
end