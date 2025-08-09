# QuizUI Responsive Setup Guide

This guide will help you make your QuizUI responsive across all screen sizes and devices.

## Core Principles

1. **Use Scale instead of Offset** for sizing
2. **Use UIAspectRatioConstraint** to maintain element proportions
3. **Use UIScale** for global scaling on different screen sizes
4. **Position elements using Scale with proper anchors**

## Step-by-Step Setup

### 1. Main ScreenGui Settings

In your QuizUI ScreenGui:
- **ResetOnSpawn**: false
- **ZIndexBehavior**: Sibling
- **IgnoreGuiInset**: true (optional, but recommended for full-screen experience)

### 2. BG Frame (Background Container)

```properties
BG Frame:
- Size: {1, 0, 1, 0}
- Position: {0, 0, 0, 0}
- AnchorPoint: (0, 0)
- BackgroundTransparency: 1
```

Add to BG:
- **UIScale** (Name: "ResponsiveScale")
  - Scale: 1 (will be adjusted by script based on screen size)

### 3. QuestionFrame

```properties
QuestionFrame:
- Size: {0.6, 0, 0.15, 0} -- 60% width, 15% height
- Position: {0.5, 0, 0.3, 0} -- Centered horizontally, 30% from top
- AnchorPoint: (0.5, 0.5)
```

Add to QuestionFrame:
- **UIAspectRatioConstraint**
  - AspectRatio: 6.667 (800/120 from original size)
  - AspectType: ScaleWithParentSize
  - DominantAxis: Width

### 4. TimerFrame

```properties
TimerFrame:
- Size: {0.15, 0, 0.08, 0} -- 15% width, 8% height
- Position: {0.5, 0, 0.1, 0} -- Centered horizontally, 10% from top
- AnchorPoint: (0.5, 0.5)
```

Add to TimerFrame:
- **UIAspectRatioConstraint**
  - AspectRatio: 2.5 (200/80 from original size)

### 5. Answer Buttons (A, B, C, D)

```properties
AnswerA:
- Size: {0.3, 0, 0.07, 0} -- 30% width, 7% height
- Position: {0.35, 0, 0.55, 0} -- Left side, 55% from top
- AnchorPoint: (0.5, 0.5)

AnswerB:
- Size: {0.3, 0, 0.07, 0}
- Position: {0.65, 0, 0.55, 0} -- Right side, 55% from top
- AnchorPoint: (0.5, 0.5)

AnswerC:
- Size: {0.3, 0, 0.07, 0}
- Position: {0.35, 0, 0.65, 0} -- Left side, 65% from top
- AnchorPoint: (0.5, 0.5)

AnswerD:
- Size: {0.3, 0, 0.07, 0}
- Position: {0.65, 0, 0.65, 0} -- Right side, 65% from top
- AnchorPoint: (0.5, 0.5)
```

Add to each Answer button:
- **UIAspectRatioConstraint**
  - AspectRatio: 5.429 (380/70 from original size)

### 6. NextQuestionFrame

```properties
NextQuestionFrame:
- Size: {0.3, 0, 0.08, 0} -- 30% width, 8% height
- Position: {0.5, 0, 0.85, 0} -- Centered horizontally, 85% from top
- AnchorPoint: (0.5, 0.5)
```

Add to NextQuestionFrame:
- **UIAspectRatioConstraint**
  - AspectRatio: 4 (400/100 from original size)

### 7. Text Scaling

For ALL TextLabels, ensure:
- **TextScaled**: true
- Remove any fixed TextSize values

Add to each TextLabel:
- **UITextSizeConstraint**
  - MaxTextSize: 36 (or appropriate max for that element)
  - MinTextSize: 12

### 8. UIStroke Scaling

For all UIStroke elements, the thickness needs to scale with screen size. We'll handle this in the script.

## Script Addition

Add this to the beginning of your QuizGui.client.lua script to handle dynamic scaling:

```lua
-- Responsive UI Setup
local function setupResponsiveUI()
    local camera = workspace.CurrentCamera
    local baseResolution = Vector2.new(1920, 1080) -- Reference resolution
    
    local function updateScale()
        local currentResolution = camera.ViewportSize
        local widthScale = currentResolution.X / baseResolution.X
        local heightScale = currentResolution.Y / baseResolution.Y
        local scale = math.min(widthScale, heightScale)
        
        -- Update main UI scale
        local uiScale = BG:FindFirstChild("ResponsiveScale")
        if uiScale then
            uiScale.Scale = scale
        end
        
        -- Update all UIStroke thicknesses
        for _, element in pairs(BG:GetDescendants()) do
            if element:IsA("UIStroke") then
                -- Base thickness of 3, scaled
                element.Thickness = math.max(1, math.floor(3 * scale))
            end
        end
    end
    
    -- Update on screen size change
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
    
    -- Initial update
    updateScale()
end

-- Call this after UI is loaded
setupResponsiveUI()
```

## Testing Different Screen Sizes

In Roblox Studio:
1. Go to Test → Device Emulation
2. Test on various devices:
   - Phone (375x667)
   - Tablet (768x1024)
   - Desktop (1920x1080)
   - Large Desktop (2560x1440)

## Additional Tips

1. **Font Scaling**: Use Gotham or SourceSans for better scaling
2. **Corner Radius**: Use Scale mode for UICorner if elements look too rounded on small screens
3. **Padding**: Add UIPadding to text elements to prevent text from touching edges
4. **Min/Max Sizes**: Use Size constraints to prevent elements from becoming too small or too large

## Common Issues and Fixes

1. **Text too small on mobile**: Increase MinTextSize in UITextSizeConstraint
2. **Elements overlapping**: Reduce Size scale values or adjust positions
3. **Elements off-screen**: Check AnchorPoint and Position values
4. **Blurry text**: Ensure TextScaled is true and fonts are appropriate

This setup ensures your UI looks consistent across all devices while maintaining readability and usability!