-- Add this to your Main.server.lua after the other module requires

-- Load the dark lighting system
local DarkLightingSystem = require(Modules:WaitForChild("DarkLightingSystem"))

-- Initialize the dark lighting
local darkLighting = DarkLightingSystem.new()

-- Optional: Add environmental lights to spawn areas
darkLighting:CreateEnvironmentalLights()

print("[Main] Dark lighting system initialized")