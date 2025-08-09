-- IntermissionGui.client.lua
-- Client-side handler for intermission countdown UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for GUI to be cloned
local gui = script.Parent
local frame = gui:WaitForChild("Frame")
local textLabel = frame:WaitForChild("TextLabel")

-- Wait for RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local updateIntermissionRemote = remoteEvents:WaitForChild("UpdateIntermission")

-- GUI Tweens for smooth animations
local fadeInInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fadeOutInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function showIntermission(timeLeft)
    gui.Enabled = true
    
    -- Update text
    textLabel.Text = "Game will start in " .. timeLeft .. " seconds"
    
    -- Fade in animation
    frame.BackgroundTransparency = 1
    textLabel.TextTransparency = 1
    
    local frameFadeIn = TweenService:Create(frame, fadeInInfo, {BackgroundTransparency = 0.3})
    local textFadeIn = TweenService:Create(textLabel, fadeInInfo, {TextTransparency = 0})
    
    frameFadeIn:Play()
    textFadeIn:Play()
end

local function hideIntermission()
    -- Fade out animation
    local frameFadeOut = TweenService:Create(frame, fadeOutInfo, {BackgroundTransparency = 1})
    local textFadeOut = TweenService:Create(textLabel, fadeOutInfo, {TextTransparency = 1})
    
    frameFadeOut:Play()
    textFadeOut:Play()
    
    -- Disable GUI after fade out
    frameFadeOut.Completed:Connect(function()
        gui.Enabled = false
    end)
end

-- Listen for intermission updates
updateIntermissionRemote.OnClientEvent:Connect(function(show, timeLeft)
    if show then
        showIntermission(timeLeft)
    else
        hideIntermission()
    end
end)

-- Initially hide the GUI
gui.Enabled = false