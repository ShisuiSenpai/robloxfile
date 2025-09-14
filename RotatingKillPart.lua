-- Rotating Kill Part Script
-- Place this script inside the cylinder part in ServerScriptService or as a child of the part

local part = script.Parent -- The cylinder part this script is attached to
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Configuration
local MIN_ROTATION_SPEED = 10 -- Starting rotation speed (degrees per second)
local MAX_ROTATION_SPEED = 200 -- Maximum rotation speed (degrees per second)
local SPEED_INCREASE_RATE = 5 -- How fast the speed increases per second
local RESPAWN_TIME = 3 -- Time before player respawns (in seconds)

-- Current rotation speed (starts at minimum)
local currentRotationSpeed = MIN_ROTATION_SPEED

-- Set up the part properties
part.Material = Enum.Material.Neon -- Makes it look dangerous
part.BrickColor = BrickColor.new("Lime green") -- Starts green (safe/slow)
part.TopSurface = Enum.SurfaceType.Smooth
part.BottomSurface = Enum.SurfaceType.Smooth
part.CanCollide = true
part.Anchored = true -- Keep it in place while rotating

-- Create a selection box for visual effect (optional)
local selectionBox = Instance.new("SelectionBox")
selectionBox.Parent = part
selectionBox.Adornee = part
selectionBox.Color3 = Color3.new(1, 0, 0) -- Red outline
selectionBox.LineThickness = 0.1
selectionBox.Transparency = 0.5

-- Rotation using RunService for smooth rotation with speed increase
local connection
connection = RunService.Heartbeat:Connect(function(deltaTime)
	-- Increase speed over time (up to maximum)
	if currentRotationSpeed < MAX_ROTATION_SPEED then
		currentRotationSpeed = math.min(currentRotationSpeed + (SPEED_INCREASE_RATE * deltaTime), MAX_ROTATION_SPEED)
		
		-- Optional: Change color based on speed (green to red)
		local speedRatio = (currentRotationSpeed - MIN_ROTATION_SPEED) / (MAX_ROTATION_SPEED - MIN_ROTATION_SPEED)
		part.Color = Color3.new(speedRatio, 1 - speedRatio, 0) -- Gradual color change from green to red
	end
	
	-- Rotate the part on Z axis for horizontal spinning (like a rolling log)
	part.CFrame = part.CFrame * CFrame.Angles(0, 0, math.rad(currentRotationSpeed * deltaTime))
end)

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
		CFrame = part.CFrame * CFrame.Angles(0, 0, math.rad(360)) -- Z-axis rotation for horizontal spin
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
		
		-- RESET THE SPEED BACK TO MINIMUM
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