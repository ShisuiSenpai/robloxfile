-- DebugLeaderstats.lua
-- Place this in ServerScriptService to debug the leaderstats issue

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

print("[DEBUG] Starting leaderstats debug script...")

-- Check if LeaderstatsManager exists
local success, LeaderstatsManager = pcall(function()
	return require(ServerScriptService:WaitForChild("LeaderstatsManager", 5))
end)

if success then
	print("[DEBUG] LeaderstatsManager loaded successfully!")
	
	-- Check what functions are available
	print("[DEBUG] Available functions in LeaderstatsManager:")
	for key, value in pairs(LeaderstatsManager) do
		print("  -", key, type(value))
	end
else
	warn("[DEBUG] Failed to load LeaderstatsManager:", LeaderstatsManager)
end

-- Monitor player joins
Players.PlayerAdded:Connect(function(player)
	print("[DEBUG] Player joined:", player.Name)
	
	-- Wait a bit for leaderstats to be created
	wait(1)
	
	-- Check if leaderstats exists
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		print("[DEBUG] Leaderstats found for", player.Name)
		
		-- Check children
		for _, child in ipairs(leaderstats:GetChildren()) do
			print("  -", child.Name, "=", child.Value)
		end
	else
		warn("[DEBUG] No leaderstats found for", player.Name)
	end
end)

-- Check existing players
for _, player in ipairs(Players:GetPlayers()) do
	print("[DEBUG] Existing player:", player.Name)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		print("  - Has leaderstats")
		for _, child in ipairs(leaderstats:GetChildren()) do
			print("    -", child.Name, "=", child.Value)
		end
	else
		print("  - No leaderstats")
	end
end

print("[DEBUG] Debug script loaded")