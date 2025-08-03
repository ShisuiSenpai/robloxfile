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
			fall = {duration = 0.8} -- Slower, more natural fall
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

		-- VFX Timing - ADJUSTABLE TIMING
		vfxTiming = {
			jumpWind = 0, -- Immediate
			slash1 = 0.15, -- Earlier slash1 for better timing
			slash2 = 0.8, -- Slash2 timing (after rise completes)
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
			holdDuration = 1.0 -- How long enemy stays at peak (1.0 = until damage)
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