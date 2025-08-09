-- UIDebugClient.lua
-- Enhanced client-side UI debug script to diagnose positioning issues

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer

-- Wait for PlayerGui
repeat task.wait() until player:FindFirstChild("PlayerGui")
local playerGui = player.PlayerGui

-- Function to capture comprehensive UI state
local function captureCompleteUIState()
    print("\n========== COMPREHENSIVE UI STATE CAPTURE ==========")
    print("Time:", os.date("%X"))
    print("Platform:", UserInputService.TouchEnabled and "Touch/Mobile" or "Desktop")
    
    -- Capture screen info
    local camera = workspace.CurrentCamera
    print("\nScreen Information:")
    print("  Camera ViewportSize:", tostring(camera.ViewportSize))
    print("  GuiInset Top:", GuiService:GetGuiInset().Y)
    print("  GuiInset Total:", tostring(GuiService:GetGuiInset()))
    
    -- Look for QuizUI
    local quizUI = playerGui:WaitForChild("QuizUI", 5)
    if not quizUI then
        print("QuizUI not found!")
        return
    end
    
    print("\nQuizUI Properties:")
    print("  Enabled:", quizUI.Enabled)
    print("  DisplayOrder:", quizUI.DisplayOrder)
    print("  IgnoreGuiInset:", quizUI.IgnoreGuiInset)
    print("  ResetOnSpawn:", quizUI.ResetOnSpawn)
    print("  ZIndexBehavior:", tostring(quizUI.ZIndexBehavior))
    print("  ScreenInsets:", tostring(quizUI.ScreenInsets))
    
    -- Check for BG frame
    local bgFrame = quizUI:FindFirstChild("BG")
    if bgFrame then
        print("\nBG Frame Properties:")
        print("  Position:", tostring(bgFrame.Position))
        print("  Size:", tostring(bgFrame.Size))
        print("  AnchorPoint:", tostring(bgFrame.AnchorPoint))
        print("  AbsolutePosition:", tostring(bgFrame.AbsolutePosition))
        print("  AbsoluteSize:", tostring(bgFrame.AbsoluteSize))
        print("  Visible:", bgFrame.Visible)
        print("  Parent AbsoluteSize:", tostring(bgFrame.Parent.AbsoluteSize))
        
        -- Calculate expected vs actual position
        local expectedX = bgFrame.Position.X.Scale * camera.ViewportSize.X + bgFrame.Position.X.Offset
        local expectedY = bgFrame.Position.Y.Scale * camera.ViewportSize.Y + bgFrame.Position.Y.Offset
        print("\n  Expected Position (calculated):", expectedX, expectedY)
        print("  Actual AbsolutePosition:", bgFrame.AbsolutePosition.X, bgFrame.AbsolutePosition.Y)
        print("  Difference X:", bgFrame.AbsolutePosition.X - expectedX)
        print("  Difference Y:", bgFrame.AbsolutePosition.Y - expectedY)
        
        -- Check for UI constraints
        print("\n  UI Constraints in BG:")
        for _, child in ipairs(bgFrame:GetChildren()) do
            if child:IsA("UIConstraint") or child:IsA("UILayout") or child:IsA("UIScale") then
                print("    " .. child.Name .. " (" .. child.ClassName .. ")")
                if child:IsA("UIScale") then
                    print("      Scale:", child.Scale)
                elseif child:IsA("UIAspectRatioConstraint") then
                    print("      AspectRatio:", child.AspectRatio)
                    print("      AspectType:", tostring(child.AspectType))
                    print("      DominantAxis:", tostring(child.DominantAxis))
                end
            end
        end
        
        -- Check nested frames
        local frames = {"NextQuestionFrame", "TimerFrame", "QuestionFrame"}
        for _, frameName in ipairs(frames) do
            local frame = bgFrame:FindFirstChild(frameName)
            if frame then
                print("\n" .. frameName .. " Properties:")
                print("  Position:", tostring(frame.Position))
                print("  Size:", tostring(frame.Size))
                print("  AnchorPoint:", tostring(frame.AnchorPoint))
                print("  AbsolutePosition:", tostring(frame.AbsolutePosition))
                print("  Visible:", frame.Visible)
            end
        end
    end
    
    -- Check for any active tweens
    print("\nChecking for active modifications...")
    
    -- Monitor position changes for 1 second
    if bgFrame then
        local startPos = bgFrame.AbsolutePosition
        local positions = {}
        
        for i = 1, 10 do
            task.wait(0.1)
            table.insert(positions, bgFrame.AbsolutePosition)
        end
        
        local moved = false
        for _, pos in ipairs(positions) do
            if pos ~= startPos then
                moved = true
                print("  Position change detected! From", tostring(startPos), "to", tostring(pos))
            end
        end
        
        if not moved then
            print("  No position changes detected during 1 second monitoring")
        end
    end
    
    print("========== END UI STATE CAPTURE ==========\n")
end

-- Auto-capture on different events
local function setupAutoCapture()
    -- Capture initial state
    task.wait(0.5)
    print("\n[UIDebug] Initial state capture:")
    captureCompleteUIState()
    
    -- Capture when QuizUI visibility changes
    local quizUI = playerGui:WaitForChild("QuizUI", 10)
    if quizUI then
        local bgFrame = quizUI:WaitForChild("BG", 5)
        if bgFrame then
            bgFrame:GetPropertyChangedSignal("Visible"):Connect(function()
                if bgFrame.Visible then
                    print("\n[UIDebug] BG Frame became visible:")
                    captureCompleteUIState()
                end
            end)
        end
    end
end

-- Manual capture with F8
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F8 then
        print("\n[UIDebug] Manual capture (F8):")
        captureCompleteUIState()
    end
end)

-- Chat commands
player.Chatted:Connect(function(message)
    if message:lower() == "/uidebug" then
        captureCompleteUIState()
    elseif message:lower() == "/uidebug monitor" then
        print("[UIDebug] Starting position monitoring...")
        local quizUI = playerGui:FindFirstChild("QuizUI")
        if quizUI and quizUI:FindFirstChild("BG") then
            local bg = quizUI.BG
            for i = 1, 20 do
                print(string.format("  [%d] BG Position: %s, AbsPos: %s", 
                    i, tostring(bg.Position), tostring(bg.AbsolutePosition)))
                task.wait(0.5)
            end
        end
    end
end)

-- Setup auto-capture
task.spawn(setupAutoCapture)

print("[UIDebugClient] Enhanced debug script loaded!")
print("Commands:")
print("  F8 - Capture current UI state")
print("  /uidebug - Capture via chat")
print("  /uidebug monitor - Monitor position for 10 seconds")