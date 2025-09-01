-- LeaderboardDisplay.lua (OPTIONAL)
-- Creates a physical leaderboard in the world showing top players
-- Place this in ServerScriptService if you want a physical leaderboard

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local LEADERBOARD_SIZE = 10 -- Show top 10 players
local UPDATE_INTERVAL = 30 -- Update every 30 seconds
local LEADERBOARD_POSITION = Vector3.new(0, 10, -20) -- Adjust position as needed

-- Wait for WinsManager to be available
local attempts = 0
while not _G.WinsManager and attempts < 10 do
	wait(0.5)
	attempts = attempts + 1
end

-- Find or create physical leaderboard
local function getPhysicalLeaderboard()
	-- First, try to find existing leaderboard in workspace
	local existingLeaderboard = workspace:FindFirstChild("WinsLeaderboard") or workspace:FindFirstChild("Leaderboard")
	
	if existingLeaderboard then
		print("[LeaderboardDisplay] Found existing leaderboard:", existingLeaderboard.Name)
		
		-- Try to find the GUI and slots
		local base = existingLeaderboard:FindFirstChild("Base") or existingLeaderboard:FindFirstChildWhichIsA("Part")
		if base then
			local surfaceGui = base:FindFirstChildWhichIsA("SurfaceGui")
			if surfaceGui then
				-- Find all text labels that represent player slots
				local slots = {}
				for i = 1, LEADERBOARD_SIZE do
					-- Look for slots by various naming patterns
					local slot = surfaceGui:FindFirstChild("Slot" .. i) or 
					           surfaceGui:FindFirstChild("Player" .. i) or
					           surfaceGui:FindFirstChild(tostring(i))
					
					-- If not found by name, try to find by position/order
					if not slot then
						local labels = {}
						for _, child in ipairs(surfaceGui:GetChildren()) do
							if child:IsA("TextLabel") and child.Name ~= "Title" and child.Name ~= "TitleLabel" then
								table.insert(labels, child)
							end
						end
						-- Sort by Y position
						table.sort(labels, function(a, b)
							return a.Position.Y.Scale < b.Position.Y.Scale
						end)
						if labels[i] then
							slot = labels[i]
						end
					end
					
					if slot then
						slots[i] = slot
						-- Set initial text if empty
						if slot.Text == "" then
							slot.Text = i .. ". ---"
						end
					end
				end
				
				-- Return the slots we found
				if #slots > 0 then
					return slots
				else
					warn("[LeaderboardDisplay] Found leaderboard but no slots!")
				end
			else
				warn("[LeaderboardDisplay] Found leaderboard but no SurfaceGui!")
			end
		else
			warn("[LeaderboardDisplay] Found leaderboard but no base part!")
		end
	end
	
	-- If no existing leaderboard found, create one
	print("[LeaderboardDisplay] No existing leaderboard found, creating new one...")
	
	local model = Instance.new("Model")
	model.Name = "WinsLeaderboard"
	
	-- Base part
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Anchored = true
	base.Size = Vector3.new(10, 15, 1)
	base.Position = LEADERBOARD_POSITION
	base.BrickColor = BrickColor.new("Dark stone grey")
	base.Material = Enum.Material.Granite
	base.Parent = model
	
	-- Title
	local titleGui = Instance.new("SurfaceGui")
	titleGui.Face = Enum.NormalId.Front
	titleGui.Parent = base
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "TOP WINNERS"
	titleLabel.TextScaled = true
	titleLabel.TextColor3 = Color3.new(1, 0.85, 0)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Parent = titleGui
	
	-- Create slots for top players
	local slots = {}
	for i = 1, LEADERBOARD_SIZE do
		local slot = Instance.new("TextLabel")
		slot.Size = UDim2.new(0.9, 0, 0.08, 0)
		slot.Position = UDim2.new(0.05, 0, 0.15 + (i * 0.08), 0)
		slot.BackgroundTransparency = 0.5
		slot.BackgroundColor3 = Color3.new(0, 0, 0)
		slot.Text = i .. ". ---"
		slot.TextScaled = true
		slot.TextColor3 = Color3.new(1, 1, 1)
		slot.Font = Enum.Font.SourceSans
		slot.Parent = titleGui
		
		-- Special colors for top 3
		if i == 1 then
			slot.TextColor3 = Color3.new(1, 0.85, 0) -- Gold
		elseif i == 2 then
			slot.TextColor3 = Color3.new(0.75, 0.75, 0.75) -- Silver
		elseif i == 3 then
			slot.TextColor3 = Color3.new(0.8, 0.5, 0.2) -- Bronze
		end
		
		slots[i] = slot
	end
	
	model.Parent = workspace
	return slots
end

-- Get leaderboard data
local function getLeaderboardData()
	local playerData = {}
	
	-- Collect all player wins
	for _, player in ipairs(Players:GetPlayers()) do
		local wins = 0
		
		-- Try to get wins from WinsManager if available
		if _G.WinsManager then
			wins = _G.WinsManager.GetWins(player)
		else
			-- Fallback to reading directly from leaderstats
			if player:FindFirstChild("leaderstats") then
				local winsValue = player.leaderstats:FindFirstChild("Wins")
				if winsValue then
					wins = winsValue.Value
				end
			end
		end
		
		if wins > 0 then
			table.insert(playerData, {
				name = player.Name,
				wins = wins
			})
		end
	end
	
	-- Sort by wins (descending)
	table.sort(playerData, function(a, b)
		return a.wins > b.wins
	end)
	
	return playerData
end

-- Update leaderboard display
local function updateLeaderboard(slots)
	local data = getLeaderboardData()
	
	for i = 1, LEADERBOARD_SIZE do
		if data[i] then
			slots[i].Text = i .. ". " .. data[i].name .. " - " .. data[i].wins .. " wins"
		else
			slots[i].Text = i .. ". ---"
		end
	end
end

-- Initialize
local function initialize()
	-- Get existing leaderboard or create if needed
	local leaderboardSlots = getPhysicalLeaderboard()
	
	if leaderboardSlots and #leaderboardSlots > 0 then
		print("[LeaderboardDisplay] Successfully initialized with", #leaderboardSlots, "slots")
		
		-- Update loop
		while true do
			updateLeaderboard(leaderboardSlots)
			wait(UPDATE_INTERVAL)
		end
	else
		warn("[LeaderboardDisplay] Failed to initialize leaderboard slots")
	end
end

-- Start the leaderboard
spawn(initialize)

print("[LeaderboardDisplay] Leaderboard system initialized")