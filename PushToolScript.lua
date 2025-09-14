-- Push Tool Script (LocalScript)
-- Place this as a LocalScript inside the Push tool in StarterPack

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local tool = script.Parent
local player = Players.LocalPlayer

-- Configuration
local PUSH_RANGE = 8 -- How far in front the push reaches (studs)
local PUSH_ANGLE = 45 -- Field of view for push (degrees)
local PUSH_FORCE = 50 -- How strong the push is
local RAGDOLL_DURATION = 1.5 -- How long they stay ragdolled (seconds)
local COOLDOWN_TIME = 1 -- Cooldown between pushes (seconds)

-- Variables
local canPush = true
local mouse = nil

-- Create RemoteEvent for server communication
local pushRemote = ReplicatedStorage:FindFirstChild("PushRemote")
if not pushRemote then
	-- Only create if we're in Studio or if it doesn't exist
	if RunService:IsStudio() then
		pushRemote = Instance.new("RemoteEvent")
		pushRemote.Name = "PushRemote"
		pushRemote.Parent = ReplicatedStorage
	else
		-- Wait for server to create it
		pushRemote = ReplicatedStorage:WaitForChild("PushRemote", 5)
	end
end

-- Function to check if a player is in front of us
local function isPlayerInFront(targetCharacter)
	if not targetCharacter then return false end
	
	local humanoidRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
	local myRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	
	if not humanoidRootPart or not myRootPart then return false end
	
	-- Calculate distance
	local distance = (humanoidRootPart.Position - myRootPart.Position).Magnitude
	if distance > PUSH_RANGE then return false end
	
	-- Calculate angle to check if player is in front
	local direction = (humanoidRootPart.Position - myRootPart.Position).Unit
	local lookDirection = myRootPart.CFrame.LookVector
	
	local dotProduct = direction:Dot(lookDirection)
	local angle = math.deg(math.acos(dotProduct))
	
	-- Check if within field of view
	if angle <= PUSH_ANGLE then
		return true, distance, direction
	end
	
	return false
end

-- Function to find the closest player in front
local function getClosestPlayerInFront()
	local closestPlayer = nil
	local closestDistance = PUSH_RANGE
	local pushDirection = nil
	
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local inFront, distance, direction = isPlayerInFront(otherPlayer.Character)
			if inFront and distance < closestDistance then
				closestPlayer = otherPlayer
				closestDistance = distance
				pushDirection = direction
			end
		end
	end
	
	return closestPlayer, pushDirection
end

-- Visual feedback for push
local function createPushEffect(targetPosition)
	if not player.Character then return end
	
	local myRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not myRootPart then return end
	
	-- Create a visual effect (optional)
	local part = Instance.new("Part")
	part.Name = "PushEffect"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(0.5, 0.5, closestDistance or PUSH_RANGE)
	part.Material = Enum.Material.ForceField
	part.BrickColor = BrickColor.new("Cyan")
	part.Transparency = 0.5
	part.CFrame = CFrame.lookAt(myRootPart.Position, targetPosition) * CFrame.new(0, 0, -part.Size.Z/2)
	part.Parent = workspace
	
	-- Fade out effect
	local startTime = tick()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		if elapsed > 0.3 then
			connection:Disconnect()
			part:Destroy()
		else
			part.Transparency = 0.5 + (elapsed / 0.3) * 0.5
		end
	end)
end

-- Tool activation
local function onActivated()
	if not canPush then return end
	if not player.Character then return end
	
	-- Find closest player in front
	local targetPlayer, pushDirection = getClosestPlayerInFront()
	
	if targetPlayer and pushRemote then
		canPush = false
		
		-- Visual feedback
		if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
			createPushEffect(targetPlayer.Character.HumanoidRootPart.Position)
		end
		
		-- Send push request to server
		pushRemote:FireServer(targetPlayer, pushDirection, PUSH_FORCE)
		
		-- Cooldown
		task.wait(COOLDOWN_TIME)
		canPush = true
	else
		-- Optional: Feedback when no target found
		print("No player in range to push!")
	end
end

-- Tool equipped
local function onEquipped(newMouse)
	mouse = newMouse
	
	-- Optional: Show range indicator
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- You can add visual indicators here
		end
	end
end

-- Tool unequipped
local function onUnequipped()
	mouse = nil
end

-- Connect events
tool.Activated:Connect(onActivated)
tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)

print("Push Tool LocalScript loaded!")