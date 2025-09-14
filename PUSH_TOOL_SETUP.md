# Push Tool Setup Guide

## 🎮 What It Does

The Push tool allows you to push other players who are in front of you, causing them to:
1. Get pushed back with physics force
2. Ragdoll realistically for 1.5 seconds
3. Automatically stand back up

## 📁 File Setup

### 1. **LocalScript** (`PushToolScript.lua`)
- Place this as a **LocalScript** inside the Push tool
- Path: `StarterPack > Push > LocalScript`

### 2. **ServerScript** (`PushServerScript.lua`)
- Place this in **ServerScriptService**
- Path: `ServerScriptService > PushServerScript`

## 🔧 How It Works

### Detection System:
- **Range**: 8 studs in front of you
- **Angle**: 45-degree cone (realistic field of view)
- **Target**: Closest player in front
- **Smart Detection**: Only pushes players you're actually facing

### Push Mechanics:
1. Click with tool equipped
2. Finds closest player in front (within range/angle)
3. Sends request to server (secure)
4. Server validates and applies push
5. Target gets pushed and ragdolls
6. After 1.5 seconds, they stand back up

## ⚙️ Configuration

### In LocalScript:
```lua
PUSH_RANGE = 8        -- Detection distance (studs)
PUSH_ANGLE = 45       -- Field of view (degrees)
PUSH_FORCE = 50       -- Push strength
RAGDOLL_DURATION = 1.5 -- Ragdoll time (seconds)
COOLDOWN_TIME = 1     -- Time between pushes
```

### In ServerScript:
```lua
RAGDOLL_DURATION = 1.5    -- Match with LocalScript
MAX_PUSH_DISTANCE = 10    -- Anti-exploit max range
```

## 🛡️ Security Features

- **Server Validation**: All pushes validated on server
- **Distance Check**: Prevents long-range exploits
- **Tool Check**: Verifies pusher has tool equipped
- **Cooldown System**: Prevents spam
- **Force Limit**: Caps maximum push force

## 🎯 Performance Optimizations

1. **Efficient Detection**: Only checks players, not all parts
2. **Dot Product Math**: Fast angle calculations
3. **Debounced Events**: Prevents spam and lag
4. **Proper Cleanup**: Removes constraints after ragdoll
5. **Threaded Processing**: Non-blocking server operations

## 🎨 Visual Features

- **Push Effect**: Blue force field beam shows push direction (optional)
- **Color Feedback**: Visual indication when pushing
- **Smooth Physics**: Natural-looking push and ragdoll

## 🎮 Usage Tips

### For Players:
- Get close to target (within 8 studs)
- Face them directly
- Click to push
- 1 second cooldown between pushes

### For Developers:
- Adjust `PUSH_RANGE` for different game styles
- Modify `PUSH_FORCE` for stronger/weaker pushes
- Change `RAGDOLL_DURATION` for longer/shorter ragdoll

## 🐛 Troubleshooting

**Push not working?**
- Check tool is named exactly "Push"
- Ensure scripts are in correct locations
- Verify RemoteEvent is created

**Players not ragdolling?**
- Check Humanoid exists
- Ensure character has proper joints
- Verify server script is running

**Too much/little force?**
- Adjust `PUSH_FORCE` value
- Modify `BodyVelocity.MaxForce`

## 📊 How Ragdoll Works

1. **Disable Motor6D joints** (except RootJoint)
2. **Create BallSocketConstraints** for realistic physics
3. **Enable collision** on body parts
4. **Set PlatformStand** to true
5. **After duration**, reverse all changes
6. **Apply small upward force** to help standing

This creates a realistic, optimized push system perfect for fun gameplay interactions!