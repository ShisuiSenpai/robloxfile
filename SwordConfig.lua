--[[
	SWORD CONFIGURATION MODULE
	Add all your swords here with their custom settings
	
	Each sword can have unique:
	- Models (HolsteredSword and Sword Tool)
	- Holster position and rotation
	- Attack speed and duration
	- Damage and range
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
	-- SWORD 1: Normal Sword
	["NormalSword"] = {
		-- Rarity
		Rarity = "Common",
		
		-- Model names in ReplicatedStorage
		HolsteredModelName = "HolsteredSwordNormal",
		SwordPartName = "NormalSword", -- The part inside the holstered model
		ToolName = "NormalSword",

		-- Holster settings
		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},

		-- Attack settings
		Attack = {
			AttackDuration = 0.3,
			AttackCooldown = 0.4,
			AnimationId = "rbxassetid://0", -- Replace with your animation
			Damage = 10,
			AttackRange = 10,
		},

		-- Keybind to equip this sword (optional)
		Keybind = Enum.KeyCode.One, -- Press "1" to equip
	},

	-- SWORD 2: Ice Sword
	["IceSword"] = {
		-- Rarity
		Rarity = "Rare",
		
		HolsteredModelName = "HolsteredSwordIce",
		SwordPartName = "IceSword", -- The part inside the holstered model
		ToolName = "IceSword",

		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7), -- SAME as NormalSword
			RotationOffset = Vector3.new(0, 90, 110), -- SAME as NormalSword
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.5,
			AttackCooldown = 0.4,
			AnimationId = "rbxassetid://102835293832677",
			Damage = 12,
			AttackRange = 10,
		},

		Keybind = Enum.KeyCode.Two, -- Press "2" to equip
	},

	-- SWORD 3: Purple Sword
	["PurpleSword"] = {
		-- Rarity
		Rarity = "Legendary",
		
		HolsteredModelName = "HolsteredSwordPurple",
		SwordPartName = "PurpleSword",
		ToolName = "PurpleSword",

		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.5,
			AttackCooldown = 0.4,
			AnimationId = "rbxassetid://102835293832677",
			Damage = 10,
			AttackRange = 10,
		},

		Keybind = Enum.KeyCode.Three, -- Press "3" to equip
	},

	-- SWORD 4: Steel Sword
	["SteelSword"] = {
		-- Rarity
		Rarity = "Uncommon",
		
		HolsteredModelName = "HolsteredSwordSteel",
		SwordPartName = "SteelSword",
		ToolName = "SteelSword",

		Holster = {
			AttachmentPart = "Torso",
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.5,
			AttackCooldown = 0.4,
			AnimationId = "rbxassetid://102835293832677",
			Damage = 10,
			AttackRange = 10,
		},

		Keybind = Enum.KeyCode.Four, -- Press "4" to equip
	},
	
	["Tomahawk"] = {
		-- Rarity
		Rarity = "Godly",
		
		HolsteredModelName = "HolsteredTomahawk",
		SwordPartName = "Tomahawk",
		ToolName = "Tomahawk",

		Holster = {
			AttachmentPart = "UpperTorso",          -- Back holster (upper back)
			PositionOffset = Vector3.new(.2, -.5, .7),  -- Centered, shoulder level, behind
			RotationOffset = Vector3.new(0, 0, -57),     -- Horizontal across back
			TransparencyValue = 0,
		},

		Attack = {
			AttackDuration = 0.4,
			AttackCooldown = 0.4,
			AnimationId = "rbxassetid://102835293832677",
			Damage = 15,  -- Tomahawks hit harder!
			AttackRange = 10,
		},

		Keybind = Enum.KeyCode.Five,  -- Press "5"
	},

	--[[
	TEMPLATE: Copy this to add more swords!
	
	["SwordName"] = {
		HolsteredModelName = "HolsteredSwordName",
		SwordPartName = "SwordPartName", -- The part inside the holstered model
		ToolName = "SwordToolName",
		
		Holster = {
			AttachmentPart = "Torso", -- or "UpperTorso", "LowerTorso"
			PositionOffset = Vector3.new(1, -1.2, 0.7),
			RotationOffset = Vector3.new(0, 90, 110),
			TransparencyValue = 0,
		},
		
		Attack = {
			AttackDuration = 0.3,
			AttackCooldown = 0.4,
			AnimationId = "rbxassetid://0",
			Damage = 10,
			AttackRange = 10,
		},
		
		Keybind = Enum.KeyCode.Three, -- Press "3" to equip
	},
	]]
}

-- ========================================
-- DEFAULT SETTINGS
-- ========================================

-- Which sword the player starts with (must match a key in SwordConfig.Swords)
SwordConfig.DefaultSword = "NormalSword"

-- Should multiple swords be visible at once? (all holstered on body)
SwordConfig.ShowAllSwords = false -- Set to true to show all swords holstered

-- Allow switching between swords?
SwordConfig.AllowSwitching = true

return SwordConfig
