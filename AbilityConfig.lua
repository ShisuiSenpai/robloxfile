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

		-- Movement phases (in seconds) - Much faster and more responsive
		phases = {
			rise = {duration = 0.4, height = 20}, -- Halved duration for snappier ascent
			hover = {duration = 0.8}, -- Slightly shorter hover
			fall = {duration = 0.5} -- Faster fall
		},

		-- Combat
		damage = {min = 100, max = 150},
		knockback = {
			force = 80,
			upwardBoost = 30,
			duration = 0.3
		},

		-- Enemy positioning - Adjusted for better sync
		enemyOffset = Vector3.new(0, 0, -5), -- 5 studs in front

		-- VFX Timing - Immediate and snappy
		vfxTiming = {
			jumpWind = 0, -- Immediate
			slash1 = 0.05, -- Almost immediate slash
			slash2 = 0.8, -- Earlier slash2
			damagePoint = 1.2 -- Earlier damage point
		},

		-- Animation timing - No delays for instant response
		animationTiming = {
			windup = 0.05, -- Minimal windup for instant response
			startDelay = 0.02 -- Almost no delay
		},

		-- Physics settings for instant, snappy movement
		bodyPositionSettings = {
			maxForce = Vector3.new(1e6, 1e6, 1e6), -- Maximum force for instant response
			P = 50000, -- Much higher P for instant positioning
			D = 5000 -- Higher D for no overshoot
		},

		-- Enemy control settings - Instant and snappy
		enemyControl = {
			maxForce = Vector3.new(1e6, 1e6, 1e6), -- Maximum force
			P = 100000, -- Extremely high P for instant positioning
			D = 10000, -- High D for no overshoot
			gyroMaxTorque = Vector3.new(1e6, 1e6, 1e6), -- Maximum rotation control
			gyroP = 50000, -- Extremely high P for instant rotation
			gyroD = 5000 -- High D for no rotation overshoot
		}
	}
}

-- Helper function to get total ability duration
function AbilityConfig.GetAbilityDuration(abilityName)
	local ability = AbilityConfig.Abilities[abilityName]
	if not ability then return 0 end

	local total = 0
	for _, phase in pairs(ability.phases) do
		total = total + phase.duration
	end
	return total
end

-- Debug logging helper
function AbilityConfig.Debug(...)
	if AbilityConfig.DEBUG_MODE then
		print("[ABILITY DEBUG]", ...)
	end
end

return AbilityConfig