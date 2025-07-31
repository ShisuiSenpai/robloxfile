-- StarterGui.AbilityUI.LocalScript
print("🔥🔥 AbilityUI LocalScript STARTED - Version 4.1 with FIXED TIMER SYSTEM")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
print("🔥 Player found:", Player.Name)

-- ROBUST LOADING - Wait for all dependencies
local screenGui
local originalFrame
local AbilityTypes

-- Function to safely get UI elements
local function initializeUI()
	print("🔥 Initializing UI...")

	-- Method 1: If script is inside AbilityUI ScreenGui
	if script.Parent and script.Parent:IsA("ScreenGui") then
		screenGui = script.Parent
		originalFrame = screenGui:FindFirstChild("Frame")
		print("🔥 Method 1: Found ScreenGui via script.Parent")
	end

	-- Method 2: If script is in StarterGui, find AbilityUI
	if not screenGui then
		local starterGui = Player:WaitForChild("PlayerGui")
		screenGui = starterGui:WaitForChild("AbilityUI", 10)
		if screenGui then
			originalFrame = screenGui:WaitForChild("Frame", 5)
			print("🔥 Method 2: Found ScreenGui in PlayerGui")
		end
	end

	-- Method 3: Direct search in PlayerGui
	if not screenGui then
		local playerGui = Player:WaitForChild("PlayerGui")
		for _, gui in pairs(playerGui:GetChildren()) do
			if gui.Name == "AbilityUI" and gui:IsA("ScreenGui") then
				screenGui = gui
				originalFrame = gui:FindFirstChild("Frame")
				print("🔥 Method 3: Found ScreenGui via search")
				break
			end
		end
	end

	if not screenGui or not originalFrame then
		warn("❌ Could not find AbilityUI ScreenGui or Frame!")
		warn("❌ Make sure AbilityUI exists in StarterGui with a Frame inside")
		return false
	end

	print("✅ UI Elements found successfully!")
	print("✅ ScreenGui:", screenGui.Name)
	print("✅ Frame:", originalFrame.Name)
	return true
end

-- Function to safely load modules
local function loadModules()
	print("🔥 Loading modules...")

	local success, result = pcall(function()
		local modules = ReplicatedStorage:WaitForChild("Modules", 10)
		if not modules then
			error("Modules folder not found in ReplicatedStorage")
		end

		local abilityTypesModule = modules:WaitForChild("AbilityTypes", 10)
		if not abilityTypesModule then
			error("AbilityTypes module not found")
		end

		return require(abilityTypesModule)
	end)

	if success then
		AbilityTypes = result
		print("✅ AbilityTypes loaded successfully!")
		return true
	else
		warn("❌ Failed to load AbilityTypes:", result)
		return false
	end
end

-- Wait for everything to load
local function waitForDependencies()
	print("🔥 Waiting for dependencies...")

	-- Wait for character
	if not Player.Character then
		print("🔥 Waiting for character...")
		Player.CharacterAdded:Wait()
	end
	print("✅ Character loaded!")

	-- Initialize UI
	if not initializeUI() then
		return false
	end

	-- Load modules
	if not loadModules() then
		return false
	end

	print("✅ All dependencies loaded successfully!")
	return true
end

-- Wait for everything before starting main script
if not waitForDependencies() then
	warn("❌ Failed to load dependencies - AbilityUI will not work")
	return
end

-- NOW START THE MAIN SCRIPT
print("🔥 Starting main AbilityUI script...")

-- UI Configuration
local UI_CONFIG = {
	AnimationDuration = 0.4,
	StackSpacing = 80,
	StartPosition = UDim2.new(1, -300, 0, 20),
	Colors = {
		ProgressFill = {
			Start = Color3.fromRGB(60, 60, 65),
			End = Color3.fromRGB(255, 255, 255)
		},
		ResetFlash = Color3.fromRGB(0, 255, 0)
	}
}

-- CLEAN SINGLE-INSTANCE SYSTEM
local activeAbilities = {}
local updateConnection = nil

-- Track last known expiry times to detect extensions
local lastExpiryTimes = {
	SpeedBoost = nil,
	Healer = nil
}

-- Hide the original frame (we'll clone it for each ability)
originalFrame.Visible = false
print("✅ Original frame hidden")

-- CLEAN UI MANAGEMENT - Single responsibility functions
local function createAbilityFrame(abilityName)
	print("🔥 Creating UI frame for:", abilityName)

	local frame = originalFrame:Clone()
	frame.Name = abilityName .. "Frame"
	frame.Parent = screenGui
	frame.Visible = false

	return {
		frame = frame,
		progressBg = frame.ProgressBg,
		progressFill = frame.ProgressBg.ProgressFill,
		shadow = frame.Shadow,
		nameLabel = frame.NameLabel,
		timeLabel = frame.TimeLabel
	}
end

-- Position all active ability frames vertically
local function repositionFrames()
	local yOffset = 20

	for abilityName, abilityData in pairs(activeAbilities) do
		if abilityData.ui and abilityData.ui.frame then
			local targetPosition = UDim2.new(1, -300, 0, yOffset)

			-- Smooth position transition
			local positionTween = TweenService:Create(abilityData.ui.frame,
				TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{Position = targetPosition}
			)
			positionTween:Play()

			yOffset = yOffset + UI_CONFIG.StackSpacing
		end
	end
end

-- Flash effect when ability duration is extended
local function flashProgressBar(ui)
	local originalColor = ui.progressFill.BackgroundColor3

	-- Flash green briefly
	ui.progressFill.BackgroundColor3 = UI_CONFIG.Colors.ResetFlash

	-- Tween back to original color
	local flashTween = TweenService:Create(ui.progressFill,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundColor3 = originalColor}
	)
	flashTween:Play()

	print("⚡⚡ Duration extension flash for", ui.nameLabel.Text)
end

-- SINGLE-INSTANCE UI CLEANER - Prevents duplicate hiding
local function cleanupAbilityUI(abilityName, reason)
	local abilityData = activeAbilities[abilityName]
	if not abilityData then
		print("🔍 No UI to cleanup for", abilityName, "- already cleaned")
		return -- Already cleaned up
	end

	print("🧹 CLEANING UP UI for", abilityName, "- Reason:", reason)

	-- Mark as being cleaned up to prevent duplicate calls
	local ui = abilityData.ui
	activeAbilities[abilityName] = nil -- Remove immediately to prevent duplicate calls

	-- Clear expiry tracking
	lastExpiryTimes[abilityName] = nil

	-- Animate out and destroy
	local tweenInfo = TweenInfo.new(
		UI_CONFIG.AnimationDuration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In
	)

	-- Fade out all elements
	TweenService:Create(ui.frame, tweenInfo, {BackgroundTransparency = 1}):Play()

	for _, child in pairs(ui.frame:GetDescendants()) do
		if child:IsA("GuiObject") and child ~= ui.frame then
			if child:IsA("TextLabel") then
				TweenService:Create(child, tweenInfo, {TextTransparency = 1}):Play()
			elseif child.BackgroundTransparency then
				TweenService:Create(child, tweenInfo, {BackgroundTransparency = 1}):Play()
			end
		end
	end

	-- Remove after animation
	task.spawn(function()
		task.wait(UI_CONFIG.AnimationDuration)
		if ui.frame and ui.frame.Parent then
			ui.frame:Destroy()
		end
		repositionFrames() -- Reposition remaining frames
		print("✅ UI cleanup completed for", abilityName)
	end)
end

-- CLEAN UI CREATOR/UPDATER - Single responsibility with FIXED TIMER CALCULATION
local function showOrUpdateAbilityUI(abilityName, totalRemainingTime, wasExtended)
	print("🔥🔥 ShowOrUpdate UI CALLED for", abilityName, "extended:", wasExtended or false)

	-- Get the ability's base duration from config
	local abilityConfig = AbilityTypes[abilityName]
	if not abilityConfig then
		warn("❌ No ability config found for", abilityName)
		return
	end

	local baseDuration
	if abilityName == "SpeedBoost" then
		baseDuration = abilityConfig.duration -- 15 seconds
	elseif abilityName == "Healer" then
		baseDuration = abilityConfig.vfxDuration -- 3 seconds
	else
		baseDuration = 15 -- fallback
	end

	print("📏 Server expiry: N/A Current time:", workspace.DistributedGameTime)
	print("📏 ACTUAL remaining time from server:", totalRemainingTime, "seconds")

	-- If ability UI already exists, update it
	if activeAbilities[abilityName] then
		print("🔄 Updating existing UI for", abilityName)
		local abilityData = activeAbilities[abilityName]

		-- Update timing for the new total duration
		abilityData.serverExpiryTime = workspace.DistributedGameTime + totalRemainingTime
		abilityData.totalDuration = totalRemainingTime -- Track the full stacked duration

		-- Flash if duration was extended
		if wasExtended then
			print("⚡ Flashing progress bar for extension")
			flashProgressBar(abilityData.ui)
		end

		print("📏 Updated total duration:", totalRemainingTime, "seconds")
		return
	end

	-- Create new UI for this ability
	print("✨ Creating completely new UI for", abilityName)

	-- Check if we have the required UI elements
	if not screenGui or not originalFrame then
		warn("❌ Missing UI elements - screenGui:", screenGui, "originalFrame:", originalFrame)
		return
	end

	local ui = createAbilityFrame(abilityName)
	if not ui or not ui.frame then
		warn("❌ Failed to create UI frame for", abilityName)
		return
	end

	-- Store ability data with proper duration tracking
	activeAbilities[abilityName] = {
		name = abilityName,
		serverExpiryTime = workspace.DistributedGameTime + totalRemainingTime,
		totalDuration = totalRemainingTime, -- This is the full duration (may be stacked)
		baseDuration = baseDuration, -- This is the single-use duration from config
		ui = ui
	}

	-- Update UI content
	ui.nameLabel.Text = abilityConfig.name or abilityName

	-- Reset progress bar to FULL (always start at 100%)
	ui.progressFill.Size = UDim2.new(1, 0, 1, 0)
	ui.progressFill.BackgroundColor3 = UI_CONFIG.Colors.ProgressFill.Start
	ui.timeLabel.Text = math.ceil(totalRemainingTime) .. "s"

	print("✅ UI content set - Name:", ui.nameLabel.Text, "Time:", ui.timeLabel.Text)
	print("✅ Total duration for progress:", totalRemainingTime, "seconds")

	-- Position the frame
	repositionFrames()

	-- Make UI visible and animate in
	ui.frame.Visible = true
	print("✅ UI frame made visible for", abilityName)

	-- Set initial transparency for fade-in effect
	for _, child in pairs(ui.frame:GetDescendants()) do
		if child:IsA("GuiObject") then
			if child:IsA("TextLabel") then
				child.TextTransparency = 1
			elseif child.BackgroundTransparency then
				child.BackgroundTransparency = 1
			end
		end
	end
	ui.frame.BackgroundTransparency = 1

	-- Animate fade-in
	local tweenInfo = TweenInfo.new(
		UI_CONFIG.AnimationDuration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	-- Fade in frame
	TweenService:Create(ui.frame, tweenInfo, {BackgroundTransparency = 0.1}):Play()

	-- Fade in all other elements
	for _, child in pairs(ui.frame:GetDescendants()) do
		if child:IsA("GuiObject") and child ~= ui.frame then
			if child:IsA("TextLabel") then
				TweenService:Create(child, tweenInfo, {TextTransparency = 0}):Play()
			elseif child.BackgroundTransparency and child == ui.shadow then
				TweenService:Create(child, tweenInfo, {BackgroundTransparency = 0.7}):Play()
			elseif child.BackgroundTransparency and child ~= ui.shadow then
				TweenService:Create(child, tweenInfo, {BackgroundTransparency = 0}):Play()
			end
		end
	end

	print("✅ Animation started for", abilityName, "- Actual duration:", totalRemainingTime, "seconds")
end

-- CLEAN PROGRESS UPDATER - Uses ACTUAL ability duration, not estimates
local function updateAbilityProgress(abilityName, abilityData)
	local currentTime = workspace.DistributedGameTime
	local remainingTime = math.max(0, abilityData.serverExpiryTime - currentTime)

	-- Check if expired
	if remainingTime <= 0 then
		print("⏰ UI timer expired for", abilityName)
		cleanupAbilityUI(abilityName, "timer_expired")
		return
	end

	local ui = abilityData.ui
	if not ui or not ui.frame or not ui.frame.Parent then
		-- UI was destroyed externally, clean up data
		activeAbilities[abilityName] = nil
		return
	end

	-- FIXED: Calculate progress using the ACTUAL total duration of this specific ability
	local totalDuration = abilityData.totalDuration
	local progress = remainingTime / totalDuration -- This gives us the correct 0-1 range

	-- Clamp progress between 0 and 1
	progress = math.max(0, math.min(1, progress))

	print("🔍 Progress calc for", abilityName, ": ")
	print("  Remaining:", remainingTime, "Total:", totalDuration, "Progress:", progress)

	-- Update progress bar width
	ui.progressFill.Size = UDim2.new(progress, 0, 1, 0)

	-- Update progress bar color (dark to white as time runs out)
	local colorProgress = 1 - progress -- Invert so it goes from dark to white
	local currentColor = UI_CONFIG.Colors.ProgressFill.Start:lerp(UI_CONFIG.Colors.ProgressFill.End, colorProgress)
	ui.progressFill.BackgroundColor3 = currentColor

	-- Update time label
	ui.timeLabel.Text = math.ceil(remainingTime) .. "s"
end

-- Detect if duration was extended
local function detectDurationExtension(abilityName, currentExpiry)
	local lastExpiry = lastExpiryTimes[abilityName]

	if lastExpiry then
		local timeDifference = currentExpiry - lastExpiry

		-- If the new expiry is significantly later, it was extended
		if timeDifference > 2 then
			print("🔄 DETECTED duration extension for", abilityName, "- Added:", timeDifference, "seconds")
			lastExpiryTimes[abilityName] = currentExpiry
			return true
		end
	end

	lastExpiryTimes[abilityName] = currentExpiry
	return false
end

-- SINGLE RESPONSIBILITY MONITOR - FIXED TIMER CALCULATION
local function monitorServerAttributes()
	if not Player.Character then return end

	local currentTime = workspace.DistributedGameTime

	-- Monitor SpeedBoost with FIXED TIMING CALCULATION
	local speedBoost = Player:GetAttribute("SpeedBoost")
	local speedBoostExpiry = Player:GetAttribute("SpeedBoost_Expiry")

	if speedBoost and speedBoostExpiry then
		-- FIXED: Use server's calculation to avoid sync issues
		local serverRemainingTime = math.max(0, speedBoostExpiry - workspace.DistributedGameTime)
		
		-- Get the base duration from AbilityTypes to validate
		local abilityConfig = AbilityTypes["SpeedBoost"]
		local baseDuration = abilityConfig and abilityConfig.duration or 15
		
		-- CLAMP the remaining time to never exceed the base duration
		-- This prevents the UI from showing inflated times due to server/client sync issues
		local displayRemainingTime = math.min(serverRemainingTime, baseDuration)
		
		print("🔥🔥 ShowOrUpdate UI CALLED for SpeedBoost extended: false")
		print("📏 Server expiry:", speedBoostExpiry, "Current time:", currentTime)
		print("📏 ACTUAL remaining time from server:", displayRemainingTime, "seconds")

		if displayRemainingTime > 0 then
			local wasExtended = detectDurationExtension("SpeedBoost", speedBoostExpiry)

			if not activeAbilities["SpeedBoost"] then
				print("🔥🔥 NEW SpeedBoost detected")
				showOrUpdateAbilityUI("SpeedBoost", displayRemainingTime, false)
			elseif wasExtended then
				print("🔄🔄 SpeedBoost EXTENDED detected")
				showOrUpdateAbilityUI("SpeedBoost", displayRemainingTime, true)
			end
		else
			print("❓ SpeedBoost has negative remaining time:", displayRemainingTime)
		end
	elseif activeAbilities["SpeedBoost"] then
		-- Server attribute removed, cleanup UI
		print("🔥 SpeedBoost server attribute removed - cleaning up UI")
		cleanupAbilityUI("SpeedBoost", "server_removed")
	end

	-- Monitor Healer VFX with FIXED TIMING CALCULATION
	local healerVfxExpiry = Player:GetAttribute("HealerVFX_Expiry")

	if healerVfxExpiry then
		-- FIXED: Use server's calculation to avoid sync issues
		local serverRemainingTime = math.max(0, healerVfxExpiry - workspace.DistributedGameTime)
		
		-- Get the base VFX duration from AbilityTypes to validate
		local abilityConfig = AbilityTypes["Healer"]
		local baseVfxDuration = abilityConfig and abilityConfig.vfxDuration or 3
		
		-- CLAMP the remaining time to never exceed the base VFX duration
		local displayRemainingTime = math.min(serverRemainingTime, baseVfxDuration)
		
		print("🔥🔥 NEW Healer VFX detected")
		print("📏 Server expiry:", healerVfxExpiry, "Current time:", currentTime)
		print("📏 ACTUAL remaining time from server:", displayRemainingTime, "seconds")

		if displayRemainingTime > 0 then
			local wasExtended = detectDurationExtension("Healer", healerVfxExpiry)

			if not activeAbilities["Healer"] then
				print("🔥🔥 NEW Healer VFX detected")
				showOrUpdateAbilityUI("Healer", displayRemainingTime, false)
			elseif wasExtended then
				print("🔄🔄 Healer VFX EXTENDED detected")
				showOrUpdateAbilityUI("Healer", displayRemainingTime, true)
			end
		else
			print("❓ Healer VFX has negative remaining time:", displayRemainingTime)
		end
	elseif activeAbilities["Healer"] then
		-- Server attribute removed, cleanup UI
		print("🔥 Healer VFX server attribute removed - cleaning up UI")
		cleanupAbilityUI("Healer", "server_removed")
	end
end

-- MAIN UPDATE LOOP - Clean separation of concerns
local function updateAllSystems()
	-- Update visual progress for all active UIs
	for abilityName, abilityData in pairs(activeAbilities) do
		updateAbilityProgress(abilityName, abilityData)
	end

	-- Monitor server changes
	monitorServerAttributes()
end

-- Start the clean update loop
local function startUpdateLoop()
	if updateConnection then
		updateConnection:Disconnect()
	end

	updateConnection = RunService.Heartbeat:Connect(updateAllSystems)
	print("✅✅ FIXED Multi-Ability UI system started")
end

-- Stop the update loop and cleanup
local function stopUpdateLoop()
	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end

	-- Clean up all active UIs
	for abilityName in pairs(activeAbilities) do
		cleanupAbilityUI(abilityName, "system_stopped")
	end

	-- Clear all tracking
	lastExpiryTimes = {
		SpeedBoost = nil,
		Healer = nil
	}
end

-- Handle character respawn
Player.CharacterAdded:Connect(function()
	print("🔥 Character respawned - restarting FIXED UI system")
	stopUpdateLoop()
	task.wait(1)
	startUpdateLoop()
end)

-- Initialize
print("🔥 Initializing FIXED UI system...")
if Player.Character then
	startUpdateLoop()
else
	Player.CharacterAdded:Wait()
	startUpdateLoop()
end

print("✅✅ FIXED AbilityUI LocalScript fully loaded and running!")

-- Enhanced debug: Show current system status every 10 seconds
task.spawn(function()
	while true do
		task.wait(10)
		if Player.Character then
			local currentTime = workspace.DistributedGameTime
			print("🔍 === FIXED UI SYSTEM STATUS ===")
			print("🔍 Current time:", currentTime)

			-- Check server attributes
			local speedBoost = Player:GetAttribute("SpeedBoost")
			local speedBoostExpiry = Player:GetAttribute("SpeedBoost_Expiry")
			local healerVfxExpiry = Player:GetAttribute("HealerVFX_Expiry")

			print("🔍 Server attributes:")
			print("  SpeedBoost:", speedBoost)
			print("  SpeedBoost_Expiry:", speedBoostExpiry)
			if speedBoostExpiry then
				print("  SpeedBoost remaining:", speedBoostExpiry - currentTime)
			end
			print("  HealerVFX_Expiry:", healerVfxExpiry)

			-- Check active UIs
			print("🔍 Active UIs:")
			local activeCount = 0
			for abilityName, abilityData in pairs(activeAbilities) do
				activeCount = activeCount + 1
				local remainingTime = abilityData.serverExpiryTime - currentTime
				print("  " .. abilityName .. ": " .. remainingTime .. "s remaining")
				print("    Total duration:", abilityData.totalDuration .. "s")
				print("    Progress:", ((remainingTime / abilityData.totalDuration) * 100) .. "%")
			end
			if activeCount == 0 then
				print("  (No active UIs)")
			end
			print("🔍 === END STATUS ===")
		end
	end
end)
