# Disappearing Floors System Setup

## 🎮 What It Does

This system makes random floor parts in your Map folder temporarily disappear, creating a challenging platforming experience where players must be aware of which floors are about to vanish!

## 📋 Features

- **Random Selection**: Randomly selects parts from your Map folder to disappear
- **Warning System**: Parts change colors before disappearing:
  - 🟢 Lime Green → 🟡 Yellow → 🟠 Orange → 🔴 Red → Gone!
- **Smooth Transitions**: Parts fade out and fade back in smoothly
- **Fall Through**: When invisible, parts become non-collidable so players fall through
- **Automatic Respawn**: Parts reappear after a set time
- **Multiple Difficulty Modes**: Optional hard mode with multiple parts disappearing

## 🔧 Setup Instructions

1. **Place the Script**:
   - Put `DisappearingFloors.lua` in **ServerScriptService**
   - NOT in the Map folder itself

2. **Ensure Your Map Structure**:
   ```
   Workspace
   └── Map (Folder)
       ├── Part
       ├── Part
       ├── Part
       └── ... (more Part objects)
   ```

3. **Run the Game**:
   - The script will automatically find all parts named "Part" in the Map folder
   - Parts will start disappearing at random intervals

## ⚙️ Configuration Options

Edit these values at the top of the script:

```lua
MIN_TIME_BETWEEN_DISAPPEAR = 3  -- Minimum seconds between disappearances
MAX_TIME_BETWEEN_DISAPPEAR = 8  -- Maximum seconds between disappearances
WARNING_TIME = 2                -- How long the color warning lasts
DISAPPEAR_TIME = 3              -- How long parts stay invisible
RESPAWN_FADE_TIME = 1           -- How long to fade back in
```

## 🎯 How It Works

1. **Selection**: Every 3-8 seconds, a random part is selected
2. **Warning Phase** (2 seconds):
   - Part changes colors: Green → Yellow → Orange → Red
   - Part starts glowing (Neon material)
3. **Disappear Phase** (3 seconds):
   - Part fades to invisible
   - Becomes non-collidable (players fall through)
4. **Respawn Phase**:
   - Part fades back in
   - Becomes solid again
   - Returns to original color

## 🔥 Hard Mode (Optional)

To enable multiple parts disappearing simultaneously:

1. Find this line in the script:
   ```lua
   local HARD_MODE = false
   ```
2. Change it to:
   ```lua
   local HARD_MODE = true
   ```
3. Adjust maximum simultaneous disappearing parts:
   ```lua
   local MAX_SIMULTANEOUS = 3  -- Up to 3 parts at once
   ```

## 🎮 Gameplay Tips for Players

- **Watch for Green**: When a part turns green, get ready to move!
- **Red = Danger**: When it's red, jump to safety immediately
- **Listen**: Consider adding sound effects for audio cues
- **Pattern Recognition**: Parts are chosen randomly, no pattern to memorize

## 🐛 Troubleshooting

**Parts not disappearing?**
- Check that your folder is named exactly "Map" in Workspace
- Ensure parts are named "Part" (case-sensitive)
- Check the Output window for error messages

**All parts disappearing at once?**
- Make sure HARD_MODE is set to false if you don't want this

**Parts not reappearing?**
- Check that nothing else is deleting the parts
- Ensure the script is in ServerScriptService

## 📊 Console Output

The script will print:
- Number of parts found
- When a part is selected to disappear
- Configuration values on startup

This creates an exciting challenge where players must stay alert and react quickly to survive!