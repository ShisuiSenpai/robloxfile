-- NPCFollowServer Script
-- Place in: ServerScriptService > NPCFollowServer

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

-- Wait for configuration
local NPCFollowModules = ReplicatedStorage:WaitForChild("NPCFollowModules")
local Config = require(NPCFollowModules:WaitForChild("NPCFollowConfig"))

-- Debug print function
local function debugPrint(...)
	if Config.DEBUG_MODE then
		print("[NPCFollow]", ...)
	end
end

-- NPC Controller Class
local NPCController = {}
NPCController.__index = NPCController

function NPCController.new(npcModel)
	local self = setmetatable({}, NPCController)

	self.Model = npcModel
	self.Humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	self.RootPart = npcModel:FindFirstChild("HumanoidRootPart") or npcModel:FindFirstChild("Torso")

	if not self.Humanoid or not self.RootPart then
		warn("[NPCFollow] NPC missing Humanoid or RootPart:", npcModel.Name)
		return nil
	end

	-- IMPORTANT: Prevent NPC from being deleted
	self.Model.Parent = workspace:FindFirstChild(Config.NPC_FOLDER_NAME) or workspace
	
	-- State
	self.State = "Idle" -- Idle, Following, Returning, Attacking, ComboAttack
	self.Target = nil
	self.StartPosition = self.RootPart.Position
	self.StartOrientation = self.RootPart.Orientation
	self.FollowStartTime = 0
	self.LastSeenPosition = nil
	self.LastSeenTime = 0

	-- Pathfinding
	self.Path = nil
	self.Waypoints = {}
	self.CurrentWaypointIndex = 1
	self.WaypointParts = {} -- For debug visualization

	-- Movement
	self.LastPathUpdate = 0
	self.LastDetectionCheck = 0

	-- Visual elements
	self.DetectionSphere = nil
	self.ExclamationMark = nil
	self.OriginalColors = {}

	-- Combat system
	self.CurrentComboHit = 0
	self.LastAttackTime = 0
	self.ComboStartTime = 0
	self.IsAttacking = false
	self.AttackCooldownEndTime = 0
	self.AttackIndicator = nil
	self.StunnedPlayers = {} -- Track stunned players

	-- Movement smoothing
	self.LastAvoidanceVector = Vector3.new(0, 0, 0)
	self.VelocitySmoother = Vector3.new(0, 0, 0)
	self.LastMoveToPosition = self.RootPart.Position

	-- Store original colors for tinting
	for _, part in pairs(npcModel:GetDescendants()) do
		if part:IsA("BasePart") and part.Parent ~= npcModel then
			self.OriginalColors[part] = part.Color
		end
	end

	-- Setup
	self:SetupHumanoid()
	self:SetupVisuals()
	self:SetupCombatVisuals()

	debugPrint("NPC Controller created for:", npcModel.Name)

	return self
end

function NPCController:SetupHumanoid()
	-- IMPORTANT: Set Humanoid properties to prevent despawning
	self.Humanoid.WalkSpeed = Config.WALK_SPEED
	self.Humanoid.JumpPower = Config.JUMP_POWER
	self.Humanoid.JumpHeight = Config.JUMP_HEIGHT
	
	-- Prevent NPC from dying and despawning
	self.Humanoid.MaxHealth = math.huge
	self.Humanoid.Health = math.huge
	
	-- Disable BreakJointsOnDeath to prevent model destruction
	self.Humanoid.BreakJointsOnDeath = false
	
	-- Set humanoid state to prevent automatic removal
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	
	-- Connect to health changed to prevent death
	self.Humanoid.HealthChanged:Connect(function(health)
		if health <= 0 then
			self.Humanoid.Health = self.Humanoid.MaxHealth
		end
	end)
end

function NPCController:SetupVisuals()
	-- Create detection sphere for debugging
	if Config.SHOW_DETECTION_SPHERE then
		local sphere = Instance.new("Part")
		sphere.Name = "DetectionSphere"
		sphere.Shape = Enum.PartType.Ball
		sphere.Material = Enum.Material.ForceField
		sphere.Size = Vector3.new(Config.DETECTION_RADIUS * 2, Config.DETECTION_RADIUS * 2, Config.DETECTION_RADIUS * 2)
		sphere.Color = Color3.new(0, 1, 0)
		sphere.Transparency = 0.8
		sphere.CanCollide = false
		sphere.Anchored = true
		sphere.Parent = self.Model
		self.DetectionSphere = sphere
	end

	-- Create exclamation mark (hidden by default)
	if Config.SHOW_EXCLAMATION_ON_DETECT then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "ExclamationMark"
		billboard.Size = UDim2.new(0, 50, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = true

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.Text = "!"
		text.TextScaled = true
		text.TextColor3 = Color3.new(1, 1, 0)
		text.Font = Enum.Font.SourceSansBold
		text.Parent = billboard

		billboard.Parent = self.RootPart
		billboard.Enabled = false
		self.ExclamationMark = billboard
	end
end

function NPCController:SetupCombatVisuals()
	-- Create attack indicator
	if Config.SHOW_ATTACK_INDICATOR then
		local indicator = Instance.new("Part")
		indicator.Name = "AttackIndicator"
		indicator.Shape = Enum.PartType.Ball
		indicator.Material = Enum.Material.Neon
		indicator.Size = Vector3.new(Config.ATTACK_RANGE * 2, 0.5, Config.ATTACK_RANGE * 2)
		indicator.Color = Config.ATTACK_INDICATOR_COLOR
		indicator.Transparency = 1
		indicator.CanCollide = false
		indicator.Anchored = true
		indicator.Parent = self.Model
		self.AttackIndicator = indicator
	end
end

function NPCController:ShowExclamation()
	if self.ExclamationMark then
		self.ExclamationMark.Enabled = true
		task.wait(Config.EXCLAMATION_DURATION)
		if self.ExclamationMark then
			self.ExclamationMark.Enabled = false
		end
	end
end

function NPCController:PlayDetectionSound()
	if Config.PLAY_DETECTION_SOUND and Config.DETECTION_SOUND_ID ~= "" then
		local sound = Instance.new("Sound")
		sound.SoundId = Config.DETECTION_SOUND_ID
		sound.Volume = 0.5
		sound.Parent = self.RootPart
		sound:Play()
		Debris:AddItem(sound, 2)
	end
end

function NPCController:TintModel(enabled)
	if not Config.TINT_COLOR_WHEN_FOLLOWING then return end

	for part, originalColor in pairs(self.OriginalColors) do
		if part and part.Parent then
			if enabled then
				part.Color = originalColor:Lerp(Config.TINT_COLOR_WHEN_FOLLOWING, 0.3)
			else
				part.Color = originalColor
			end
		end
	end
end

function NPCController:CanSeeTarget(target)
	if not Config.OBSTACLE_DETECTION then return true end

	local rayOrigin = self.RootPart.Position + Vector3.new(0, 2, 0)
	local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return false end

	local rayDirection = (targetRoot.Position - rayOrigin).Unit * Config.DETECTION_RADIUS

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {self.Model, target.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	return result == nil
end

function NPCController:IsInFieldOfView(target)
	local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return false end

	local npcLookDirection = self.RootPart.CFrame.LookVector
	local toTarget = (targetRoot.Position - self.RootPart.Position).Unit

	local angle = math.deg(math.acos(npcLookDirection:Dot(toTarget)))

	return angle <= Config.FIELD_OF_VIEW / 2
end

function NPCController:FindNearestPlayer()
	local nearestPlayer = nil
	local nearestDistance = math.huge

	for _, player in pairs(Players:GetPlayers()) do
		-- Check blacklist/whitelist
		if #Config.BLACKLIST_PLAYERS > 0 and table.find(Config.BLACKLIST_PLAYERS, player.Name) then
			continue
		end
		if #Config.WHITELIST_PLAYERS > 0 and not table.find(Config.WHITELIST_PLAYERS, player.Name) then
			continue
		end

		local character = player.Character
		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoidRootPart and humanoid and humanoid.Health > 0 then
				local distance = (humanoidRootPart.Position - self.RootPart.Position).Magnitude

				-- Check if within detection radius
				if distance <= Config.DETECTION_RADIUS and distance < nearestDistance then
					-- Check field of view
					if self:IsInFieldOfView(player) then
						-- Check line of sight
						if self:CanSeeTarget(player) then
							nearestDistance = distance
							nearestPlayer = player
						end
					end
				end
			end
		end
	end

	return nearestPlayer, nearestDistance
end

function NPCController:CreatePath(targetPosition)
	if not Config.USE_PATHFINDING then
		-- Simple direct movement
		return {targetPosition}
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = Config.CAN_CLIMB,
		AgentJumpHeight = Config.JUMP_HEIGHT,
		AgentMaxSlope = Config.SLOPE_LIMIT,
		WaypointSpacing = 4,
		Costs = Config.PATHFINDING_COSTS
	})

	local success, errorMessage = pcall(function()
		path:ComputeAsync(self.RootPart.Position, targetPosition)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		self.Path = path
		self.Waypoints = path:GetWaypoints()
		self.CurrentWaypointIndex = 1

		-- Visualize waypoints for debugging
		if Config.SHOW_PATHFINDING_WAYPOINTS then
			self:VisualizeWaypoints()
		end

		return self.Waypoints
	else
		debugPrint("Pathfinding failed:", errorMessage)
		return nil
	end
end

function NPCController:VisualizeWaypoints()
	-- Clear old waypoint parts
	for _, part in pairs(self.WaypointParts) do
		part:Destroy()
	end
	self.WaypointParts = {}

	-- Create new waypoint parts
	for i, waypoint in pairs(self.Waypoints) do
		local part = Instance.new("Part")
		part.Name = "Waypoint" .. i
		part.Size = Vector3.new(1, 1, 1)
		part.Material = Enum.Material.Neon
		part.Color = Color3.new(0, 1, 0)
		part.Anchored = true
		part.CanCollide = false
		part.Position = waypoint.Position
		part.Parent = workspace

		table.insert(self.WaypointParts, part)
		Debris:AddItem(part, 5)
	end
end

function NPCController:GetNearbyNPCs()
	local nearbyNPCs = {}
	local npcFolder = workspace:FindFirstChild(Config.NPC_FOLDER_NAME)
	if not npcFolder then return nearbyNPCs end

	for _, npcModel in pairs(npcFolder:GetChildren()) do
		if npcModel:IsA("Model") and npcModel ~= self.Model then
			local otherRoot = npcModel:FindFirstChild("HumanoidRootPart") or npcModel:FindFirstChild("Torso")
			if otherRoot then
				local distance = (otherRoot.Position - self.RootPart.Position).Magnitude
				if distance < Config.NPC_SPACING_RADIUS * 2 then
					table.insert(nearbyNPCs, {
						model = npcModel,
						rootPart = otherRoot,
						distance = distance
					})
				end
			end
		end
	end

	return nearbyNPCs
end

function NPCController:CalculateAvoidanceVector()
	local avoidanceVector = Vector3.new(0, 0, 0)
	local nearbyNPCs = self:GetNearbyNPCs()

	for _, npcData in pairs(nearbyNPCs) do
		if npcData.distance < Config.NPC_SPACING_RADIUS then
			-- Calculate repulsion vector
			local direction = (self.RootPart.Position - npcData.rootPart.Position)
			if direction.Magnitude > 0 then
				direction = direction.Unit
				local strength = 1 - (npcData.distance / Config.NPC_SPACING_RADIUS)
				strength = strength * strength -- Square for smoother falloff
				avoidanceVector = avoidanceVector + direction * strength * Config.AVOIDANCE_FORCE
			end
		end
	end

	-- Smooth the avoidance vector to prevent jittering
	self.LastAvoidanceVector = self.LastAvoidanceVector:Lerp(avoidanceVector, Config.AVOIDANCE_SMOOTHING)

	-- Only apply Y component if it's significant (prevents floating)
	return Vector3.new(self.LastAvoidanceVector.X, 0, self.LastAvoidanceVector.Z)
end

function NPCController:GetFormationPosition(targetPosition, followerIndex, totalFollowers)
	if Config.FORMATION_TYPE == "circle" then
		local angle = (followerIndex / totalFollowers) * math.pi * 2
		local offset = Vector3.new(
			math.cos(angle) * Config.FORMATION_SPREAD,
			0,
			math.sin(angle) * Config.FORMATION_SPREAD
		)
		return targetPosition + offset

	elseif Config.FORMATION_TYPE == "semicircle" then
		local angle = (followerIndex / (totalFollowers + 1)) * math.pi
		local offset = Vector3.new(
			math.cos(angle) * Config.FORMATION_SPREAD,
			0,
			math.sin(angle) * Config.FORMATION_SPREAD
		)
		return targetPosition + offset

	else -- random
		local angle = math.random() * math.pi * 2
		local distance = Config.STOP_DISTANCE + math.random() * (Config.FORMATION_SPREAD - Config.STOP_DISTANCE)
		local offset = Vector3.new(
			math.cos(angle) * distance,
			0,
			math.sin(angle) * distance
		)
		return targetPosition + offset
	end
end

-- Combat System Functions
function NPCController:CanAttack()
	local currentTime = tick()
	return currentTime >= self.AttackCooldownEndTime and not self.IsAttacking
end

function NPCController:StartCombo()
	if not self:CanAttack() then return end
	
	self.State = "ComboAttack"
	self.IsAttacking = true
	self.CurrentComboHit = 1
	self.ComboStartTime = tick()
	
	debugPrint(self.Model.Name, "starting combo attack")
	
	-- Start the combo sequence
	self:ExecuteComboHit()
end

function NPCController:ExecuteComboHit()
	if not self.Target or not self.Target.Character then
		self:EndCombo()
		return
	end
	
	local targetRoot = self.Target.Character:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = self.Target.Character:FindFirstChildOfClass("Humanoid")
	
	if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
		self:EndCombo()
		return
	end
	
	-- Check if still in range
	local distance = (targetRoot.Position - self.RootPart.Position).Magnitude
	if distance > Config.ATTACK_RANGE * 1.5 then -- Give a bit of leeway
		self:EndCombo()
		return
	end
	
	-- Telegraph the attack
	if Config.SHOW_ATTACK_INDICATOR and self.AttackIndicator then
		self.AttackIndicator.Position = self.RootPart.Position - Vector3.new(0, 2.5, 0)
		self.AttackIndicator.Transparency = 0.5
		
		-- Flash indicator
		local tween = TweenService:Create(
			self.AttackIndicator,
			TweenInfo.new(Config.ATTACK_TELEGRAPH_TIME, Enum.EasingStyle.Linear),
			{Transparency = 0.8}
		)
		tween:Play()
	end
	
	-- Wait for telegraph
	task.wait(Config.ATTACK_TELEGRAPH_TIME)
	
	-- Execute the hit
	if self.Target and self.Target.Character then
		targetRoot = self.Target.Character:FindFirstChild("HumanoidRootPart")
		targetHumanoid = self.Target.Character:FindFirstChildOfClass("Humanoid")
		
		if targetRoot and targetHumanoid then
			distance = (targetRoot.Position - self.RootPart.Position).Magnitude
			
			if distance <= Config.ATTACK_RANGE then
				-- Deal damage
				targetHumanoid:TakeDamage(Config.DAMAGE_PER_HIT)
				
				-- Apply knockback
				local knockbackDirection = (targetRoot.Position - self.RootPart.Position).Unit
				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
				bodyVelocity.Velocity = knockbackDirection * Config.KNOCKBACK_FORCE
				bodyVelocity.Parent = targetRoot
				Debris:AddItem(bodyVelocity, 0.1)
				
				-- Stun the player
				self:StunPlayer(self.Target)
				
				-- Create hit effect
				self:CreateHitEffect(targetRoot.Position)
				
				debugPrint("Hit", self.CurrentComboHit, "dealt to", self.Target.Name)
			end
		end
	end
	
	-- Hide attack indicator
	if self.AttackIndicator then
		self.AttackIndicator.Transparency = 1
	end
	
	-- Check if combo continues
	if self.CurrentComboHit < Config.COMBO_HIT_COUNT then
		self.CurrentComboHit = self.CurrentComboHit + 1
		task.wait(Config.HIT_INTERVAL)
		self:ExecuteComboHit()
	else
		self:EndCombo()
	end
end

function NPCController:EndCombo()
	self.IsAttacking = false
	self.CurrentComboHit = 0
	self.AttackCooldownEndTime = tick() + Config.COMBO_COOLDOWN
	self.State = "Following"
	
	-- Hide attack indicator
	if self.AttackIndicator then
		self.AttackIndicator.Transparency = 1
	end
	
	debugPrint(self.Model.Name, "combo ended")
end

function NPCController:StunPlayer(player)
	if not player.Character then return end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Store original walkspeed if not already stunned
	if not self.StunnedPlayers[player] then
		self.StunnedPlayers[player] = {
			originalWalkSpeed = humanoid.WalkSpeed,
			originalJumpPower = humanoid.JumpPower
		}
	end
	
	-- Apply stun
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	
	-- Remove stun after duration
	task.wait(Config.PLAYER_STUN_DURATION)
	
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		local data = self.StunnedPlayers[player]
		if data then
			humanoid.WalkSpeed = data.originalWalkSpeed
			humanoid.JumpPower = data.originalJumpPower
			self.StunnedPlayers[player] = nil
		end
	end
end

function NPCController:CreateHitEffect(position)
	-- Create a simple visual effect when hit lands
	local effect = Instance.new("Part")
	effect.Name = "HitEffect"
	effect.Shape = Enum.PartType.Ball
	effect.Material = Enum.Material.Neon
	effect.Size = Vector3.new(1, 1, 1)
	effect.Color = Color3.new(1, 0.5, 0) -- Orange
	effect.Anchored = true
	effect.CanCollide = false
	effect.Position = position + Vector3.new(math.random(-1, 1), math.random(0, 2), math.random(-1, 1))
	effect.Parent = workspace

	-- Create expanding sphere effect
	local tween = TweenService:Create(
		effect,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Transparency = 1,
			Size = Vector3.new(3, 3, 3),
			Position = effect.Position + Vector3.new(0, 1, 0)
		}
	)
	tween:Play()

	-- Add sound effect
	local hitSound = Instance.new("Sound")
	hitSound.SoundId = "rbxasset://sounds/impact_water_low.mp3"
	hitSound.Volume = 0.5
	hitSound.Parent = effect
	hitSound:Play()

	-- Clean up
	Debris:AddItem(effect, 0.5)
end

function NPCController:MoveToTarget()
	if not self.Target or not self.Target.Character then
		self:StopFollowing()
		return
	end

	local targetRoot = self.Target.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		self:StopFollowing()
		return
	end

	local distance = (targetRoot.Position - self.RootPart.Position).Magnitude

	-- Check if in attack range and should attack
	if Config.ENABLE_COMBAT_SYSTEM and distance <= Config.ATTACK_RANGE and self:CanAttack() then
		-- Stop moving and start combo
		self.Humanoid:MoveTo(self.RootPart.Position)
		self:StartCombo()
		return
	end

	-- Update speed based on distance and state
	if self.State == "ComboAttack" then
		self.Humanoid.WalkSpeed = Config.COMBAT_MOVEMENT_SPEED
	elseif distance > Config.RUN_DISTANCE_THRESHOLD then
		self.Humanoid.WalkSpeed = Config.RUN_SPEED
	else
		self.Humanoid.WalkSpeed = Config.WALK_SPEED
	end

	-- Calculate target position with formation and avoidance
	local targetPosition = targetRoot.Position

	-- Get follower index for formation
	local followerIndex = 1
	local totalFollowers = 1
	if NPCFollowSystem then
		local followers = NPCFollowSystem:GetFollowersForPlayer(self.Target)
		for i, controller in ipairs(followers) do
			if controller == self then
				followerIndex = i
			end
		end
		totalFollowers = #followers
	end

	-- Apply formation positioning
	if totalFollowers > 1 and Config.USE_FLOCKING then
		targetPosition = self:GetFormationPosition(targetRoot.Position, followerIndex, totalFollowers)
	end

	-- Stop if close enough (but not if we're trying to attack)
	if distance <= Config.STOP_DISTANCE and not Config.ENABLE_COMBAT_SYSTEM then
		-- Apply avoidance even when stopped
		local avoidance = self:CalculateAvoidanceVector()
		if avoidance.Magnitude > 0.5 then
			local avoidPos = self.RootPart.Position + avoidance * 0.1
			self.Humanoid:MoveTo(avoidPos)
		else
			-- Fully stop to prevent wobbling
			self.Humanoid:MoveTo(self.RootPart.Position)
		end
		return
	end

	-- Update path if needed
	local currentTime = tick()
	if currentTime - self.LastPathUpdate > Config.PATH_UPDATE_INTERVAL then
		self.LastPathUpdate = currentTime
		self:CreatePath(targetPosition)
	end

	-- Move along path with avoidance
	local moveToPosition = targetPosition

	if self.Waypoints and #self.Waypoints > 0 then
		local currentWaypoint = self.Waypoints[self.CurrentWaypointIndex]
		if currentWaypoint then
			moveToPosition = currentWaypoint.Position

			-- Check if reached waypoint
			local waypointDistance = (currentWaypoint.Position - self.RootPart.Position).Magnitude
			if waypointDistance < 5 then
				self.CurrentWaypointIndex = self.CurrentWaypointIndex + 1
				if self.CurrentWaypointIndex > #self.Waypoints then
					self.CurrentWaypointIndex = #self.Waypoints
				end
			end

			-- Jump if necessary
			if currentWaypoint.Action == Enum.PathWaypointAction.Jump then
				self.Humanoid.Jump = true
			end
		end
	end

	-- Apply avoidance with smoothing
	local avoidance = self:CalculateAvoidanceVector()
	local adjustedPosition = moveToPosition + avoidance * 0.05 -- Reduced influence

	-- Smooth the movement to prevent stuttering
	local smoothedPosition = self.LastMoveToPosition:Lerp(adjustedPosition, 0.5)
	self.LastMoveToPosition = smoothedPosition

	-- Move to smoothed position
	self.Humanoid:MoveTo(smoothedPosition)

	-- Update last seen position
	self.LastSeenPosition = targetRoot.Position
	self.LastSeenTime = currentTime
end

function NPCController:ReturnToStart()
	local distance = (self.StartPosition - self.RootPart.Position).Magnitude

	if distance < 2 then
		-- Reached start position
		self.Humanoid:MoveTo(self.RootPart.Position)
		self.State = "Idle"

		-- Reset orientation
		self.RootPart.CFrame = CFrame.lookAt(self.RootPart.Position, 
			self.RootPart.Position + CFrame.Angles(0, math.rad(self.StartOrientation.Y), 0).LookVector)

		debugPrint(self.Model.Name, "returned to start position")
		return
	end

	self.Humanoid.WalkSpeed = Config.RETURN_SPEED

	-- Update path occasionally
	local currentTime = tick()
	if currentTime - self.LastPathUpdate > 1 then
		self.LastPathUpdate = currentTime
		self:CreatePath(self.StartPosition)
	end

	-- Move along path or directly
	if self.Waypoints and #self.Waypoints > 0 then
		local currentWaypoint = self.Waypoints[self.CurrentWaypointIndex]
		if currentWaypoint then
			self.Humanoid:MoveTo(currentWaypoint.Position)

			local waypointDistance = (currentWaypoint.Position - self.RootPart.Position).Magnitude
			if waypointDistance < 5 then
				self.CurrentWaypointIndex = self.CurrentWaypointIndex + 1
				if self.CurrentWaypointIndex > #self.Waypoints then
					self.CurrentWaypointIndex = #self.Waypoints
				end
			end
		end
	else
		self.Humanoid:MoveTo(self.StartPosition)
	end
end

function NPCController:StartFollowing(player)
	if self.State == "Following" and self.Target == player then
		return
	end

	self.State = "Following"
	self.Target = player
	self.FollowStartTime = tick()

	-- Visual feedback
	self:TintModel(true)
	task.spawn(function()
		self:ShowExclamation()
	end)
	self:PlayDetectionSound()

	debugPrint(self.Model.Name, "started following", player.Name)
end

function NPCController:StopFollowing()
	if self.State ~= "Following" and self.State ~= "ComboAttack" then return end

	-- End any ongoing combo
	if self.State == "ComboAttack" then
		self:EndCombo()
	end

	self.State = Config.IDLE_RETURN_TO_START and "Returning" or "Idle"
	self.Target = nil

	-- Clear stunned players
	for player, data in pairs(self.StunnedPlayers) do
		if player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = data.originalWalkSpeed
				humanoid.JumpPower = data.originalJumpPower
			end
		end
	end
	self.StunnedPlayers = {}

	-- Reset visuals
	self:TintModel(false)

	-- Clear waypoint visualization
	for _, part in pairs(self.WaypointParts) do
		part:Destroy()
	end
	self.WaypointParts = {}

	debugPrint(self.Model.Name, "stopped following")
end

function NPCController:Update()
	-- IMPORTANT: Check if model still exists
	if not self.Model.Parent then
		debugPrint("NPC model was removed, skipping update")
		return
	end

	local currentTime = tick()

	-- Update detection sphere position
	if self.DetectionSphere then
		self.DetectionSphere.Position = self.RootPart.Position
	end

	-- Update attack indicator position if visible
	if self.AttackIndicator and self.AttackIndicator.Transparency < 1 then
		self.AttackIndicator.Position = self.RootPart.Position - Vector3.new(0, 2.5, 0)
	end

	-- State machine
	if self.State == "Idle" then
		-- Check for nearby players
		if currentTime - self.LastDetectionCheck > Config.DETECTION_CHECK_INTERVAL then
			self.LastDetectionCheck = currentTime

			local nearestPlayer, distance = self:FindNearestPlayer()
			if nearestPlayer then
				self:StartFollowing(nearestPlayer)
			end
		end

	elseif self.State == "Following" then
		-- Check if should stop following
		if not self.Target or not self.Target.Character then
			self:StopFollowing()
			return
		end

		local targetRoot = self.Target.Character:FindFirstChild("HumanoidRootPart")
		if not targetRoot then
			self:StopFollowing()
			return
		end

		local distance = (targetRoot.Position - self.RootPart.Position).Magnitude
		local distanceFromOrigin = (self.RootPart.Position - self.StartPosition).Magnitude

		-- Check if too far from origin
		if Config.MAX_FOLLOW_DISTANCE > 0 and distanceFromOrigin > Config.MAX_FOLLOW_DISTANCE then
			debugPrint(self.Model.Name, "too far from origin:", distanceFromOrigin)
			self:StopFollowing()
			return
		end

		-- Check if target is too far
		if distance > Config.LOSE_INTEREST_RADIUS then
			-- Check memory time
			if currentTime - self.LastSeenTime > Config.MEMORY_TIME then
				self:StopFollowing()
				return
			else
				-- Move to last seen position
				if self.LastSeenPosition then
					self.Humanoid:MoveTo(self.LastSeenPosition)
				end
				return
			end
		end

		-- Check max follow time
		if Config.MAX_FOLLOW_TIME > 0 and currentTime - self.FollowStartTime > Config.MAX_FOLLOW_TIME then
			self:StopFollowing()
			return
		end

		-- Continue following
		self:MoveToTarget()

	elseif self.State == "ComboAttack" then
		-- Combat is handled by the combo execution

	elseif self.State == "Returning" then
		self:ReturnToStart()
	end
end

function NPCController:Destroy()
	-- Clean up
	if self.DetectionSphere then
		self.DetectionSphere:Destroy()
	end
	if self.ExclamationMark then
		self.ExclamationMark:Destroy()
	end
	if self.AttackIndicator then
		self.AttackIndicator:Destroy()
	end
	for _, part in pairs(self.WaypointParts) do
		part:Destroy()
	end
	self:TintModel(false)

	-- Clear stunned players
	for player, data in pairs(self.StunnedPlayers) do
		if player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = data.originalWalkSpeed
				humanoid.JumpPower = data.originalJumpPower
			end
		end
	end
end

-- Main System
local NPCFollowSystem = {}
NPCFollowSystem.Controllers = {}
NPCFollowSystem.ActiveCount = 0

function NPCFollowSystem:GetFollowersForPlayer(player)
	local followers = {}
	for _, controller in pairs(self.Controllers) do
		if controller.State == "Following" and controller.Target == player then
			table.insert(followers, controller)
		end
	end
	return followers
end

function NPCFollowSystem:Initialize()
	debugPrint("Initializing NPC Follow System...")

	-- Find or create NPC folder
	local npcFolder = workspace:FindFirstChild(Config.NPC_FOLDER_NAME)
	if not npcFolder then
		-- Create the folder if it doesn't exist
		npcFolder = Instance.new("Folder")
		npcFolder.Name = Config.NPC_FOLDER_NAME
		npcFolder.Parent = workspace
		warn("[NPCFollow] Created NPC folder:", Config.NPC_FOLDER_NAME)
	end

	-- Setup existing NPCs
	for _, npcModel in pairs(npcFolder:GetChildren()) do
		if npcModel:IsA("Model") then
			self:SetupNPC(npcModel)
		end
	end

	-- Listen for new NPCs
	npcFolder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.wait(0.1) -- Small delay to ensure model is fully loaded
			self:SetupNPC(child)
		end
	end)

	-- Listen for removed NPCs
	npcFolder.ChildRemoved:Connect(function(child)
		local controller = self.Controllers[child]
		if controller then
			controller:Destroy()
			self.Controllers[child] = nil
			if controller.State == "Following" then
				self.ActiveCount = self.ActiveCount - 1
			end
		end
	end)

	-- Start update loop
	self:StartUpdateLoop()

	debugPrint("NPC Follow System initialized with", #self.Controllers, "NPCs")
end

function NPCFollowSystem:SetupNPC(npcModel)
	-- Check if already setup
	if self.Controllers[npcModel] then return end

	-- Ensure NPC stays in the folder
	if npcModel.Parent ~= workspace:FindFirstChild(Config.NPC_FOLDER_NAME) then
		npcModel.Parent = workspace:FindFirstChild(Config.NPC_FOLDER_NAME)
	end

	-- Create controller
	local controller = NPCController.new(npcModel)
	if controller then
		self.Controllers[npcModel] = controller
		debugPrint("Setup NPC:", npcModel.Name)
	end
end

function NPCFollowSystem:StartUpdateLoop()
	RunService.Heartbeat:Connect(function()
		-- Check active NPC limit
		local activeCount = 0
		for _, controller in pairs(self.Controllers) do
			if controller.State == "Following" or controller.State == "ComboAttack" then
				activeCount = activeCount + 1
			end
		end
		self.ActiveCount = activeCount

		-- Update all NPCs
		for npcModel, controller in pairs(self.Controllers) do
			-- Ensure NPC is still valid
			if npcModel.Parent then
				-- Skip if at active limit and this NPC is idle
				if controller.State == "Idle" and self.ActiveCount >= Config.MAX_ACTIVE_NPCS then
					continue
				end

				controller:Update()
			else
				-- Remove invalid controller
				self.Controllers[npcModel] = nil
			end
		end
	end)

	-- Periodic cleanup
	task.spawn(function()
		while true do
			task.wait(Config.CLEANUP_INTERVAL)
			self:Cleanup()
		end
	end)
end

function NPCFollowSystem:Cleanup()
	-- Remove destroyed controllers
	for npcModel, controller in pairs(self.Controllers) do
		if not npcModel.Parent then
			controller:Destroy()
			self.Controllers[npcModel] = nil
		end
	end
end

-- Initialize system
NPCFollowSystem:Initialize()

-- Set global reference for formation calculations
_G.NPCFollowSystem = NPCFollowSystem

print("[NPCFollow] Server system with combat loaded successfully!")