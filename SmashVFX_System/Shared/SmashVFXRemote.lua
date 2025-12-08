--[[
	SmashVFXRemote (ModuleScript)
	Location: ReplicatedStorage/SmashVFXRemote
	
	Shared module for creating and accessing the RemoteEvent
	Used for multiplayer VFX replication (optional)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SmashVFXRemote = {}

local REMOTE_NAME = "SmashVFXEvent"

function SmashVFXRemote.GetOrCreateRemote()
	local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
	
	if not remote then
		-- Only server can create RemoteEvents
		if game:GetService("RunService"):IsServer() then
			remote = Instance.new("RemoteEvent")
			remote.Name = REMOTE_NAME
			remote.Parent = ReplicatedStorage
		else
			-- Client waits for it
			remote = ReplicatedStorage:WaitForChild(REMOTE_NAME, 10)
		end
	end
	
	return remote
end

return SmashVFXRemote
