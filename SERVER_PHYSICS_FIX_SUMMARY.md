# Server-Side Physics Fix Summary

## Issues Identified & Fixed

### 1. Enemy Not Moving Up
**Problem**: Enemy movement was only happening on the client side, which doesn't replicate to other players.

**Root Cause**: 
- Client-side physics (BodyPosition/BodyGyro) only affects the local client's view
- Server wasn't applying any physics to actually move the enemy
- This caused desync where the attacker saw the enemy move but the enemy player didn't

**Solution**:
- Moved all enemy physics handling to the server
- Server now creates BodyPosition and BodyGyro immediately when ability starts
- Physics objects are replicated to all clients automatically

### 2. Enemy Not Getting Knockback
**Problem**: Knockback wasn't working because physics constraints were still active.

**Root Cause**:
- BodyPosition was preventing the knockback BodyVelocity from working
- Physics constraints were fighting each other

**Solution**:
- Server now removes BodyPosition and BodyGyro before applying knockback
- Clear separation between hold phase and knockback phase

### 3. Attacker Landing Stutter
**Problem**: Frame skip/stutter when attacker lands on the ground.

**Root Cause**:
- Quadratic easing (progress²) creates an abrupt stop at the end
- No ground position clamping could cause overshooting

**Solution**:
- Changed to smoothstep easing: `progress * progress * (3.0 - 2.0 * progress)`
- Added ground position clamping: `math.max(fallHeight, attackerStartPos.Y)`
- Smoother deceleration prevents the jarring stop

## Architecture Changes

### Before:
```
Client A (Attacker) → Moves enemy locally → Other clients don't see it
Server → Only disables movement
```

### After:
```
Server → Creates BodyPosition/BodyGyro → Replicates to all clients
Client → Only handles attacker movement and visual effects
```

## Key Improvements

1. **Proper Replication**: Enemy movement now visible to all players
2. **Server Authority**: Server controls all combat physics
3. **Clean Separation**: Client handles visuals, server handles physics
4. **Smooth Movement**: Better easing functions prevent stuttering
5. **Proper Cleanup**: Physics objects removed at the right times

## Server-Side Enemy Movement Flow

1. **Ability Start**:
   - Calculate enemy peak position
   - Create BodyPosition set to peak position
   - Create BodyGyro to face attacker
   - Physics immediately takes control

2. **During Hold**:
   - BodyPosition keeps enemy at peak
   - BodyGyro maintains facing direction

3. **Damage Phase**:
   - Remove BodyPosition and BodyGyro
   - Apply knockback BodyVelocity
   - Enemy flies away naturally

4. **Cleanup**:
   - Restore enemy movement values
   - Remove any remaining physics objects

## Performance Benefits

- No client-server physics fighting
- Single source of truth (server)
- Less network traffic (no position syncing needed)
- Smoother experience for all players