# Win Streak System Setup

## New Script to Add:

### In ServerScriptService:
- **WinStreakSystem.lua** (Regular Script) - Place alongside WinsLeaderstat.lua

## How the Streak System Works:

1. **Streak Display**:
   - Shows a styled BillboardGui above player's head after 2+ wins in a row
   - Features a fire emoji 🔥, streak number, and "STREAK" text
   - Has a semi-transparent background with rounded corners and gradient

2. **Color Coding by Streak Level**:
   - 2-4 wins: White
   - 5-9 wins: Gold
   - 10-14 wins: Red-Orange
   - 15-19 wins: Purple
   - 20+ wins: Cyan

3. **Special Effects**:
   - Smooth animation when appearing/disappearing
   - Pulsing effect for streaks of 10+
   - Persists through respawns

4. **Game Integration**:
   - Winner's streak increases by 1
   - Loser's streak resets to 0
   - Streak UI disappears when reset

## Testing:
1. Win 2 games in a row - streak UI should appear showing "2"
2. Keep winning - number and color should update
3. Lose a game - streak UI should animate out and disappear
4. The streak display follows you even after respawning

## Customization:
- Change `MIN_STREAK_TO_SHOW` to adjust when streak appears (default: 2)
- Modify `STREAK_COLORS` table to change color thresholds
- Adjust `STREAK_UI_HEIGHT` to change display height above head