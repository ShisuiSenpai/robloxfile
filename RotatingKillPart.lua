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
local MIN_ORBIT_SPEED = 20 -- Starting orbit speed (degrees per second)
local MAX_ORBIT_SPEED = 120 -- Maximum orbit speed (degrees per second)
local SPEED_INCREASE_RATE = 5 -- How fast the speed increases per second
local ORBIT_RADIUS = 15 -- How far from center the part orbits (studs)
local PART_SPIN_SPEED = 180 -- How fast the part spins on itself (degrees per second)
local RESPAWN_TIME = 3 -- Time before player respawns (in seconds)

-- Current orbit speed (starts at minimum)
local currentOrbitSpeed = MIN_ORBIT_SPEED

-- Store the original position and orientation
local originalCFrame = part.CFrame
local centerPosition = originalCFrame.Position -- The center point to orbit around
local currentOrbitAngle = 0 -- Track orbit angle around center
local currentSpinAngle = 0 -- Track the part's own rotation

print("RotatingKillPart: Center position stored:", centerPosition)
print("RotatingKillPart: Orbit radius:", ORBIT_RADIUS, "studs")

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

-- Optional: Create a visual indicator for the orbit path (a ring on the ground)
local function createOrbitIndicator()
	local indicator = Instance.new("Part")
	indicator.Name = "OrbitPath"
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Material = Enum.Material.ForceField
	indicator.Size = Vector3.new(0.5, ORBIT_RADIUS * 2, ORBIT_RADIUS * 2) -- Thin cylinder with diameter = orbit diameter
	indicator.Position = centerPosition - Vector3.new(0, part.Size.Y/2, 0) -- Place on ground
	indicator.Orientation = Vector3.new(0, 0, 90) -- Rotate to be flat on ground
	indicator.Anchored = true
	indicator.CanCollide = false
	indicator.CanTouch = false
	indicator.CanQuery = false
	indicator.Transparency = 0.8
	indicator.BrickColor = BrickColor.new("Cyan")
	indicator.Parent = workspace
	
	-- Add a glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 0.5
	pointLight.Color = Color3.new(0, 1, 1) -- Cyan glow
	pointLight.Range = ORBIT_RADIUS * 1.5
	pointLight.Parent = indicator
	
	return indicator
end

-- Create the orbit path indicator
local orbitIndicator = createOrbitIndicator()
print("RotatingKillPart: Orbit path indicator created")

-- METHOD 1: Orbiting Kill Part (Like a sweeping obstacle)
-- The part orbits around a center point while also spinning on itself

print("RotatingKillPart: Starting orbit and rotation loop...")

local connection
connection = RunService.Heartbeat:Connect(function(deltaTime)
	-- Safety check
	if not part or not part.Parent then
		warn("RotatingKillPart: Part no longer exists, disconnecting...")
		connection:Disconnect()
		return
	end
	
	-- Increase orbit speed over time (up to maximum)
	if currentOrbitSpeed < MAX_ORBIT_SPEED then
		currentOrbitSpeed = math.min(currentOrbitSpeed + (SPEED_INCREASE_RATE * deltaTime), MAX_ORBIT_SPEED)
		
		-- Change color based on speed (green to red)
		local speedRatio = (currentOrbitSpeed - MIN_ORBIT_SPEED) / (MAX_ORBIT_SPEED - MIN_ORBIT_SPEED)
		part.Color = Color3.new(speedRatio, 1 - speedRatio, 0) -- Gradual color change from green to red
	end
	
	-- Update the orbit angle (how far around the circle we've gone)
	currentOrbitAngle = currentOrbitAngle + math.rad(currentOrbitSpeed * deltaTime)
	
	-- Update the part's own spin angle
	currentSpinAngle = currentSpinAngle + math.rad(PART_SPIN_SPEED * deltaTime)
	
	-- Keep angles in reasonable range to prevent overflow
	if currentOrbitAngle > math.pi * 2 then
		currentOrbitAngle = currentOrbitAngle - math.pi * 2
	end
	if currentSpinAngle > math.pi * 2 then
		currentSpinAngle = currentSpinAngle - math.pi * 2
	end
	
	-- Calculate the new position in the orbit
	local orbitX = centerPosition.X + math.cos(currentOrbitAngle) * ORBIT_RADIUS
	local orbitZ = centerPosition.Z + math.sin(currentOrbitAngle) * ORBIT_RADIUS
	local orbitPosition = Vector3.new(orbitX, centerPosition.Y, orbitZ)
	
	-- Apply both orbit position and part rotation
	-- The part orbits around the center AND spins on its own axis
	part.CFrame = CFrame.new(orbitPosition) * CFrame.Angles(currentSpinAngle, 0, 0)
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
		
		-- RESET THE ORBIT SPEED BACK TO MINIMUM (smooth reset)
		currentOrbitSpeed = MIN_ORBIT_SPEED
		part.BrickColor = BrickColor.new("Lime green") -- Visual feedback for reset
		
		-- Flash effect to show speed reset
		task.spawn(function()
			task.wait(0.2)
			part.BrickColor = BrickColor.new("Really red")
		end)
		
		-- Optional: Add death effect
		local player = game.Players:GetPlayerFromCharacter(character)
		if player then
			print(player.Name .. " was killed by the orbiting cylinder! Orbit speed reset to minimum.")
			print("Current orbit speed: " .. currentOrbitSpeed .. " degrees/second")
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