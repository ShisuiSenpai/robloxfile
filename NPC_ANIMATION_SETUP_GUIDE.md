# NPC Animation Setup Guide

## The Animation Problem & Solution

The issue you're experiencing is that `Humanoid.MoveDirection` remains at `0,0,0` even when NPCs are moving via `Humanoid:MoveTo()`. This prevents the Animate script from detecting movement and playing walk/run animations.

## Fixed Scripts

I've fixed the "Fire is not a valid member" error and created several solutions:

### 1. **NPCAnimationDiagnostic.lua** (Fixed)
- No longer tries to `Fire()` the Running event
- Now properly diagnoses movement issues
- Shows when MoveDirection is incorrectly zero

### 2. **NPCAnimationFixer.lua** (Fixed)
- Monitors NPC movement
- Adds debug visualization
- No longer has the Fire() error

### 3. **NPCAnimationSimpleFix.lua** (NEW - Recommended)
- Uses BodyVelocity to ensure physics simulation
- Helps the Humanoid detect movement
- Should make animations work automatically

### 4. **NPCMovementFixer.lua** (NEW - Alternative)
- Provides a complete movement replacement
- Uses BodyVelocity for movement
- Can be integrated with NPCFollowServer

## How to Set Up NPC Animations

### Step 1: NPC Model Structure
Your NPC model should have:
```
NPC (Model)
├── HumanoidRootPart (Part)
├── Head (Part)
├── Torso/UpperTorso (Part)
├── Left Arm/LeftUpperArm (Part)
├── Right Arm/RightUpperArm (Part)
├── Left Leg/LeftUpperLeg (Part)
├── Right Leg/RightUpperLeg (Part)
├── Humanoid (Humanoid)
│   └── Animator (Animator) - Will be created automatically
└── Animate (Script) - Your animation script
    ├── idle (StringValue)
    │   └── Animation1 (Animation)
    ├── walk (StringValue)
    │   └── WalkAnim (Animation)
    ├── run (StringValue)
    │   └── RunAnim (Animation)
    └── ... other animations
```

### Step 2: Place the Animate Script
- The Animate script should be a direct child of the NPC model
- It should be a Script (not LocalScript) for NPCs
- The script needs the animation StringValues as children

### Step 3: Use the Animation Fix Scripts

Place these scripts in ServerScriptService:

1. **NPCAnimationSimpleFix.lua** - Main animation fixer (recommended)
2. **NPCAnimationDiagnostic.lua** - For debugging (optional)
3. **NPCAnimateSetupComplete.lua** - Ensures proper setup

### Step 4: Testing

1. Start the game
2. Check the output for setup confirmations
3. When NPCs move, you should see:
   - Movement detection messages
   - Animation fix messages
   - NPCs playing walk/run animations

## Troubleshooting

### If animations still don't work:

1. **Check the Animate script placement**
   - Must be inside the NPC model
   - Must be a Script (not LocalScript)

2. **Verify animation IDs**
   - The Animation objects inside the StringValues must have valid AnimationIds
   - Use Roblox's default animation IDs or your own uploaded animations

3. **Enable Debug Mode**
   - Set `DEBUG_MODE = true` in NPCFollowConfig
   - Check the output for detailed movement information

4. **Try the NPCMovementFixer**
   - This provides an alternative movement system
   - Can be integrated if the simple fix doesn't work

## Alternative: Manual Animation Control

If the Animate script approach doesn't work, you can manually control animations:

```lua
-- In NPCFollowServer, after movement:
local animator = humanoid:FindFirstChild("Animator")
if animator then
    local walkAnim = animator:LoadAnimation(walkAnimationObject)
    if speed > 0.5 then
        if not walkAnim.IsPlaying then
            walkAnim:Play()
        end
    else
        walkAnim:Stop()
    end
end
```

## Current Status

- ✅ Fixed "Fire is not a valid member" error
- ✅ Created multiple animation fix approaches
- ✅ Added debug tools
- ⏳ Waiting for you to test with NPCAnimationSimpleFix.lua

The NPCAnimationSimpleFix.lua script should resolve your animation issues by ensuring the physics system properly detects NPC movement.