-- SoundManager.lua
-- ModuleScript to handle all game sounds

local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SoundManager = {}

-- Sound IDs (replace these with your actual sound IDs)
local SOUND_IDS = {
	CARD_HOVER = "rbxassetid://0", -- Replace with hover sound ID
	CARD_CLICK = "rbxassetid://0", -- Replace with click sound ID
	POKER_CLICK = "rbxassetid://0", -- Replace with poker card click sound ID
	COUNTDOWN_TICK = "rbxassetid://0", -- Replace with countdown tick sound ID (optional)
	GAME_START = "rbxassetid://0", -- Replace with game start sound ID (optional)
}

-- Sound properties configuration
local SOUND_CONFIG = {
	CARD_HOVER = {
		Volume = 0.3,
		Pitch = 1.2,
		EmitterSize = 10,
	},
	CARD_CLICK = {
		Volume = 0.5,
		Pitch = 1,
		EmitterSize = 10,
	},
	POKER_CLICK = {
		Volume = 0.8,
		Pitch = 0.9,
		EmitterSize = 15,
	},
	COUNTDOWN_TICK = {
		Volume = 0.4,
		Pitch = 1,
		EmitterSize = 15,
	},
	GAME_START = {
		Volume = 0.5,
		Pitch = 1.1,
		EmitterSize = 20,
	},
}

-- Cache for loaded sounds
local soundCache = {}
local lastHoverSound = nil

-- Initialize sounds
local function initializeSounds()
	for soundName, soundId in pairs(SOUND_IDS) do
		if soundId ~= "rbxassetid://0" then -- Only create if ID is set
			local sound = Instance.new("Sound")
			sound.SoundId = soundId
			sound.Name = soundName
			
			-- Apply configuration
			local config = SOUND_CONFIG[soundName]
			if config then
				sound.Volume = config.Volume
				if config.Pitch then
					sound.Pitch = config.Pitch
				end
				sound.EmitterSize = config.EmitterSize or 10
			end
			
			sound.Parent = SoundService
			soundCache[soundName] = sound
		end
	end
end

-- Play a sound
function SoundManager:PlaySound(soundName, position)
	local sound = soundCache[soundName]
	if not sound then
		warn("[SoundManager] Sound not found:", soundName)
		return
	end
	
	-- Clone the sound for overlapping plays
	local soundClone = sound:Clone()
	
	-- If position is provided, create a 3D sound
	if position then
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Position = position
		part.Size = Vector3.new(1, 1, 1)
		part.Parent = workspace
		
		soundClone.Parent = part
		soundClone:Play()
		
		-- Clean up after sound finishes
		soundClone.Ended:Connect(function()
			part:Destroy()
		end)
	else
		-- Play as 2D sound
		soundClone.Parent = SoundService
		soundClone:Play()
		
		-- Clean up after sound finishes
		soundClone.Ended:Connect(function()
			soundClone:Destroy()
		end)
	end
	
	return soundClone
end

-- Play hover sound (with debouncing to prevent spam)
function SoundManager:PlayHoverSound(position)
	-- Debounce hover sounds
	if lastHoverSound and lastHoverSound.IsPlaying then
		return
	end
	
	lastHoverSound = self:PlaySound("CARD_HOVER", position)
end

-- Play click sound
function SoundManager:PlayClickSound(position)
	self:PlaySound("CARD_CLICK", position)
end

-- Play poker click sound
function SoundManager:PlayPokerClickSound(position)
	self:PlaySound("POKER_CLICK", position)
end

-- Play countdown tick
function SoundManager:PlayCountdownTick()
	self:PlaySound("COUNTDOWN_TICK")
end

-- Play game start sound
function SoundManager:PlayGameStartSound()
	self:PlaySound("GAME_START")
end

-- Stop all sounds
function SoundManager:StopAllSounds()
	for _, sound in pairs(soundCache) do
		sound:Stop()
	end
	
	-- Also stop any cloned sounds
	for _, child in ipairs(SoundService:GetChildren()) do
		if child:IsA("Sound") then
			child:Stop()
		end
	end
end

-- Initialize on module load
initializeSounds()

return SoundManager