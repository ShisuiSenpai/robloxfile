-- QuickMatchClient.lua (Disable Button Version)
-- Client-side quick match button handler with disable functionality
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Wait for UI and RemoteFunction
local playerGui = player:WaitForChild("PlayerGui")
local quickMatchUI = playerGui:WaitForChild("QuickMatchUI")
local quickMatchBtn = quickMatchUI:WaitForChild("QuickMatchBtn")
local quickMatchEvent = ReplicatedStorage:WaitForChild("QuickMatchEvent")
local quickMatchRemote = quickMatchEvent:WaitForChild("QuickMatchFunction")

print("[QuickMatch] Client initializing, RemoteFunction found:", quickMatchRemote ~= nil)

-- UI feedback elements (create if they don't exist)
local feedbackLabel = quickMatchUI:FindFirstChild("FeedbackLabel")
if not feedbackLabel then
	feedbackLabel = Instance.new("TextLabel")
	feedbackLabel.Name = "FeedbackLabel"
	feedbackLabel.Size = UDim2.new(0.8, 0, 0, 30)
	feedbackLabel.Position = UDim2.new(0.1, 0, 1, 10)
	feedbackLabel.BackgroundTransparency = 1
	feedbackLabel.TextScaled = true
	feedbackLabel.Font = Enum.Font.SourceSansBold
	feedbackLabel.TextColor3 = Color3.new(1, 1, 1)
	feedbackLabel.Text = ""
	feedbackLabel.Parent = quickMatchUI
end

-- Button state management
local isButtonEnabled = true
local originalButtonColor = quickMatchBtn.BackgroundColor3
local disabledButtonColor = Color3.fromRGB(100, 100, 100)

-- Cooldown tracking
local isOnCooldown = false
local COOLDOWN_TIME = 2 -- seconds

-- UI State Management (Disable version)
local function setButtonEnabled(enabled, reason)
	print("[QuickMatch] Setting button enabled:", enabled, "Reason:", reason or "unknown")
	
	isButtonEnabled = enabled
	quickMatchBtn.Active = enabled
	quickMatchBtn.AutoButtonColor = enabled
	
	if enabled then
		quickMatchBtn.Text = "Quick Match"
		quickMatchBtn.BackgroundColor3 = originalButtonColor
		quickMatchBtn.TextTransparency = 0
	else
		quickMatchBtn.Text = "In Game"
		quickMatchBtn.BackgroundColor3 = disabledButtonColor
		quickMatchBtn.TextTransparency = 0.5
	end
end

-- Show feedback message
local function showFeedback(message, isSuccess)
	feedbackLabel.Text = message
	feedbackLabel.TextColor3 = isSuccess and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
	
	-- Fade in
	feedbackLabel.TextTransparency = 1
	local fadeIn = TweenService:Create(feedbackLabel, 
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)
	fadeIn:Play()
	
	-- Fade out after delay
	wait(2)
	local fadeOut = TweenService:Create(feedbackLabel,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{TextTransparency = 1}
	)
	fadeOut:Play()
end

-- Handle button click
quickMatchBtn.MouseButton1Click:Connect(function()
	print("[QuickMatch] Button clicked, enabled:", isButtonEnabled, "cooldown:", isOnCooldown)
	
	if not isButtonEnabled then
		print("[QuickMatch] Button disabled, ignoring click")
		return
	end
	
	if isOnCooldown then
		showFeedback("Please wait before trying again...", false)
		return
	end
	
	-- Set cooldown
	isOnCooldown = true
	
	-- Visual feedback
	local originalText = quickMatchBtn.Text
	quickMatchBtn.Text = "Finding match..."
	
	print("[QuickMatch] Invoking server...")
	
	-- Request quick match with timeout
	local result = nil
	local finished = false
	
	-- Invoke server in a coroutine with timeout
	coroutine.wrap(function()
		local invokeSuccess, invokeResult = pcall(function()
			return quickMatchRemote:InvokeServer()
		end)
		
		if invokeSuccess then
			result = invokeResult
		else
			print("[QuickMatch] Server invocation error:", invokeResult)
			result = {
				success = false,
				message = "Server error: " .. tostring(invokeResult)
			}
		end
		finished = true
	end)()
	
	-- Wait for response with timeout
	local timeoutCounter = 0
	while not finished and timeoutCounter < 50 do -- 5 second timeout
		wait(0.1)
		timeoutCounter = timeoutCounter + 1
	end
	
	if not finished then
		print("[QuickMatch] Server invocation timed out!")
		showFeedback("Server timeout! Please try again.", false)
		-- Reset button text
		if isButtonEnabled then
			quickMatchBtn.Text = originalText
		end
		-- Reset cooldown
		wait(COOLDOWN_TIME)
		isOnCooldown = false
		return
	end
	
	print("[QuickMatch] Server response:", result)
	
	-- Reset button text if still enabled
	if isButtonEnabled then
		quickMatchBtn.Text = originalText
	end
	
	-- Show result
	if result then
		showFeedback(result.message, result.success)
		
		if result.success then
			-- Optional: Add success sound or animation
		end
	else
		showFeedback("No response from server!", false)
	end
	
	-- Reset cooldown
	wait(COOLDOWN_TIME)
	isOnCooldown = false
end)

-- Optional: Add hover effects (only when enabled)
quickMatchBtn.MouseEnter:Connect(function()
	if isButtonEnabled and not isOnCooldown then
		TweenService:Create(quickMatchBtn,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(100, 255, 100)}
		):Play()
	end
end)

quickMatchBtn.MouseLeave:Connect(function()
	if isButtonEnabled then
		TweenService:Create(quickMatchBtn,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = originalButtonColor}
		):Play()
	end
end)

-- Monitor seating state
local function checkSeatingState()
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	-- Disable button if seated, enable if not
	if humanoid.SeatPart then
		setButtonEnabled(false, "Player is seated")
	else
		setButtonEnabled(true, "Player is not seated")
	end
end

-- Monitor character and seating
local function onCharacterAdded(character)
	-- Wait for character to be fully loaded
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")
	
	-- Add a small delay to ensure character is fully initialized
	wait(0.5)
	
	-- Always enable button on respawn (player is not seated when they respawn)
	setButtonEnabled(true, "Character respawned")
	
	-- Check initial state after delay
	task.wait(0.1)
	checkSeatingState()
	
	-- Monitor seating changes
	local seatConnection
	local seatPartConnection
	
	seatConnection = humanoid.Seated:Connect(function()
		task.wait(0.1) -- Small delay to ensure seat state is updated
		checkSeatingState()
	end)
	
	seatPartConnection = humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		task.wait(0.1) -- Small delay to ensure seat state is updated
		checkSeatingState()
	end)
	
	-- Clean up connections when character is removed
	character.AncestryChanged:Connect(function()
		if not character.Parent then
			if seatConnection then
				seatConnection:Disconnect()
			end
			if seatPartConnection then
				seatPartConnection:Disconnect()
			end
		end
	end)
end

-- Connect character events
if player.Character then
	task.spawn(function()
		onCharacterAdded(player.Character)
	end)
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Also handle character removal to ensure UI is re-enabled
player.CharacterRemoving:Connect(function()
	-- Enable UI when character is being removed (about to respawn)
	setButtonEnabled(true, "Character removing")
end)

-- Listen for game state changes from all tables
for i = 1, 10 do
	local tableFolder = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild("Table" .. i)
	if tableFolder then
		local gameStateEvent = tableFolder:FindFirstChild("GameStateUpdate")
		if gameStateEvent then
			gameStateEvent.OnClientEvent:Connect(function(state, data)
				-- Re-enable button when game ends
				if state == "game_end" or state == "full_reset" then
					-- Delay to allow for end game animations
					wait(3)
					checkSeatingState()
				elseif state == "table_state_changed" and data then
					-- Only disable button if player is actually seated at a table
					local character = player.Character
					if character then
						local humanoid = character:FindFirstChild("Humanoid")
						if humanoid and humanoid.SeatPart then
							-- Disable button during active game states only if seated
							if data.state == "IN_GAME" or data.state == "COUNTDOWN" then
								setButtonEnabled(false, "Game state: " .. data.state)
							end
						end
					end
				end
			end)
		end
	end
end

-- Failsafe: Periodically check button state in case events are missed
task.spawn(function()
	while true do
		wait(5) -- Check every 5 seconds
		if player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid then
				-- If not seated but button is disabled, enable it
				if not humanoid.SeatPart and not isButtonEnabled then
					print("[QuickMatch] Failsafe: Re-enabling button")
					setButtonEnabled(true, "Failsafe check - not seated")
				end
			end
		end
	end
end)

print("[QuickMatch] Client initialized with button disable management and respawn handling")