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

		-- Movement phases (in seconds) - Adjusted for smoother flow
		phases = {
			rise = {duration = 0.8, height = 20},
			hover = {duration = 1.0},
			fall = {duration = 0.71}
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

		-- VFX Timing - Improved timing for smoother flow
		vfxTiming = {
			jumpWind = 0, -- Immediate
			slash1 = 0.1, -- Reduced delay for better sync
			slash2 = 1.0, -- Slightly earlier for better timing
			damagePoint = 1.65 -- Adjusted to match slash2 timing
		},

		-- Animation timing
		animationTiming = {
			windup = 0.2, -- Reduced windup for more responsive feel
			startDelay = 0.1 -- Small delay before movement starts
		},

		-- Physics settings for smooth movement
		bodyPositionSettings = {
			maxForce = Vector3.new(4000, 1e6, 4000),
			P = 20000,
			D = 2000
		},

		-- Enemy control settings
		enemyControl = {
			maxForce = Vector3.new(1e6, 1e6, 1e6), -- Stronger control
			P = 30000, -- Higher P for more responsive control
			D = 3000, -- Higher D for better damping
			gyroMaxTorque = Vector3.new(1e6, 1e6, 1e6), -- Strong rotation control
			gyroP = 5000,
			gyroD = 1000
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