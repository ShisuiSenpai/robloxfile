-- NPCCombatServer Script
-- Place in: ServerScriptService

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvents for client communication
local remotes = ReplicatedStorage:FindFirstChild("NPCRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "NPCRemotes"
	remotes.Parent = ReplicatedStorage
end

local damageRemote = remotes:FindFirstChild("NPCDamage") or Instance.new("RemoteEvent")
damageRemote.Name = "NPCDamage"
damageRemote.Parent = remotes

local combatRemote = remotes:FindFirstChild("NPCCombat") or Instance.new("RemoteEvent")
combatRemote.Name = "NPCCombat"
combatRemote.Parent = remotes

-- Configuration
local CONFIG = {
	-- Detection
	DETECTION_RANGE = 50,
	ATTACK_RANGE = 6,
	LOSE_RANGE = 100,
	
	-- Movement
	WALK_SPEED = 16,
	RUN_SPEED = 22,
	
	-- Combat
	DAMAGE_PER_HIT = 10,
	HITS_IN_COMBO = 5,
	HIT_DELAY = 0.3,
	COMBO_COOLDOWN = 2,
	STUN_DURATION = 0.2,
	KNOCKBACK_POWER = 20,
	
	-- Performance
	UPDATE_RATE = 0.1,
}

-- NPC storage
local NPCs = {}

-- NPC Class
local NPC = {}
NPC.__index = NPC

function NPC.new(model)
	local self = setmetatable({}, NPC)
	
	self.Model = model
	self.Humanoid = model:FindFirstChildOfClass("Humanoid")
	self.Root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
	
	if not self.Humanoid or not self.Root then
		warn("NPC missing Humanoid or RootPart:", model.Name)
		return nil
	end
	
	-- Set up humanoid
	self.Humanoid.MaxHealth = 500
	self.Humanoid.Health = 500
	self.Humanoid.WalkSpeed = CONFIG.WALK_SPEED
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	
	-- State
	self.State = "Idle" -- Idle, Following, Attacking
	self.Target = nil
	self.LastAttack = 0
	self.ComboHit = 0
	self.AttackCooldown = 0
	
	-- Pathfinding
	self.Path = nil
	self.Waypoints = {}
	self.WaypointIndex = 1
	self.LastPathUpdate = 0
	
	print("NPC initialized:", model.Name)
	return self
end

function NPC:FindTarget()
	local closest = nil
	local closestDist = CONFIG.DETECTION_RANGE
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
			local root = player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local dist = (root.Position - self.Root.Position).Magnitude
				if dist < closestDist then
					closest = player
					closestDist = dist
				end
			end
		end
	end
	
	return closest, closestDist
end

function NPC:CreatePath(targetPos)
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		WaypointSpacing = 4,
	})
	
	local success, err = pcall(function()
		path:ComputeAsync(self.Root.Position, targetPos)
	end)
	
	if success and path.Status == Enum.PathStatus.Success then
		self.Path = path
		self.Waypoints = path:GetWaypoints()
		self.WaypointIndex = 1
		return true
	end
	
	return false
end

function NPC:MoveToTarget()
	if not self.Target or not self.Target.Character then
		self.State = "Idle"
		return
	end
	
	local targetRoot = self.Target.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		self.State = "Idle"
		return
	end
	
	local dist = (targetRoot.Position - self.Root.Position).Magnitude
	
	-- Update path
	if tick() - self.LastPathUpdate > 0.5 then
		self:CreatePath(targetRoot.Position)
		self.LastPathUpdate = tick()
	end
	
	-- Move along path
	if self.Waypoints and #self.Waypoints > 0 then
		local waypoint = self.Waypoints[self.WaypointIndex]
		if waypoint then
			self.Humanoid:MoveTo(waypoint.Position)
			
			local waypointDist = (waypoint.Position - self.Root.Position).Magnitude
			if waypointDist < 5 then
				self.WaypointIndex = math.min(self.WaypointIndex + 1, #self.Waypoints)
			end
			
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				self.Humanoid.Jump = true
			end
		end
	else
		-- Direct movement if no path
		self.Humanoid:MoveTo(targetRoot.Position)
	end
	
	-- Set speed based on distance
	self.Humanoid.WalkSpeed = dist > 20 and CONFIG.RUN_SPEED or CONFIG.WALK_SPEED
end

function NPC:Attack()
	if not self.Target or not self.Target.Character then return end
	
	local humanoid = self.Target.Character:FindFirstChild("Humanoid")
	local root = self.Target.Character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not root or humanoid.Health <= 0 then return end
	
	-- Face target
	self.Root.CFrame = CFrame.lookAt(self.Root.Position, Vector3.new(root.Position.X, self.Root.Position.Y, root.Position.Z))
	
	-- Deal damage
	humanoid:TakeDamage(CONFIG.DAMAGE_PER_HIT)
	
	-- Send damage info to client
	damageRemote:FireClient(self.Target, CONFIG.DAMAGE_PER_HIT, self.Root.Position)
	
	-- Knockback
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(4000, 0, 4000)
	bv.Velocity = (root.Position - self.Root.Position).Unit * CONFIG.KNOCKBACK_POWER
	bv.Parent = root
	Debris:AddItem(bv, 0.1)
	
	-- Stun
	local oldWalkSpeed = humanoid.WalkSpeed
	local oldJumpPower = humanoid.JumpPower
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	
	task.wait(CONFIG.STUN_DURATION)
	
	if humanoid and humanoid.Parent then
		humanoid.WalkSpeed = oldWalkSpeed
		humanoid.JumpPower = oldJumpPower
	end
end

function NPC:UpdateCombat()
	if not self.Target or not self.Target.Character then
		self.State = "Idle"
		return
	end
	
	local root = self.Target.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		self.State = "Idle"
		return
	end
	
	local dist = (root.Position - self.Root.Position).Magnitude
	
	-- Check if in attack range
	if dist <= CONFIG.ATTACK_RANGE and self.AttackCooldown <= 0 then
		self.State = "Attacking"
		self.Humanoid:MoveTo(self.Root.Position) -- Stop moving
		
		-- Start combo
		if self.ComboHit == 0 then
			combatRemote:FireClient(self.Target, "combo_start", self.Model)
			self.ComboHit = 1
		end
		
		-- Execute hit
		task.spawn(function()
			self:Attack()
			
			self.ComboHit = self.ComboHit + 1
			
			if self.ComboHit > CONFIG.HITS_IN_COMBO then
				-- Combo finished
				self.ComboHit = 0
				self.AttackCooldown = CONFIG.COMBO_COOLDOWN
				self.State = "Following"
				combatRemote:FireClient(self.Target, "combo_end", self.Model)
			else
				-- Continue combo
				task.wait(CONFIG.HIT_DELAY)
			end
		end)
	elseif dist > CONFIG.ATTACK_RANGE then
		self.State = "Following"
		self.ComboHit = 0
	end
end

function NPC:Update(dt)
	-- Update cooldowns
	if self.AttackCooldown > 0 then
		self.AttackCooldown = self.AttackCooldown - dt
	end
	
	-- State machine
	if self.State == "Idle" then
		local target, dist = self:FindTarget()
		if target and dist <= CONFIG.DETECTION_RANGE then
			self.Target = target
			self.State = "Following"
			print(self.Model.Name, "now following", target.Name)
		end
		
	elseif self.State == "Following" then
		if not self.Target or not self.Target.Character then
			self.State = "Idle"
			return
		end
		
		local root = self.Target.Character:FindFirstChild("HumanoidRootPart")
		if not root then
			self.State = "Idle"
			return
		end
		
		local dist = (root.Position - self.Root.Position).Magnitude
		
		if dist > CONFIG.LOSE_RANGE then
			print(self.Model.Name, "lost target")
			self.State = "Idle"
			self.Target = nil
		elseif dist <= CONFIG.ATTACK_RANGE and self.AttackCooldown <= 0 then
			self:UpdateCombat()
		else
			self:MoveToTarget()
		end
		
	elseif self.State == "Attacking" then
		self:UpdateCombat()
	end
end

-- Main system
local lastUpdate = 0

local function SetupNPC(model)
	if NPCs[model] then return end
	
	local npc = NPC.new(model)
	if npc then
		NPCs[model] = npc
		
		-- Clean up on removal
		model.AncestryChanged:Connect(function()
			if not model.Parent then
				NPCs[model] = nil
			end
		end)
	end
end

-- Look for NPCs in workspace
local function FindAllNPCs()
	print("Searching for NPCs...")
	
	-- Look in NPCS folder first
	local npcsFolder = workspace:FindFirstChild("NPCS")
	if npcsFolder then
		print("Found NPCS folder")
		for _, child in ipairs(npcsFolder:GetChildren()) do
			if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then
				-- Check if it's not a player character
				local isPlayer = false
				for _, player in ipairs(Players:GetPlayers()) do
					if player.Character == child then
						isPlayer = true
						break
					end
				end
				
				if not isPlayer then
					print("Found NPC:", child.Name)
					SetupNPC(child)
				end
			end
		end
	else
		print("NPCS folder not found, searching workspace...")
		-- Search entire workspace as fallback
		for _, child in ipairs(workspace:GetDescendants()) do
			if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then
				-- Check if it's not a player character
				local isPlayer = false
				for _, player in ipairs(Players:GetPlayers()) do
					if player.Character == child then
						isPlayer = true
						break
					end
				end
				
				-- Check if name suggests it's an NPC
				local name = child.Name:lower()
				if not isPlayer and (name:find("npc") or name:find("noob") or name:find("enemy") or name:find("bot")) then
					print("Found NPC:", child.Name)
					SetupNPC(child)
				end
			end
		end
	end
	
	local npcCount = 0
	for _ in pairs(NPCs) do
		npcCount = npcCount + 1
	end
	print("Total NPCs found:", npcCount)
end

-- Initial setup with delay to ensure workspace is loaded
task.wait(1)
FindAllNPCs()

-- Listen for new NPCs
workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
		task.wait(0.1) -- Let model load
		local name = obj.Name:lower()
		if name:find("npc") or name:find("noob") or name:find("bot") or name:find("enemy") then
			-- Make sure it's not a player
			local isPlayer = false
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character == obj then
					isPlayer = true
					break
				end
			end
			
			if not isPlayer then
				print("New NPC added:", obj.Name)
				SetupNPC(obj)
			end
		end
	end
end)

-- Update loop
RunService.Heartbeat:Connect(function()
	local now = tick()
	local dt = now - lastUpdate
	
	if dt >= CONFIG.UPDATE_RATE then
		lastUpdate = now
		
		for model, npc in pairs(NPCs) do
			if model.Parent then
				npc:Update(dt)
			else
				NPCs[model] = nil
			end
		end
	end
end)

print("NPC Combat System loaded!")