-- Sound Manager - Client-Side Sound System
-- Place this as a LocalScript in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

print("[SOUND MANAGER] Loading...")

-- Wait for RemoteEvent
local playSoundEvent = ReplicatedStorage:WaitForChild("PlaySound", 10)

if not playSoundEvent then
	warn("[SOUND MANAGER] Could not find PlaySound RemoteEvent!")
	return
end

-- ==================== SOUND CONFIGURATION ====================

local SOUND_IDS = {
	-- Countdown sounds
	countdown_tick = "rbxassetid://122531515344257",      -- Tick sound for 3, 2, 1
	countdown_go = "rbxassetid://140419294351439",        -- GO! sound

	-- King of the Hill sounds
	become_king = "rbxassetid://2222222",         -- When you become king
	king_tick = "rbxassetid://2222222",           -- Subtle tick while king timer counts
	player_wins = "rbxassetid://7464917496",         -- Victory sound

	-- Intermission sounds
	intermission_tick = "rbxassetid://122531515344257",   -- Quiet tick during intermission

	-- Push tool sounds
	push_swing = "rbxassetid://74238153433253",          -- Swing/whoosh sound when pushing
	push_hit = "rbxassetid://146163534",            -- Impact sound when hitting player
}

-- Sound volume settings
local SOUND_VOLUMES = {
	countdown_tick = 0.5,
	countdown_go = 0.7,
	become_king = 0.6,
	king_tick = 0.15,
	player_wins = 0.8,
	intermission_tick = 0.1,
	push_swing = 0.4,
	push_hit = 0.5,
}

-- ==================== SOUND POOL SYSTEM ====================

local soundPool = {}
local activeSounds = {}

-- Create a sound instance
local function createSound(soundName, soundId, volume)
	local sound = Instance.new("Sound")
	sound.Name = soundName
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.Parent = SoundService

	-- Cleanup when finished
	sound.Ended:Connect(function()
		activeSounds[sound] = nil
		sound:Destroy()
	end)

	return sound
end

-- Play a sound (with pooling to prevent overlap)
local function playSound(soundName, forceNew)
	local soundId = SOUND_IDS[soundName]
	local volume = SOUND_VOLUMES[soundName] or 0.5

	if not soundId then
		warn("[SOUND MANAGER] Sound not found:", soundName)
		return
	end

	-- Check if this sound is already playing (prevent spam)
	if not forceNew and soundPool[soundName] then
		local existingSound = soundPool[soundName]
		if existingSound and existingSound.IsPlaying then
			-- Don't play again if already playing
			return
		end
	end

	-- Create and play new sound
	local sound = createSound(soundName, soundId, volume)
	soundPool[soundName] = sound
	activeSounds[sound] = true

	sound:Play()

	return sound
end

-- Stop a specific sound
local function stopSound(soundName)
	if soundPool[soundName] then
		soundPool[soundName]:Stop()
		soundPool[soundName] = nil
	end
end

-- Stop all sounds
local function stopAllSounds()
	for sound, _ in pairs(activeSounds) do
		if sound then
			sound:Stop()
		end
	end
	activeSounds = {}
	soundPool = {}
end

-- ==================== REMOTE EVENT HANDLER ====================

playSoundEvent.OnClientEvent:Connect(function(soundName, forceNew)
	playSound(soundName, forceNew)
end)

-- ==================== EXPORT FOR OTHER SCRIPTS ====================

-- Make functions available globally for other LocalScripts
_G.SoundManager = {
	play = playSound,
	stop = stopSound,
	stopAll = stopAllSounds
}

print("[SOUND MANAGER] Ready!")
