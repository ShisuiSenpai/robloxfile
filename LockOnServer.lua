-- LockOnServer Script (Optional - for multiplayer synchronization)
-- Place in: ServerScriptService > LockOnServer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- This script is optional and only needed if you want other players to see lock-on indicators
-- The current system works entirely client-side, which is recommended for performance

-- Create remote events folder if needed
local remotesFolder = ReplicatedStorage:FindFirstChild("LockOnRemotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "LockOnRemotes"
	remotesFolder.Parent = ReplicatedStorage
end

-- Create remotes if they don't exist
local requestLockOn = remotesFolder:FindFirstChild("RequestLockOn") or Instance.new("RemoteEvent")
requestLockOn.Name = "RequestLockOn"
requestLockOn.Parent = remotesFolder

local updateLockOn = remotesFolder:FindFirstChild("UpdateLockOn") or Instance.new("RemoteEvent")
updateLockOn.Name = "UpdateLockOn"
updateLockOn.Parent = remotesFolder

-- Track active locks for validation
local activeLocks = {}

-- Handle lock-on requests (if you want server validation)
requestLockOn.OnServerEvent:Connect(function(player, targetCharacter, isLocking)
	-- Validate the request
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	if isLocking and targetCharacter then
		-- Validate target
		if not targetCharacter:FindFirstChild("HumanoidRootPart") or 
		   not targetCharacter:FindFirstChildOfClass("Humanoid") then
			return
		end
		
		-- Store the lock
		activeLocks[player] = targetCharacter
		
		-- Broadcast to other players if needed
		updateLockOn:FireAllClients(player, targetCharacter, true)
	else
		-- Remove the lock
		activeLocks[player] = nil
		updateLockOn:FireAllClients(player, nil, false)
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	if activeLocks[player] then
		activeLocks[player] = nil
		updateLockOn:FireAllClients(player, nil, false)
	end
end)

print("Lock-On Server initialized (optional multiplayer support)")