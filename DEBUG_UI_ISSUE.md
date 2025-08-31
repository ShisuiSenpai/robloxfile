# Debug Analysis: Winner UI Issue

## Key Finding
The UI issue only affects the **winner** who stays seated, not the loser who dies and respawns.

## Why This Happens

### For the Loser:
1. Picks the Poker card
2. Dies (humanoid.Health = 0)
3. Respawns with fresh character
4. All UI gets recreated from scratch
5. Everything works normally

### For the Winner:
1. Game ends, they stay seated
2. UI transitions from game state to waiting state
3. UI might be in a corrupted/destroyed state
4. No respawn = no fresh UI setup
5. Next game fails to show turn UI

## Root Cause
The issue occurs at line 774 in the fade animation completion callback:
```lua
tableData.gameUI.TurnFrame.Visible = true  -- Direct access without validation!
```

This happens when the winner's status message fades out and tries to show the waiting UI.

## Fixes Applied

1. **Safe UI Access in Fade Callback** (lines 768-791):
   - Added UI validation before showing waiting UI
   - Uses FindFirstChild instead of direct access
   - Recreates UI if invalid

2. **Force UI Refresh at Countdown** (lines 621-628):
   - When new game starts, validates UI for all players
   - Especially important for winners who didn't respawn
   - Recreates UI if validation fails

3. **Debug Logging**:
   - Added logging for game end events
   - Shows which player is winner/loser
   - Tracks UI recreation attempts

## Testing Instructions

1. Play a game and note who wins
2. Start another game immediately
3. Check if winner gets turn UI
4. Look for these debug messages:
   - "[PokerGame] Game ended for table X - Player: Y Winner: Z"
   - "[PokerGame] UI invalid after game end, recreating for winner"
   - "[PokerGame] UI invalid at countdown start, recreating"

## Additional Considerations

The winner's UI might be destroyed by:
- The fade animation
- Garbage collection
- State transitions
- UI cleanup that shouldn't happen for seated players

The fix ensures UI is validated and recreated whenever needed, especially for winners who remain seated.