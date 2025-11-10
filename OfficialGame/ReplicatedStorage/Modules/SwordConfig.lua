--[[
	SWORD CONFIGURATION MODULE
	Add all your swords here with their custom settings
	
	Each sword can have unique:
	- Models (HolsteredSword and Sword Tool)
	- Holster position and rotation
	- Attack speed and duration
	- Push force and range (NO DAMAGE - push only!)
	- Animation
]]

local SwordConfig = {}

-- ========================================
-- RARITY SYSTEM
-- ========================================

SwordConfig.Rarities = {
	["Common"] = {
		Color = Color3.fromRGB(150, 150, 150), -- Gray
		Chance = 55,
		DisplayName = "Common",
		SortOrder = 1,
	},
	["Uncommon"] = {
		Color = Color3.fromRGB(80, 200, 80), -- Green
		Chance = 25,
		DisplayName = "Uncommon",
		SortOrder = 2,
	},
	["Rare"] = {
		Color = Color3.fromRGB(80, 140, 255), -- Blue
		Chance = 12,
		DisplayName = "Rare",
		SortOrder = 3,
	},
	["Legendary"] = {
		Color = Color3.fromRGB(255, 70, 70), -- Red
		Chance = 7,
		DisplayName = "Legendary",
		SortOrder = 4,
	},
	["Godly"] = {
		Color = Color3.fromRGB(255, 220, 60), -- Yellow/Gold
		Chance = 1,
		DisplayName = "Godly",
		SortOrder = 5,
	},
	["???"] = {
		Color = Color3.fromRGB(180, 100, 255), -- Purple
		Chance = 0.1,
		DisplayName = "???",
		SortOrder = 6,
	},
}

-- ========================================
-- SWORD DEFINITIONS
-- ========================================

SwordConfig.Swords = {
	-- COMMON SWORDS (55% total)
	["Nightward"] = {
		Rarity = "Common",
		HolsteredModelName = "HolsteredNightward",
		SwordPartName = "Nightward",
		ToolName = "Nightward",

		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.45,
			AttackCooldown = 0.5,
			AnimationId = "rbxassetid://102835293832677",
			PushForce = 50, -- Push force (was Damage)
			AttackRange = 10, -- Hit detection range
		},

		Keybind = Enum.KeyCode.One,
	},

	["Hollow"] = {
		Rarity = "Common",
		HolsteredModelName = "HolsteredHollow",
		SwordPartName = "Hollow",
		ToolName = "Hollow",

		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.45,
			AttackCooldown = 0.4,
			AnimationId = "rbxassetid://102835293832677",
			PushForce = 50,
			AttackRange = 10,
		},

		Keybind = Enum.KeyCode.Two,
	},

	["Dravos"] = {
		Rarity = "Common",
		HolsteredModelName = "HolsteredDravos",
		SwordPartName = "Dravos",
		ToolName = "Dravos",

		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.45,
			AttackCooldown = 0.4,
			AnimationId = "rbxassetid://102835293832677",
			PushForce = 50,
			AttackRange = 10,
		},

		Keybind = Enum.KeyCode.Three,
	},

	-- UNCOMMON SWORDS (25% total)
	["Asterion"] = {
		Rarity = "Uncommon",
		HolsteredModelName = "HolsteredAsterion",
		SwordPartName = "Asterion",
		ToolName = "Asterion",

		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.45,
			AttackCooldown = 0.4,
			AnimationId = "rbxassetid://102835293832677",
			PushForce = 52,
			AttackRange = 10,
		},

		Keybind = Enum.KeyCode.Four,
	},

	["Duskcarver"] = {
		Rarity = "Uncommon",
		HolsteredModelName = "HolsteredDuskcarver",
		SwordPartName = "Duskcarver",
		ToolName = "Duskcarver",

		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.45,
			AttackCooldown = 0.4,
			AnimationId = "rbxassetid://102835293832677",
			PushForce = 52,
			AttackRange = 10,
		},

		Keybind = Enum.KeyCode.Five,
	},

	-- RARE SWORDS (12% total)
	["Soulbreaker"] = {
		Rarity = "Rare",
		HolsteredModelName = "HolsteredSoulbreaker",
		SwordPartName = "Soulbreaker",
		ToolName = "Soulbreaker",

		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.45,
			AttackCooldown = 0.4,
			AnimationId = "rbxassetid://102835293832677",
			PushForce = 54,
			AttackRange = 10,
		},

		Keybind = Enum.KeyCode.Six,
	},

	["Nyxcaller"] = {
		Rarity = "Rare",
		HolsteredModelName = "HolsteredNyxcaller",
		SwordPartName = "Nyxcaller",
		ToolName = "Nyxcaller",

		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.45,
			AttackCooldown = 0.4,
			AnimationId = "rbxassetid://102835293832677",
			PushForce = 54,
			AttackRange = 10,
		},

		Keybind = Enum.KeyCode.Seven,
	},

	-- LEGENDARY SWORDS (7% total)
	["Wolfreign"] = {
		Rarity = "Legendary",
		HolsteredModelName = "HolsteredWolfreign",
		SwordPartName = "Wolfreign",
		ToolName = "Wolfreign",

		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.45,
			AttackCooldown = 0.4,
			AnimationId = "rbxassetid://102835293832677",
			PushForce = 56,
			AttackRange = 10,
		},

		Keybind = Enum.KeyCode.Eight,
	},

	["WynterEdge"] = {
		Rarity = "Legendary",
		HolsteredModelName = "HolsteredWynterEdge",
		SwordPartName = "WynterEdge",
		ToolName = "WynterEdge",

		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.45,
			AttackCooldown = 0.4,
			AnimationId = "rbxassetid://102835293832677",
			PushForce = 56,
			AttackRange = 10,
		},

		Keybind = Enum.KeyCode.Nine,
	},

	-- GODLY SWORDS (1% total)
	["Seraphine"] = {
		Rarity = "Godly",
		HolsteredModelName = "HolsteredSwordSeraphine",
		SwordPartName = "Seraphine",
		ToolName = "Seraphine",

		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.45,
			AttackCooldown = 0.3,
			AnimationId = "rbxassetid://102835293832677",
			PushForce = 58,
			AttackRange = 12,
		},

		Keybind = Enum.KeyCode.Zero,
	},

	["Moonwake"] = {
		Rarity = "Godly",
		HolsteredModelName = "HolsteredMoonwake",
		SwordPartName = "Moonwake",
		ToolName = "Moonwake",

		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.45,
			AttackCooldown = 0.3,
			AnimationId = "rbxassetid://102835293832677",
			PushForce = 58,
			AttackRange = 12,
		},

		Keybind = nil,
	},

	-- ??? TIER (0.1% - Ultra rare!)
	["Dawnstar"] = {
		Rarity = "???",
		HolsteredModelName = "HolsteredDawnstar",
		SwordPartName = "Dawnstar",
		ToolName = "Dawnstar",

		Holster = {
			AttachmentPart = "UpperTorso",
			PositionOffset = Vector3.new(.2, -.5, .7),
			RotationOffset = Vector3.new(0, 0, -57),
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.45,
			AttackCooldown = 0.3,
			AnimationId = "rbxassetid://102835293832677",
			PushForce = 60, -- Strongest push!
			AttackRange = 12,
		},

		Keybind = nil,
	},
}

-- ========================================
-- DEFAULT SETTINGS
-- ========================================

SwordConfig.DefaultSword = "Nightward"
SwordConfig.ShowAllSwords = false
SwordConfig.AllowSwitching = true

return SwordConfig
