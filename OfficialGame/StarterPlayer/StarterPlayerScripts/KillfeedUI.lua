-- Killfeed UI - Client Script
-- Place this as a LocalScript in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvent
local killfeedEvent = ReplicatedStorage:WaitForChild("KillfeedEvent", 10)

if not killfeedEvent then
	warn("[KILLFEED] Could not find KillfeedEvent!")
	return
end

print("[KILLFEED] Loaded successfully")

-- ==================== CONFIGURATION ====================

local MAX_KILLS_DISPLAYED = 3
local KILL_DISPLAY_TIME = 5 -- Seconds each kill is shown
local KILL_SPACING = 42 -- Pixels between kills

-- ==================== UI CREATION ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KillfeedUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

-- Container for all kill notifications
local killContainer = Instance.new("Frame")
killContainer.Name = "KillContainer"
killContainer.AnchorPoint = Vector2.new(0, 1)
killContainer.Position = UDim2.new(0, 10, 1, -10)
killContainer.Size = UDim2.new(0, 350, 0, 300)
killContainer.BackgroundTransparency = 1
killContainer.BorderSizePixel = 0
killContainer.Parent = screenGui

-- Add UIScale for mobile
local containerScale = Instance.new("UIScale")
containerScale.Parent = killContainer

-- ==================== MOBILE SCALING ====================

local function updateUIScale()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local baseScale = math.min(viewportSize.X / 1920, viewportSize.Y / 1080)
	local scale = math.clamp(baseScale, 0.85, 1.3)
	containerScale.Scale = scale
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale)
updateUIScale()

-- ==================== KILL NOTIFICATION CREATION ====================

local activeKills = {}

local function createKillNotification(killerName, victimName)
	-- Create kill frame
	local killFrame = Instance.new("Frame")
	killFrame.Name = "KillNotification"
	killFrame.AnchorPoint = Vector2.new(0, 1)
	killFrame.Size = UDim2.new(1, 0, 0, 35)
	killFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	killFrame.BackgroundTransparency = 0.2
	killFrame.BorderSizePixel = 0
	killFrame.Parent = killContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = killFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 100, 120)
	stroke.Thickness = 1
	stroke.Transparency = 0.6
	stroke.Parent = killFrame

	-- Killer name (white)
	local killerLabel = Instance.new("TextLabel")
	killerLabel.Name = "Killer"
	killerLabel.Position = UDim2.new(0, 10, 0, 0)
	killerLabel.Size = UDim2.new(0.4, -15, 1, 0)
	killerLabel.BackgroundTransparency = 1
	killerLabel.Font = Enum.Font.GothamBold
	killerLabel.Text = killerName
	killerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	killerLabel.TextSize = 15
	killerLabel.TextXAlignment = Enum.TextXAlignment.Right
	killerLabel.TextTruncate = Enum.TextTruncate.AtEnd
	killerLabel.Parent = killFrame

	-- Arrow
	local arrowLabel = Instance.new("TextLabel")
	arrowLabel.Name = "Arrow"
	arrowLabel.Position = UDim2.new(0.4, 0, 0, 0)
	arrowLabel.Size = UDim2.new(0.2, 0, 1, 0)
	arrowLabel.BackgroundTransparency = 1
	arrowLabel.Font = Enum.Font.GothamBold
	arrowLabel.Text = "~>"
	arrowLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	arrowLabel.TextSize = 14
	arrowLabel.TextTransparency = 0.3
	arrowLabel.Parent = killFrame

	-- Victim name (red)
	local victimLabel = Instance.new("TextLabel")
	victimLabel.Name = "Victim"
	victimLabel.Position = UDim2.new(0.6, 0, 0, 0)
	victimLabel.Size = UDim2.new(0.4, -10, 1, 0)
	victimLabel.BackgroundTransparency = 1
	victimLabel.Font = Enum.Font.Gotham
	victimLabel.Text = victimName
	victimLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	victimLabel.TextSize = 15
	victimLabel.TextXAlignment = Enum.TextXAlignment.Left
	victimLabel.TextTruncate = Enum.TextTruncate.AtEnd
	victimLabel.Parent = killFrame

	return killFrame
end

-- ==================== KILL MANAGEMENT ====================

local function updateKillPositions()
	for i, killData in ipairs(activeKills) do
		local targetPosition = UDim2.new(0, 0, 1, -(i * KILL_SPACING))

		if killData.frame.Position ~= targetPosition then
			local tween = TweenService:Create(
				killData.frame,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Position = targetPosition}
			)
			tween:Play()
		end
	end
end

local isRemoving = false

local function removeKill(killData, skipListRemoval)
	if not killData or not killData.frame then return end

	-- Mark as removing to prevent double-removal
	if killData.removing then return end
	killData.removing = true

	-- Find and remove from active kills list
	if not skipListRemoval then
		for i, data in ipairs(activeKills) do
			if data == killData then
				table.remove(activeKills, i)
				break
			end
		end
	end

	local frame = killData.frame
	if not frame.Parent then 
		return 
	end

	-- Quick fade out animation
	local tween = TweenService:Create(
		frame,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Position = UDim2.new(0, -400, frame.Position.Y.Scale, frame.Position.Y.Offset),
			BackgroundTransparency = 1
		}
	)
	tween:Play()

	-- Fade children
	for _, child in pairs(frame:GetDescendants()) do
		if child:IsA("TextLabel") then
			TweenService:Create(child, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
		elseif child:IsA("UIStroke") then
			TweenService:Create(child, TweenInfo.new(0.25), {Transparency = 1}):Play()
		end
	end

	-- Destroy after animation
	task.delay(0.3, function()
		if frame and frame.Parent then
			frame:Destroy()
		end
	end)
end

local function addKill(killerName, victimName)
	print("[KILLFEED] Adding kill:", killerName, "~>", victimName)

	-- Create notification
	local killFrame = createKillNotification(killerName, victimName)

	-- Start off-screen to the left
	killFrame.Position = UDim2.new(0, -400, 1, 0)

	-- Add to active kills
	local killData = {
		frame = killFrame,
		timestamp = tick(),
		removing = false
	}
	table.insert(activeKills, 1, killData) -- Insert at beginning (newest at top)

	-- Remove oldest if exceeding max (instant removal from list, animated fade)
	if #activeKills > MAX_KILLS_DISPLAYED then
		local toRemove = {}

		-- Collect items to remove
		for i = MAX_KILLS_DISPLAYED + 1, #activeKills do
			table.insert(toRemove, activeKills[i])
		end

		-- Remove from list first
		for i = #activeKills, MAX_KILLS_DISPLAYED + 1, -1 do
			table.remove(activeKills, i)
		end

		-- Then animate them out
		for _, oldKill in ipairs(toRemove) do
			task.spawn(function()
				removeKill(oldKill, true) -- Skip list removal since already removed
			end)
		end
	end

	-- Update positions (animates the new kill in)
	updateKillPositions()

	-- Schedule auto-removal after display time
	task.delay(KILL_DISPLAY_TIME, function()
		-- Verify it's still in the list and not already removed
		for i, data in ipairs(activeKills) do
			if data == killData and not killData.removing then
				removeKill(killData)
				updateKillPositions()
				break
			end
		end
	end)
end

-- ==================== EVENT HANDLER ====================

killfeedEvent.OnClientEvent:Connect(function(killerName, victimName)
	print("[KILLFEED] Kill:", killerName, "~>", victimName)
	addKill(killerName, victimName)
end)

-- Cleanup
player.CharacterRemoving:Connect(function()
	for _, killData in ipairs(activeKills) do
		if killData.frame then
			killData.frame:Destroy()
		end
	end
	activeKills = {}
end)

print("[KILLFEED] Ready!")
