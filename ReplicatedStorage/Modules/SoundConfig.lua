-- SoundConfig.lua
-- Centralized sound configuration for the game

local SoundConfig = {
    -- Timer tick sound for last 3 seconds
    TimerTick = {
        SoundId = "rbxassetid://CHANGE_ME_TIMER_TICK", -- Change this to your tick sound ID
        Volume = 0.5,
        Pitch = 1.2,
        EmitterSize = 10
    },
    
    -- Correct answer sound
    CorrectAnswer = {
        SoundId = "rbxassetid://CHANGE_ME_CORRECT", -- Change this to your correct sound ID
        Volume = 0.6,
        Pitch = 1.0,
        EmitterSize = 10
    },
    
    -- Wrong answer sound
    WrongAnswer = {
        SoundId = "rbxassetid://CHANGE_ME_WRONG", -- Change this to your wrong sound ID
        Volume = 0.6,
        Pitch = 0.9,
        EmitterSize = 10
    },
    
    -- Victory sound
    Victory = {
        SoundId = "rbxassetid://CHANGE_ME_VICTORY", -- Change this to your victory sound ID
        Volume = 0.8,
        Pitch = 1.0,
        EmitterSize = 15
    },
    
    -- Button hover sound
    ButtonHover = {
        SoundId = "rbxassetid://CHANGE_ME_HOVER", -- Change this to your hover sound ID
        Volume = 0.3,
        Pitch = 1.5,
        EmitterSize = 10
    },
    
    -- Question appear sound
    QuestionAppear = {
        SoundId = "rbxassetid://CHANGE_ME_APPEAR", -- Change this to your question appear sound ID
        Volume = 0.4,
        Pitch = 1.0,
        EmitterSize = 10
    }
}

return SoundConfig