# SmashVFX System

A smooth, multiplayer-ready VFX ability system for Roblox with knockback and ragdoll physics.

---

## 📁 Explorer Hierarchy (Multiplayer Setup)

```
game
├── ReplicatedStorage
│   └── VFX
│       └── SmashVfx (Part)
│           ├── Attachment1
│           │   └── ParticleEmitter
│           ├── Attachment2
│           │   └── ParticleEmitter
│           └── ... (your attachments)
│
├── ServerScriptService
│   └── SmashVFXHandler (Script)  ← Server/SmashVFXHandler.server.lua
│
└── StarterPlayer
    └── StarterPlayerScripts
        └── SmashVFXController (LocalScript)  ← Client/SmashVFXController_Multiplayer.client.lua
```

---

## 🚀 Quick Setup

### Step 1: VFX Template
Make sure your `SmashVfx` Part is at:
```
ReplicatedStorage → VFX → SmashVfx
```

### Step 2: Server Script
1. Create a **Script** in `ServerScriptService`
2. Name it `SmashVFXHandler`
3. Paste contents of `Server/SmashVFXHandler.server.lua`

### Step 3: Client Script
1. Create a **LocalScript** in `StarterPlayer → StarterPlayerScripts`
2. Name it `SmashVFXController`
3. Paste contents of `Client/SmashVFXController_Multiplayer.client.lua`

### Step 4: Play!
- Hold **E** to preview
- **Left-click** on ground to smash!

---

## 🎮 Controls

| Key | Action |
|-----|--------|
| **Hold E** | Show preview circle on ground |
| **Release E** | Hide preview |
| **Left Click** | Spawn VFX & hit enemies |

---

## ✨ Features

### Multiplayer
| Feature | Handled By |
|---------|------------|
| Input & Preview | Client |
| VFX Visuals | Client (all see it) |
| Hit Detection | **Server** |
| Knockback & Ragdoll | **Server** |
| Validation | **Server** |

### Effects
- ✅ Smooth VFX tweening (scale in/out)
- ✅ Ground-only spawning (no walls/players)
- ✅ 20 stud max range
- ✅ Goofy knockback (up + back + spin)
- ✅ Ragdoll physics (1.5 seconds)
- ✅ Smooth recovery animation
- ✅ Works on Players AND NPCs
- ✅ Visual debug hitbox

---

## ⚙️ Configuration

### Client Settings (LocalScript)
```lua
local MAX_DISTANCE = 20          -- Click range
local VFX_LIFETIME = 2           -- VFX duration
local PREVIEW_SIZE = 7           -- Preview circle size
local DEBUG_HITBOX = true        -- Show/hide hitbox visual
```

### Server Settings (Script)
```lua
local MAX_DISTANCE = 20          -- Validation range
local COOLDOWN = 0.3             -- Anti-spam

-- Hitbox
local HITBOX_SIZE = Vector3.new(7, 8, 7)

-- Knockback & Ragdoll
local KNOCKBACK_FORCE_UP = 35    -- Upward launch
local KNOCKBACK_FORCE_BACK = 25  -- Backward push
local RAGDOLL_DURATION = 1.5     -- Time on ground
```

---

## 🔒 Security

The server handles all important logic:

1. **Validates** position is within range
2. **Validates** surface is ground (not walls)
3. **Checks** cooldown to prevent spam
4. **Detects** hits server-side (can't be exploited)
5. **Applies** knockback/ragdoll authoritatively

Clients only:
- Send position request
- Render visuals

---

## 📋 File Summary

| File | Type | Location |
|------|------|----------|
| `SmashVFXHandler.server.lua` | Script | ServerScriptService |
| `SmashVFXController_Multiplayer.client.lua` | LocalScript | StarterPlayerScripts |
| `SmashVFXController.client.lua` | LocalScript | (Single-player version) |

---

## 🎯 How It Works

```
Player clicks ground
        ↓
   [CLIENT] Validates locally, sends to server
        ↓
   [SERVER] Validates request
        ↓
   [SERVER] Detects hits (GetPartBoundsInBox)
        ↓
   [SERVER] Applies knockback & ragdoll to victims
        ↓
   [SERVER] Broadcasts VFX position to ALL clients
        ↓
   [ALL CLIENTS] Spawn VFX visuals
```

---

## 🔧 Production Checklist

Before publishing:
- [ ] Set `DEBUG_HITBOX = false` in client script
- [ ] Adjust knockback/ragdoll values to your liking
- [ ] Test with multiple players
- [ ] Add damage system if needed (in server script)

---

## 💡 Adding Damage

In `SmashVFXHandler.server.lua`, find the `knockbackAndRagdoll` function and add:

```lua
local function knockbackAndRagdoll(character, hitPosition)
    -- ... existing code ...
    
    -- Add damage here:
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:TakeDamage(25) -- Deal 25 damage
    end
    
    -- ... rest of code ...
end
```

---

Enjoy your multiplayer smash ability! 🎮💥
