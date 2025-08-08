-- NPCAnimateSetup Script
-- Place in: ServerScriptService > NPCAnimateSetup
-- This script adds the default Roblox Animate script to NPCs

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for configuration
local NPCFollowModules = ReplicatedStorage:WaitForChild("NPCFollowModules")
local Config = require(NPCFollowModules:WaitForChild("NPCFollowConfig"))

-- Function to check if an NPC already has an Animate script
local function hasAnimateScript(npcModel)
	return npcModel:FindFirstChild("Animate") ~= nil
end

-- Function to create a server-side Animate script for NPCs
local function createNPCAnimateScript(npcModel)
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("NPC has no humanoid:", npcModel.Name)
		return
	end
	
	-- Create the Animate script
	local animateScript = Instance.new("Script")
	animateScript.Name = "Animate"
	animateScript.Parent = npcModel
	
	-- The actual animation code (simplified version of Roblox's default)
	local animateSource = [[
local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")
local pose = "Standing"

local currentAnim = ""
local currentAnimInstance = nil
local currentAnimTrack = nil
local currentAnimSpeed = 1.0

-- Animation IDs
local animNames = {
	idle = {
		{ id = "http://www.roblox.com/asset/?id=507766666", weight = 1 },
		{ id = "http://www.roblox.com/asset/?id=507766951", weight = 1 },
		{ id = "http://www.roblox.com/asset/?id=507766388", weight = 9 }
	},
	walk = {
		{ id = "http://www.roblox.com/asset/?id=507777826", weight = 10 }
	},
	run = {
		{ id = "http://www.roblox.com/asset/?id=507767714", weight = 10 }
	},
	jump = {
		{ id = "http://www.roblox.com/asset/?id=507765000", weight = 10 }
	},
	fall = {
		{ id = "http://www.roblox.com/asset/?id=507767968", weight = 10 }
	},
	climb = {
		{ id = "http://www.roblox.com/asset/?id=507765644", weight = 10 }
	},
	sit = {
		{ id = "http://www.roblox.com/asset/?id=2506281703", weight = 10 }
	}
}

-- Create animation instances
local animTable = {}
for name, fileList in pairs(animNames) do
	animTable[name] = {}
	animTable[name].count = 0
	animTable[name].totalWeight = 0
	
	for idx, anim in pairs(fileList) do
		animTable[name][idx] = {}
		animTable[name][idx].anim = Instance.new("Animation")
		animTable[name][idx].anim.Name = name
		animTable[name][idx].anim.AnimationId = anim.id
		animTable[name][idx].weight = anim.weight
		animTable[name].count = animTable[name].count + 1
		animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
	end
end

-- Utility functions
function stopAllAnimations()
	local oldAnim = currentAnim
	currentAnim = ""
	currentAnimInstance = nil
	if (currentAnimTrack ~= nil) then
		currentAnimTrack:Stop()
		currentAnimTrack:Destroy()
		currentAnimTrack = nil
	end
	return oldAnim
end

function setAnimationSpeed(speed)
	if speed ~= currentAnimSpeed then
		currentAnimSpeed = speed
		if currentAnimTrack then
			currentAnimTrack:AdjustSpeed(currentAnimSpeed)
		end
	end
end

function playAnimation(animName, transitionTime)
	local roll = math.random(1, animTable[animName].totalWeight) 
	local origRoll = roll
	local idx = 1
	while (roll > animTable[animName][idx].weight) do
		roll = roll - animTable[animName][idx].weight
		idx = idx + 1
	end
	
	local anim = animTable[animName][idx].anim
	
	-- Switch animation
	if (anim ~= currentAnimInstance) then
		if (currentAnimTrack ~= nil) then
			currentAnimTrack:Stop(transitionTime)
			currentAnimTrack:Destroy()
		end
		
		currentAnimSpeed = 1.0
		
		-- Load it to the humanoid
		local animator = Humanoid:FindFirstChild("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = Humanoid
		end
		
		currentAnimTrack = animator:LoadAnimation(anim)
		currentAnimTrack.Priority = Enum.AnimationPriority.Core
		
		-- Play the animation
		currentAnimTrack:Play(transitionTime)
		currentAnim = animName
		currentAnimInstance = anim
	end
end

-- Animation state handlers
function onRunning(speed)
	if speed > 0.75 then
		local scale = 16.0
		if speed > 17 then
			playAnimation("run", 0.2)
		else
			playAnimation("walk", 0.2)
		end
		setAnimationSpeed(speed / scale)
		pose = "Running"
	else
		playAnimation("idle", 0.2)
		pose = "Standing"
	end
end

function onDied()
	pose = "Dead"
	stopAllAnimations()
end

function onJumping()
	playAnimation("jump", 0.1)
	pose = "Jumping"
end

function onClimbing(speed)
	local scale = 5.0
	playAnimation("climb", 0.1)
	setAnimationSpeed(speed / scale)
	pose = "Climbing"
end

function onGettingUp()
	pose = "GettingUp"
end

function onFreeFall()
	playAnimation("fall", 0.2)
	pose = "FreeFall"
end

function onFallingDown()
	pose = "FallingDown"
end

function onSeated()
	pose = "Seated"
	playAnimation("sit", 0.5)
end

function onPlatformStanding()
	pose = "PlatformStanding"
end

-- Connect events
Humanoid.Died:Connect(onDied)
Humanoid.Running:Connect(onRunning)
Humanoid.Jumping:Connect(onJumping)
Humanoid.Climbing:Connect(onClimbing)
Humanoid.GettingUp:Connect(onGettingUp)
Humanoid.FreeFalling:Connect(onFreeFall)
Humanoid.FallingDown:Connect(onFallingDown)
Humanoid.Seated:Connect(onSeated)
Humanoid.PlatformStanding:Connect(onPlatformStanding)

-- Initialize
if Character.Parent ~= nil then
	playAnimation("idle", 0.1)
	pose = "Standing"
end
]]
	
	animateScript.Source = animateSource
	
	print("[NPCAnimateSetup] Added Animate script to", npcModel.Name)
end

-- Function to setup animations for an NPC
local function setupNPCAnimations(npcModel)
	if not npcModel:IsA("Model") then return end
	
	-- Check if it already has an Animate script
	if hasAnimateScript(npcModel) then
		print("[NPCAnimateSetup] NPC already has Animate script:", npcModel.Name)
		return
	end
	
	-- Add the Animate script
	createNPCAnimateScript(npcModel)
end

-- Setup existing NPCs
local npcFolder = workspace:WaitForChild(Config.NPC_FOLDER_NAME, 10)
if npcFolder then
	for _, npcModel in pairs(npcFolder:GetChildren()) do
		setupNPCAnimations(npcModel)
	end
	
	-- Setup new NPCs as they're added
	npcFolder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			wait(0.1) -- Small delay to ensure NPC is fully loaded
			setupNPCAnimations(child)
		end
	end)
end

print("[NPCAnimateSetup] System initialized!")