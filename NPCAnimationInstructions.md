# NPC Animation Setup Instructions

## How to Set Up Animations for NPCs

### 1. Placing the Animate Script
The `Animate` script should be placed **directly inside each NPC model**, at the same level as the Humanoid.

**Correct hierarchy:**
```
Workspace
└── NPCS
    └── YourNPCModel
        ├── Humanoid
        ├── HumanoidRootPart
        ├── Head
        ├── Torso/UpperTorso
        ├── [Other body parts...]
        └── Animate (Script) ← Place here, NOT inside Humanoid
            ├── idle
            ├── walk
            ├── run
            └── [Other animation StringValues...]
```

### 2. Converting LocalScript to Script
If your Animate script is a LocalScript (taken from a player character), you need to convert it:
- The `NPCAnimateSetupComplete` script will automatically do this for you
- It will convert any LocalScript named "Animate" into a regular Script
- This is necessary because LocalScripts don't run on NPCs on the server

### 3. Required Scripts
Make sure you have these scripts running in ServerScriptService:
1. `NPCFollowServer` - Main NPC following logic
2. `NPCAnimateSetupComplete` - Handles animation setup and movement detection
3. Remove or disable `NPCAnimationDiagnostic` and `NPCAnimationFixer` (old versions)

### 4. How It Works
The animation system now works as follows:
1. `NPCAnimateSetupComplete` monitors each NPC's movement
2. When movement is detected, it determines if the NPC should walk or run
3. It ensures the Humanoid is in the correct state for animations
4. The Animate script then plays the appropriate animation automatically

### 5. Troubleshooting
If animations still don't work:
- Check that the Animate script has animation StringValues as children
- Ensure animation IDs in those StringValues are valid
- Make sure NPCs have all required body parts (Head, Torso, limbs)
- Enable `DEBUG_MODE` in `NPCFollowConfig` to see detailed logs
- Check the Output window for any error messages

### 6. Common Issues
- **"Fire is not a valid member"** - Fixed in the updated scripts
- **Animations not playing** - The movement handler now properly triggers animations
- **NPCs wobbling** - Adjust `AVOIDANCE_FORCE` and `PATH_UPDATE_INTERVAL` in config