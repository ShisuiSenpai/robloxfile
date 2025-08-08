# NPC Combat System - Complete Setup Guide

## IMPORTANT: DO NOT CREATE ANY NEW FOLDERS!
The system will automatically find NPCs in your existing workspace structure.

## Explorer Hierarchy

```
game
├── Workspace
│   └── NPCS (Your existing folder with NPC models)
│       ├── Noob1 (Model)
│       │   ├── Humanoid
│       │   ├── HumanoidRootPart
│       │   └── [Other body parts]
│       ├── Noob2 (Model)
│       │   ├── Humanoid
│       │   ├── HumanoidRootPart
│       │   └── [Other body parts]
│       └── [More NPC models...]
│
├── ServerScriptService
│   └── NPCCombatServer (Script) ← NEW
│
├── StarterPlayer
│   └── StarterPlayerScripts
│       └── NPCCombatClient (LocalScript) ← NEW
│
└── ReplicatedStorage
    └── NPCRemotes (Folder) ← Created automatically
        ├── NPCDamage (RemoteEvent)
        └── NPCCombat (RemoteEvent)
```

## Step-by-Step Setup

### 1. Delete Old Scripts
First, delete these old scripts if they exist:
- ServerScriptService > NPCFollowServer
- StarterPlayer > StarterPlayerScripts > NPCFollowClient
- ReplicatedStorage > NPCFollowModules

### 2. Create Server Script
1. Right-click on `ServerScriptService`
2. Add Object > Script
3. Name it: `NPCCombatServer`
4. Delete the default code
5. Paste the contents from `NPCCombatServer.lua`

### 3. Create Client Script
1. Navigate to `StarterPlayer > StarterPlayerScripts`
2. Right-click and Add Object > LocalScript
3. Name it: `NPCCombatClient`
4. Delete the default code
5. Paste the contents from `NPCCombatClient.lua`

### 4. Your NPCs
Make sure your NPCs in `Workspace > NPCS` have:
- A Humanoid object
- A HumanoidRootPart (or Torso for R6)
- The name contains "npc" or "noob" (case insensitive)

## How It Works

1. **Server Script** (`NPCCombatServer`):
   - Automatically finds all NPCs in your workspace
   - No configuration needed - it searches common locations
   - Handles movement, pathfinding, and combat
   - Creates RemoteEvents for client communication

2. **Client Script** (`NPCCombatClient`):
   - Shows damage numbers
   - Displays attack warnings
   - Shows proximity indicators
   - Handles visual effects

## Configuration

Edit these values in `NPCCombatServer` to customize:

```lua
local CONFIG = {
    -- Detection
    DETECTION_RANGE = 50,      -- How far NPCs can see
    ATTACK_RANGE = 6,         -- Attack distance
    LOSE_RANGE = 100,         -- When to stop following
    
    -- Movement
    WALK_SPEED = 16,          -- Normal speed
    RUN_SPEED = 22,           -- Chase speed
    
    -- Combat
    DAMAGE_PER_HIT = 10,      -- Damage per hit
    HITS_IN_COMBO = 5,        -- Hits in combo
    HIT_DELAY = 0.3,          -- Time between hits
    COMBO_COOLDOWN = 2,       -- Time between combos
    STUN_DURATION = 0.2,      -- Stun per hit
    KNOCKBACK_POWER = 20,     -- Push force
}
```

## Testing

1. Run the game
2. Check the output - you should see:
   ```
   NPC Combat System loaded! Found X NPCs
   NPC Combat Client loaded!
   ```
3. Walk near an NPC (within 50 studs)
4. The NPC should start following you
5. When you get within 6 studs, it will attack

## Troubleshooting

### NPCs not moving?
- Check output for "NPC initialized: [name]" messages
- Ensure NPCs have Humanoid and HumanoidRootPart
- Make sure NPC names contain "npc" or "noob"

### No damage/effects?
- Check that RemoteEvents were created in ReplicatedStorage
- Ensure both scripts are running (check output)

### NPCs despawning?
- The new system sets NPC health to 500
- Disables death state
- Should prevent despawning

## Features

✅ Automatic NPC detection (no folder creation)
✅ Smart pathfinding with obstacle avoidance
✅ 5-hit combo system with knockback
✅ Visual indicators (proximity bars, damage numbers)
✅ Attack warnings and screen effects
✅ Server-authoritative combat
✅ No configuration files needed

## Tips

- NPCs will chase players who get within 50 studs
- They attack when within 6 studs
- Each combo does 50 total damage (10 per hit)
- Players are stunned during combos
- 2-second cooldown between combos
- NPCs return to idle if player gets 100+ studs away