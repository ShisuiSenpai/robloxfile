# Rotating Kill Part Setup Instructions

## How to Set Up the Rotating Kill Cylinder in Roblox Studio

### Step 1: Create the Cylinder Part
1. Open Roblox Studio and your game
2. In the Explorer window, find "Workspace"
3. Right-click on Workspace and select "Insert Object" > "Part"
4. Select the newly created part
5. In the Properties window, change:
   - **Shape**: Set to "Cylinder"
   - **Name**: Change to "KillCylinder" (or any name you prefer)
   - **Size**: Adjust to your desired size (e.g., 10, 4, 10 for a medium cylinder)
   - **Position**: Place it where you want in your game
   - **Anchored**: Check this box (✓) to keep it in place

### Step 2: Add the Script
1. Right-click on your cylinder part in the Explorer
2. Select "Insert Object" > "Script"
3. Delete the default code in the script
4. Copy all the code from `RotatingKillPart.lua`
5. Paste it into the script
6. The script will automatically start working!

### Step 3: Customize (Optional)
You can modify these values at the top of the script:
- **ROTATION_SPEED**: Change from 50 to make it spin faster or slower
- **RESPAWN_TIME**: Currently set to 3 seconds
- **Color**: Change `BrickColor.new("Really red")` to any color you want
- **Material**: Change from Neon to any other material

### Alternative Setup Method
If you want multiple kill parts with the same behavior:
1. Put the script in ServerScriptService instead
2. Modify the first line to: `local part = workspace.KillCylinder` (or your part's name)
3. You can duplicate and rename parts, then create multiple scripts

### Testing
1. Click "Play" or "Play Here" to test
2. Walk your character into the spinning cylinder
3. Your character should die on contact
4. The cylinder should be continuously rotating

### Troubleshooting
- **Part not rotating**: Make sure Anchored is checked
- **Player not dying**: Check that the script is a child of the part or properly references it
- **Too fast/slow**: Adjust ROTATION_SPEED value
- **Part falling**: Make sure Anchored property is true

### Features Included
- ✅ Smooth continuous rotation
- ✅ Instant kill on touch
- ✅ Red glowing appearance (Neon material)
- ✅ Particle effects for visual enhancement
- ✅ Debounce system to prevent multiple kills
- ✅ Console logging when players are killed
- ✅ Clean disconnection when script is removed

Enjoy your rotating death trap!