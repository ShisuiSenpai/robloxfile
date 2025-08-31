# UI Fix Setup Guide

## The Problem
The "TurnFrame is not a valid member of ScreenGui" error occurs because:
1. The UI elements are being accessed without proper validation
2. UI components might be getting destroyed or corrupted between games
3. The script tries to access `tableData.gameUI.TurnFrame` directly without checking if it exists

## The Solution
The fixed script includes:
1. **UI Validation Function** - `validateAndRepairUI()` checks all UI components exist
2. **Safe UI Access** - Always uses `FindFirstChild` before accessing UI elements
3. **Automatic Recovery** - If UI is missing, it attempts to recreate it
4. **Periodic Validation** - Checks UI integrity every 2 seconds during active games

## Implementation Steps

### Option 1: Replace Current Script (Recommended)
1. In **StarterPlayer > StarterPlayerScripts**
2. Find and disable/delete the current `PokerGameClientMulti` LocalScript
3. Create a new LocalScript named `PokerGameClientMulti`
4. Copy the contents from `/workspace/PokerGameClientMulti_Fixed.lua`

### Option 2: Apply Minimal Fix to Current Script
If you prefer to keep your current script, apply these key changes:

1. **Add UI validation function** (after line 200):
```lua
-- Validate and repair UI
local function validateAndRepairUI(tableData)
	if not tableData.gameUI or not tableData.gameUI.Parent then
		setupGameUI(tableData)
		return false
	end
	
	local turnFrame = tableData.gameUI:FindFirstChild("TurnFrame")
	if not turnFrame then
		warn("[PokerGame] TurnFrame missing for table", tableData.id, "- attempting repair")
		tableData.gameUI = nil
		setupGameUI(tableData)
		return false
	end
	
	return true
end
```

2. **Replace line 546** (the error line):
```lua
-- OLD:
if tableData.gameUI and tableData.gameUI.TurnFrame then

-- NEW:
if tableData.gameUI then
	local turnFrame = tableData.gameUI:FindFirstChild("TurnFrame")
	if turnFrame then
```

3. **Replace line 616** (in game_start handler):
```lua
-- OLD:
tableData.gameUI.TurnFrame.Visible = true

-- NEW:
local turnFrame = tableData.gameUI:FindFirstChild("TurnFrame")
if turnFrame then
	turnFrame.Visible = true
else
	warn("[PokerGame] TurnFrame missing, recreating UI")
	setupGameUI(tableData)
end
```

4. **Update all other direct UI accesses** to use `FindFirstChild`

## Key Improvements in Fixed Version

1. **Robust UI Validation**
   - Checks UI exists before every use
   - Automatically recreates missing UI components
   - Validates entire UI hierarchy

2. **Safe Property Access**
   - Never accesses UI properties directly
   - Always uses FindFirstChild with nil checks
   - Graceful fallbacks when UI is missing

3. **Automatic Recovery**
   - Periodic validation every 2 seconds
   - Immediate repair attempts when issues detected
   - Maintains game continuity even with UI issues

4. **Better Error Messages**
   - Clear warnings about what's missing
   - Indicates when repairs are attempted
   - Helps with debugging

## Testing

1. Play one complete game
2. Immediately start a second game on the same table
3. The UI should work properly without errors
4. Check output for any warning messages

## Additional Notes

- The fix ensures UI elements are never accessed without validation
- If UI goes missing mid-game, it will be automatically recreated
- The periodic validation helps catch issues early
- All UI updates now have proper error handling

This should completely resolve the "TurnFrame is not a valid member" error and make the system much more reliable for consecutive games.