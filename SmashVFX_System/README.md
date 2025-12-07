# SmashVFX System

A smooth, optimized VFX spawning system for Roblox. Left-click on the ground within 20 studs to spawn your SmashVfx effect with beautiful tweening animations.

---

## 📁 Explorer Hierarchy

### Option A: Single Player (Client-Only) - Simplest Setup

```
game
├── ReplicatedStorage
│   └── VFX
│       └── SmashVfx (Part)
│           ├── Attachment1
│           │   └── ParticleEmitter
│           ├── Attachment2
│           │   └── ParticleEmitter
│           └── ... (your other attachments)
│
└── StarterPlayer
    └── StarterPlayerScripts
        └── SmashVFXController (LocalScript) ← Use: SmashVFXController.client.lua
```

### Option B: Multiplayer (All Players See VFX)

```
game
├── ReplicatedStorage
│   └── VFX
│       └── SmashVfx (Part)
│           ├── Attachment1
│           │   └── ParticleEmitter
│           ├── Attachment2
│           │   └── ParticleEmitter
│           └── ... (your other attachments)
│
├── ServerScriptService
│   └── SmashVFXHandler (Script) ← Use: SmashVFXHandler.server.lua
│
└── StarterPlayer
    └── StarterPlayerScripts
        └── SmashVFXController (LocalScript) ← Use: SmashVFXController_Multiplayer.client.lua
```

---

## 🚀 Setup Instructions

### Step 1: Make sure your VFX is in the right place
Your `SmashVfx` Part should already be at:
```
ReplicatedStorage → VFX → SmashVfx
```

### Step 2: For Single Player (Recommended for testing)
1. Create a **LocalScript** in `StarterPlayer → StarterPlayerScripts`
2. Name it `SmashVFXController`
3. Copy the contents of `SmashVFXController.client.lua` into it
4. Done! Play the game and left-click on the ground.

### Step 3: For Multiplayer (Optional)
1. Create a **Script** in `ServerScriptService`
2. Name it `SmashVFXHandler`
3. Copy the contents of `SmashVFXHandler.server.lua` into it
4. Create a **LocalScript** in `StarterPlayer → StarterPlayerScripts`
5. Name it `SmashVFXController`
6. Copy the contents of `SmashVFXController_Multiplayer.client.lua` into it

---

## ⚙️ Configuration

Edit these values at the top of the LocalScript:

```lua
local MAX_DISTANCE = 20      -- How far you can click (in studs)
local VFX_LIFETIME = 2       -- How long VFX stays visible (seconds)
local TWEEN_IN_TIME = 0.15   -- Scale-in animation duration
local TWEEN_OUT_TIME = 0.4   -- Fade-out animation duration
local COOLDOWN = 0.3         -- Time between clicks (prevents spam)
```

---

## ✨ Features

- **Smooth Tweening**: VFX scales in with a bouncy `Back` easing, scales out smoothly
- **Surface Alignment**: VFX automatically orients to match the ground surface (works on slopes!)
- **Recursive Particle Emission**: Finds ALL ParticleEmitters in ALL children automatically
- **Click Validation**: Only works when clicking on actual surfaces within range
- **Spam Protection**: Built-in cooldown prevents accidental double-clicks
- **Auto Cleanup**: VFX automatically destroyed after lifetime (with safety fallback via Debris)
- **Performance Optimized**: 
  - Parts are non-collidable
  - CanQuery/CanTouch disabled
  - Uses burst emission instead of continuous

---

## 🎨 Tips for Your VFX

For the smoothest results, make sure your `SmashVfx` Part:

1. **Is Anchored** (script sets this, but good practice)
2. **Has Transparency = 1** (we only want to see particles, not the part)
3. **ParticleEmitters have good Lifetime values** (1-3 seconds recommended)

### Optional: Custom Emit Count
Add an attribute called `EmitCount` (Number) to any ParticleEmitter to control how many particles burst. Default is 15.

---

## 🔧 Troubleshooting

**VFX doesn't appear:**
- Check that `ReplicatedStorage.VFX.SmashVfx` exists
- Make sure you're clicking within 20 studs
- Check the Output window for error messages

**VFX appears but no particles:**
- Make sure your ParticleEmitters have proper settings
- Check that `Rate` and `Lifetime` values are set correctly
- Verify particle textures are loading

**Clicking doesn't work:**
- Make sure you're not clicking on UI elements
- Check that the LocalScript is in StarterPlayerScripts
- Verify the script is enabled

---

## 📋 File Summary

| File | Type | Location in Roblox |
|------|------|-------------------|
| `SmashVFXController.client.lua` | LocalScript | StarterPlayerScripts |
| `SmashVFXController_Multiplayer.client.lua` | LocalScript | StarterPlayerScripts (use instead of above for multiplayer) |
| `SmashVFXHandler.server.lua` | Script | ServerScriptService (multiplayer only) |

---

Enjoy your smooth VFX system! 🎮✨
