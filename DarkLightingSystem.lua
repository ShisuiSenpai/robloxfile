-- DarkLightingSystem.lua
-- Creates a dark, interrogation-style atmosphere with point lights above players

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local DarkLightingSystem = {}
DarkLightingSystem.__index = DarkLightingSystem

function DarkLightingSystem.new()
	local self = setmetatable({}, DarkLightingSystem)
	self.playerLights = {}
	self.originalLighting = {}
	self:Initialize()
	return self
end

function DarkLightingSystem:Initialize()
	-- Store original lighting settings
	self:StoreOriginalSettings()
	
	-- Apply dark atmosphere
	self:ApplyDarkAtmosphere()
	
	-- Setup player connections
	self:SetupPlayerConnections()
	
	print("[DarkLightingSystem] Initialized")
end

function DarkLightingSystem:StoreOriginalSettings()
	self.originalLighting = {
		Ambient = Lighting.Ambient,
		Brightness = Lighting.Brightness,
		ColorShift_Bottom = Lighting.ColorShift_Bottom,
		ColorShift_Top = Lighting.ColorShift_Top,
		EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
		GlobalShadows = Lighting.GlobalShadows,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		ClockTime = Lighting.ClockTime,
		FogEnd = Lighting.FogEnd,
		FogStart = Lighting.FogStart,
		FogColor = Lighting.FogColor
	}
end

function DarkLightingSystem:ApplyDarkAtmosphere()
	-- Set to night time
	Lighting.ClockTime = 0 -- Midnight
	
	-- Dark ambient lighting but visible
	Lighting.Ambient = Color3.fromRGB(15, 15, 20) -- Dark with slight blue tint
	Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 25) -- Slightly visible outdoor
	
	-- Low brightness for darkness but playable
	Lighting.Brightness = 0.2 -- Dark but visible
	
	-- Color shifts for interrogation atmosphere
	Lighting.ColorShift_Bottom = Color3.fromRGB(25, 25, 35) -- Dark blue bottom
	Lighting.ColorShift_Top = Color3.fromRGB(15, 15, 25) -- Darker blue top
	
	-- Environmental lighting
	Lighting.EnvironmentDiffuseScale = 0.15
	Lighting.EnvironmentSpecularScale = 0.1
	
	-- Ensure shadows are on for dramatic effect
	Lighting.GlobalShadows = true
	
	-- Fog for atmosphere
	Lighting.FogEnd = 200
	Lighting.FogStart = 30
	Lighting.FogColor = Color3.fromRGB(15, 15, 20) -- Match ambient for seamless blend
	
	-- Add atmospheric effects if not present
	self:AddAtmosphericEffects()
end

function DarkLightingSystem:AddAtmosphericEffects()
	-- Add or update Atmosphere
	local atmosphere = Lighting:FindFirstChild("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	
	-- Atmospheric settings for oppressive interrogation room feel
	atmosphere.Density = 0.7 -- Thicker atmosphere
	atmosphere.Offset = 0
	atmosphere.Color = Color3.fromRGB(20, 20, 25) -- Very dark blue-grey
	atmosphere.Decay = Color3.fromRGB(10, 10, 15) -- Darker decay
	atmosphere.Glare = 0 -- No glare in darkness
	atmosphere.Haze = 3 -- More haze for oppressive depth
	
	-- Add or update Bloom for harsh light contrast
	local bloom = Lighting:FindFirstChild("Bloom")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Parent = Lighting
	end
	
	bloom.Intensity = 3 -- Stronger bloom for harsh lights
	bloom.Size = 20 -- Focused bloom
	bloom.Threshold = 0.9 -- Higher threshold for only bright lights
	
	-- Add or update ColorCorrection for harsh mood
	local colorCorrection = Lighting:FindFirstChild("ColorCorrection")
	if not colorCorrection then
		colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Parent = Lighting
	end
	
	colorCorrection.Brightness = -0.2 -- Much darker
	colorCorrection.Contrast = 0.4 -- Higher contrast for harsh shadows
	colorCorrection.Saturation = -0.5 -- Very desaturated, almost black and white
	colorCorrection.TintColor = Color3.fromRGB(245, 245, 250) -- Cold white tint
end

function DarkLightingSystem:CreatePlayerLight(character)
	if not character then return end
	
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoidRootPart then return end
	
	-- Create attachment for light positioned above head
	local lightAttachment = Instance.new("Attachment")
	lightAttachment.Name = "InterrogationLightAttachment"
	lightAttachment.Position = Vector3.new(0, 5, 0) -- 5 studs above character
	lightAttachment.Parent = humanoidRootPart
	
	-- Main interrogation point light above head
	local pointLight = Instance.new("PointLight")
	pointLight.Name = "InterrogationLight"
	pointLight.Brightness = 4 -- Bright enough to see clearly
	pointLight.Color = Color3.fromRGB(255, 250, 240) -- Warm white interrogation light
	pointLight.Range = 25 -- Good coverage area
	pointLight.Shadows = true -- Cast dramatic shadows
	pointLight.Parent = lightAttachment
	
	-- Add downward spotlight for focused effect
	local spotLight = Instance.new("SpotLight")
	spotLight.Name = "FocusedSpot"
	spotLight.Brightness = 3 -- Additional focused light
	spotLight.Color = Color3.fromRGB(255, 255, 250) -- Bright white
	spotLight.Range = 30 -- Good range
	spotLight.Angle = 50 -- Reasonable cone
	spotLight.Face = Enum.NormalId.Bottom -- Point down
	spotLight.Shadows = true
	spotLight.Parent = lightAttachment
	
	-- Small fill light to soften harsh shadows slightly
	local fillLight = Instance.new("PointLight")
	fillLight.Name = "FillLight"
	fillLight.Brightness = 0.8 -- Soft fill
	fillLight.Color = Color3.fromRGB(230, 230, 240) -- Cool white
	fillLight.Range = 15 -- Smaller radius
	fillLight.Shadows = false
	fillLight.Parent = lightAttachment
	
	-- Add subtle flickering for realism
	self:AddLightFlicker(pointLight, spotLight)
	
	-- Store reference
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		self.playerLights[player] = {
			attachment = lightAttachment,
			pointLight = pointLight,
			spotLight = spotLight,
			fillLight = fillLight
		}
	end
	
	return lightAttachment
end

function DarkLightingSystem:AddLightFlicker(pointLight, spotLight)
	-- Subtle flickering for interrogation room effect
	task.spawn(function()
		local pointBaseBrightness = pointLight.Brightness
		local spotBaseBrightness = spotLight.Brightness
		
		while pointLight.Parent do
			-- Occasional flicker
			if math.random() < 0.02 then -- 2% chance per frame
				-- Quick flicker
				local flickerStrength = 0.8 + math.random() * 0.2
				pointLight.Brightness = pointBaseBrightness * flickerStrength
				spotLight.Brightness = spotBaseBrightness * flickerStrength
				
				task.wait(0.05 + math.random() * 0.05)
				
				pointLight.Brightness = pointBaseBrightness
				spotLight.Brightness = spotBaseBrightness
			end
			
			-- Subtle brightness variation
			local variation = 0.95 + math.random() * 0.05
			pointLight.Brightness = pointBaseBrightness * variation
			
			task.wait(0.2 + math.random() * 0.3)
		end
	end)
end

function DarkLightingSystem:SetupPlayerConnections()
	-- Connect to existing players
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			self:CreatePlayerLight(player.Character)
		end
		
		player.CharacterAdded:Connect(function(character)
			task.wait(0.5) -- Wait for character to load
			self:CreatePlayerLight(character)
		end)
	end
	
	-- Connect to new players
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			task.wait(0.5)
			self:CreatePlayerLight(character)
		end)
	end)
	
	-- Clean up on player leaving
	Players.PlayerRemoving:Connect(function(player)
		if self.playerLights[player] then
			if self.playerLights[player].attachment then
				self.playerLights[player].attachment:Destroy()
			end
			self.playerLights[player] = nil
		end
	end)
end

function DarkLightingSystem:CreateEnvironmentalLights()
	-- Remove all environmental lights - keep it DARK
	-- Players should only see by their interrogation lights
	
	-- Optional: Add extremely dim emergency lighting
	local workspace = game:GetService("Workspace")
	local spawns = workspace:FindFirstChild("Spawns")
	if spawns then
		for _, spawn in ipairs(spawns:GetChildren()) do
			if spawn:IsA("SpawnLocation") then
				-- Add VERY dim light at each spawn
				local spawnLight = Instance.new("PointLight")
				spawnLight.Name = "EmergencyLight"
				spawnLight.Brightness = 0.1 -- Barely visible
				spawnLight.Color = Color3.fromRGB(80, 80, 90) -- Cold grey
				spawnLight.Range = 8 -- Very small radius
				spawnLight.Shadows = false
				spawnLight.Parent = spawn
			end
		end
	end
end

function DarkLightingSystem:RestoreOriginalLighting()
	-- Restore all original settings
	for property, value in pairs(self.originalLighting) do
		Lighting[property] = value
	end
	
	-- Remove atmospheric effects
	local atmosphere = Lighting:FindFirstChild("Atmosphere")
	if atmosphere then atmosphere:Destroy() end
	
	local bloom = Lighting:FindFirstChild("Bloom")
	if bloom then bloom:Destroy() end
	
	local colorCorrection = Lighting:FindFirstChild("ColorCorrection")
	if colorCorrection then colorCorrection:Destroy() end
	
	-- Remove all player lights
	for player, lightData in pairs(self.playerLights) do
		if lightData.attachment then
			lightData.attachment:Destroy()
		end
	end
	self.playerLights = {}
end

return DarkLightingSystem