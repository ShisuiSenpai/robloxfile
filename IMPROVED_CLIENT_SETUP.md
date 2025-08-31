# Improved Client Setup Guide

## Overview
This guide explains how to implement the improved client system that addresses highlight and UI reliability issues.

## New Features

### 1. **ClientStateManager (ModuleScript)**
- Centralized state management for each table
- Automatic retry mechanism for failed initializations
- State validation and recovery system
- Component initialization queue for proper loading order

### 2. **Improved Client Script (PokerGameClientMulti_V2)**
- Better error handling and recovery
- Diagnostic system that runs every 5 seconds
- Structured initialization process
- Automatic UI and highlight recovery

## Implementation Steps

### Step 1: Add ClientStateManager Module
1. In **StarterPlayer > StarterPlayerScripts**, create a new **ModuleScript**
2. Name it: `ClientStateManager`
3. Copy the contents from `/workspace/ClientStateManager.lua`

### Step 2: Choose Implementation Option

#### Option A: Replace Existing Client (Recommended)
1. Disable or delete the old `PokerGameClientMulti` script
2. Create a new **LocalScript** in **StarterPlayer > StarterPlayerScripts**
3. Name it: `PokerGameClientMulti`
4. Copy the contents from `/workspace/PokerGameClientMulti_V2.lua`

#### Option B: Test Alongside Existing Client
1. Keep the old client disabled
2. Create a new **LocalScript** named `PokerGameClientMulti_V2`
3. Copy the contents from `/workspace/PokerGameClientMulti_V2.lua`
4. Test and compare behavior

### Step 3: Verify Setup
Ensure you have:
- ✅ ClientStateManager (ModuleScript) in StarterPlayerScripts
- ✅ Either replaced or added new client script
- ✅ Old client script disabled if testing new version

## Key Improvements

### 1. **State Management**
- Each table has its own state manager
- States: IDLE → WAITING → COUNTDOWN → IN_GAME → ENDING
- Prevents invalid operations in wrong states

### 2. **Initialization Queue**
- UI initialized before highlights
- Components load in correct order
- Retry mechanism for failed initializations

### 3. **Automatic Recovery**
- Diagnostic system checks every 5 seconds
- Detects missing UI or highlights
- Automatically attempts to fix issues

### 4. **Better Error Handling**
- All UI operations check if elements exist
- Graceful fallbacks for missing components
- Detailed logging for debugging

## Benefits

1. **No More Missing Highlights**
   - Highlights are recreated if they disappear
   - State validation ensures they exist during games

2. **UI Always Shows**
   - UI recovery if it goes missing
   - Proper state tracking prevents UI conflicts

3. **Better Performance**
   - Components only initialize when needed
   - Efficient state-based updates

4. **Easier Debugging**
   - Clear state transitions in output
   - Diagnostic messages identify issues
   - Recovery attempts are logged

## Testing

1. **Test Normal Flow**
   - Join a table and play normally
   - UI and highlights should work consistently

2. **Test Recovery**
   - Play multiple games in succession
   - Switch between tables rapidly
   - Check output for recovery messages

3. **Monitor Output**
   Look for these messages:
   - `[StateManager] Table X: State transitions`
   - `[StateManager] Component initialized successfully`
   - `[Diagnostics] Recovery performed`

## Troubleshooting

If issues persist:
1. Check that ClientStateManager module is properly placed
2. Ensure all RemoteEvents exist in ReplicatedStorage
3. Verify UI folders are in StarterGui
4. Check output for error messages

## Alternative: Minimal Fix

If you prefer not to use the new system yet, you can apply these minimal fixes to your existing client:

1. Add nil checks before using UI elements
2. Re-enable UI when showing turn updates
3. Recreate highlights if they're missing
4. Add recovery attempts in error cases

However, the new system is recommended for long-term stability.