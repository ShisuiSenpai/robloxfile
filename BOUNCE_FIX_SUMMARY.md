# Bounce/Physics Fix Summary

## Problem
After the ability completes, the attacker sometimes bounces up (sometimes very high) when returning to the ground.

## Root Causes Identified

1. **Residual Velocity**: Movement velocity not being cleared after ability
2. **Collision Issues**: Attacker colliding with enemy or ground during fall
3. **Position Precision**: Landing slightly below ground level causing physics bounce
4. **Mass/Physics Conflicts**: Normal physics fighting with ability movement

## Fixes Applied

### 1. Velocity Cleanup (Client)
```lua
-- Clear any existing velocity when ability ends
attackerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
attackerRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
```

### 2. Collision Prevention (Server)
```lua
-- Make attacker massless during ability
rootPart.Massless = true

-- Disable collision for body parts (except HumanoidRootPart)
part.CanCollide = false
```

### 3. Landing Buffer (Client)
```lua
-- Add small buffer above ground
fallHeight = math.max(fallHeight, attackerStartPos.Y + 0.1)

-- Snap to exact position when nearly done
if fallProgress > 0.95 then
    fallHeight = attackerStartPos.Y
end
```

### 4. Post-Ability Cleanup (Server)
```lua
-- Restore mass
rootPart.Massless = false

-- Clear velocities again
rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

-- Restore collision properties
part.CanCollide = originalValue
```

## How It Prevents Bouncing

1. **During Ability**:
   - Attacker is massless (no gravity accumulation)
   - Collision disabled (no physics conflicts)
   - Controlled movement only

2. **Landing Phase**:
   - Small buffer prevents going below ground
   - Snap to exact height at 95% completion
   - Ensures clean landing

3. **After Ability**:
   - All velocities cleared
   - Position set to exact start position
   - Double-check velocity after 0.1s delay

## Testing Notes

- No more bouncing on landing
- Smooth transition back to normal movement
- No collision with enemy during ability
- Clean physics state after completion