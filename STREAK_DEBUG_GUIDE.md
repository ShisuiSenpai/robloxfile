# Streak System Debug Guide

## Current Changes Made:

1. **Lowered MIN_STREAK_TO_SHOW to 1** for testing (was 2)
2. **Added extensive debug logging** throughout the system
3. **Changed BillboardGui parent** from HumanoidRootPart to Head
4. **Added error handling** with pcall for UI creation
5. **Created SimpleStreakTest.lua** for basic testing

## What to Check:

1. **Server Output** - Look for these messages:
   - `[StreakManager] Player2 win streak increased to: X`
   - `[StreakManager] updateStreakUI called for Player2 with streak: X`
   - `[StreakManager] Creating streak UI for Player2 with streak: X`
   - `[StreakManager] Creating BillboardGui for streak: X`
   - `[StreakManager] Successfully created streak UI for streak: X`
   - `[StreakManager] Streak UI stored for Player2`

2. **If SimpleStreakTest.lua works** (shows "STREAK TEST" above head):
   - The issue is with the complex UI in WinStreakSystem
   - Check for any error messages in output

3. **If SimpleStreakTest.lua doesn't work**:
   - BillboardGui might be disabled in your game settings
   - Character might not have a Head part
   - There might be other scripts interfering

## Common Issues:

1. **BillboardGui not showing**:
   - Check if BillboardGui is enabled in game settings
   - Ensure character has a Head part
   - Check if other scripts are deleting UI elements

2. **Streak not incrementing**:
   - Player might not be initialized in playerStreaks table
   - PokerGameServerMulti might not be calling IncrementStreak

## Next Steps:

1. Run a game and win once
2. Check server output for all the debug messages
3. If SimpleStreakTest shows UI but WinStreakSystem doesn't, the issue is in the complex UI
4. Share the debug output to identify where it's failing