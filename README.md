# Step to Victory - Roblox Game

A 4-player competitive game where players answer questions to advance along footstep paths.

## Recent Updates

### QuizUI Debug System
Added comprehensive debug system to identify UI positioning issues:
- **Client-side**: Automatic captures at key moments + F9 manual trigger
- **Server-side**: Chat commands for UI inspection (`/debugui`, `/debugui me`, `/debugui start/stop`)
- **Documentation**: See [`QUIZUI_DEBUG_GUIDE.md`](QUIZUI_DEBUG_GUIDE.md) for detailed usage
- **Purpose**: Identify why UI shifts left in-game vs Studio

## Project Structure

```
ServerScriptService/
├── Main.server.lua          -- Main server script
└── Modules/
    ├── GameManager.lua      -- Core game state management
    ├── SpawnManager.lua     -- Player spawn handling
    ├── IntermissionManager.lua -- Countdown and intermission logic
    └── PathManager.lua      -- Footstep path management

ReplicatedStorage/
├── RemoteEvents/
│   ├── UpdateIntermission   -- Intermission countdown updates
│   ├── FreezePlayer        -- Player movement control
│   └── MoveToFootstep      -- Footstep movement commands
└── Modules/
    └── GameConstants.lua    -- Shared game constants

StarterGui/
└── IntermissionGui/
    ├── Frame/
    │   └── TextLabel       -- Countdown display
    └── LocalScript         -- GUI handler

StarterPlayer/
└── StarterPlayerScripts/
    └── ClientController.lua -- Client-side logic
```

## Game Setup Instructions

1. Create the spawn locations in Workspace:
   - Create a folder named "Spawns" in Workspace
   - Add 4 SpawnLocation parts named "SpawnLocation1" through "SpawnLocation4"

2. Create the footstep paths:
   - Create folders "Footsteps1" through "Footsteps4" in Workspace
   - In each folder, add 6 parts named "Footstep1" through "Footstep6"
   - Add footstep decals to each part

3. Place the scripts in their respective locations as shown in the structure above

## Features

- Maximum 4 players per game
- Unique spawn assignment system
- 5-second intermission with UI countdown
- Automatic player orientation toward their path
- Modular architecture for easy extension