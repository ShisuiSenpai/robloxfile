# FINAL Setup Guide - Poker Game with Win Tracking

## CRITICAL FIRST STEP:
**DELETE or DISABLE the old PokerGameServer.lua in ServerScriptService!**
The error shows this old script is still running and breaking the game.

## Scripts to Place in ServerScriptService:

### Regular Scripts:
1. **WinsLeaderstat.lua** (NEW - Simple wins tracking)
2. **PokerGameServerMulti.lua**
3. **CardOrientationFixerMulti.lua**
4. **QuickMatchServerV2.lua**
5. **LeaderboardDisplay.lua** (Optional - for physical leaderboard)

### ModuleScripts:
1. **TableManager.lua**

### Scripts to DELETE/REMOVE:
- **LeaderstatsManager.lua** (the complex one that wasn't working)
- **PokerGameServer.lua** (OLD single-table version)
- **DebugLeaderstats.lua** (was just for testing)

## Scripts in StarterPlayer > StarterPlayerScripts:
1. **PokerGameClientMulti.lua**
2. **GameStartScriptMulti.lua**
3. **TableCameraScriptMulti.lua**
4. **QuickMatchClientV2_DisableVersion.lua**

## In ReplicatedStorage:
1. **SoundManager.lua** (ModuleScript)

## How the Win System Works:
1. **WinsLeaderstat.lua** creates a "Wins" stat in the leaderboard when players join
2. It saves wins using DataStore (if available)
3. Other scripts can award wins using `_G.WinsManager.IncrementWins(player)`
4. The poker game awards a win when someone wins a match

## Testing:
1. Join the game - you should see "Wins: 0" in the leaderboard
2. Play a poker game and win
3. Your wins should increase to 1
4. The physical leaderboard (if using LeaderboardDisplay) will update

## Common Issues:
- If the game still breaks when clicking poker, the old PokerGameServer.lua is still running
- If no "Wins" stat appears, check that WinsLeaderstat.lua is in ServerScriptService as a Script
- Make sure all scripts are the correct type (Script vs LocalScript vs ModuleScript)