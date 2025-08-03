# Orientation Locking Update Summary

## Changes Applied

### 1. AbilityConfig Updates
- Updated `vfxTiming.slash1` from 0.15 to 0.09
- Updated `vfxTiming.slash2` from 0.8 to 1.25
- Updated `enemyMovement.holdDuration` from 1.0 to 1.5

### 2. Attacker Orientation Lock (Server-side)
The attacker's orientation is now locked during the ability:
- Stores original `AutoRotate` value
- Sets `humanoid.AutoRotate = false` when ability starts
- Restores original `AutoRotate` value when ability ends

This prevents the attacker from turning or changing direction during the ability.

### 3. Enemy Facing Direction (Client-side)
The enemy now faces the attacker throughout the ability:
- Initial rotation tween moves enemy to face attacker
- `BodyGyro` is added to maintain facing direction while at peak
- Only Y-axis rotation is allowed (prevents tilting)
- BodyGyro parameters:
  - MaxTorque: `Vector3.new(0, 1e6, 0)` (Y-axis only)
  - P: 10000 (strong position holding)
  - D: 500 (damping for smooth movement)

### 4. Cleanup Improvements
Added proper cleanup for the new BodyGyro in all scenarios:
- When damage is applied (enemy released for knockback)
- When ability ends normally
- When character respawns
- When player leaves the game

## How It Works

1. **Ability Start**: 
   - Attacker's `AutoRotate` is disabled, locking their orientation
   - Enemy is teleported to peak position
   - Enemy is rotated to face the attacker

2. **During Ability**:
   - Attacker cannot turn (locked orientation)
   - Enemy is held at peak with BodyPosition
   - Enemy's facing direction is maintained with BodyGyro

3. **Damage Phase**:
   - BodyPosition and BodyGyro are removed
   - Enemy is free to be knocked back naturally

4. **Ability End**:
   - Attacker's `AutoRotate` is restored
   - All physics constraints are cleaned up

## Testing Notes

- Test that attacker cannot rotate during ability
- Verify enemy consistently faces attacker
- Check that orientation is properly restored after ability
- Test with different initial facing directions
- Verify cleanup on character death/respawn