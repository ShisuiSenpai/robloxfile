-- DebugQuizUI.server.lua
-- Server-side debug script to monitor QuizUI state

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Function to capture comprehensive UI properties
local function captureUIProperties(instance, indent)
    indent = indent or ""
    local className = instance.ClassName
    local output = {}
    
    -- Basic info
    table.insert(output, indent .. instance.Name .. " (" .. className .. ")")
    
    -- Properties to check based on class
    local properties = {}
    
    if className == "Frame" or className == "TextLabel" or className == "TextButton" or className == "ImageLabel" then
        properties = {
            "Position", "Size", "AnchorPoint", "Visible", 
            "BackgroundTransparency", "BackgroundColor3",
            "BorderSizePixel", "ClipsDescendants", "ZIndex",
            "Rotation", "LayoutOrder", "SizeConstraint",
            "AbsolutePosition", "AbsoluteSize"
        }
    elseif className == "ScreenGui" then
        properties = {
            "Enabled", "DisplayOrder", "IgnoreGuiInset", 
            "ResetOnSpawn", "ZIndexBehavior", "ScreenInsets"
        }
    elseif className == "UIScale" then
        properties = {"Scale"}
    elseif className == "UICorner" then
        properties = {"CornerRadius"}
    elseif className == "UIStroke" then
        properties = {"Color", "Thickness", "Transparency", "ApplyStrokeMode"}
    elseif className == "UIGradient" then
        properties = {"Color", "Transparency", "Rotation", "Offset"}
    elseif className == "UIListLayout" or className == "UIGridLayout" then
        properties = {
            "FillDirection", "HorizontalAlignment", "VerticalAlignment",
            "SortOrder", "Padding"
        }
    elseif className == "UIPadding" then
        properties = {"PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"}
    elseif className == "UIAspectRatioConstraint" then
        properties = {"AspectRatio", "AspectType", "DominantAxis"}
    elseif className == "UISizeConstraint" then
        properties = {"MaxSize", "MinSize"}
    end
    
    -- Capture properties
    for _, prop in ipairs(properties) do
        local success, value = pcall(function()
            return instance[prop]
        end)
        if success then
            local valueStr = tostring(value)
            if typeof(value) == "UDim2" then
                valueStr = string.format("UDim2.new(%g, %g, %g, %g)", 
                    value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
            elseif typeof(value) == "Vector2" then
                valueStr = string.format("Vector2.new(%g, %g)", value.X, value.Y)
            elseif typeof(value) == "Color3" then
                valueStr = string.format("Color3.fromRGB(%d, %d, %d)", 
                    math.round(value.R * 255), math.round(value.G * 255), math.round(value.B * 255))
            elseif typeof(value) == "UDim" then
                valueStr = string.format("UDim.new(%g, %g)", value.Scale, value.Offset)
            end
            table.insert(output, indent .. "  " .. prop .. ": " .. valueStr)
        end
    end
    
    -- Special case for TextLabel/TextButton
    if className == "TextLabel" or className == "TextButton" then
        local textProps = {"Text", "TextColor3", "TextScaled", "TextSize", 
                         "TextTransparency", "Font", "TextXAlignment", "TextYAlignment"}
        for _, prop in ipairs(textProps) do
            local success, value = pcall(function() return instance[prop] end)
            if success then
                table.insert(output, indent .. "  " .. prop .. ": " .. tostring(value))
            end
        end
    end
    
    -- Return collected output
    return output
end

-- Function to check player GUI with comprehensive output
local function debugPlayerUI(player)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then 
        print("[SERVER DEBUG] No PlayerGui found for player:", player.Name)
        return 
    end
    
    local quizUI = playerGui:FindFirstChild("QuizUI")
    if not quizUI then 
        print("[SERVER DEBUG] No QuizUI found for player:", player.Name)
        return 
    end
    
    print("\n========== [SERVER DEBUG] QuizUI State for " .. player.Name .. " ==========")
    print("Time:", os.date("%X"))
    print("QuizUI FullName:", quizUI:GetFullName())
    
    -- Capture full hierarchy
    local function printHierarchy(instance, indent)
        local output = captureUIProperties(instance, indent)
        for _, line in ipairs(output) do
            print(line)
        end
        
        -- Check for any UI constraint objects
        local constraints = {}
        for _, child in ipairs(instance:GetChildren()) do
            if child:IsA("UIConstraint") or child:IsA("UILayout") or child:IsA("UIScale") then
                table.insert(constraints, child.Name .. " (" .. child.ClassName .. ")")
            end
        end
        
        if #constraints > 0 then
            print(indent .. "  UI Constraints: " .. table.concat(constraints, ", "))
        end
        
        -- Recurse through children
        for _, child in ipairs(instance:GetChildren()) do
            printHierarchy(child, indent .. "  ")
        end
    end
    
    -- Start from ScreenGui
    printHierarchy(quizUI)
    
    -- Check for any server-side scripts or modifications
    local scripts = {}
    for _, desc in ipairs(quizUI:GetDescendants()) do
        if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
            table.insert(scripts, desc:GetFullName())
        end
    end
    
    if #scripts > 0 then
        print("\nScripts found in QuizUI:")
        for _, scriptPath in ipairs(scripts) do
            print("  " .. scriptPath)
        end
    end
    
    -- Check viewport info
    print("\n[Note: Camera ViewportSize is only available on client]")
    print("========== END SERVER DEBUG ==========\n")
end

-- Monitor when players join
Players.PlayerAdded:Connect(function(player)
    -- Wait for GUI to load
    player.CharacterAdded:Connect(function()
        task.wait(2) -- Give more time for GUI to fully replicate
        print("\n[SERVER DEBUG] Character spawned for:", player.Name)
        debugPlayerUI(player)
    end)
end)

-- Command to manually check all players
game.Players:GetService("Chat").Chatted:Connect(function(player, message)
    if message:lower() == "/debugui" then
        print("\n===== MANUAL UI DEBUG CHECK (SERVER) =====")
        print("Triggered by:", player.Name)
        for _, p in ipairs(Players:GetPlayers()) do
            debugPlayerUI(p)
        end
        print("===== END MANUAL DEBUG =====\n")
    elseif message:lower() == "/debugui me" then
        print("\n===== SINGLE PLAYER DEBUG CHECK (SERVER) =====")
        debugPlayerUI(player)
        print("===== END SINGLE PLAYER DEBUG =====\n")
    end
end)

-- Add periodic check command
local debugInterval = nil
game.Players:GetService("Chat").Chatted:Connect(function(player, message)
    if message:lower() == "/debugui start" then
        if debugInterval then
            print("[SERVER DEBUG] Debug monitoring already active")
            return
        end
        
        print("[SERVER DEBUG] Starting periodic UI monitoring (every 5 seconds)")
        debugInterval = task.spawn(function()
            while true do
                task.wait(5)
                print("\n===== PERIODIC UI CHECK (SERVER) =====")
                for _, p in ipairs(Players:GetPlayers()) do
                    debugPlayerUI(p)
                end
            end
        end)
    elseif message:lower() == "/debugui stop" then
        if debugInterval then
            task.cancel(debugInterval)
            debugInterval = nil
            print("[SERVER DEBUG] Stopped periodic UI monitoring")
        end
    end
end)

print("[DebugQuizUI] Enhanced server debug script loaded.")
print("Commands:")
print("  /debugui - Check all players")
print("  /debugui me - Check yourself only")
print("  /debugui start - Start periodic monitoring (every 5s)")
print("  /debugui stop - Stop periodic monitoring")