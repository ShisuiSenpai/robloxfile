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
	
	-- Very dark ambient lighting with slight blue tint
	Lighting.Ambient = Color3.fromRGB(10, 10, 15) -- Almost black with slight blue
	Lighting.OutdoorAmbient = Color3.fromRGB(15, 15, 20) -- Slightly lighter outdoor
	
	-- Low brightness for darkness
	Lighting.Brightness = 0.1
	
	-- Color shifts for eerie atmosphere
	Lighting.ColorShift_Bottom = Color3.fromRGB(20, 20, 30) -- Dark blue bottom
	Lighting.ColorShift_Top = Color3.fromRGB(10, 10, 20) -- Darker blue top
	
	-- Environmental lighting
	Lighting.EnvironmentDiffuseScale = 0.2
	Lighting.EnvironmentSpecularScale = 0.1
	
	-- Ensure shadows are on for dramatic effect
	Lighting.GlobalShadows = true
	
	-- Add fog for atmosphere
	Lighting.FogEnd = 200
	Lighting.FogStart = 20
	Lighting.FogColor = Color3.fromRGB(10, 10, 15) -- Match ambient for seamless blend
	
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
	
	-- Atmospheric settings for foggy/mysterious effect
	atmosphere.Density = 0.5 -- Thick atmosphere
	atmosphere.Offset = 0
	atmosphere.Color = Color3.fromRGB(30, 30, 40) -- Dark blue-grey
	atmosphere.Decay = Color3.fromRGB(20, 20, 30) -- Dark decay
	atmosphere.Glare = 0 -- No glare in darkness
	atmosphere.Haze = 2 -- Some haze for depth
	
	-- Add or update Bloom for light sources to glow
	local bloom = Lighting:FindFirstChild("Bloom")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Parent = Lighting
	end
	
	bloom.Intensity = 2 -- Make lights bloom/glow
	bloom.Size = 24 -- Larger bloom radius
	bloom.Threshold = 0.8 -- Lower threshold so more things bloom
	
	-- Add or update ColorCorrection for mood
	local colorCorrection = Lighting:FindFirstChild("ColorCorrection")
	if not colorCorrection then
		colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Parent = Lighting
	end
	
	colorCorrection.Brightness = -0.1 -- Slightly darker
	colorCorrection.Contrast = 0.2 -- More contrast
	colorCorrection.Saturation = -0.3 -- Less saturation for grimmer feel
	colorCorrection.TintColor = Color3.fromRGB(240, 240, 255) -- Slight blue tint
end

function DarkLightingSystem:CreatePlayerLight(character)
	if not character then return end
	
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoidRootPart then return end
	
	-- Create attachment for light
	local lightAttachment = Instance.new("Attachment")
	lightAttachment.Name = "InterrogationLightAttachment"
	lightAttachment.Position = Vector3.new(0, 6, 0) -- 6 studs above character
	lightAttachment.Parent = humanoidRootPart
	
	-- Create main interrogation light
	local pointLight = Instance.new("PointLight")
	pointLight.Name = "InterrogationLight"
	pointLight.Brightness = 3 -- Bright spotlight effect
	pointLight.Color = Color3.fromRGB(255, 245, 220) -- Warm white/yellow interrogation light
	pointLight.Range = 20 -- Medium range
	pointLight.Shadows = true -- Cast shadows for dramatic effect
	pointLight.Parent = lightAttachment
	
	-- Create secondary softer fill light
	local fillLight = Instance.new("PointLight")
	fillLight.Name = "FillLight"
	fillLight.Brightness = 0.5
	fillLight.Color = Color3.fromRGB(150, 150, 180) -- Cool fill light
	fillLight.Range = 15
	fillLight.Shadows = false
	fillLight.Parent = lightAttachment
	
	-- Create downward spotlight effect
	local spotLight = Instance.new("SpotLight")
	spotLight.Name = "DownwardSpot"
	spotLight.Brightness = 2
	spotLight.Color = Color3.fromRGB(255, 245, 220)
	spotLight.Range = 25
	spotLight.Angle = 60 -- Wide cone
	spotLight.Face = Enum.NormalId.Bottom -- Point downward
	spotLight.Shadows = true
	spotLight.Parent = lightAttachment
	
	-- Add subtle flickering for realism
	self:AddLightFlicker(pointLight, fillLight)
	
	-- Store reference
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		self.playerLights[player] = {
			attachment = lightAttachment,
			pointLight = pointLight,
			fillLight = fillLight,
			spotLight = spotLight
		}
	end
	
	return lightAttachment
end

function DarkLightingSystem:AddLightFlicker(pointLight, fillLight)
	-- Subtle random flickering for interrogation room effect
	task.spawn(function()
		local baseBrightness = pointLight.Brightness
		local fillBaseBrightness = fillLight.Brightness
		
		while pointLight.Parent do
			-- Occasional flicker
			if math.random() < 0.02 then -- 2% chance per frame
				-- Quick flicker
				local flickerStrength = 0.7 + math.random() * 0.3
				pointLight.Brightness = baseBrightness * flickerStrength
				fillLight.Brightness = fillBaseBrightness * flickerStrength
				
				task.wait(0.05 + math.random() * 0.1)
				
				pointLight.Brightness = baseBrightness
				fillLight.Brightness = fillBaseBrightness
			end
			
			-- Subtle brightness variation
			local variation = 0.95 + math.random() * 0.1
			pointLight.Brightness = baseBrightness * variation
			
			task.wait(0.1 + math.random() * 0.2)
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
	-- Add some environmental light sources for atmosphere
	local workspace = game:GetService("Workspace")
	
	-- Find spawn areas and add dim lights
	local spawns = workspace:FindFirstChild("Spawns")
	if spawns then
		for _, spawn in ipairs(spawns:GetChildren()) do
			if spawn:IsA("SpawnLocation") then
				-- Add dim light at each spawn
				local spawnLight = Instance.new("PointLight")
				spawnLight.Name = "SpawnAreaLight"
				spawnLight.Brightness = 0.3
				spawnLight.Color = Color3.fromRGB(100, 100, 120) -- Cold blue-white
				spawnLight.Range = 15
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