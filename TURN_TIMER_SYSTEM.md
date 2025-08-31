# Turn Timer System

## Overview
Players now have 10 seconds to make their card selection on each turn. If time runs out, a random available card is automatically selected.

## Features

### Server-Side (PokerGameServerMulti.lua)
1. **10-Second Timer**: Each turn starts with a 10-second countdown
2. **Auto-Selection**: When timer expires, a random unselected card is chosen
3. **Timer Updates**: Sends timer updates to all clients every 0.1 seconds
4. **Timer Management**: 
   - Starts when game begins
   - Restarts on each turn change
   - Cancels when game ends

### Client-Side (PokerGameClientMulti.lua)
1. **Visual Timer**: Shows countdown next to turn text (e.g., "Your Turn (8)")
2. **Color Coding**:
   - Green: Normal time remaining
   - Red: 3 seconds or less (urgent)
   - Yellow: Opponent's turn
3. **Pulse Effect**: Turn text pulses when time is running low (≤3 seconds)

## How It Works

1. **Game Start**: Timer begins for the randomly selected first player
2. **Turn Change**: Timer resets to 10 seconds for the next player
3. **Timer Expiration**: 
   - Server selects a random available card
   - Turn automatically passes to the other player
   - New timer starts
4. **Game End**: Timer is cancelled

## Technical Implementation

### Server Functions
- `startTurnTimer(tableInstance)`: Starts the countdown and handles expiration
- `cancelTurnTimer(tableInstance)`: Stops the current timer
- Timer stored in `tableInstance.gameState.turnTimer`

### Network Communication
- `TurnUpdate` RemoteEvent now sends: `(playerName, timeLeft)`
- Updates sent every 0.1 seconds for smooth countdown

### Edge Cases Handled
- Timer cancellation on game end
- Timer reset on manual card selection
- No timer conflicts between tables
- Proper cleanup on player disconnect