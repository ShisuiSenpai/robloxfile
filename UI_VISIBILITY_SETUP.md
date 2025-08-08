# Quiz UI Manual Setup Guide

## Initial Visibility Settings (Set these in Studio)

### 1. **ScreenGui (QuizUI)**
- **Enabled**: `false` (The script will enable it when needed)
- **ResetOnSpawn**: `false`
- **ZIndexBehavior**: `Sibling`

### 2. **BG Frame**
- **Visible**: `true`
- **BackgroundTransparency**: `1` (fully transparent as per your design)

### 3. **QuestionFrame**
- **Visible**: `true`
- **Active**: `true`
- **All properties**: Leave as you've set them

### 4. **Answer Frames (AnswerA, AnswerB, AnswerC, AnswerD)**
- **Visible**: `true` for all
- **Active**: `true` for all
- **All properties**: Leave as you've set them

### 5. **Timer Frame**
- **NOTE**: The timer frame is created by the script, so you DON'T need to create it manually
- If you want to create it manually instead, use these properties:
  - Name: `TimerFrame`
  - Size: `{0, 200}, {0, 80}`
  - Position: `{0.5, -100}, {0.05, 0}`
  - BackgroundColor3: `255, 255, 255`
  - With UICorner (CornerRadius: `{0, 40}`)
  - With UIStroke (Color: `100, 150, 250`, Thickness: `3`)
  - Inside TimerFrame, add TextLabel named `TimerText`

## What NOT to Create/Enable

### Don't create these (they're made by the script):
1. **ResultFrame** - Created dynamically when showing results
2. **WinnerFrame** - Created dynamically for winner announcement
3. **Confetti particles** - Created dynamically during celebration

## Important Parent-Child Hierarchy

```
StarterGui/
└── QuizUI (ScreenGui) [Enabled = false]
    └── BG (Frame) [Visible = true, BackgroundTransparency = 1]
        ├── QuestionFrame [Visible = true]
        │   └── QuestionText (TextLabel)
        ├── AnswerA (Frame) [Visible = true]
        │   ├── UICorner
        │   ├── UIStroke
        │   ├── Frame (content container)
        │   │   ├── LetterCircle (Frame)
        │   │   │   └── Letter (TextLabel) - Should say "A"
        │   │   └── AnswerText (TextLabel)
        │   └── TextButton (for clicking)
        ├── AnswerB (Frame) [Visible = true]
        │   └── (same structure as AnswerA)
        ├── AnswerC (Frame) [Visible = true]
        │   └── (same structure as AnswerA)
        └── AnswerD (Frame) [Visible = true]
            └── (same structure as AnswerA)
```

## TextButton Settings for Each Answer

Make sure each answer frame (AnswerA, B, C, D) has:
- **TextButton** with:
  - Size: `{1, 0}, {1, 0}`
  - Position: `{0, 0}, {0, 0}`
  - BackgroundTransparency: `1`
  - Text: `""` (empty string)
  - Active: `true`
  - AutoButtonColor: `false` (to prevent default hover effects)

## Color Reference (in case you need to adjust)

- **Blue**: `RGB(100, 150, 250)`
- **White**: `RGB(255, 255, 255)`
- **Blue Dark**: `RGB(80, 130, 230)`
- **Blue Light**: `RGB(120, 170, 255)`
- **Green (Correct)**: `RGB(50, 200, 100)`
- **Red (Incorrect)**: `RGB(250, 100, 100)`

## Script Placement

Make sure the `QuizGui.client.lua` script is placed at:
```
StarterGui/
└── QuizUI (ScreenGui)
    └── QuizGui (LocalScript) - The client script goes here
```

## Testing Checklist

After setup, verify:
- [ ] QuizUI ScreenGui has Enabled = false
- [ ] All answer frames are named exactly: AnswerA, AnswerB, AnswerC, AnswerD
- [ ] Each answer frame has a TextButton child
- [ ] QuestionFrame has QuestionText child
- [ ] The LocalScript is a child of the QuizUI ScreenGui

## How the System Works

1. **Initially**: ScreenGui is disabled (Enabled = false)
2. **When quiz starts**: Script enables the GUI and animates elements in
3. **During quiz**: All frames stay visible, script handles animations
4. **After answer**: Script shows results with color changes
5. **Round end**: Script fades out and disables GUI again

The script handles all the showing/hiding automatically - you just need to set up the initial state!