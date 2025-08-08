# NPC Follow & Combat System for Roblox

A comprehensive NPC follow and combat system that allows NPCs to detect, follow, and attack players with a 5-hit combo system.

## Features

- **Smart NPC Detection**: NPCs detect players within a configurable radius using field of view and line-of-sight checks
- **Pathfinding**: Intelligent pathfinding with obstacle avoidance
- **Combat System**: 5-hit combo attacks with damage, knockback, and player stunning
- **Formation Movement**: Multiple NPCs can follow in formation (circle, semicircle, or random)
- **Visual Feedback**: Attack indicators, damage numbers, follower count UI, and proximity indicators
- **Performance Optimized**: Configurable NPC limits and cleanup systems

## Setup Instructions

### 1. Folder Structure

Create the following structure in your Roblox Studio:

```
ReplicatedStorage
└── NPCFollowModules
    └── NPCFollowConfig (ModuleScript)

ServerScriptService
└── NPCFollowServer (Script)

StarterPlayer
└── StarterPlayerScripts
    └── NPCFollowClient (LocalScript)

Workspace
└── NPCS (Folder)
    ├── NPC1 (Model with Humanoid and HumanoidRootPart)
    ├── NPC2 (Model with Humanoid and HumanoidRootPart)
    └── ... (more NPCs)
```

### 2. Installation Steps

1. **Copy the NPCFollowConfig.lua** content into a ModuleScript in `ReplicatedStorage > NPCFollowModules`
2. **Copy the NPCFollowServer.lua** content into a Script in `ServerScriptService`
3. **Copy the NPCFollowClient.lua** content into a LocalScript in `StarterPlayer > StarterPlayerScripts`
4. **Create NPC models** in the `Workspace > NPCS` folder

### 3. NPC Model Requirements

Each NPC model must have:
- A **Humanoid** object
- A **HumanoidRootPart** (or Torso for R6)
- Standard Roblox character parts (Head, Torso/UpperTorso, etc.)

## Configuration

Edit the `NPCFollowConfig` module to customize the system:

### Key Combat Settings
```lua
ENABLE_COMBAT_SYSTEM = true -- Enable/disable combat
ATTACK_RANGE = 5 -- Distance NPCs can attack from
COMBO_HIT_COUNT = 5 -- Number of hits in combo
DAMAGE_PER_HIT = 10 -- Damage per hit
PLAYER_STUN_DURATION = 0.2 -- Stun time per hit
```

### Detection Settings
```lua
DETECTION_RADIUS = 30 -- Detection range
FIELD_OF_VIEW = 120 -- NPC vision cone
LOSE_INTEREST_RADIUS = 60 -- When to stop following
```

### Performance Settings
```lua
MAX_ACTIVE_NPCS = 10 -- Max NPCs following at once
DEBUG_MODE = true -- Enable debug prints
```

## Troubleshooting

### NPCs are despawning/disappearing

The system has been fixed to prevent this by:
1. Setting NPC health to `math.huge` (infinite)
2. Disabling `BreakJointsOnDeath`
3. Preventing the dead state
4. Ensuring NPCs stay in their folder

### NPCs not detecting players

Check:
1. NPCs are in the `Workspace > NPCS` folder
2. NPCs have proper Humanoid and HumanoidRootPart
3. Detection radius is large enough
4. Field of view includes the player
5. No obstacles blocking line of sight

### Combat not working

Verify:
1. `ENABLE_COMBAT_SYSTEM = true` in config
2. NPCs can get within `ATTACK_RANGE` (5 studs)
3. Player has a Humanoid with health

### Performance issues

Try:
1. Reducing `MAX_ACTIVE_NPCS`
2. Increasing `DETECTION_CHECK_INTERVAL`
3. Disabling `SHOW_PATHFINDING_WAYPOINTS`
4. Reducing `DETECTION_RADIUS`

## How the Combat System Works

1. **Detection Phase**: NPC detects player within radius
2. **Follow Phase**: NPC pathfinds and follows player
3. **Attack Phase**: When in range, NPC stops and begins combo
4. **Combo Sequence**:
   - Telegraph attack (orange indicator)
   - Deal damage with knockback
   - Stun player briefly
   - Repeat for 5 hits
   - Cooldown before next combo

## Customization Tips

### Change combo behavior
- Adjust `COMBO_HIT_COUNT` for more/fewer hits
- Modify `HIT_INTERVAL` for faster/slower combos
- Change `KNOCKBACK_FORCE` for stronger pushback

### Modify NPC behavior
- Set `MAX_FOLLOW_TIME` to make NPCs give up
- Enable `IDLE_RETURN_TO_START` to make them return home
- Adjust `FORMATION_TYPE` for group following patterns

### Visual customization
- Change `ATTACK_INDICATOR_COLOR` for different warning colors
- Modify `TINT_COLOR_WHEN_FOLLOWING` for NPC appearance
- Toggle `SHOW_ATTACK_INDICATOR` for visibility

## Debug Commands

Enable `DEBUG_MODE = true` in config to see:
- NPC state changes
- Combat events
- Pathfinding status
- Detection events

## Known Limitations

1. No attack animations (uses indicators instead)
2. Simple stun system (just stops movement)
3. Basic AI (no advanced tactics)
4. No damage types or resistances

## Future Improvements

- Attack animations
- Different attack patterns
- Ranged attacks
- NPC health bars
- Team system
- Loot drops
- Experience/leveling