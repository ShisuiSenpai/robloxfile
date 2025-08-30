-- QuickMatchClientV2_DisableVersion.lua (uses RemoteEvents)
-- Client-side quick match button handler with disable functionality
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Wait for UI
local playerGui = player:WaitForChild("PlayerGui")
local quickMatchUI = playerGui:WaitForChild("QuickMatchUI")
local quickMatchBtn = quickMatchUI:WaitForChild("QuickMatchBtn")

-- Get RemoteEvents
local quickMatchEvent = ReplicatedStorage:WaitForChild("QuickMatchEvent")
local requestEvent = quickMatchEvent:WaitForChild("QuickMatchRequest")
local responseEvent = quickMatchEvent:WaitForChild("QuickMatchResponse")

print("[QuickMatch V2] Client initializing, RemoteEvents found")

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

-- Track pending request
local pendingRequest = false

-- UI State Management (Disable version)
local function setButtonEnabled(enabled, reason)
	print("[QuickMatch V2] Setting button enabled:", enabled, "Reason:", reason or "unknown")
	
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
	feedbackLabel.TextTransparency = 0
	
	-- Fade in
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

-- Handle server response
responseEvent.OnClientEvent:Connect(function(result)
	print("[QuickMatch V2] Received response:", result)
	
	pendingRequest = false
	
	-- Reset button text if still enabled
	if isButtonEnabled then
		quickMatchBtn.Text = "Quick Match"
	end
	
	-- Show result
	if result then
		showFeedback(result.message, result.success)
		
		if result.success then
			-- Optional: Add success sound or animation
		end
	else
		showFeedback("Invalid server response!", false)
	end
	
	-- Reset cooldown
	wait(COOLDOWN_TIME)
	isOnCooldown = false
end)

-- Handle button click
quickMatchBtn.MouseButton1Click:Connect(function()
	print("[QuickMatch V2] Button clicked, enabled:", isButtonEnabled, "cooldown:", isOnCooldown, "pending:", pendingRequest)
	
	if not isButtonEnabled then
		print("[QuickMatch V2] Button disabled, ignoring click")
		return
	end
	
	if isOnCooldown then
		showFeedback("Please wait before trying again...", false)
		return
	end
	
	if pendingRequest then
		showFeedback("Request already in progress...", false)
		return
	end
	
	-- Set cooldown and pending
	isOnCooldown = true
	pendingRequest = true
	
	-- Visual feedback
	quickMatchBtn.Text = "Finding match..."
	
	print("[QuickMatch V2] Sending request to server...")
	
	-- Send request
	requestEvent:FireServer()
	
	-- Set a timeout in case server doesn't respond
	task.wait(5)
	if pendingRequest then
		print("[QuickMatch V2] Request timed out")
		pendingRequest = false
		
		if isButtonEnabled then
			quickMatchBtn.Text = "Quick Match"
		end
		
		showFeedback("Server timeout! Please try again.", false)
		
		-- Reset cooldown
		wait(COOLDOWN_TIME)
		isOnCooldown = false
	end
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
	
	-- Clear any pending requests
	pendingRequest = false
	isOnCooldown = false
	
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
	-- Clear pending state
	pendingRequest = false
	isOnCooldown = false
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
					print("[QuickMatch V2] Failsafe: Re-enabling button")
					setButtonEnabled(true, "Failsafe check - not seated")
				end
			end
		end
	end
end)

print("[QuickMatch V2] Client initialized with RemoteEvents and respawn handling")