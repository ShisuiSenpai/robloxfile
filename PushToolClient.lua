-- Push Tool LocalScript (Improved)
-- Place this as a LocalScript inside the Push tool in StarterPack

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tool = script.Parent
local player = Players.LocalPlayer

-- Verify this is actually a tool
if not tool:IsA("Tool") then
	warn("[PUSH CLIENT] Script parent is not a Tool! Parent is:", tool.ClassName)
	return
end

-- Configuration
local PUSH_RANGE = 10 -- How far in front the push reaches (studs)
local PUSH_FORCE = 65 -- Push force strength
local COOLDOWN_TIME = 1.5 -- Cooldown between pushes in seconds

-- Debug mode
local DEBUG = false -- Set to true to see debug messages

-- Cooldown tracking
local lastPushTime = 0

-- Wait for character
local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

-- Debug print function
local function debugPrint(...)
	if DEBUG then
		print("[PUSH CLIENT]", ...)
	end
end

debugPrint("Push tool LocalScript starting...")

-- Create or wait for RemoteEvent
local pushRemote = ReplicatedStorage:FindFirstChild("PushRemote")
if not pushRemote then
	debugPrint("RemoteEvent not found, waiting for server to create it...")
	pushRemote = ReplicatedStorage:WaitForChild("PushRemote", 10)
	if not pushRemote then
		warn("[PUSH CLIENT] RemoteEvent not created after 10 seconds!")
		return
	end
end

debugPrint("RemoteEvent found successfully")

-- Visual push effect
local function createPushEffect(targetPosition, distance)
	local character = getCharacter()
	if not character then return end

	local myRootPart = character:FindFirstChild("HumanoidRootPart")
	if not myRootPart then return end

	-- Create a visual wave effect
	local part = Instance.new("Part")
	part.Name = "PushEffect"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(0.5, 0.5, math.min(distance or PUSH_RANGE, 8))
	part.Material = Enum.Material.ForceField
	part.Color = Color3.fromRGB(0, 170, 255)
	part.Transparency = 0.3
	part.CFrame = CFrame.lookAt(myRootPart.Position, targetPosition) * CFrame.new(0, 0, -part.Size.Z/2)
	part.Parent = workspace

	-- Fade out
	game:GetService("TweenService"):Create(part, TweenInfo.new(0.4), {Transparency = 1}):Play()
	game:GetService("Debris"):AddItem(part, 0.4)
end

-- Find target in front of player
local function getTargetInFront()
	local character = getCharacter()
	if not character then return nil, nil end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return nil, nil end

	local closestPlayer = nil
	local closestDistance = PUSH_RANGE

	local lookDirection = humanoidRootPart.CFrame.LookVector
	local myPosition = humanoidRootPart.Position

	-- Check all players
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
			local otherHumanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")

			if otherRoot and otherHumanoid and otherHumanoid.Health > 0 then
				local distance = (otherRoot.Position - myPosition).Magnitude
				local toTarget = (otherRoot.Position - myPosition).Unit
				local dotProduct = toTarget:Dot(lookDirection)

				-- Check if in range and roughly in front
				if distance <= PUSH_RANGE and dotProduct > 0.4 and distance < closestDistance then
					closestPlayer = otherPlayer
					closestDistance = distance
				end
			end
		end
	end

	return closestPlayer, closestDistance
end

-- Tool activation
local function onActivated()
	-- Check cooldown
	local currentTime = tick()
	if currentTime - lastPushTime < COOLDOWN_TIME then
		local timeLeft = COOLDOWN_TIME - (currentTime - lastPushTime)
		print("Push on cooldown! Wait", math.ceil(timeLeft), "more seconds")
		return
	end

	local character = getCharacter()
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Find target
	local targetPlayer, targetDistance = getTargetInFront()

	if targetPlayer then
		local targetRoot = targetPlayer.Character.HumanoidRootPart
		local pushDirection = (targetRoot.Position - humanoidRootPart.Position).Unit

		-- Create visual effect
		createPushEffect(targetRoot.Position, targetDistance)

		-- Send to server
		pushRemote:FireServer(targetPlayer, pushDirection, PUSH_FORCE)

		-- Set cooldown
		lastPushTime = currentTime

		print("Pushed", targetPlayer.Name, "!")
	else
		print("No player in range to push!")
	end
end

-- Connect events
tool.Activated:Connect(onActivated)

-- Mouse support
local mouse = nil
tool.Equipped:Connect(function(newMouse)
	mouse = newMouse
	if mouse then
		mouse.Button1Down:Connect(function()
			onActivated()
		end)
	end
end)

debugPrint("Push tool LocalScript loaded successfully!")
