-- DebugQuizUI.server.lua
-- Server-side debug script to monitor QuizUI state

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Function to check player GUI
local function debugPlayerUI(player)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    local quizUI = playerGui:FindFirstChild("QuizUI")
    if not quizUI then return end
    
    print("\n[SERVER DEBUG] QuizUI found for player:", player.Name)
    print("QuizUI FullName:", quizUI:GetFullName())
    
    -- Check for any server-side modifications
    local bg = quizUI:FindFirstChild("BG")
    if bg then
        print("BG found - checking for UIScale...")
        local uiScale = bg:FindFirstChildOfClass("UIScale")
        if uiScale then
            print("UIScale found! Scale value:", uiScale.Scale)
        else
            print("No UIScale found on BG")
        end
    end
end

-- Monitor when players join
Players.PlayerAdded:Connect(function(player)
    -- Wait for GUI to load
    player.CharacterAdded:Connect(function()
        task.wait(1) -- Give time for GUI to replicate
        debugPlayerUI(player)
    end)
end)

-- Command to manually check all players
game:GetService("Chat").Chatted:Connect(function(player, message)
    if message == "/debugui" then
        print("\n===== MANUAL UI DEBUG CHECK =====")
        for _, p in ipairs(Players:GetPlayers()) do
            debugPlayerUI(p)
        end
        print("===== END MANUAL DEBUG =====\n")
    end
end)

print("[DebugQuizUI] Server debug script loaded. Type '/debugui' in chat to check all players.")