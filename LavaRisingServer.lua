-- Lava Rising System - Server Script
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local LAVA_PART_NAME = "Lava"
local START_Y_POSITION = 4.85
local MAX_Y_POSITION = 70.85
local RISE_INTERVAL = 15 -- Seconds between each rise
local RISE_AMOUNT = 3 -- How much it rises each interval (studs)
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

-- Find lava part
local lavaPart = workspace:FindFirstChild(LAVA_PART_NAME)
if not lavaPart then
	warn("[LAVA SYSTEM] Could not find part named '" .. LAVA_PART_NAME .. "' in workspace!")
	return
end

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
		if not lavaActive then return end -- Only kill during active rounds
		
		local character = hit.Parent
		if not character then return end
		
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end
		
		-- Get player
		local victim = Players:GetPlayerFromCharacter(character)
		if not victim then return end
		
		-- Prevent duplicate kills
		if recentLavaDeaths[victim.UserId] then return end
		recentLavaDeaths[victim.UserId] = true
		
		debugPrint("Player killed by lava:", victim.Name)
		
		-- Check if they were recently pushed
		local killer = nil
		if _G.PushTracker then
			killer = _G.PushTracker.getRecentPusher(victim.UserId)
			if killer then
				debugPrint("Kill attributed to pusher:", killer.Name)
				-- Send killfeed notification
				killfeedEvent:FireAllClients(killer.Name, victim.Name)
				-- Clear push data
				_G.PushTracker.clearPushData(victim.UserId)
			end
		end
		
		-- Kill player
		humanoid.Health = 0
		
		-- Clear death tracking after respawn
		task.delay(2, function()
			recentLavaDeaths[victim.UserId] = nil
		end)
	end)
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
	
	debugPrint("Resetting lava to start position")
	
	-- Stop any active rising
	if riseTask then
		task.cancel(riseTask)
		riseTask = nil
	end
	
	lavaActive = false
	currentHeight = START_Y_POSITION
	
	-- Clear lava death tracking
	recentLavaDeaths = {}
	
	-- Instantly reset position (no tween)
	lavaPart.Position = originalPosition
	
	-- Notify clients
	lavaStatusEvent:FireAllClients("reset", START_Y_POSITION, MAX_Y_POSITION)
end

-- Start lava rising loop
local function startLavaRising()
	if riseTask then return end -- Already running
	
	debugPrint("Starting lava rising sequence")
	
	lavaActive = true
	currentHeight = START_Y_POSITION
	
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

print("========================================")
print("Lava Rising System Ready!")
print("Start Position Y:", START_Y_POSITION)
print("Max Position Y:", MAX_Y_POSITION)
print("Rise Interval:", RISE_INTERVAL, "seconds")
print("========================================")
print("Call _G.LavaRisingControl.startRising() to begin")
print("Call _G.LavaRisingControl.resetLava() to reset")
print("========================================")
