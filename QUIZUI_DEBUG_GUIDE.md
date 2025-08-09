# QuizUI Debug System Guide

## Overview
This debug system helps identify why the QuizUI appears shifted to the left in the actual game while looking correct in Studio. The system captures comprehensive UI properties from both client and server perspectives.

## Debug Features

### 1. Automatic Client-Side Debug Captures
The client automatically captures UI state at these moments:
- **On script load** - Initial state of the UI
- **0.1 seconds after load** - Catches any immediate changes
- **Before ShowQuestion** - State before quiz UI animations
- **After ShowQuestion animations** - State after all tweens complete (1 second later)

### 2. Manual Debug Triggers

#### Client-Side (In-Game):
- **Press F9** - Captures current UI state at any time
- Look for output starting with `[QuizUI]` in the console

#### Server-Side (Chat Commands):
- `/debugui` - Check all players' UI state
- `/debugui me` - Check only your UI state
- `/debugui start` - Start monitoring every 5 seconds
- `/debugui stop` - Stop periodic monitoring

### 3. Information Captured

The debug system captures:
- **Full UI Hierarchy** - All UI elements and their children
- **Position & Size** - Both relative (UDim2) and absolute (Vector2) values
- **Anchor Points** - Critical for responsive positioning
- **Visibility States** - What's shown/hidden
- **UI Constraints** - UIScale, UIAspectRatioConstraint, etc.
- **Text Properties** - Font, size, alignment
- **Colors & Transparency** - Visual properties
- **Scripts** - Any scripts attached to UI elements

## How to Use the Debug System

### Step 1: Reproduce the Issue
1. Open the game in Roblox Studio
2. Start a Play Solo test
3. Wait for the intermission and first quiz question to appear
4. Check the Output window for initial debug captures

### Step 2: Compare Studio vs In-Game
1. Note the UI properties captured in Studio (especially Position, Size, AnchorPoint)
2. Publish the game and test in the actual Roblox client
3. Press F9 when the UI appears shifted
4. Compare the captured properties between Studio and in-game

### Step 3: Key Things to Look For

#### Position Differences:
```
Studio:   Position: UDim2.new(0.5, 0, 0.5, 0)  -- Centered
In-Game:  Position: UDim2.new(0, 100, 0.5, 0)  -- Shifted left
```

#### UIScale Presence:
```
Look for unexpected UIScale instances:
  BG (Frame)
    UI Constraints: UIScale (UIScale)
    UIScale
      Scale: 0.8  -- This could cause shifting
```

#### Anchor Point Changes:
```
Studio:   AnchorPoint: Vector2.new(0.5, 0.5)  -- Center anchor
In-Game:  AnchorPoint: Vector2.new(0, 0.5)    -- Left anchor
```

#### Absolute Position:
```
Compare AbsolutePosition values:
Studio:   AbsolutePosition: Vector2.new(960, 540)   -- Center of 1920x1080
In-Game:  AbsolutePosition: Vector2.new(100, 540)   -- Far left
```

### Step 4: Server-Side Verification
1. Use `/debugui me` in chat to check server perspective
2. Look for any server-side modifications or unexpected UI elements
3. Check if any scripts are being added server-side

## Common Causes of UI Shift

1. **UIScale Interference** - Scripts adding UIScale at runtime
2. **Anchor Point Mismatch** - Different anchor points in Studio vs runtime
3. **Position Override** - Scripts changing position after initial setup
4. **Parent Size Difference** - Parent frame having different size
5. **ScreenInsets** - IgnoreGuiInset property differences
6. **Device Emulation** - Studio device emulation vs actual device

## Debug Output Example

```
========== QUIZUI DEBUG INFORMATION ==========
Time: 14:32:15
Script Location: Players.LocalPlayer.PlayerGui.QuizUI.QuizGui

QuizUI (ScreenGui)
  Enabled: true
  DisplayOrder: 0
  IgnoreGuiInset: false
  BG (Frame)
    Position: UDim2.new(0.5, 0, 0.5, 0)
    Size: UDim2.new(0, 800, 0, 600)
    AnchorPoint: Vector2.new(0.5, 0.5)
    AbsolutePosition: Vector2.new(560, 240)  <-- This shows actual screen position
    AbsoluteSize: Vector2.new(800, 600)
    UI Constraints: UICorner (UICorner)

Camera ViewportSize: 1920, 1080
========== END DEBUG INFORMATION ==========
```

## Troubleshooting Steps

1. **If UI is shifted left:**
   - Check if Position.X.Scale is 0 instead of 0.5
   - Verify AnchorPoint.X is 0.5 (centered)
   - Look for UIScale with values less than 1

2. **If UI appears at different sizes:**
   - Check AbsoluteSize values
   - Look for unexpected UISizeConstraint
   - Verify parent frame sizes

3. **If animations cause shift:**
   - Compare "BEFORE changes" with "AFTER animations"
   - Check if tweens are modifying Position or AnchorPoint

## Fixing Common Issues

Once you identify the problem using the debug system:

1. **For position issues:** Ensure all UI elements use proper anchoring
2. **For scale issues:** Remove or adjust UIScale instances
3. **For script conflicts:** Check what scripts modify the UI after creation
4. **For device differences:** Use Scale values instead of Offset in UDim2

## Important Notes

- The debug system does NOT modify the UI, it only observes
- Server-side debug cannot access Camera.ViewportSize
- Client-side debug is more accurate for visual properties
- Always test on multiple screen sizes after fixing