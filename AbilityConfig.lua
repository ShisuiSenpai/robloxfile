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

		-- Movement phases (in seconds) - Instant and snappy
		phases = {
			rise = {duration = 0.3, height = 25}, -- Fast rise with higher height
			hover = {duration = 0.6}, -- Shorter hover
			fall = {duration = 0.4} -- Fast fall
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
			slash1 = 0.1, -- Quick slash
			slash2 = 0.6, -- Earlier slash2
			damagePoint = 0.9 -- Earlier damage point
		},

		-- Animation timing - Instant response
		animationTiming = {
			windup = 0.02, -- Almost no windup
			startDelay = 0.01 -- Minimal delay
		},

		-- Direct CFrame movement settings (no BodyPosition)
		movementSettings = {
			useDirectCFrame = true, -- Use direct CFrame manipulation
			teleportEnemy = true, -- Teleport enemy to peak height immediately
			smoothAttacker = false -- No smoothing for attacker - direct movement
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