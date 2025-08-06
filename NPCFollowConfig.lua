-- NPCFollowConfig ModuleScript
-- Place in: ReplicatedStorage > NPCFollowModules > NPCFollowConfig

local NPCFollowConfig = {}

-- DETECTION SETTINGS
NPCFollowConfig.DETECTION_RADIUS = 30 -- How close player needs to be for NPC to start following (studs)
NPCFollowConfig.LOSE_INTEREST_RADIUS = 60 -- How far player needs to be for NPC to stop following (studs)
NPCFollowConfig.DETECTION_CHECK_INTERVAL = 0.5 -- How often to check for nearby players (seconds)
NPCFollowConfig.FIELD_OF_VIEW = 120 -- NPC's field of view in degrees (0-180, 180 = can see behind)

-- MOVEMENT SETTINGS
NPCFollowConfig.WALK_SPEED = 16 -- Normal walking speed
NPCFollowConfig.RUN_SPEED = 24 -- Speed when player is far away
NPCFollowConfig.RUN_DISTANCE_THRESHOLD = 20 -- Distance at which NPC starts running
NPCFollowConfig.STOP_DISTANCE = 8 -- How close NPC gets before stopping
NPCFollowConfig.PATH_UPDATE_INTERVAL = 0.2 -- How often to recalculate path (seconds)
NPCFollowConfig.MOVEMENT_SMOOTHING = 0.8 -- How smooth the movement is (0-1, higher = smoother)

-- SPACING SETTINGS
NPCFollowConfig.NPC_SPACING_RADIUS = 6 -- Minimum distance between NPCs (studs)
NPCFollowConfig.FORMATION_TYPE = "circle" -- "circle", "semicircle", or "random"
NPCFollowConfig.FORMATION_SPREAD = 12 -- How spread out NPCs are around player
NPCFollowConfig.AVOIDANCE_FORCE = 50 -- How strongly NPCs push away from each other
NPCFollowConfig.USE_FLOCKING = true -- Enable flocking behavior for natural movement

-- BEHAVIOR SETTINGS
NPCFollowConfig.MAX_FOLLOW_TIME = 30 -- Maximum time to follow before giving up (seconds, 0 = infinite)
NPCFollowConfig.MAX_FOLLOW_DISTANCE = 100 -- Maximum distance from origin before returning (studs)
NPCFollowConfig.IDLE_RETURN_TO_START = true -- Whether NPC returns to starting position when idle
NPCFollowConfig.RETURN_SPEED = 12 -- Speed when returning to start position
NPCFollowConfig.MEMORY_TIME = 5 -- How long NPC remembers last seen position (seconds)
NPCFollowConfig.CAN_FOLLOW_MULTIPLE = false -- Can multiple NPCs follow the same player?
NPCFollowConfig.MAX_FOLLOWERS_PER_PLAYER = 3 -- Max NPCs that can follow one player (if above is true)

-- PATHFINDING SETTINGS
NPCFollowConfig.USE_PATHFINDING = true -- Use Roblox pathfinding service
NPCFollowConfig.PATHFINDING_COSTS = {
	Water = 20,
	Mud = 10,
	Neon = math.huge, -- Avoid neon parts (obstacles)
}
NPCFollowConfig.JUMP_HEIGHT = 7.2 -- How high NPC can jump
NPCFollowConfig.JUMP_POWER = 50 -- Jump power for humanoid
NPCFollowConfig.CAN_CLIMB = true -- Whether NPC can climb ladders/trusses

-- ANIMATION SETTINGS
NPCFollowConfig.USE_ANIMATIONS = true -- Enable custom animations
NPCFollowConfig.IDLE_ANIMATION_ID = "" -- Leave empty for default
NPCFollowConfig.WALK_ANIMATION_ID = "" -- Leave empty for default
NPCFollowConfig.RUN_ANIMATION_ID = "" -- Leave empty for default

-- VISUAL FEEDBACK SETTINGS
NPCFollowConfig.SHOW_DETECTION_SPHERE = false -- Show detection radius in studio (debug)
NPCFollowConfig.SHOW_EXCLAMATION_ON_DETECT = true -- Show "!" above NPC when detecting player
NPCFollowConfig.EXCLAMATION_DURATION = 1 -- How long to show exclamation (seconds)
NPCFollowConfig.TINT_COLOR_WHEN_FOLLOWING = Color3.new(1, 0.8, 0.8) -- Slight red tint when following

-- SOUND SETTINGS
NPCFollowConfig.PLAY_DETECTION_SOUND = true -- Play sound when detecting player
NPCFollowConfig.DETECTION_SOUND_ID = "rbxasset://sounds/bass.mp3" -- Sound to play
NPCFollowConfig.FOOTSTEP_SOUNDS = true -- Enable footstep sounds
NPCFollowConfig.FOOTSTEP_VOLUME = 0.5 -- Volume of footsteps

-- PERFORMANCE SETTINGS
NPCFollowConfig.MAX_ACTIVE_NPCS = 10 -- Maximum NPCs that can be actively following at once
NPCFollowConfig.LOD_DISTANCE = 100 -- Distance for level of detail reduction
NPCFollowConfig.CLEANUP_INTERVAL = 5 -- How often to clean up inactive NPCs (seconds)

-- DEBUG SETTINGS
NPCFollowConfig.DEBUG_MODE = false -- Enable debug prints
NPCFollowConfig.SHOW_PATHFINDING_WAYPOINTS = false -- Visualize pathfinding waypoints

-- NPC IDENTIFICATION
NPCFollowConfig.NPC_FOLDER_NAME = "NPCS" -- Name of the folder containing NPCs in Workspace
NPCFollowConfig.NPC_TAG = "FollowNPC" -- Optional tag to identify followable NPCs

-- ADVANCED SETTINGS
NPCFollowConfig.BLACKLIST_PLAYERS = {} -- Array of player names that NPCs won't follow
NPCFollowConfig.WHITELIST_PLAYERS = {} -- If not empty, only these players can be followed
NPCFollowConfig.FOLLOW_PRIORITY = "closest" -- "closest", "first", or "random"
NPCFollowConfig.OBSTACLE_DETECTION = true -- Check for obstacles between NPC and player
NPCFollowConfig.SLOPE_LIMIT = 45 -- Maximum slope angle NPC can walk up (degrees)

return NPCFollowConfig