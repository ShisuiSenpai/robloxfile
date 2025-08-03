# 🎛️ TIMING SETTINGS GUIDE

## 📍 Where to Adjust Settings

All timing settings are in `AbilityConfig.lua` in the `UpwardSlash` configuration.

## ⚙️ Main Timing Settings

### Movement Phases
```lua
phases = {
    rise = {duration = 0.6, height = 25}, -- How fast you rise and how high
    hover = {duration = 1.2}, -- How long you stay at peak
    fall = {duration = 0.5} -- How fast you fall
}
```

**Adjust these for:**
- **Slower ascent**: Increase `rise.duration` (e.g., 0.8, 1.0)
- **Faster ascent**: Decrease `rise.duration` (e.g., 0.4, 0.3)
- **Higher jump**: Increase `rise.height` (e.g., 30, 35)
- **Longer hover**: Increase `hover.duration` (e.g., 1.5, 2.0)
- **Shorter hover**: Decrease `hover.duration` (e.g., 0.8, 0.6)

### VFX Timing
```lua
vfxTiming = {
    jumpWind = 0, -- When wind VFX plays (0 = immediate)
    slash1 = 0.2, -- When first slash plays
    slash2 = 0.8, -- When second slash plays
    damagePoint = 1.0 -- When damage is applied
}
```

**Adjust these for:**
- **Earlier slash1**: Decrease `slash1` (e.g., 0.1, 0.15)
- **Later slash1**: Increase `slash1` (e.g., 0.3, 0.4)
- **Earlier slash2**: Decrease `slash2` (e.g., 0.6, 0.7)
- **Later slash2**: Increase `slash2` (e.g., 0.9, 1.0)
- **Earlier damage**: Decrease `damagePoint` (e.g., 0.8, 0.9)
- **Later damage**: Increase `damagePoint` (e.g., 1.1, 1.2)

### Animation Timing
```lua
animationTiming = {
    windup = 0.05, -- Delay before movement starts
    startDelay = 0.02 -- Additional delay
}
```

**Adjust these for:**
- **More responsive**: Decrease both values (e.g., 0.02, 0.01)
- **More dramatic**: Increase both values (e.g., 0.1, 0.05)

### Enemy Movement
```lua
enemyMovement = {
    syncWithAttacker = true, -- Enemy follows attacker's position
    stayAtPeak = true, -- Enemy stays at peak until damage
    peakHeight = 25, -- Same as attacker peak height
    reactToSlash = true -- Enemy reacts to slash moment
}
```

**Adjust these for:**
- **Perfect sync**: Keep `syncWithAttacker = true`
- **Different enemy height**: Change `peakHeight` (must match `phases.rise.height`)
- **Enemy reaction**: Keep `reactToSlash = true` for natural knockback

## 🎯 Quick Adjustment Examples

### For Slower, More Dramatic Movement:
```lua
phases = {
    rise = {duration = 0.8, height = 30}, -- Slower, higher
    hover = {duration = 1.5}, -- Longer hover
    fall = {duration = 0.6} -- Slower fall
}

vfxTiming = {
    slash1 = 0.3, -- Later slash1
    slash2 = 1.0, -- Later slash2
    damagePoint = 1.2 -- Later damage
}
```

### For Faster, More Responsive Movement:
```lua
phases = {
    rise = {duration = 0.4, height = 20}, -- Faster, lower
    hover = {duration = 0.8}, -- Shorter hover
    fall = {duration = 0.3} -- Faster fall
}

vfxTiming = {
    slash1 = 0.1, -- Earlier slash1
    slash2 = 0.6, -- Earlier slash2
    damagePoint = 0.8 -- Earlier damage
}
```

### For Perfect Slash Timing:
```lua
-- Make sure slash2 plays during hover phase
phases = {
    rise = {duration = 0.6, height = 25},
    hover = {duration = 1.2}, -- Long enough for slash2
    fall = {duration = 0.5}
}

vfxTiming = {
    slash1 = 0.2, -- During rise
    slash2 = 0.8, -- During hover
    damagePoint = 1.0 -- After slash2
}
```

## 🔧 Troubleshooting

### If Slash2 Plays Too Early:
- Increase `vfxTiming.slash2` (e.g., 0.9, 1.0)
- Or increase `phases.rise.duration` to give more time

### If Enemy Falls Too Early:
- Make sure `enemyMovement.stayAtPeak = true`
- Increase `phases.hover.duration`
- Check that `damagePoint` is after `slash2`

### If Movement Feels Sluggish:
- Decrease `phases.rise.duration`
- Decrease `animationTiming.windup` and `startDelay`
- Decrease `enemyMovement.tweenDuration`

### If Movement Is Too Fast:
- Increase `phases.rise.duration`
- Increase `animationTiming.windup` and `startDelay`
- Increase `enemyMovement.tweenDuration`

## 📝 File Location
All settings are in: `AbilityConfig.lua` → `AbilityConfig.Abilities.UpwardSlash`