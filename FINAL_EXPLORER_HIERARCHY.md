# Step to Victory - Complete Explorer Hierarchy

## Full Game Structure

```
game
├── Workspace
│   ├── Spawns (Folder)
│   │   ├── SpawnLocation1 (SpawnLocation)
│   │   ├── SpawnLocation2 (SpawnLocation)
│   │   ├── SpawnLocation3 (SpawnLocation)
│   │   └── SpawnLocation4 (SpawnLocation)
│   │
│   ├── Footsteps1 (Folder)
│   │   ├── Footstep1 (Part with decal)
│   │   ├── Footstep2 (Part with decal)
│   │   ├── Footstep3 (Part with decal)
│   │   ├── Footstep4 (Part with decal)
│   │   ├── Footstep5 (Part with decal)
│   │   └── Footstep6 (Part with decal)
│   │
│   ├── Footsteps2 (Folder)
│   │   └── [Same structure as Footsteps1]
│   │
│   ├── Footsteps3 (Folder)
│   │   └── [Same structure as Footsteps1]
│   │
│   └── Footsteps4 (Folder)
│       └── [Same structure as Footsteps1]
│
├── ServerScriptService
│   ├── Main.server.lua (Script)
│   └── Modules (Folder)
│       ├── GameManager.lua (ModuleScript)
│       ├── SpawnManager.lua (ModuleScript)
│       ├── IntermissionManager.lua (ModuleScript)
│       ├── PathManager.lua (ModuleScript)
│       ├── QuestionManager.lua (ModuleScript)
│       └── QuizController.lua (ModuleScript)
│
├── ReplicatedStorage
│   ├── Modules (Folder)
│   │   └── GameConstants.lua (ModuleScript)
│   └── RemoteEvents (Folder) [Created automatically]
│       ├── UpdateIntermission (RemoteEvent)
│       ├── FreezePlayer (RemoteEvent)
│       ├── SetMovementState (RemoteEvent)
│       ├── MoveToFootstep (RemoteEvent)
│       ├── ShowQuestion (RemoteEvent)
│       ├── SubmitAnswer (RemoteEvent)
│       ├── UpdateQuizTimer (RemoteEvent)
│       ├── ShowQuizResult (RemoteEvent)
│       └── AnnounceWinner (RemoteEvent)
│
├── StarterGui
│   ├── IntermissionGui (ScreenGui)
│   │   ├── Frame (Frame)
│   │   │   └── TextLabel (TextLabel)
│   │   └── IntermissionGui.client.lua (LocalScript)
│   │
│   └── QuizGui (ScreenGui)
│       ├── MainFrame (Frame)
│       │   ├── UICorner
│       │   ├── UIStroke
│       │   ├── QuestionFrame (Frame)
│       │   │   ├── UICorner
│       │   │   ├── CategoryLabel (TextLabel)
│       │   │   └── QuestionLabel (TextLabel)
│       │   ├── TimerFrame (Frame)
│       │   │   ├── UICorner
│       │   │   ├── TimerBar (Frame)
│       │   │   │   └── UICorner
│       │   │   └── TimerLabel (TextLabel)
│       │   └── AnswersFrame (Frame)
│       │       ├── UIGridLayout
│       │       ├── Answer1 (TextButton)
│       │       │   └── UICorner
│       │       ├── Answer2 (TextButton)
│       │       │   └── UICorner
│       │       ├── Answer3 (TextButton)
│       │       │   └── UICorner
│       │       └── Answer4 (TextButton)
│       │           └── UICorner
│       ├── ResultFrame (Frame)
│       │   ├── UICorner
│       │   ├── UIStroke
│       │   ├── ResultLabel (TextLabel)
│       │   └── CorrectAnswerLabel (TextLabel)
│       ├── WinnerFrame (Frame)
│       │   ├── UICorner
│       │   ├── UIStroke
│       │   └── WinnerLabel (TextLabel)
│       └── QuizGui.client.lua (LocalScript)
│
└── StarterPlayer
    └── StarterPlayerScripts
        └── ClientController.lua (LocalScript)
```

## Key Features

### 1. **Spawn System**
- 4 unique spawn locations
- Players face their assigned path
- No overlapping spawns

### 2. **Movement System**
- Players walk naturally to footsteps
- Smooth animations
- Perfect centering on footsteps

### 3. **Intermission System**
- 5-second countdown
- Players frozen during intermission
- Smooth UI transitions

### 4. **Quiz System**
- 6 difficulty levels matching footstep positions
- 15-second timer per question
- Multiple categories: Math, Science, Geography, History, Roblox, Cinema, Nature
- Random question selection
- Automatic progression when all players answer

### 5. **Victory System**
- Win by answering footstep 6 question correctly
- Winner announcement
- Game reset after victory

### 6. **UI Design**
- Modern, clean interface
- Smooth animations
- Color-coded feedback
- Responsive design

## Setup Instructions

1. Create all Workspace objects (Spawns and Footsteps folders with their parts)
2. Copy all scripts to their respective locations
3. Create the UI structures in StarterGui following the hierarchy
4. Test with 1-4 players

## Configuration

Edit `GameConstants.lua` to adjust:
- Player limits
- Timer durations
- Game states

Edit `QuestionManager.lua` to:
- Add more questions
- Modify difficulties
- Add new categories

The system is fully modular and extensible!