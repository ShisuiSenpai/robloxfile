# Combat System Integration Summary

## Overview
The ability system has been fully integrated with your custom combat system, using HealthValue/PercentValue instead of default Humanoid health.

## Key Changes

### 1. Damage Application
Instead of `humanoid:TakeDamage()`, the ability now:
```lua
-- Uses your HealthValue system
local healthValue = enemy.Character:FindFirstChild("HealthValue")
healthValue.Value = math.max(0, healthValue.Value - damage)
```

### 2. Percentage-Based Knockback Scaling
The knockback now scales with the enemy's damage percentage:
```lua
local scaledPercent = math.clamp(percentValue.Value, 0, 400)
local scaledForce = baseForce * (1 + (scaledPercent / 200)) -- Up to 3x at 400%
```

### 3. RagdollModule Integration
Uses your knockback system instead of simple BodyVelocity:
```lua
ragdollModule.Knockback(enemy, knockbackVector, true, duration, player)
```

### 4. Hit Effects
The client now applies your combat framework's hit effects:
- Highlight effects (red flash)
- Hit animations (HitSpin for high percentage, Hit1 for normal)
- Sound effects
- Particle effects

## Damage Flow

1. **Ability Damage Point** (1.0 seconds):
   - Calculate random damage (100-150)
   - Reduce enemy's HealthValue
   - PercentageManager auto-updates PercentValue

2. **Knockback Calculation**:
   - Get current percentage (0-400%)
   - Scale knockback force based on percentage
   - Higher percentage = stronger knockback

3. **Visual Feedback**:
   - CombatFramework.ApplyHitEffects shows:
     - Red highlight flash
     - Hit animation (spins at >150%)
     - Hit particles
     - Sound effects

4. **Physics**:
   - Enemy released from BodyPosition hold
   - RagdollModule applies scaled knockback
   - Natural physics takes over

## Configuration in AbilityConfig

```lua
damage = {min = 100, max = 150},
knockback = {
    force = 59,          -- Base force (scaled by percentage)
    upwardBoost = 30,    -- Vertical component
    duration = 0.3       -- Knockback duration
}
```

## Advantages

1. **Consistent System**: Uses same damage/knockback system as regular combat
2. **Percentage Scaling**: Higher damage = stronger knockback (anime-style)
3. **Visual Feedback**: All your existing hit effects work
4. **Fallback Support**: Still works if combat system not initialized

## Testing Notes

- Damage should update the percentage display above enemy
- Knockback should be stronger on high-percentage enemies
- Hit effects should match your regular combat
- Billboard should show updated percentage after hit