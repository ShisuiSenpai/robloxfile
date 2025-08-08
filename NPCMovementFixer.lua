-- NPCMovementFixer Script
-- This script provides an alternative movement method that ensures animations work
-- Place in ServerScriptService

local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage:WaitForChild("NPCFollowModules"):WaitForChild("NPCFollowConfig"))

-- Alternative movement handler that ensures MoveDirection updates
local MovementHandler = {}
MovementHandler.__index = MovementHandler

function MovementHandler.new(npcModel)
	local self = setmetatable({}, MovementHandler)
	
	self.Model = npcModel
	self.Humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	self.RootPart = npcModel:FindFirstChild("HumanoidRootPart")
	
	if not self.Humanoid or not self.RootPart then
		return nil
	end
	
	self.TargetPosition = nil
	self.IsMoving = false
	self.Connection = nil
	
	-- Create BodyVelocity for smooth movement
	self.BodyVelocity = Instance.new("BodyVelocity")
	self.BodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
	self.BodyVelocity.Velocity = Vector3.zero
	self.BodyVelocity.Parent = self.RootPart
	
	-- Create BodyPosition for precise positioning
	self.BodyPosition = Instance.new("BodyPosition")
	self.BodyPosition.MaxForce = Vector3.new(0, 0, 0) -- Disabled by default
	self.BodyPosition.D = 2000
	self.BodyPosition.P = 10000
	self.BodyPosition.Parent = self.RootPart
	
	return self
end

function MovementHandler:MoveTo(targetPosition)
	self.TargetPosition = targetPosition
	self.IsMoving = true
	
	-- Start movement loop if not already running
	if not self.Connection then
		self:StartMovementLoop()
	end
end

function MovementHandler:Stop()
	self.IsMoving = false
	self.TargetPosition = nil
	self.BodyVelocity.Velocity = Vector3.zero
	self.BodyPosition.MaxForce = Vector3.new(0, 0, 0)
	
	-- Ensure humanoid stops
	self.Humanoid:MoveTo(self.RootPart.Position)
end

function MovementHandler:StartMovementLoop()
	self.Connection = RunService.Heartbeat:Connect(function()
		if not self.IsMoving or not self.TargetPosition then
			self.BodyVelocity.Velocity = Vector3.zero
			return
		end
		
		-- Calculate direction and distance
		local currentPos = self.RootPart.Position
		local targetPos = Vector3.new(self.TargetPosition.X, currentPos.Y, self.TargetPosition.Z)
		local direction = (targetPos - currentPos)
		local distance = direction.Magnitude
		
		-- Stop if close enough
		if distance < 2 then
			self:Stop()
			return
		end
		
		-- Calculate velocity
		direction = direction.Unit
		local speed = self.Humanoid.WalkSpeed
		local velocity = direction * speed
		
		-- Apply velocity
		self.BodyVelocity.Velocity = velocity
		
		-- IMPORTANT: Also call MoveTo to ensure MoveDirection updates
		-- This combination ensures both smooth movement AND proper animation triggers
		local moveToPos = currentPos + direction * 5
		self.Humanoid:MoveTo(moveToPos)
		
		-- Face the direction of movement
		local lookDirection = self.RootPart.CFrame.LookVector:Lerp(direction, 0.2)
		self.RootPart.CFrame = CFrame.lookAt(currentPos, currentPos + lookDirection)
	end)
end

function MovementHandler:Destroy()
	if self.Connection then
		self.Connection:Disconnect()
	end
	if self.BodyVelocity then
		self.BodyVelocity:Destroy()
	end
	if self.BodyPosition then
		self.BodyPosition:Destroy()
	end
end

-- Module to manage all NPC movement handlers
local NPCMovementFixer = {
	Handlers = {}
}

function NPCMovementFixer:GetHandler(npcModel)
	if not self.Handlers[npcModel] then
		self.Handlers[npcModel] = MovementHandler.new(npcModel)
	end
	return self.Handlers[npcModel]
end

function NPCMovementFixer:RemoveHandler(npcModel)
	if self.Handlers[npcModel] then
		self.Handlers[npcModel]:Destroy()
		self.Handlers[npcModel] = nil
	end
end

-- Export for use by NPCFollowServer
_G.NPCMovementFixer = NPCMovementFixer

print("[NPCMovementFixer] Movement fix system initialized")
print("[NPCMovementFixer] NPCFollowServer can use _G.NPCMovementFixer:GetHandler(npcModel)")

return NPCMovementFixer