-- SoundManager.lua
-- ModuleScript to handle all game sounds
-- PLACE THIS IN ReplicatedStorage

local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local SoundManager = {}

-- Sound IDs (replace these with your actual sound IDs)
SoundManager.SOUND_IDS = {
	CARD_HOVER = "rbxassetid://0", -- Replace with hover sound ID
	CARD_CLICK = "rbxassetid://0", -- Replace with click sound ID
	POKER_CLICK = "rbxassetid://0", -- Replace with poker card click sound ID
	COUNTDOWN_TICK = "rbxassetid://0", -- Replace with countdown tick sound ID
	GAME_START = "rbxassetid://0", -- Replace with game start sound ID
}

-- Simple function to play a sound
function SoundManager:PlaySoundAtPosition(soundId, position, volume, pitch)
	if soundId == "rbxassetid://0" or soundId == "" then
		return -- Don't play if no sound ID set
	end
	
	-- Create sound
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.Pitch = pitch or 1
	sound.RollOffMaxDistance = 50
	sound.RollOffMinDistance = 10
	
	if position then
		-- 3D sound - create part at position
		local part = Instance.new("Part")
		part.Name = "SoundEmitter"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false -- THIS IS KEY! Prevents mouse raycast detection
		part.CanTouch = false -- Also prevents touch detection
		part.Transparency = 1
		part.Size = Vector3.new(0.1, 0.1, 0.1) -- Make it tiny
		part.Position = position
		part.Parent = workspace
		
		sound.Parent = part
		sound:Play()
		
		-- Clean up after sound finishes
		sound.Ended:Connect(function()
			part:Destroy()
		end)
		
		-- Backup cleanup
		Debris:AddItem(part, 10)
	else
		-- 2D sound
		sound.Parent = workspace
		sound:Play()
		
		-- Clean up
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
		
		-- Backup cleanup
		Debris:AddItem(sound, 10)
	end
	
	return sound
end

-- Hover sound with debounce
local lastHoverTime = 0
local HOVER_DEBOUNCE = 0.1 -- Minimum time between hover sounds

function SoundManager:PlayHoverSound(position)
	local now = tick()
	if now - lastHoverTime < HOVER_DEBOUNCE then
		return -- Skip if too soon
	end
	lastHoverTime = now
	
	return self:PlaySoundAtPosition(self.SOUND_IDS.CARD_HOVER, position, 0.3, 1.2)
end

function SoundManager:PlayClickSound(position)
	return self:PlaySoundAtPosition(self.SOUND_IDS.CARD_CLICK, position, 0.5, 1)
end

function SoundManager:PlayPokerClickSound(position)
	return self:PlaySoundAtPosition(self.SOUND_IDS.POKER_CLICK, position, 0.8, 0.9)
end

function SoundManager:PlayCountdownTick()
	return self:PlaySoundAtPosition(self.SOUND_IDS.COUNTDOWN_TICK, nil, 0.4, 1)
end

function SoundManager:PlayGameStartSound()
	return self:PlaySoundAtPosition(self.SOUND_IDS.GAME_START, nil, 0.5, 1.1)
end

return SoundManager