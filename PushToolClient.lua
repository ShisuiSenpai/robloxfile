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
local PUSH_FORCE = 50 -- Increased push force for better distance
local COOLDOWN_TIME = 2 -- Cooldown between pushes in seconds

-- Debug mode
local DEBUG = true -- Set to false to hide debug messages

-- Cooldown tracking
local lastPushTime = 0
local canPush = true

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
debugPrint("Tool name:", tool.Name)
debugPrint("Tool parent:", tool.Parent and tool.Parent.Name or "nil")
debugPrint("Tool RequiresHandle:", tool.RequiresHandle)

-- Check if tool has a handle
local handle = tool:FindFirstChild("Handle")
if handle then
	debugPrint("Tool has a Handle part")
else
	debugPrint("Tool has NO Handle part")
	if tool.RequiresHandle then
		warn("[PUSH CLIENT] Tool requires handle but no Handle part found!")
	end
end

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

debugPrint("RemoteEvent found/created successfully")

-- IMPROVED: Better visual push effect
local function createPushEffect(targetPosition, distance)
	local character = getCharacter()
	if not character then return end

	local myRootPart = character:FindFirstChild("HumanoidRootPart")
	if not myRootPart then return end

	-- Create a visual effect that shows the push direction
	local part = Instance.new("Part")
	part.Name = "PushEffect"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(0.3, 0.3, math.min(distance or PUSH_RANGE, 8))
	part.Material = Enum.Material.ForceField
	part.BrickColor = BrickColor.new("Cyan")
	part.Transparency = 0.3
	part.CFrame = CFrame.lookAt(myRootPart.Position, targetPosition) * CFrame.new(0, 0, -part.Size.Z/2)
	part.Parent = workspace

	-- Fade out and remove
	game:GetService("Debris"):AddItem(part, 0.4)

	-- Smooth fade animation
	local startTime = tick()
	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		if elapsed < 0.4 and part.Parent then
			part.Transparency = 0.3 + (elapsed / 0.4) * 0.7
		else
			connection:Disconnect()
		end
	end)
end

-- IMPROVED: Better target detection
local function getTargetInFront()
	local character = getCharacter()
	if not character then 
		debugPrint("No character found")
		return nil, nil 
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then 
		debugPrint("No HumanoidRootPart found")
		return nil, nil 
	end

	local closestPlayer = nil
	local closestDistance = PUSH_RANGE

	-- Get look direction
	local lookDirection = humanoidRootPart.CFrame.LookVector
	local myPosition = humanoidRootPart.Position

	-- Check all players
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
			local otherHumanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")

			if otherRoot and otherHumanoid and otherHumanoid.Health > 0 then
				-- Calculate distance
				local distance = (otherRoot.Position - myPosition).Magnitude

				-- Calculate if in front using dot product
				local toTarget = (otherRoot.Position - myPosition).Unit
				local dotProduct = toTarget:Dot(lookDirection)

				debugPrint("Checking player:", otherPlayer.Name, "Distance:", string.format("%.2f", distance), "Dot:", string.format("%.2f", dotProduct))

				-- Check if in range and in front (dot product > 0.3 means roughly in front)
				if distance <= PUSH_RANGE and dotProduct > 0.3 and distance < closestDistance then
					closestPlayer = otherPlayer
					closestDistance = distance
					debugPrint("Found valid target:", otherPlayer.Name)
				end
			end
		end
	end

	return closestPlayer, closestDistance
end

-- IMPROVED: Tool activation with better feedback
local function onActivated()
	debugPrint("Tool activated!")

	-- Check cooldown
	local currentTime = tick()
	if currentTime - lastPushTime < COOLDOWN_TIME then
		local timeLeft = COOLDOWN_TIME - (currentTime - lastPushTime)
		debugPrint("On cooldown! Time left:", string.format("%.1f", timeLeft), "seconds")
		print("Push on cooldown! Wait", string.format("%.1f", timeLeft), "more seconds")
		return
	end

	local character = getCharacter()
	if not character then
		debugPrint("No character on activation")
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		debugPrint("No HumanoidRootPart on activation")
		return
	end

	-- Find target
	local targetPlayer, targetDistance = getTargetInFront()

	if targetPlayer then
		debugPrint("Pushing player:", targetPlayer.Name, "at distance:", string.format("%.2f", targetDistance))

		-- IMPROVED: Calculate push direction (from pusher to target)
		local targetRoot = targetPlayer.Character.HumanoidRootPart
		local pushDirection = (targetRoot.Position - humanoidRootPart.Position).Unit

		-- Create visual effect
		createPushEffect(targetRoot.Position, targetDistance)

		-- Send to server with direction and force
		pushRemote:FireServer(targetPlayer, pushDirection, PUSH_FORCE)

		-- Set cooldown
		lastPushTime = currentTime

		-- Visual feedback
		print("Pushed", targetPlayer.Name, "!")
		print("Cooldown active for", COOLDOWN_TIME, "seconds")
	else
		debugPrint("No valid target found in range")
		print("No player in range to push! (Range:", PUSH_RANGE, "studs)")
	end
end

-- Connect events
tool.Activated:Connect(onActivated)

-- Tool equipped/unequipped events
tool.Equipped:Connect(function()
	debugPrint("Tool equipped!")
end)

tool.Unequipped:Connect(function()
	debugPrint("Tool unequipped!")
end)

-- Alternative activation method (mouse click when equipped)
local mouse = nil
tool.Equipped:Connect(function(newMouse)
	mouse = newMouse
	debugPrint("Mouse connected")

	if mouse then
		mouse.Button1Down:Connect(function()
			debugPrint("Mouse clicked while tool equipped!")
			onActivated()
		end)
	end
end)

debugPrint("Push tool LocalScript loaded successfully!")
debugPrint("Waiting for tool activation...")
