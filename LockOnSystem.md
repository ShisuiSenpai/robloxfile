# Roblox Lock-On System

## Explorer Hierarchy Setup

```
StarterPlayer
└── StarterPlayerScripts
    └── LockOnClient (LocalScript)

ServerScriptService
└── LockOnServer (Script) [OPTIONAL - Only for multiplayer sync]

ReplicatedStorage
├── LockOnRemotes (Folder) [OPTIONAL - Created by server script]
│   ├── RequestLockOn (RemoteEvent)
│   └── UpdateLockOn (RemoteEvent)
└── LockOnModules (Folder)
    └── LockOnConfig (ModuleScript)
```

## Features

### Basic Version (LockOnClient.lua)
- Left Ctrl to toggle lock-on
- Targets nearest Humanoid in view or proximity
- Custom target marker decal with rotation
- Smooth camera zoom effect
- Clean lock-on cancellation
- Optimized performance with proper cleanup

### Enhanced Version (LockOnClientEnhanced.lua)
- All basic features PLUS:
- Tab to switch between targets while locked
- Advanced visual effects:
  - Spinning outer ring
  - Counter-rotating inner crosshair
  - Orbiting particle effects with glow
  - Smooth animations and transitions
- Velocity prediction for smoother tracking
- Better target management

## Installation

1. **Create the folder structure in ReplicatedStorage:**
   - Create a folder named "LockOnModules"
   - Place LockOnConfig.lua inside it as a ModuleScript

2. **Set up the client script:**
   - Choose either LockOnClient.lua (basic) or LockOnClientEnhanced.lua (advanced)
   - Place your chosen script in StarterPlayer > StarterPlayerScripts
   - Name it "LockOnClient"

3. **Configure the system:**
   - Open LockOnConfig module
   - Replace the TARGET_DECAL_ID with your decal asset ID
   - Adjust any other settings as needed

4. **Optional multiplayer support:**
   - Only add LockOnServer.lua if you want other players to see lock-on indicators
   - Place it in ServerScriptService

## Configuration Options

All settings are in the LockOnConfig module:

- **Visual Settings**: Decal ID, marker size, transparency, color
- **Camera Settings**: Zoom FOV, zoom speed, tracking smoothness
- **Targeting Settings**: Max distance, angle threshold, target prioritization
- **Performance Settings**: Update rates for optimization
- **Input Settings**: Key bindings

## Usage

- **Press Left Ctrl** to lock onto the nearest valid target
- **Press Left Ctrl again** to cancel the lock
- **Press Tab** (enhanced version only) to switch between targets
- The system automatically unlocks if:
  - Target dies
  - Target moves out of range
  - Target is destroyed
  - Your character respawns

## Performance Notes

- The basic version is highly optimized for minimal performance impact
- The enhanced version adds visual flair but uses more resources
- Both versions use proper cleanup to prevent memory leaks
- Target scanning is throttled to maintain good FPS

## Customization Tips

1. **Change the marker appearance**: Edit createTargetMarker() function
2. **Add sound effects**: Add sound playing in startLockOn/cancelLockOn
3. **Modify target selection**: Adjust the scoring algorithm in findBestTarget()
4. **Add target filters**: Modify isTargetValid() to exclude certain targets
5. **Change controls**: Update the KeyCode values in the input handling section