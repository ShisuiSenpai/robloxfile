# QuizGui UI Structure

Create the following UI structure in StarterGui:

```
QuizGui (ScreenGui)
├── Properties:
│   ├── Name: "QuizGui"
│   ├── Enabled: false
│   ├── ResetOnSpawn: false
│   └── ZIndexBehavior: Sibling
│
├── MainFrame (Frame)
│   ├── Properties:
│   │   ├── Name: "MainFrame"
│   │   ├── Size: {0.7, 0}, {0.8, 0}
│   │   ├── Position: {0.5, 0}, {0.5, 0}
│   │   ├── AnchorPoint: (0.5, 0.5)
│   │   ├── BackgroundColor3: Color3.fromRGB(30, 30, 30)
│   │   ├── BorderSizePixel: 0
│   │   └── ClipsDescendants: true
│   │
│   ├── UICorner
│   │   └── CornerRadius: UDim.new(0, 20)
│   │
│   ├── UIStroke
│   │   ├── Color: Color3.fromRGB(70, 130, 180)
│   │   ├── Thickness: 3
│   │   └── Transparency: 0.3
│   │
│   ├── QuestionFrame (Frame)
│   │   ├── Properties:
│   │   │   ├── Size: {0.9, 0}, {0.3, 0}
│   │   │   ├── Position: {0.5, 0}, {0.15, 0}
│   │   │   ├── AnchorPoint: (0.5, 0)
│   │   │   ├── BackgroundColor3: Color3.fromRGB(40, 40, 40)
│   │   │   └── BorderSizePixel: 0
│   │   ├── UICorner
│   │   │   └── CornerRadius: UDim.new(0, 15)
│   │   ├── CategoryLabel (TextLabel)
│   │   │   ├── Size: {1, 0}, {0.3, 0}
│   │   │   ├── Position: {0, 0}, {0, 0}
│   │   │   ├── BackgroundTransparency: 1
│   │   │   ├── Text: "Category"
│   │   │   ├── TextColor3: Color3.fromRGB(70, 130, 180)
│   │   │   ├── TextScaled: true
│   │   │   └── Font: Enum.Font.SourceSansBold
│   │   └── QuestionLabel (TextLabel)
│   │       ├── Size: {0.95, 0}, {0.7, 0}
│   │       ├── Position: {0.5, 0}, {0.3, 0}
│   │       ├── AnchorPoint: (0.5, 0)
│   │       ├── BackgroundTransparency: 1
│   │       ├── Text: "Question goes here?"
│   │       ├── TextColor3: Color3.new(1, 1, 1)
│   │       ├── TextScaled: true
│   │       ├── TextWrapped: true
│   │       └── Font: Enum.Font.SourceSans
│   │
│   ├── TimerFrame (Frame)
│   │   ├── Properties:
│   │   │   ├── Size: {0.9, 0}, {0.05, 0}
│   │   │   ├── Position: {0.5, 0}, {0.48, 0}
│   │   │   ├── AnchorPoint: (0.5, 0)
│   │   │   ├── BackgroundColor3: Color3.fromRGB(50, 50, 50)
│   │   │   └── BorderSizePixel: 0
│   │   ├── UICorner
│   │   │   └── CornerRadius: UDim.new(0, 10)
│   │   ├── TimerBar (Frame)
│   │   │   ├── Size: {1, 0}, {1, 0}
│   │   │   ├── Position: {0, 0}, {0, 0}
│   │   │   ├── BackgroundColor3: Color3.fromRGB(46, 204, 113)
│   │   │   ├── BorderSizePixel: 0
│   │   │   └── UICorner
│   │   │       └── CornerRadius: UDim.new(0, 10)
│   │   └── TimerLabel (TextLabel)
│   │       ├── Size: {1, 0}, {1, 0}
│   │       ├── Position: {0, 0}, {0, 0}
│   │       ├── BackgroundTransparency: 1
│   │       ├── Text: "15"
│   │       ├── TextColor3: Color3.new(1, 1, 1)
│   │       ├── TextScaled: true
│   │       └── Font: Enum.Font.SourceSansBold
│   │
│   └── AnswersFrame (Frame)
│       ├── Properties:
│       │   ├── Size: {0.9, 0}, {0.4, 0}
│       │   ├── Position: {0.5, 0}, {0.55, 0}
│       │   ├── AnchorPoint: (0.5, 0)
│       │   ├── BackgroundTransparency: 1
│       │   └── BorderSizePixel: 0
│       ├── UIGridLayout
│       │   ├── CellSize: {0.47, 0}, {0.45, 0}
│       │   ├── CellPadding: {0.03, 0}, {0.05, 0}
│       │   └── SortOrder: LayoutOrder
│       ├── Answer1 (TextButton)
│       │   ├── LayoutOrder: 1
│       │   ├── BackgroundColor3: Color3.fromRGB(70, 130, 180)
│       │   ├── TextColor3: Color3.new(1, 1, 1)
│       │   ├── TextScaled: true
│       │   ├── Font: Enum.Font.SourceSans
│       │   └── UICorner
│       │       └── CornerRadius: UDim.new(0, 15)
│       ├── Answer2 (TextButton) - Same as Answer1, LayoutOrder: 2
│       ├── Answer3 (TextButton) - Same as Answer1, LayoutOrder: 3
│       └── Answer4 (TextButton) - Same as Answer1, LayoutOrder: 4
│
├── ResultFrame (Frame)
│   ├── Properties:
│   │   ├── Name: "ResultFrame"
│   │   ├── Size: {0.4, 0}, {0.2, 0}
│   │   ├── Position: {0.5, 0}, {0.5, 0}
│   │   ├── AnchorPoint: (0.5, 0.5)
│   │   ├── BackgroundColor3: Color3.fromRGB(30, 30, 30)
│   │   ├── BorderSizePixel: 0
│   │   └── Visible: false
│   ├── UICorner
│   │   └── CornerRadius: UDim.new(0, 20)
│   ├── UIStroke
│   │   ├── Thickness: 3
│   │   └── Transparency: 0.3
│   ├── ResultLabel (TextLabel)
│   │   ├── Size: {0.9, 0}, {0.5, 0}
│   │   ├── Position: {0.5, 0}, {0.25, 0}
│   │   ├── AnchorPoint: (0.5, 0.5)
│   │   ├── BackgroundTransparency: 1
│   │   ├── TextScaled: true
│   │   └── Font: Enum.Font.SourceSansBold
│   └── CorrectAnswerLabel (TextLabel)
│       ├── Size: {0.9, 0}, {0.3, 0}
│       ├── Position: {0.5, 0}, {0.7, 0}
│       ├── AnchorPoint: (0.5, 0.5)
│       ├── BackgroundTransparency: 1
│       ├── TextScaled: true
│       ├── TextColor3: Color3.new(0.8, 0.8, 0.8)
│       └── Font: Enum.Font.SourceSans
│
├── WinnerFrame (Frame)
│   ├── Properties:
│   │   ├── Name: "WinnerFrame"
│   │   ├── Size: {0.6, 0}, {0.3, 0}
│   │   ├── Position: {0.5, 0}, {0.5, 0}
│   │   ├── AnchorPoint: (0.5, 0.5)
│   │   ├── BackgroundColor3: Color3.fromRGB(30, 30, 30)
│   │   ├── BorderSizePixel: 0
│   │   └── Visible: false
│   ├── UICorner
│   │   └── CornerRadius: UDim.new(0, 20)
│   ├── UIStroke
│   │   ├── Color: Color3.fromRGB(241, 196, 15)
│   │   ├── Thickness: 5
│   │   └── Transparency: 0
│   └── WinnerLabel (TextLabel)
│       ├── Size: {0.9, 0}, {0.8, 0}
│       ├── Position: {0.5, 0}, {0.5, 0}
│       ├── AnchorPoint: (0.5, 0.5)
│       ├── BackgroundTransparency: 1
│       ├── TextScaled: true
│       └── Font: Enum.Font.SourceSansBold
│
└── QuizGui.client.lua (LocalScript)