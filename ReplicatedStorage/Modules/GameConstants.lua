-- GameConstants.lua
-- Shared constants for Step to Victory game

local GameConstants = {
    -- Player limits
    MAX_PLAYERS = 4,
    
    -- Timing
    INTERMISSION_TIME = 5, -- seconds
    FREEZE_TIME = 5, -- seconds
    
    -- Spawn locations
    SPAWN_NAMES = {
        "SpawnLocation1",
        "SpawnLocation2", 
        "SpawnLocation3",
        "SpawnLocation4"
    },
    
    -- Footstep paths
    FOOTSTEP_FOLDERS = {
        "Footsteps1",
        "Footsteps2",
        "Footsteps3", 
        "Footsteps4"
    },
    
    FOOTSTEPS_PER_PATH = 6,
    
    -- Game states
    GameState = {
        WAITING = "Waiting",
        INTERMISSION = "Intermission",
        IN_GAME = "InGame",
        ROUND_END = "RoundEnd"
    }
}

return GameConstants