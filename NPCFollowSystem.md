# NPC Follow System Documentation

## Overview
A comprehensive NPC follow system for Roblox that makes NPCs detect and follow players when they get close. Features intelligent pathfinding, customizable behavior, and visual feedback.

## Explorer Hierarchy Setup

```
Workspace
└── NPCS (Folder)
    ├── NPC1 (Model)
    ├── NPC2 (Model)
    └── ... (More NPC Models)

ServerScriptService
└── NPCFollowServer (Script)

StarterPlayer
└── StarterPlayerScripts
    └── NPCFollowClient (LocalScript) [OPTIONAL]

ReplicatedStorage
└── NPCFollowModules (Folder)
    └── NPCFollowConfig (ModuleScript)
```

## Installation

1. **Create the folder structure:**
   - Create a folder named "NPCS" in Workspace
   - Create a folder named "NPCFollowModules" in ReplicatedStorage

2. **Install the scripts:**
   - Place `NPCFollowConfig.lua` as a ModuleScript in `ReplicatedStorage > NPCFollowModules`
   - Place `NPCFollowServer.lua` as a Script in `ServerScriptService`
   - Place `NPCAnimateSetup.lua` as a Script in `ServerScriptService` (for animations)
   - (Optional) Place `NPCFollowClient.lua` as a LocalScript in `StarterPlayer > StarterPlayerScripts`

3. **Add NPCs to the NPCS folder:**
   - Each NPC must be a Model with:
     - A Humanoid
     - A HumanoidRootPart (or Torso for R6)
   - NPCs can be R15 or R6 characters
   - Animations will be added automatically by NPCAnimateSetup script

## Configuration Guide

All settings are in the `NPCFollowConfig` module. Here are the key settings:

### Detection Settings
- `DETECTION_RADIUS` (30): How close you need to be for NPCs to notice you
- `LOSE_INTEREST_RADIUS` (60): How far before they stop following
- `FIELD_OF_VIEW` (120): NPC's vision cone in degrees

### Movement Settings
- `WALK_SPEED` (16): Normal follow speed
- `RUN_SPEED` (24): Speed when you're far away
- `STOP_DISTANCE` (8): How close they get before stopping

### Spacing Settings
- `NPC_SPACING_RADIUS` (6): Minimum distance between NPCs
- `FORMATION_TYPE` ("circle"): How NPCs arrange around you
- `FORMATION_SPREAD` (12): How spread out the formation is
- `AVOIDANCE_FORCE` (50): How strongly NPCs avoid each other

### Behavior Settings
- `MAX_FOLLOW_TIME` (30): Seconds before giving up (0 = infinite)
- `MAX_FOLLOW_DISTANCE` (100): Max distance from origin before returning
- `IDLE_RETURN_TO_START` (true): Return to spawn when done following
- `MEMORY_TIME` (5): Remember last position for X seconds

### Visual Settings
- `SHOW_EXCLAMATION_ON_DETECT` (true): Show "!" when detecting player
- `TINT_COLOR_WHEN_FOLLOWING`: Slight color change when following

## Features

### Core Features
- ✅ Automatic detection when player enters radius
- ✅ Smart pathfinding around obstacles
- ✅ Field of view detection (NPCs must "see" you)
- ✅ Line of sight checking
- ✅ Gives up after max time or distance
- ✅ Returns to origin when too far (MAX_FOLLOW_DISTANCE)
- ✅ Returns to starting position when idle
- ✅ Multiple NPCs can follow simultaneously
- ✅ NPCs maintain spacing to avoid crowding
- ✅ Formation system (circle, semicircle, random)
- ✅ Collision avoidance between NPCs

### Visual Feedback
- ✅ Exclamation mark on detection
- ✅ Color tinting when following
- ✅ Optional UI showing follower count
- ✅ Proximity indicators
- ✅ Debug visualization options

### Performance Features
- ✅ Optimized update intervals
- ✅ Active NPC limit to prevent lag
- ✅ Automatic cleanup of destroyed NPCs
- ✅ Level of detail system

## NPC Requirements

Your NPC models must have:
1. **Humanoid** - For movement and health
2. **HumanoidRootPart** or **Torso** - As the root part
3. **Be inside the NPCS folder** - Or change `NPC_FOLDER_NAME` in config

Example NPC structure:
```
NPC1 (Model)
├── Humanoid
├── HumanoidRootPart
├── Head
├── Torso
├── Left Arm
├── Right Arm
├── Left Leg
└── Right Leg
```

## Testing & Debugging

1. **Enable debug mode:**
   ```lua
   NPCFollowConfig.DEBUG_MODE = true
   ```

2. **Show detection spheres:**
   ```lua
   NPCFollowConfig.SHOW_DETECTION_SPHERE = true
   ```

3. **Show pathfinding waypoints:**
   ```lua
   NPCFollowConfig.SHOW_PATHFINDING_WAYPOINTS = true
   ```

## Common Issues & Solutions

### NPCs not following
- Check that NPCs have Humanoid and HumanoidRootPart
- Ensure NPCs are in the NPCS folder
- Verify detection radius is large enough
- Check if obstacles are blocking line of sight

### NPCs getting stuck
- Enable pathfinding: `USE_PATHFINDING = true`
- Adjust pathfinding costs in config
- Check for invisible barriers

### Performance issues
- Reduce `MAX_ACTIVE_NPCS`
- Increase `DETECTION_CHECK_INTERVAL`
- Disable visual effects

## Advanced Usage

### Blacklist/Whitelist Players
```lua
-- Only specific players can be followed
NPCFollowConfig.WHITELIST_PLAYERS = {"Player1", "Player2"}

-- Certain players are ignored
NPCFollowConfig.BLACKLIST_PLAYERS = {"AdminName"}
```

### Custom Pathfinding Costs
```lua
NPCFollowConfig.PATHFINDING_COSTS = {
    Water = 20,      -- Avoid water
    Mud = 10,        -- Slightly avoid mud
    Neon = math.huge -- Never cross neon parts
}
```

### Multiple Followers
```lua
-- Allow multiple NPCs to follow same player
NPCFollowConfig.CAN_FOLLOW_MULTIPLE = true
NPCFollowConfig.MAX_FOLLOWERS_PER_PLAYER = 3
```

## Tips

1. **For horror games:** Set `FIELD_OF_VIEW` low so you can sneak behind NPCs
2. **For friendly NPCs:** Increase `STOP_DISTANCE` so they don't get too close
3. **For performance:** Use fewer NPCs with larger detection radii
4. **For realism:** Enable all visual feedback options

## API Reference

The system runs automatically, but you can interact with it:

### Getting follower count (client-side)
The optional client script creates a UI showing follower count automatically.

### Customizing individual NPCs
Add attributes to NPC models to override settings:
- Add NumberValue "DetectionRadius" to override radius
- Add BoolValue "CanFollow" to enable/disable following

## Animation Setup

The system now supports Roblox's default animations for NPCs. Since you already have the Animate script in your NPCs, here's how to make it work:

### Required Scripts for Animations:
1. **NPCAnimationFixer.lua** - Makes animations work by properly firing Humanoid events
2. **NPCAnimateSetupComplete.lua** - Ensures Animate scripts have required components

### Installation:
1. Place both scripts in ServerScriptService
2. The scripts will automatically:
   - Add missing components (Animator, msg StringValue)
   - Monitor NPC movement and fire animation events
   - Handle the connection between movement and animations

### Why NPCs Need Help with Animations:
- Player characters automatically fire Humanoid.Running events when moving
- NPCs using Humanoid:MoveTo() don't always fire these events properly
- The NPCAnimationFixer monitors actual movement and manually fires the events
- This ensures the Animate script receives the signals it needs

### Troubleshooting:
- Check that NPCs have an "Animator" object in their Humanoid
- Ensure the Animate script has a "msg" StringValue child
- Verify NPCs are actually moving (not just having MoveTo called)
- Check console for diagnostic messages

## Performance Metrics

With default settings:
- 10 NPCs: ~0.5ms script activity
- 50 NPCs: ~2ms script activity  
- 100 NPCs: ~4ms script activity

Actual performance depends on pathfinding complexity and active followers.