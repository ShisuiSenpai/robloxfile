# CRITICAL: Fix Setup Issues

## The Problems:
1. **OLD PokerGameServer.lua is STILL RUNNING** (causing the infinite yield error)
2. **PokerGameServerMulti.lua is NOT RUNNING** (no initialization logs)
3. **TableManager is NOT INITIALIZING** (causing QuickMatch to fail)

## Immediate Actions Required:

### 1. DELETE/DISABLE Old Scripts in ServerScriptService:
- **PokerGameServer.lua** - DELETE or set Disabled = true
- Any other old single-table scripts

### 2. ENSURE These Scripts ARE in ServerScriptService:
Make sure these are ENABLED (Disabled = false):
- **PokerGameServerMulti.lua** (Script)
- **TableManager.lua** (ModuleScript)
- **WinsLeaderstat.lua** (Script)
- **CardOrientationFixerMulti.lua** (Script)
- **QuickMatchServerV2.lua** (Script)
- **WinStreakSystem.lua** (Script)
- **LeaderboardDisplay.lua** (Script - optional)

### 3. Check Script Types:
- ModuleScripts: TableManager.lua
- Regular Scripts: All others

### 4. Verify Output After Fix:
You should see these messages in server output:
```
[TableManager] Initialized table: Table1
[TableManager] Initialized table: Table2
... (up to Table10)
[TableManager] All tables initialized with player cleanup
[PokerGame] Monitoring setup complete for table: Table1
... (up to Table10)
[PokerGame] Multi-table server initialized
```

## Why This Happened:
- The old PokerGameServer.lua is interfering with the new system
- PokerGameServerMulti.lua might be disabled or not in the right place
- Without TableManager initialization, QuickMatch has no tables to work with

## Quick Test After Fix:
1. Restart server/game
2. Check server output for TableManager initialization
3. Try QuickMatch - it should work
4. Try sitting in chairs manually - game should start