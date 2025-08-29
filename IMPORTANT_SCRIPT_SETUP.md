# IMPORTANT: Script Setup Instructions

## Scripts to DELETE or DISABLE in Roblox Studio:
- PokerGameClient.lua
- GameStartScript.lua
- TableCameraScript.lua
- CardOrientationFixer.lua
- PokerGameServer.lua

## Scripts to USE (Multi-table versions):

### In ServerScriptService:
- PokerGameServerMulti.lua
- CardOrientationFixerMulti.lua
- TableManager.lua (ModuleScript)

### In StarterPlayer > StarterPlayerScripts:
- PokerGameClientMulti.lua
- GameStartScriptMulti.lua
- TableCameraScriptMulti.lua

### In ReplicatedStorage:
- SoundManager.lua (ModuleScript)

## Folder Structure in Workspace:
```
Workspace
├── Table1Folder
│   ├── Table1 (UnionPart with cards as children)
│   ├── Player1Chair (Model with Seat part inside)
│   ├── Player2Chair (Model with Seat part inside)
│   └── CameraPartTable1 (Part)
└── Table2Folder
    ├── Table2 (UnionPart with cards as children)
    ├── Player1Chair (Model with Seat part inside)
    ├── Player2Chair (Model with Seat part inside)
    └── CameraPartTable2 (Part)
```

## RemoteEvents Structure in ReplicatedStorage:
```
ReplicatedStorage
└── RemoteEvents
    ├── Table1
    │   ├── CardClick
    │   ├── GameStateUpdate
    │   ├── TurnUpdate
    │   └── CardFlip
    └── Table2
        ├── CardClick
        ├── GameStateUpdate
        ├── TurnUpdate
        └── CardFlip
```

Make sure you're ONLY using the Multi versions of the scripts!