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
	
	-- EXTREMELY dark ambient lighting - almost pitch black
	Lighting.Ambient = Color3.fromRGB(5, 5, 8) -- Near black with very faint blue
	Lighting.OutdoorAmbient = Color3.fromRGB(8, 8, 10) -- Barely visible outdoor
	
	-- Minimal brightness for near darkness
	Lighting.Brightness = 0.05 -- Even darker
	
	-- Color shifts for harsh interrogation atmosphere
	Lighting.ColorShift_Bottom = Color3.fromRGB(10, 10, 15) -- Very dark blue bottom
	Lighting.ColorShift_Top = Color3.fromRGB(5, 5, 10) -- Near black top
	
	-- Minimal environmental lighting
	Lighting.EnvironmentDiffuseScale = 0.1
	Lighting.EnvironmentSpecularScale = 0.05
	
	-- Ensure shadows are on for dramatic effect
	Lighting.GlobalShadows = true
	
	-- Closer fog for claustrophobic feel
	Lighting.FogEnd = 150
	Lighting.FogStart = 15
	Lighting.FogColor = Color3.fromRGB(5, 5, 8) -- Match ambient for seamless blend
	
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
	
	-- Create attachment for light positioned directly above head
	local lightAttachment = Instance.new("Attachment")
	lightAttachment.Name = "InterrogationLightAttachment"
	lightAttachment.Position = Vector3.new(0, 8, 0) -- 8 studs above character for more overhead feel
	lightAttachment.Parent = humanoidRootPart
	
	-- Remove point lights - only use focused spotlight
	
	-- Create single harsh downward spotlight - THE interrogation light
	local spotLight = Instance.new("SpotLight")
	spotLight.Name = "InterrogationSpotlight"
	spotLight.Brightness = 5 -- Very bright for harsh contrast
	spotLight.Color = Color3.fromRGB(255, 255, 245) -- Harsh cold white
	spotLight.Range = 20 -- Focused range
	spotLight.Angle = 45 -- Narrower cone for focused light
	spotLight.Face = Enum.NormalId.Bottom -- Point straight down
	spotLight.Shadows = true -- Strong shadows
	spotLight.Parent = lightAttachment
	
	-- Add a very dim ambient light just so player isn't completely blind
	local minimalLight = Instance.new("PointLight")
	minimalLight.Name = "MinimalAmbient"
	minimalLight.Brightness = 0.2 -- Barely visible
	minimalLight.Color = Color3.fromRGB(200, 200, 210) -- Cold white
	minimalLight.Range = 8 -- Small radius
	minimalLight.Shadows = false
	minimalLight.Parent = lightAttachment
	
	-- Add subtle flickering for realism
	self:AddLightFlicker(spotLight, minimalLight)
	
	-- Store reference
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		self.playerLights[player] = {
			attachment = lightAttachment,
			spotLight = spotLight,
			minimalLight = minimalLight
		}
	end
	
	return lightAttachment
end

function DarkLightingSystem:AddLightFlicker(spotLight, minimalLight)
	-- Harsh flickering for interrogation room effect
	task.spawn(function()
		local baseBrightness = spotLight.Brightness
		local minimalBaseBrightness = minimalLight.Brightness
		
		while spotLight.Parent do
			-- More frequent harsh flickers
			if math.random() < 0.03 then -- 3% chance per frame
				-- Harsh flicker
				local flickerStrength = 0.6 + math.random() * 0.4
				spotLight.Brightness = baseBrightness * flickerStrength
				minimalLight.Brightness = minimalBaseBrightness * flickerStrength
				
				task.wait(0.03 + math.random() * 0.07)
				
				-- Sometimes double flicker for more unsettling effect
				if math.random() < 0.3 then
					spotLight.Brightness = baseBrightness * 0.7
					task.wait(0.02)
				end
				
				spotLight.Brightness = baseBrightness
				minimalLight.Brightness = minimalBaseBrightness
			end
			
			-- Less subtle brightness variation - more noticeable
			local variation = 0.9 + math.random() * 0.1
			spotLight.Brightness = baseBrightness * variation
			
			task.wait(0.15 + math.random() * 0.3)
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