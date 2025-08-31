-- SimpleStreakTest.lua
-- A simpler version to test if BillboardGui works
-- Place in ServerScriptService temporarily for testing

local Players = game:GetService("Players")

-- Test function to create a simple streak UI
local function createSimpleStreakUI(player)
	print("[SimpleStreakTest] Creating UI for", player.Name)
	
	local character = player.Character
	if not character then
		print("[SimpleStreakTest] No character")
		return
	end
	
	local head = character:FindFirstChild("Head")
	if not head then
		print("[SimpleStreakTest] No head")
		return
	end
	
	-- Create simple BillboardGui
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "TestStreakDisplay"
	billboardGui.Size = UDim2.new(3, 0, 1, 0)
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.Parent = head
	
	-- Simple text label
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundColor3 = Color3.new(0, 0, 0)
	textLabel.BackgroundTransparency = 0.3
	textLabel.Text = "🔥 STREAK TEST"
	textLabel.TextScaled = true
	textLabel.TextColor3 = Color3.new(1, 1, 0)
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.Parent = billboardGui
	
	print("[SimpleStreakTest] UI created successfully")
end

-- Test on all players when they spawn
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		wait(1) -- Wait for character to fully load
		createSimpleStreakUI(player)
	end)
	
	-- If character already exists
	if player.Character then
		wait(1)
		createSimpleStreakUI(player)
	end
end)

-- Test on existing players
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		createSimpleStreakUI(player)
	end
end

print("[SimpleStreakTest] Script loaded")