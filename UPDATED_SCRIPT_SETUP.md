# UPDATED Script Setup Instructions (With Win Tracking)

## Scripts to DELETE or DISABLE in Roblox Studio:
- PokerGameClient.lua
- GameStartScript.lua
- TableCameraScript.lua
- CardOrientationFixer.lua
- PokerGameServer.lua (**IMPORTANT: Make sure this is DELETED/DISABLED**)

## Scripts to USE (Multi-table versions):

### In ServerScriptService:
- PokerGameServerMulti.lua (Script)
- CardOrientationFixerMulti.lua (Script)
- TableManager.lua (ModuleScript)
- LeaderstatsManager.lua (ModuleScript) **NEW**
- LeaderboardDisplay.lua (Script) **NEW - Optional**
- QuickMatchServerV2.lua (Script)

### In StarterPlayer > StarterPlayerScripts:
- PokerGameClientMulti.lua (LocalScript)
- GameStartScriptMulti.lua (LocalScript)
- TableCameraScriptMulti.lua (LocalScript)
- QuickMatchClientV2_DisableVersion.lua (LocalScript)

### In ReplicatedStorage:
- SoundManager.lua (ModuleScript)

## CRITICAL: Disable Old Scripts
The error you're seeing is because the OLD PokerGameServer.lua is still running!
Make sure to:
1. Find PokerGameServer.lua in ServerScriptService
2. Either DELETE it or DISABLE it (change Disabled property to true)
3. Make sure ONLY PokerGameServerMulti.lua is enabled

## Folder Structure in Workspace:
```
Workspace
├── Table1Folder through Table10Folder
│   ├── TableX (UnionPart with cards as children)
│   ├── Player1Chair (Model with Seat part inside)
│   ├── Player2Chair (Model with Seat part inside)
│   └── CameraPartTableX (Part)
```

## RemoteEvents Structure in ReplicatedStorage:
```
ReplicatedStorage
├── RemoteEvents
│   ├── Table1 through Table10
│   │   ├── CardClick
│   │   ├── GameStateUpdate
│   │   ├── TurnUpdate
│   │   └── CardFlip
└── QuickMatchEvent
    ├── QuickMatchRequest (RemoteEvent)
    └── QuickMatchResponse (RemoteEvent)
```

## UI Structure in StarterGui:
```
StarterGui
├── PokerGameUI_Table (Folder)
│   ├── PokerGameUI_Table1 through PokerGameUI_Table10 (ScreenGuis - all disabled)
├── GameStartCountdown_Table (Folder)
│   ├── GameStartCountdown_Table1 through GameStartCountdown_Table10 (ScreenGuis - all disabled)
└── QuickMatchUI (ScreenGui with QuickMatchBtn)
```

## Verification Steps:
1. Check ServerScriptService - ONLY Multi versions should be there
2. Check that LeaderstatsManager shows in the Explorer as a ModuleScript
3. You should see "[LeaderstatsManager] Initialized" in the server output
4. Players should have a "Wins" stat in the leaderboard when they join