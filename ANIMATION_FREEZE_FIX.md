# Enemy Animation Freeze Fix

## Problem
When the ability starts, the enemy's movement animation briefly plays before they get frozen, creating a visual glitch.

## Root Causes
1. Animation tracks take time to stop, even with `Stop()`
2. The default Animate script continues to play animations based on movement
3. Humanoid movement states can trigger animations

## Solution Applied

### 1. Immediate Animation Stop
```lua
-- Stop all animations with 0 fade time
for _, track in pairs(animator:GetPlayingAnimationTracks()) do
    track:Stop(0) -- 0 fade time = immediate stop
end
```

### 2. PlatformStand State
```lua
-- Set PlatformStand to prevent movement animations
enemyHumanoid.PlatformStand = true
```
- PlatformStand prevents the humanoid from playing walk/run/jump animations
- Character appears "ragdolled" but held in place by physics

### 3. Disable Animate Script
```lua
-- Disable Animate script completely
local animateScript = enemy.Character:FindFirstChild("Animate")
if animateScript then
    animateScript.Disabled = true
end
```
- The Animate script is what plays animations based on humanoid states
- Disabling it prevents ANY automatic animations from playing

### 4. Proper Restoration
When the ability ends or enemy is released:
- Restore PlatformStand to original value (usually false)
- Re-enable the Animate script
- This allows normal animations to resume

## How It Works

1. **Ability Start**:
   - Stop all current animations immediately (0 fade)
   - Set PlatformStand = true (prevents movement animations)
   - Disable Animate script (prevents any new animations)
   - Apply physics constraints

2. **During Ability**:
   - Enemy is completely frozen
   - No animations can play
   - Physics holds them in position

3. **After Damage/End**:
   - Restore PlatformStand
   - Re-enable Animate script
   - Normal animations resume

## Benefits
- No animation glitches at ability start
- Complete visual freeze matches the physical freeze
- Clean restoration to normal state
- Works with any character/animation setup