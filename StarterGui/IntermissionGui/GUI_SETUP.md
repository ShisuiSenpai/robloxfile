# IntermissionGui Setup

Create the following GUI structure in StarterGui:

```
IntermissionGui (ScreenGui)
├── Properties:
│   ├── Name: "IntermissionGui"
│   ├── Enabled: false
│   └── ResetOnSpawn: true
├── Frame
│   ├── Properties:
│   │   ├── Name: "Frame"
│   │   ├── Size: {0.5, 0}, {0.15, 0}
│   │   ├── Position: {0.25, 0}, {0.4, 0}
│   │   ├── BackgroundColor3: Color3.new(0, 0, 0)
│   │   ├── BackgroundTransparency: 0.3
│   │   ├── BorderSizePixel: 0
│   │   └── AnchorPoint: (0, 0)
│   └── TextLabel
│       ├── Properties:
│       │   ├── Name: "TextLabel"
│       │   ├── Size: {1, 0}, {1, 0}
│       │   ├── Position: {0, 0}, {0, 0}
│       │   ├── BackgroundTransparency: 1
│       │   ├── Text: "Game will start in 5 seconds"
│       │   ├── TextColor3: Color3.new(1, 1, 1)
│       │   ├── TextScaled: true
│       │   ├── Font: Enum.Font.SourceSansBold
│       │   └── TextStrokeTransparency: 0.5
│       └── UITextSizeConstraint (Optional)
│           ├── MaxTextSize: 36
│           └── MinTextSize: 18
└── IntermissionGui.client.lua (LocalScript)
```

The LocalScript should be placed as a child of the IntermissionGui ScreenGui.