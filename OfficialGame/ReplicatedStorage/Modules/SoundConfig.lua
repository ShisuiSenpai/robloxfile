--[[
	SOUND CONFIGURATION MODULE
	Place this ModuleScript in ReplicatedStorage/Modules
	
	Centralizes all sound IDs for easy management
	Replace the placeholder IDs with your actual Roblox sound asset IDs
]]

local SoundConfig = {}

-- ========================================
-- CRATE SYSTEM SOUNDS
-- ========================================

SoundConfig.CrateSounds = {
	-- Sound when player opens the crate (at the start of animation)
	CrateOpen = {
		SoundId = "rbxassetid://121586099520003", -- REPLACE WITH YOUR SOUND ID
		Volume = 0.5,
		Pitch = 1.0,
	},

	-- Click sound during spinning animation
	SpinClick = {
		SoundId = "rbxassetid://88442833509532", -- REPLACE WITH YOUR SOUND ID
		Volume = 0.3,
		Pitch = 1.0, -- This will be dynamically adjusted
	},
}

-- ========================================
-- RARITY EXPLOSION SOUNDS
-- ========================================

SoundConfig.ExplosionSounds = {
	["Common"] = {
		SoundId = "rbxassetid://111174530730534", -- REPLACE WITH YOUR SOUND ID
		Volume = 0.6,
		Pitch = 1.0,
	},

	["Uncommon"] = {
		SoundId = "rbxassetid://111174530730534", -- REPLACE WITH YOUR SOUND ID
		Volume = 0.6,
		Pitch = 1.0,
	},

	["Rare"] = {
		SoundId = "rbxassetid://3295473241", -- REPLACE WITH YOUR SOUND ID
		Volume = 0.6,
		Pitch = 1.0,
	},

	["Legendary"] = {
		SoundId = "rbxassetid://1926608277", -- REPLACE WITH YOUR SOUND ID
		Volume = 0.7,
		Pitch = 1.0,
	},

	["Godly"] = {
		SoundId = "rbxassetid://86811255527245", -- REPLACE WITH YOUR SOUND ID
		Volume = 0.8,
		Pitch = 1.0,
	},

	["???"] = {
		SoundId = "rbxassetid://104414731133846", -- REPLACE WITH YOUR SOUND ID (glitchy/secret sound)
		Volume = 0.9,
		Pitch = 1.0,
	},
}

-- ========================================
-- HELPER FUNCTION
-- ========================================

-- Function to create a Sound instance from config
function SoundConfig.CreateSound(soundConfig, parent)
	if not soundConfig or soundConfig.SoundId == "rbxassetid://0" then
		warn("Sound ID not configured or is placeholder")
		return nil
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundConfig.SoundId
	sound.Volume = soundConfig.Volume or 0.5
	sound.PlaybackSpeed = soundConfig.Pitch or 1.0
	sound.Parent = parent

	return sound
end

return SoundConfig
