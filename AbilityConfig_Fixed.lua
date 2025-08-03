-- AbilityConfig: Central configuration for all abilities
local AbilityConfig = {}

-- Debug mode for extensive logging
AbilityConfig.DEBUG_MODE = true

-- Ability configurations
AbilityConfig.Abilities = {
	UpwardSlash = {
		-- Basic settings
		name = "Upward Slash",
		key = Enum.KeyCode.E,
		cooldown = 5,

		-- Detection
		detectionRange = 15,

		-- Animation
		animationId = "rbxassetid://126685859180940",
		animationPriority = Enum.AnimationPriority.Action4,

		-- Movement phases (in seconds) - ADJUSTABLE TIMING
		phases = {
			rise = {duration = 0.6, height = 25}, -- Slower rise for better timing
			hover = {duration = 1.2}, -- Longer hover for slash completion
			fall = {duration = 0.5} -- Slower, more natural fall
		},

		-- Combat
		damage = {min = 100, max = 150},
		knockback = {
			force = 59,
			upwardBoost = 30,
			duration = 0.3
		},

		-- Enemy positioning - Adjusted for better sync
		enemyOffset = Vector3.new(0, 0, -5), -- 5 studs in front

		-- VFX Timing - ADJUSTABLE TIMING
		vfxTiming = {
			jumpWind = 0, -- Immediate
			slash1 = 0.09, -- Earlier slash1 for better timing
			slash2 = 1.25, -- Slash2 timing (after rise completes)
			damagePoint = 1.0 -- Damage point (after slash2)
		},

		-- Animation timing - ADJUSTABLE TIMING
		animationTiming = {
			windup = 0.05, -- Small windup
			startDelay = 0.02 -- Small delay
		},

		-- Enemy movement settings - INDEPENDENT WITH PEAK HOLD
		enemyMovement = {
			useTween = true, -- Use TweenService for smooth movement
			tweenDuration = 0.4, -- How fast enemy moves to peak
			stayAtPeak = true, -- Enemy stays at peak until damage
			peakHeight = 25, -- Same as attacker peak height
			releaseAfterDamage = true, -- Release enemy after damage is applied
			holdUntilDamage = true, -- Keep enemy frozen until damage moment
			holdDuration = 1.5 -- How long enemy stays at peak (1.0 = until damage)
		}
	}
}

-- Helper function to get total ability duration
function AbilityConfig.GetAbilityDuration(abilityName)
	local ability = AbilityConfig.Abilities[abilityName]
	if not ability then return 0 end

	local total = 0
	for _, phase in pairs(ability.phases) do
		total = total + (phase.duration or 0)
	end
	return total
end

-- Get phase end times for easier calculation
function AbilityConfig.GetPhaseEndTimes(abilityName)
	local ability = AbilityConfig.Abilities[abilityName]
	if not ability or not ability.phases then return {} end
	
	local endTimes = {}
	local currentTime = 0
	
	-- Rise phase
	currentTime = currentTime + (ability.phases.rise.duration or 0)
	endTimes.rise = currentTime
	
	-- Hover phase
	currentTime = currentTime + (ability.phases.hover.duration or 0)
	endTimes.hover = currentTime
	
	-- Fall phase
	currentTime = currentTime + (ability.phases.fall.duration or 0)
	endTimes.fall = currentTime
	
	return endTimes
end

-- Validate ability configuration
function AbilityConfig.ValidateAbility(abilityName)
	local ability = AbilityConfig.Abilities[abilityName]
	if not ability then
		return false, "Ability not found"
	end
	
	-- Check required fields
	local required = {"name", "key", "cooldown", "phases", "damage"}
	for _, field in ipairs(required) do
		if not ability[field] then
			return false, "Missing required field: " .. field
		end
	end
	
	-- Validate phases
	if not ability.phases.rise or not ability.phases.hover or not ability.phases.fall then
		return false, "Missing phase configuration"
	end
	
	return true, "Valid"
end

-- Debug logging helper
function AbilityConfig.Debug(...)
	if AbilityConfig.DEBUG_MODE then
		print("[ABILITY DEBUG]", ...)
	end
end

-- Get safe config value with fallback
function AbilityConfig.GetConfigValue(abilityName, path, default)
	local ability = AbilityConfig.Abilities[abilityName]
	if not ability then return default end
	
	local current = ability
	for segment in path:gmatch("[^%.]+") do
		if type(current) ~= "table" then
			return default
		end
		current = current[segment]
	end
	
	return current ~= nil and current or default
end

return AbilityConfig