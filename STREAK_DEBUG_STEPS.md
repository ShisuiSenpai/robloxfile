# Streak UI Debug Steps

## Test Script Added:
- **TestStreakUI.lua** - Allows manual testing with chat commands

## Chat Commands:
- `/streak 2` - Sets your streak to 2 (should show UI)
- `/streak 5` - Sets your streak to 5 (should show gold color)
- `/resetstreak` - Resets your streak to 0

## What to Check in Server Output:

1. **When you win a game**, look for:
   ```
   [StreakManager] Player2 win streak increased to: X
   [StreakManager] updateStreakUI called for Player2 with streak: X MIN_STREAK_TO_SHOW: 2
   ```

2. **If streak >= 2**, you should see:
   ```
   [StreakManager] Streak high enough, creating UI
   [StreakManager] createStreakUI called
   [StreakManager] Creating BillboardGui...
   [StreakManager] BillboardGui created successfully, returning it
   [StreakManager] UI created and stored successfully
   ```

3. **If you DON'T see these messages**, the issue is:
   - Streak not incrementing properly
   - Player not found
   - Character/Head not found

## Common Issues:

1. **Streak resets between games** - Check if player is rejoining
2. **UI not visible** - Check if BillboardGui is enabled in game
3. **Head not found** - Character might not be fully loaded

## Testing Steps:
1. Join game and use `/streak 2` command
2. If UI appears, the display system works
3. If not, check server output for errors
4. Win 2 games in a row naturally and check if it appears