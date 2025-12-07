--[[
	SmashVFXHandler (Script)
	Location: ServerScriptService/SmashVFXHandler
	
	Server-side handler for multiplayer VFX replication.
	Validates client requests and broadcasts VFX to all players.
	
	NOTE: This is OPTIONAL - only needed if you want other players 
	to see the VFX. For single-player, use only the LocalScript.
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local MAX_DISTANCE = 20
local COOLDOWN = 0.3

-- Player cooldowns
local playerCooldowns = {}

-- Create RemoteEvent
local smashVFXEvent = Instance.new("RemoteEvent")
smashVFXEvent.Name = "SmashVFXEvent"
smashVFXEvent.Parent = ReplicatedStorage

-- Validate the request from client
local function validateRequest(player, position, normal)
	-- Check if player has a character
	local character = player.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	-- Validate position type
	if typeof(position) ~= "Vector3" then return false end
	if typeof(normal) ~= "Vector3" then return false end
	
	-- Check distance
	local distance = (position - humanoidRootPart.Position).Magnitude
	if distance > MAX_DISTANCE + 5 then -- Small buffer for lag
		return false
	end
	
	-- Check cooldown
	local lastTime = playerCooldowns[player.UserId] or 0
	if tick() - lastTime < COOLDOWN then
		return false
	end
	
	return true
end

-- Handle VFX request from client
local function onSmashVFXRequested(player, position, normal)
	-- Validate
	if not validateRequest(player, position, normal) then
		return
	end
	
	-- Set cooldown
	playerCooldowns[player.UserId] = tick()
	
	-- Broadcast to all clients (including the sender for consistency)
	smashVFXEvent:FireAllClients(player, position, normal)
end

-- Cleanup when player leaves
local function onPlayerRemoving(player)
	playerCooldowns[player.UserId] = nil
end

-- Connect events
smashVFXEvent.OnServerEvent:Connect(onSmashVFXRequested)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("[SmashVFX] Server handler initialized!")
