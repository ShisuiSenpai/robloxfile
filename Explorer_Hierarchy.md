# Roblox Studio Explorer Hierarchy

## Complete Setup Structure:

```
game
├── Workspace
│   └── RowBoat (Model)
│       ├── [Boat Parts] (Parts/MeshParts/etc.)
│       ├── Seat (Seat) - First seat
│       ├── Seat (Seat) - Second seat
│       └── Seat (Seat) - Third seat
│
├── ServerScriptService
│   └── BoatController (Script) - Copy the BoatController.lua content here
│
├── StarterPlayer
│   └── StarterPlayerScripts
│       └── RowingUI (LocalScript) - Copy the RowingUI.lua content here
│
└── ReplicatedStorage
    └── BoatRowingEvent (RemoteEvent) - Created automatically by the server script
```

## Setup Instructions:

1. **Create the Boat Model:**
   - Make sure your boat model is named exactly "RowBoat" in Workspace
   - Ensure all three seats inside the boat are named "Seat"
   - Optionally set a PrimaryPart for the boat model (any part of the boat)

2. **Add the Server Script:**
   - In ServerScriptService, create a new Script
   - Name it "BoatController"
   - Copy the entire content from BoatController.lua into this script

3. **Add the Client Script:**
   - In StarterPlayer > StarterPlayerScripts, create a new LocalScript
   - Name it "RowingUI"
   - Copy the entire content from RowingUI.lua into this script

4. **The RemoteEvent:**
   - The RemoteEvent "BoatRowingEvent" will be created automatically in ReplicatedStorage when the server script runs

## Features:

- **Automatic Seat Detection:** The system automatically detects when players sit in any of the three seats
- **Synchronized Rowing:** Multiple players can row together to increase speed
- **Dynamic UI:** Keys spawn from right to left at configurable intervals
- **Speed Feedback:** Visual speed bar changes color based on current speed
- **Smooth Movement:** Boat moves forward only, maintaining its original orientation
- **Configurable Settings:** Easy to adjust speed limits, key spawn rates, and other parameters

## Configuration Options (in scripts):

**Server Script (BoatController):**
- `MAX_SPEED = 50` - Maximum boat speed
- `BASE_SPEED = 5` - Minimum speed when occupied
- `SPEED_INCREASE_PER_CORRECT = 2` - Speed gain per correct key
- `SPEED_DECREASE_PER_INCORRECT = 3` - Speed loss per wrong key
- `SPEED_DECAY_RATE = 0.95` - Natural speed decay

**Client Script (RowingUI):**
- `KEY_SPAWN_INTERVAL = 0.8` - Time between key spawns
- `KEY_LIFETIME = 2.5` - How long keys stay on screen
- `POSSIBLE_KEYS` - Array of keys to use (currently left-side keyboard keys)