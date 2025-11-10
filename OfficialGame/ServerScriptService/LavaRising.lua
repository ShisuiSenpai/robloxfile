-- Lava Rising System - Server Script
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local LAVA_PART_NAME = "Lava"
local START_Y_POSITION = 4.85
local MAX_Y_POSITION = 150
local RISE_INTERVAL = 5 -- Seconds between each rise
local RISE_AMOUNT = 8 -- How much it rises each interval (studs)
local RISE_DURATION = 2 -- How long the tween takes (smooth rising)
local DEBUG = false

-- State
local lavaActive = false
local currentHeight = START_Y_POSITION
local riseTask = nil

-- Debug print
local function debugPrint(...)
	if DEBUG then
		print("[LAVA SYSTEM]", ...)
	end
end

print("[LAVA SYSTEM] Starting...")

-- Find lava part (works for Part, MeshPart, UnionOperation, etc.)
local lavaPart = workspace:FindFirstChild(LAVA_PART_NAME)
if not lavaPart or not lavaPart:IsA("BasePart") then
	warn("[LAVA SYSTEM] Could not find BasePart named '" .. LAVA_PART_NAME .. "' in workspace!")
	warn("[LAVA SYSTEM] Make sure you have a Part/MeshPart named 'Lava' in Workspace")
	return
end

print("[LAVA SYSTEM] Found lava part:", lavaPart.Name, "Type:", lavaPart.ClassName)

-- Store original position
local originalPosition = lavaPart.Position

-- Create RemoteEvents
local lavaStatusEvent = ReplicatedStorage:FindFirstChild("LavaStatus") or Instance.new("RemoteEvent")
lavaStatusEvent.Name = "LavaStatus"
lavaStatusEvent.Parent = ReplicatedStorage

local killfeedEvent = ReplicatedStorage:FindFirstChild("KillfeedEvent") or Instance.new("RemoteEvent")
killfeedEvent.Name = "KillfeedEvent"
killfeedEvent.Parent = ReplicatedStorage

debugPrint("Lava part found at:", lavaPart.Position)
debugPrint("Will rise from Y:", START_Y_POSITION, "to Y:", MAX_Y_POSITION)

-- Track players who died to lava (prevent duplicate kill credits)
local recentLavaDeaths = {}

-- Setup lava touch kill with kill attribution
local function setupLavaKill()
	lavaPart.Touched:Connect(function(hit)
		if not lavaActive then 
			debugPrint("Lava touch but not active")
			return 
		end

		-- More robust character detection
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then 
			debugPrint("No character found from hit:", hit.Name)
			return 
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then 
			debugPrint("No humanoid or already dead")
			return 
		end

		-- Get player
		local victim = Players:GetPlayerFromCharacter(character)
		if not victim then 
			debugPrint("Not a player character:", character.Name)
			return 
		end

		-- Prevent duplicate kills
		if recentLavaDeaths[victim.UserId] then 
			debugPrint("Already processed death for:", victim.Name)
			return 
		end
		recentLavaDeaths[victim.UserId] = true

		print("[LAVA] Player", victim.Name, "touched lava!")

		-- Check if they were recently pushed
		local killer = nil
		if _G.PushTracker then
			killer = _G.PushTracker.getRecentPusher(victim.UserId)
			if killer then
				print("[LAVA] Kill attributed to pusher:", killer.Name)

				-- Send killfeed notification
				killfeedEvent:FireAllClients(killer.Name, victim.Name)

				-- Award kill to pusher
				if _G.StatsManager then
					print("[LAVA] Awarding kill to:", killer.Name)
					_G.StatsManager.addKill(killer)
					print("[LAVA] Kill awarded successfully")
				else
					warn("[LAVA] StatsManager not available, cannot award kill!")
				end

				-- Clear push data
				_G.PushTracker.clearPushData(victim.UserId)
			else
				print("[LAVA] No recent pusher found for:", victim.Name)
			end
		else
			print("[LAVA] PushTracker not available!")
		end

		-- Kill player
		humanoid.Health = 0

		-- Clear death tracking after respawn
		task.delay(2, function()
			recentLavaDeaths[victim.UserId] = nil
		end)
	end)

	print("[LAVA] Touch detection setup complete")
end

-- Smoothly rise lava to target Y position
local function riseLava(targetY)
	if not lavaPart then return end

	-- Clamp to max height
	targetY = math.min(targetY, MAX_Y_POSITION)

	-- Calculate new position
	local newPosition = Vector3.new(
		originalPosition.X,
		targetY,
		originalPosition.Z
	)

	-- Create tween for smooth rising
	local tween = TweenService:Create(
		lavaPart,
		TweenInfo.new(RISE_DURATION, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{Position = newPosition}
	)

	debugPrint("Rising lava to Y:", targetY)

	-- Notify clients
	lavaStatusEvent:FireAllClients("rising", targetY, MAX_Y_POSITION)

	-- Play tween
	tween:Play()
	tween.Completed:Wait()

	currentHeight = targetY
end

-- Reset lava to starting position
local function resetLava()
	if not lavaPart then return end

	print("[LAVA] Resetting lava to start position")

	-- Stop any active rising
	if riseTask then
		task.cancel(riseTask)
		riseTask = nil
	end

	lavaActive = false
	currentHeight = START_Y_POSITION

	-- Clear lava death tracking
	recentLavaDeaths = {}

	-- Instantly reset position (no tween) - force Y position to start
	lavaPart.Position = Vector3.new(originalPosition.X, START_Y_POSITION, originalPosition.Z)

	print("[LAVA] Lava reset to position:", lavaPart.Position)
	print("[LAVA] Current height set to:", currentHeight)

	-- Notify clients
	lavaStatusEvent:FireAllClients("reset", START_Y_POSITION, MAX_Y_POSITION)
end

-- Start lava rising loop
local function startLavaRising()
	if riseTask then 
		print("[LAVA] Lava rising already active, canceling old task")
		task.cancel(riseTask)
		riseTask = nil
	end

	print("[LAVA] Starting lava rising sequence")

	-- Force reset to start position first
	lavaPart.Position = Vector3.new(originalPosition.X, START_Y_POSITION, originalPosition.Z)

	lavaActive = true
	currentHeight = START_Y_POSITION

	print("[LAVA] Lava reset to Y:", lavaPart.Position.Y, "before rising")

	-- Initial notification
	lavaStatusEvent:FireAllClients("started", currentHeight, MAX_Y_POSITION)

	riseTask = task.spawn(function()
		-- Wait a bit before first rise (give players time)
		task.wait(RISE_INTERVAL)

		while lavaActive and currentHeight < MAX_Y_POSITION do
			-- Calculate next height
			local nextHeight = currentHeight + RISE_AMOUNT

			-- Rise the lava
			riseLava(nextHeight)

			-- Check if reached max
			if currentHeight >= MAX_Y_POSITION then
				debugPrint("Lava reached maximum height!")
				lavaStatusEvent:FireAllClients("maxHeight", MAX_Y_POSITION, MAX_Y_POSITION)
				break
			end

			-- Wait before next rise
			task.wait(RISE_INTERVAL)
		end

		riseTask = nil
	end)
end

-- Stop lava rising
local function stopLavaRising()
	if riseTask then
		task.cancel(riseTask)
		riseTask = nil
	end
	lavaActive = false
	debugPrint("Lava rising stopped")
end

-- Setup lava kill on touch
setupLavaKill()

-- Listen for round status changes
local roundStatusEvent = ReplicatedStorage:WaitForChild("RoundStatus", 10)
if roundStatusEvent then
	roundStatusEvent.OnServerEvent:Connect(function(player, status)
		-- This won't be called, but we can listen to when it fires to all clients
	end)

	-- Hook into existing round system
	-- We'll start lava when round starts and reset when round ends
	local function hookRoundSystem()
		-- Monitor game state by checking for round start/end patterns
		local lastStatus = nil

		-- Since we can't directly listen to FireAllClients, we'll use a different approach
		-- We'll start lava rising after the countdown ends
	end

	hookRoundSystem()
else
	warn("[LAVA SYSTEM] Could not find RoundStatus event!")
end

-- Create a function to be called by round system
_G.LavaRisingControl = {
	startRising = startLavaRising,
	stopRising = stopLavaRising,
	resetLava = resetLava
}

-- Alternative: Listen for specific game states
-- We'll add this to the round system integration
local function integrateWithRoundSystem()
	-- Wait for existing players and new players
	local function monitorPlayer(player)
		-- When a player's character is added during a round, check game state
		player.CharacterAdded:Connect(function(character)
			-- Check if lava should be active based on current game state
			task.wait(1)
			if lavaActive then
				-- Notify the player about current lava status
				lavaStatusEvent:FireClient(player, "update", currentHeight, MAX_Y_POSITION)
			end
		end)
	end

	for _, player in pairs(Players:GetPlayers()) do
		monitorPlayer(player)
	end

	Players.PlayerAdded:Connect(monitorPlayer)
end

integrateWithRoundSystem()

-- Wait for PushTracker and StatsManager to be ready (ensure proper load order)
task.spawn(function()
	local attempts = 0
	while not _G.PushTracker and attempts < 50 do
		task.wait(0.1)
		attempts = attempts + 1
	end

	if _G.PushTracker then
		print("[LAVA] PushTracker found! Kill attribution ready")
	else
		warn("[LAVA] PushTracker not found after 5 seconds - kills won't be attributed")
	end
end)

task.spawn(function()
	local attempts = 0
	while not _G.StatsManager and attempts < 50 do
		task.wait(0.1)
		attempts = attempts + 1
	end

	if _G.StatsManager then
		print("[LAVA] StatsManager found! Kill tracking ready")
	else
		warn("[LAVA] StatsManager not found after 5 seconds - kills won't be tracked")
	end
end)

print("========================================")
print("Lava Rising System Ready!")
print("Start Position Y:", START_Y_POSITION)
print("Max Position Y:", MAX_Y_POSITION)
print("Rise Interval:", RISE_INTERVAL, "seconds")
print("========================================")
print("Call _G.LavaRisingControl.startRising() to begin")
print("Call _G.LavaRisingControl.resetLava() to reset")
print("========================================")
