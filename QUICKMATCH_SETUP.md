# Quick Match System Setup

## Overview
The Quick Match system automatically finds and seats players at the best available table with a single button click.

## Priority System:
1. **First Priority**: Tables with one player waiting (join as opponent)
2. **Second Priority**: Empty tables (start new game)
3. **Never**: Tables with games in progress or full tables

## Files Created:

### 1. **QuickMatchServer.lua** (ServerScriptService)
- Handles quick match requests
- Finds best available table
- Teleports and seats players
- Returns success/failure messages

### 2. **QuickMatchClient.lua** (StarterPlayer > StarterPlayerScripts)
- Handles button clicks
- Shows feedback messages
- Implements cooldown system
- Provides visual feedback

### 3. **TableManager.lua** (Updated)
Added:
- Table state tracking (EMPTY, WAITING, COUNTDOWN, IN_GAME, ENDING)
- `getBestTableForQuickMatch()` method
- `isAvailableForQuickMatch()` method
- `getAvailableSeat()` method
- State update notifications

### 4. **PokerGameServerMulti.lua** (Updated)
- Now updates table states during game flow
- COUNTDOWN state when both players seated
- IN_GAME state when game starts
- ENDING state when game ends

## Explorer Hierarchy:

```
game
├── ServerScriptService
│   ├── TableManager (ModuleScript)
│   ├── PokerGameServerMulti (Script)
│   ├── CardOrientationFixerMulti (Script)
│   └── QuickMatchServer (Script) [NEW]
│
├── StarterPlayer
│   └── StarterPlayerScripts
│       ├── PokerGameClientMulti (LocalScript)
│       ├── GameStartScriptMulti (LocalScript)
│       ├── TableCameraScriptMulti (LocalScript)
│       └── QuickMatchClient (LocalScript) [NEW]
│
├── StarterGui
│   └── QuickMatchUI (ScreenGui) [USER CREATED]
│       ├── QuickMatchBtn (TextButton) [USER CREATED]
│       └── FeedbackLabel (TextLabel) [AUTO-CREATED BY SCRIPT]
│
├── ReplicatedStorage
│   ├── SoundManager (ModuleScript)
│   ├── QuickMatchFunction (RemoteFunction) [AUTO-CREATED]
│   └── RemoteEvents (Folder)
│       ├── Table1 (Folder)
│       │   ├── CardClick (RemoteEvent)
│       │   ├── GameStateUpdate (RemoteEvent)
│       │   ├── TurnUpdate (RemoteEvent)
│       │   └── CardFlip (RemoteEvent)
│       └── ... (Table2-Table10 with same structure)
│
└── Workspace
    ├── Table1Folder
    │   ├── Table1 (UnionPart with cards)
    │   ├── Player1Chair (Model)
    │   │   └── Seat (Seat)
    │   ├── Player2Chair (Model)
    │   │   └── Seat (Seat)
    │   └── CameraPartTable1 (Part)
    └── ... (Table2Folder-Table10Folder with same structure)
```

## Table States:

1. **EMPTY** - No players seated
2. **WAITING_FOR_PLAYER** - One player seated, waiting for opponent
3. **COUNTDOWN** - Both players seated, countdown in progress
4. **IN_GAME** - Game is actively being played
5. **ENDING** - Game is ending, cleanup in progress

## How It Works:

1. Player clicks Quick Match button
2. Client sends request to server
3. Server checks if player is already seated
4. Server finds best available table:
   - Prioritizes tables with one waiting player
   - Falls back to empty tables
5. Server teleports player above seat
6. Server seats player automatically
7. Client shows success/failure message

## Features:

- **Smart Matching**: Prioritizes joining existing waiting players
- **Safe Teleportation**: Unseats from current seat first
- **Error Handling**: Validates player state before matching
- **Feedback System**: Clear success/failure messages
- **Cooldown System**: Prevents spam clicking (2 second cooldown)
- **Visual Feedback**: Button state changes during matching
- **Hover Effects**: Button highlights on hover

## Testing:

1. Click Quick Match when no tables are occupied → Should seat at Table1
2. Have Player1 sit at Table3, Player2 clicks Quick Match → Should seat at Table3
3. Click Quick Match while already seated → Should show error message
4. Click Quick Match rapidly → Should show cooldown message