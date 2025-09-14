-- Rotating Kill Part Script
-- Place this script inside the cylinder part in ServerScriptService or as a child of the part

local part = script.Parent -- The cylinder part this script is attached to

-- Debug: Check if part exists and is valid
if not part or not part:IsA("BasePart") then
	warn("RotatingKillPart: Script parent is not a valid part! Make sure this script is a child of the cylinder part.")
	return
end

print("RotatingKillPart: Initializing on part:", part.Name)

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Configuration
local MIN_ROTATION_SPEED = 10 -- Starting rotation speed (degrees per second)
local MAX_ROTATION_SPEED = 200 -- Maximum rotation speed (degrees per second)
local SPEED_INCREASE_RATE = 5 -- How fast the speed increases per second
local RESPAWN_TIME = 3 -- Time before player respawns (in seconds)

-- Current rotation speed (starts at minimum)
local currentRotationSpeed = MIN_ROTATION_SPEED

-- Store the original position and orientation
local originalCFrame = part.CFrame
local originalPosition = originalCFrame.Position
local currentAngle = 0 -- Track total rotation angle

print("RotatingKillPart: Original position stored:", originalPosition)

-- Set up the part properties
part.Material = Enum.Material.Neon -- Makes it look dangerous
part.BrickColor = BrickColor.new("Lime green") -- Starts green (safe/slow)
part.TopSurface = Enum.SurfaceType.Smooth
part.BottomSurface = Enum.SurfaceType.Smooth
part.CanCollide = true
part.Anchored = true -- Keep it in place while rotating

-- Network ownership can't be set on anchored parts, so we skip it
-- part:SetNetworkOwner(nil) -- This causes an error with anchored parts

-- Ensure part properties are set correctly
part.CanCollide = true -- Keep collisions for touch detection
part.CanTouch = true -- Keep touch events
part.CanQuery = true -- Keep this true for touch detection to work properly

-- Create a selection box for visual effect (optional)
local selectionBox = Instance.new("SelectionBox")
selectionBox.Parent = part
selectionBox.Adornee = part
selectionBox.Color3 = Color3.new(1, 0, 0) -- Red outline
selectionBox.LineThickness = 0.1
selectionBox.Transparency = 0.5

-- METHOD 1: Absolute Position Rotation (SMOOTHEST - Recommended)
-- This method calculates the exact rotation from the original position
-- preventing any drift or accumulation of floating point errors

print("RotatingKillPart: Starting rotation loop...")

local connection
connection = RunService.Heartbeat:Connect(function(deltaTime)
	-- Safety check
	if not part or not part.Parent then
		warn("RotatingKillPart: Part no longer exists, disconnecting...")
		connection:Disconnect()
		return
	end
	
	-- Increase speed over time (up to maximum)
	if currentRotationSpeed < MAX_ROTATION_SPEED then
		currentRotationSpeed = math.min(currentRotationSpeed + (SPEED_INCREASE_RATE * deltaTime), MAX_ROTATION_SPEED)
		
		-- Change color based on speed (green to red)
		local speedRatio = (currentRotationSpeed - MIN_ROTATION_SPEED) / (MAX_ROTATION_SPEED - MIN_ROTATION_SPEED)
		part.Color = Color3.new(speedRatio, 1 - speedRatio, 0) -- Gradual color change from green to red
	end
	
	-- Update the total angle
	currentAngle = currentAngle + math.rad(currentRotationSpeed * deltaTime)
	
	-- Keep angle in reasonable range to prevent overflow
	if currentAngle > math.pi * 2 then
		currentAngle = currentAngle - math.pi * 2
	end
	
	-- Set the CFrame using absolute positioning from original position
	-- Rotate on X-axis for horizontal spinning (like a rolling log)
	-- This ensures the part NEVER drifts from its original position
	part.CFrame = CFrame.new(originalPosition) * CFrame.Angles(currentAngle, 0, 0)
end)

print("RotatingKillPart: Rotation started successfully!")

-- METHOD 2: Alternative using Stepped for physics synchronization (uncomment to use)
--[[
local connection
connection = RunService.Stepped:Connect(function(time, deltaTime)
	-- Increase speed over time
	if currentRotationSpeed < MAX_ROTATION_SPEED then
		currentRotationSpeed = math.min(currentRotationSpeed + (SPEED_INCREASE_RATE * deltaTime), MAX_ROTATION_SPEED)
		
		local speedRatio = (currentRotationSpeed - MIN_ROTATION_SPEED) / (MAX_ROTATION_SPEED - MIN_ROTATION_SPEED)
		part.Color = Color3.new(speedRatio, 1 - speedRatio, 0)
	end
	
	-- Update angle
	currentAngle = currentAngle + math.rad(currentRotationSpeed * deltaTime)
	
	-- Apply rotation with fixed position (X-axis for horizontal spin)
	part.CFrame = CFrame.new(originalPosition) * CFrame.Angles(currentAngle, 0, 0)
end)
--]]

-- METHOD 3: Using BodyPosition + BodyAngularVelocity for physics-based rotation (uncomment to use)
--[[
-- Create BodyPosition to lock position
local bodyPosition = Instance.new("BodyPosition")
bodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
bodyPosition.Position = originalPosition
bodyPosition.Parent = part

-- Create BodyAngularVelocity for rotation
local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
bodyAngularVelocity.MaxTorque = Vector3.new(math.huge, 0, 0) -- X-axis torque for horizontal spin
bodyAngularVelocity.AngularVelocity = Vector3.new(math.rad(currentRotationSpeed), 0, 0) -- X-axis rotation
bodyAngularVelocity.Parent = part

-- Update only the angular velocity
local connection
connection = RunService.Heartbeat:Connect(function(deltaTime)
	if currentRotationSpeed < MAX_ROTATION_SPEED then
		currentRotationSpeed = math.min(currentRotationSpeed + (SPEED_INCREASE_RATE * deltaTime), MAX_ROTATION_SPEED)
		
		local speedRatio = (currentRotationSpeed - MIN_ROTATION_SPEED) / (MAX_ROTATION_SPEED - MIN_ROTATION_SPEED)
		part.Color = Color3.new(speedRatio, 1 - speedRatio, 0)
		
		-- Update angular velocity (X-axis)
		bodyAngularVelocity.AngularVelocity = Vector3.new(math.rad(currentRotationSpeed), 0, 0)
	end
end)
--]]

-- Alternative rotation method using TweenService (smoother but less flexible)
--[[
local function rotatePart()
	local tweenInfo = TweenInfo.new(
		2, -- Duration (2 seconds for full rotation)
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.InOut,
		-1, -- Repeat infinitely
		false -- Don't reverse
	)
	
	local goal = {
		CFrame = part.CFrame * CFrame.Angles(math.rad(360), 0, 0) -- X-axis rotation for horizontal spin
	}
	
	local tween = TweenService:Create(part, tweenInfo, goal)
	tween:Play()
end
rotatePart()
--]]

-- Kill function with speed reset
local function killPlayer(character)
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid and humanoid.Health > 0 then
		-- Set health to 0 to kill the player
		humanoid.Health = 0
		
		-- RESET THE SPEED BACK TO MINIMUM (smooth reset)
		currentRotationSpeed = MIN_ROTATION_SPEED
		part.BrickColor = BrickColor.new("Lime green") -- Visual feedback for reset
		
		-- Flash effect to show speed reset
		task.spawn(function()
			task.wait(0.2)
			part.BrickColor = BrickColor.new("Really red")
		end)
		
		-- Optional: Add death effect
		local player = game.Players:GetPlayerFromCharacter(character)
		if player then
			print(player.Name .. " was killed by the rotating cylinder! Speed reset to minimum.")
			print("Current speed: " .. currentRotationSpeed .. " degrees/second")
		end
	end
end

-- Debounce table to prevent multiple kills
local debounce = {}

-- Touch event
part.Touched:Connect(function(hit)
	-- Check if the touched object belongs to a player
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
	if humanoid then
		-- Check debounce to prevent multiple triggers
		if not debounce[character] then
			debounce[character] = true
			
			-- Kill the player
			killPlayer(character)
			
			-- Reset debounce after a short delay
			task.wait(1)
			debounce[character] = nil
		end
	end
end)

-- Optional: Add particle effects for visual enhancement
local function addParticleEffect()
	local attachment = Instance.new("Attachment")
	attachment.Parent = part
	
	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Parent = attachment
	particleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particleEmitter.Rate = 50
	particleEmitter.Lifetime = NumberRange.new(0.5, 1)
	particleEmitter.VelocityInheritance = 0.5
	particleEmitter.EmissionDirection = Enum.NormalId.Top
	particleEmitter.Speed = NumberRange.new(2, 5)
	particleEmitter.SpreadAngle = Vector2.new(45, 45)
	particleEmitter.Color = ColorSequence.new(Color3.new(1, 0, 0)) -- Red particles
	particleEmitter.LightEmission = 1
	particleEmitter.LightInfluence = 0
end

-- Add particle effect
addParticleEffect()

-- Clean up on script removal
script.AncestryChanged:Connect(function()
	if not script.Parent then
		if connection then
			connection:Disconnect()
		end
	end
end)

print("Rotating Kill Part initialized!")