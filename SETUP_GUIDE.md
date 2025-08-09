# Step to Victory - Complete Setup Guide

## Overview
This guide will help you set up the "Step to Victory" game in Roblox Studio. The game supports up to 4 players who spawn at unique locations, face a 5-second intermission, and then move to their first footstep.

## Step 1: Create the Workspace Structure

### 1.1 Create Spawn Locations
1. In the Explorer, right-click on `Workspace`
2. Create a new Folder named `Spawns`
3. Inside the `Spawns` folder, create 4 SpawnLocation parts:
   - Name them: `SpawnLocation1`, `SpawnLocation2`, `SpawnLocation3`, `SpawnLocation4`
   - Position them at different locations in your game
   - Make sure they're spread out with enough space between them

### 1.2 Create Footstep Paths
1. In `Workspace`, create 4 folders named:
   - `Footsteps1`
   - `Footsteps2`
   - `Footsteps3`
   - `Footsteps4`

2. In each `Footsteps#` folder, create 6 parts:
   - Name them: `Footstep1`, `Footstep2`, `Footstep3`, `Footstep4`, `Footstep5`, `Footstep6`
   - Arrange them in a path leading away from the corresponding spawn location
   - Add footstep decals to make them visually distinct
   - Ensure each path is clearly associated with its spawn point

## Step 2: Set Up Scripts

### 2.1 ServerScriptService Structure
1. Create the following folder structure in `ServerScriptService`:
```
ServerScriptService/
├── Main.server.lua
└── Modules/
    ├── GameManager.lua
    ├── SpawnManager.lua
    ├── IntermissionManager.lua
    └── PathManager.lua
```

2. Copy the corresponding code files into each location

### 2.2 ReplicatedStorage Structure
1. Create the following in `ReplicatedStorage`:
```
ReplicatedStorage/
└── Modules/
    └── GameConstants.lua
```

2. The RemoteEvents folder will be created automatically when the game runs

### 2.3 Client-Side Setup

#### StarterGui Setup:
1. In `StarterGui`, create a ScreenGui named `IntermissionGui`
2. Set its properties:
   - Enabled: false
   - ResetOnSpawn: true

3. Add the following structure inside IntermissionGui:
   - Frame (child of IntermissionGui)
     - Size: {0.5, 0}, {0.15, 0}
     - Position: {0.25, 0}, {0.4, 0}
     - BackgroundColor3: Color3.new(0, 0, 0)
     - BackgroundTransparency: 0.3
     - BorderSizePixel: 0
   
   - TextLabel (child of Frame)
     - Size: {1, 0}, {1, 0}
     - Position: {0, 0}, {0, 0}
     - BackgroundTransparency: 1
     - Text: "Game will start in 5 seconds"
     - TextColor3: Color3.new(1, 1, 1)
     - TextScaled: true
     - Font: Enum.Font.SourceSansBold
     - TextStrokeTransparency: 0.5

4. Add the LocalScript `IntermissionGui.client.lua` as a child of the IntermissionGui

#### StarterPlayer Setup:
1. In `StarterPlayer/StarterPlayerScripts`, add:
   - `ClientController.lua`

## Step 3: Game Configuration

### 3.1 Adjust Game Settings
1. In `GameConstants.lua`, you can modify:
   - `MAX_PLAYERS`: Maximum players (default: 4)
   - `INTERMISSION_TIME`: Countdown duration (default: 5 seconds)
   - `FREEZE_TIME`: How long players are frozen (default: 5 seconds)

### 3.2 Position Your Spawns and Paths
1. Make sure each spawn location faces its corresponding footstep path
2. Space footsteps appropriately (recommended: 5-10 studs apart)
3. Ensure paths don't intersect or confuse players

## Step 4: Testing

### 4.1 Studio Testing
1. Open the Output window (View → Output)
2. Start a Play Solo test
3. You should see console messages showing:
   - Module initialization
   - Player spawn assignment
   - Intermission countdown
   - Player movement to first footstep

### 4.2 Multi-Player Testing
1. Test with multiple players using Test → Start
2. Select 2-4 players
3. Verify that each player:
   - Spawns at a unique location
   - Faces their path
   - Sees the intermission UI
   - Moves to their first footstep after 5 seconds

## Step 5: Extending the Game

The modular architecture makes it easy to add features:

### Adding Question System
1. Create a new module: `QuestionManager.lua`
2. Add RemoteEvents for question display and answers
3. Integrate with `PathManager` to advance players

### Adding Visual Effects
1. Modify `PathManager:MovePlayerToFootstep()` to add particles
2. Add sound effects for movement
3. Highlight current footsteps

### Adding Win Conditions
1. Track player progress in `PathManager`
2. Detect when a player reaches `Footstep6`
3. Trigger win sequence and reset game

## Troubleshooting

### Common Issues:

1. **"Spawns folder not found"**
   - Ensure the `Spawns` folder exists in Workspace
   - Check spelling and capitalization

2. **Players not moving to footsteps**
   - Verify footstep folders and parts are named correctly
   - Check that footsteps are anchored

3. **UI not showing**
   - Ensure GUI structure matches the setup
   - Check that LocalScript is a child of IntermissionGui

4. **Players overlapping spawns**
   - This happens if the game is full (4 players already)
   - The system prevents more than 4 players

## Notes

- The game uses R6 compatibility (anchoring HumanoidRootPart when frozen)
- All modules use descriptive logging for debugging
- The system is designed to handle player disconnections gracefully
- RemoteEvents are created automatically on server start

Feel free to customize the visual appearance, add more features, or modify the game flow to suit your needs!