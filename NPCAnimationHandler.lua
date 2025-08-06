-- NPCAnimationHandler ModuleScript
-- Place in: ReplicatedStorage > NPCFollowModules > NPCAnimationHandler

local NPCAnimationHandler = {}
NPCAnimationHandler.__index = NPCAnimationHandler

-- Default R15 animation IDs
local DEFAULT_ANIMATIONS = {
	idle = {
		"http://www.roblox.com/asset/?id=507766666",
		"http://www.roblox.com/asset/?id=507766951",
		"http://www.roblox.com/asset/?id=507766388"
	},
	walk = {
		"http://www.roblox.com/asset/?id=507777826"
	},
	run = {
		"http://www.roblox.com/asset/?id=507767714"
	}
}

function NPCAnimationHandler.new(humanoid)
	local self = setmetatable({}, NPCAnimationHandler)
	
	self.Humanoid = humanoid
	self.Animations = {}
	self.CurrentAnimation = nil
	self.CurrentAnimationTrack = nil
	self.CurrentAnimationName = ""
	
	-- Load default animations
	self:LoadDefaultAnimations()
	
	return self
end

function NPCAnimationHandler:LoadDefaultAnimations()
	for animName, animIds in pairs(DEFAULT_ANIMATIONS) do
		self.Animations[animName] = {}
		for i, animId in ipairs(animIds) do
			local animation = Instance.new("Animation")
			animation.AnimationId = animId
			table.insert(self.Animations[animName], animation)
		end
	end
end

function NPCAnimationHandler:PlayAnimation(animationName, fadeTime)
	fadeTime = fadeTime or 0.1
	
	-- Don't replay the same animation
	if self.CurrentAnimationName == animationName then
		return
	end
	
	-- Stop current animation
	if self.CurrentAnimationTrack then
		self.CurrentAnimationTrack:Stop(fadeTime)
		self.CurrentAnimationTrack = nil
	end
	
	-- Get animation list
	local animList = self.Animations[animationName]
	if not animList or #animList == 0 then
		return
	end
	
	-- Pick random animation from list
	local animation = animList[math.random(1, #animList)]
	
	-- Load and play animation
	local animator = self.Humanoid:FindFirstChild("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = self.Humanoid
	end
	
	self.CurrentAnimationTrack = animator:LoadAnimation(animation)
	self.CurrentAnimationTrack:Play(fadeTime)
	self.CurrentAnimationName = animationName
	
	-- Adjust speed for walk/run
	if animationName == "walk" or animationName == "run" then
		self.CurrentAnimationTrack:AdjustSpeed(1)
	end
end

function NPCAnimationHandler:AdjustSpeed(speed)
	if self.CurrentAnimationTrack then
		self.CurrentAnimationTrack:AdjustSpeed(speed)
	end
end

function NPCAnimationHandler:Stop()
	if self.CurrentAnimationTrack then
		self.CurrentAnimationTrack:Stop(0.1)
		self.CurrentAnimationTrack = nil
		self.CurrentAnimationName = ""
	end
end

function NPCAnimationHandler:UpdateMovementAnimation(velocity)
	local speed = velocity.Magnitude
	
	if speed < 0.5 then
		self:PlayAnimation("idle", 0.1)
	elseif speed < 20 then
		self:PlayAnimation("walk", 0.1)
		-- Adjust animation speed based on movement speed
		local animSpeed = speed / 16 -- 16 is default walk speed
		self:AdjustSpeed(animSpeed)
	else
		self:PlayAnimation("run", 0.1)
		local animSpeed = speed / 24 -- 24 is default run speed
		self:AdjustSpeed(animSpeed)
	end
end

return NPCAnimationHandler