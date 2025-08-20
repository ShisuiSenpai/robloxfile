-- Advanced Particle System with Dynamic Effects
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

-- Configuration
local CONFIG = {
    ACTIVATION_KEY = Enum.KeyCode.E,
    COOLDOWN = 3,
    RANGE = 50,
    PARTICLE_COUNT = 100,
    WAVE_SPEED = 40,
    EFFECT_DURATION = 10
}

-- Variables
local lastActivation = 0
local activeEffects = {}
local isActive = false

-- Create base part for effect origin
local function createEffectPart(position)
    local part = Instance.new("Part")
    part.Name = "EffectCore"
    part.Size = Vector3.new(2, 2, 2)
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Parent = workspace
    
    -- Core glow
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 10
    pointLight.Range = 30
    pointLight.Color = Color3.fromRGB(100, 200, 255)
    pointLight.Parent = part
    
    -- Particle emitter
    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particleEmitter.Rate = 500
    particleEmitter.Lifetime = NumberRange.new(1, 3)
    particleEmitter.Speed = NumberRange.new(10, 30)
    particleEmitter.SpreadAngle = Vector2.new(360, 360)
    particleEmitter.VelocityInheritance = 0.5
    particleEmitter.EmissionDirection = Enum.NormalId.Top
    particleEmitter.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 100))
    }
    particleEmitter.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 1.5),
        NumberSequenceKeypoint.new(1, 0)
    }
    particleEmitter.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    }
    particleEmitter.LightEmission = 1
    particleEmitter.LightInfluence = 0
    particleEmitter.Parent = part
    
    return part, particleEmitter, pointLight
end

-- Create energy wave
local function createWave(origin, color)
    local wave = Instance.new("Part")
    wave.Name = "EnergyWave"
    wave.Size = Vector3.new(4, 0.5, 4)
    wave.Position = origin
    wave.Anchored = true
    wave.CanCollide = false
    wave.Transparency = 0.3
    wave.Material = Enum.Material.ForceField
    wave.Color = color
    wave.Shape = Enum.PartType.Cylinder
    wave.CFrame = CFrame.new(origin) * CFrame.Angles(0, 0, math.rad(90))
    wave.Parent = workspace
    
    -- Wave expansion
    local startSize = wave.Size
    local endSize = Vector3.new(CONFIG.RANGE * 2, 0.5, CONFIG.RANGE * 2)
    
    local tween = TweenService:Create(wave, TweenInfo.new(
        CONFIG.RANGE / CONFIG.WAVE_SPEED,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    ), {
        Size = endSize,
        Transparency = 1
    })
    
    tween:Play()
    tween.Completed:Connect(function()
        wave:Destroy()
    end)
    
    return wave
end

-- Create floating orb
local function createOrb(position, targetPosition, color)
    local orb = Instance.new("Part")
    orb.Name = "EnergyOrb"
    orb.Size = Vector3.new(1, 1, 1)
    orb.Position = position
    orb.Anchored = true
    orb.CanCollide = false
    orb.Transparency = 0.5
    orb.Material = Enum.Material.Neon
    orb.Color = color
    orb.Shape = Enum.PartType.Ball
    orb.Parent = workspace
    
    -- Orb glow
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 2
    pointLight.Range = 10
    pointLight.Color = color
    pointLight.Parent = orb
    
    -- Orb trail
    local attachment0 = Instance.new("Attachment", orb)
    attachment0.Position = Vector3.new(0, 0.5, 0)
    local attachment1 = Instance.new("Attachment", orb)
    attachment1.Position = Vector3.new(0, -0.5, 0)
    
    local trail = Instance.new("Trail")
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Lifetime = 0.5
    trail.MinLength = 0
    trail.Color = ColorSequence.new(color)
    trail.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    }
    trail.LightEmission = 1
    trail.Parent = orb
    
    -- Orb movement
    local moveTween = TweenService:Create(orb, TweenInfo.new(
        2,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut
    ), {
        Position = targetPosition
    })
    
    moveTween:Play()
    moveTween.Completed:Connect(function()
        -- Create explosion effect
        local explosion = Instance.new("Part")
        explosion.Name = "OrbExplosion"
        explosion.Size = Vector3.new(0.1, 0.1, 0.1)
        explosion.Position = orb.Position
        explosion.Anchored = true
        explosion.CanCollide = false
        explosion.Transparency = 0
        explosion.Material = Enum.Material.Neon
        explosion.Color = color
        explosion.Shape = Enum.PartType.Ball
        explosion.Parent = workspace
        
        local explosionTween = TweenService:Create(explosion, TweenInfo.new(
            0.5,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ), {
            Size = Vector3.new(10, 10, 10),
            Transparency = 1
        })
        
        explosionTween:Play()
        explosionTween.Completed:Connect(function()
            explosion:Destroy()
        end)
        
        orb:Destroy()
    end)
    
    return orb
end

-- Create beam connection
local function createBeam(part1, part2, color)
    local attachment1 = Instance.new("Attachment", part1)
    local attachment2 = Instance.new("Attachment", part2)
    
    local beam = Instance.new("Beam")
    beam.Attachment0 = attachment1
    beam.Attachment1 = attachment2
    beam.Width0 = 2
    beam.Width1 = 2
    beam.Color = ColorSequence.new(color)
    beam.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0.5)
    }
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    beam.TextureSpeed = 5
    beam.TextureLength = 1
    beam.Parent = part1
    
    return beam, attachment1, attachment2
end

-- Main effect activation
local function activateEffect(character)
    if isActive or tick() - lastActivation < CONFIG.COOLDOWN then
        return
    end
    
    lastActivation = tick()
    isActive = true
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local position = humanoidRootPart.Position
    
    -- Create main effect core
    local core, emitter, light = createEffectPart(position)
    table.insert(activeEffects, core)
    
    -- Initial burst
    for i = 1, 5 do
        wait(0.1)
        createWave(position, Color3.fromHSV(i/5, 1, 1))
    end
    
    -- Create orbiting system
    local orbitParts = {}
    local orbitRadius = 15
    local orbitSpeed = 2
    
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2
        local orbitPart = Instance.new("Part")
        orbitPart.Name = "OrbitNode"
        orbitPart.Size = Vector3.new(2, 2, 2)
        orbitPart.Anchored = true
        orbitPart.CanCollide = false
        orbitPart.Transparency = 0.5
        orbitPart.Material = Enum.Material.Neon
        orbitPart.Color = Color3.fromHSV(i/8, 1, 1)
        orbitPart.Shape = Enum.PartType.Ball
        orbitPart.Parent = workspace
        
        local orbitLight = Instance.new("PointLight")
        orbitLight.Brightness = 3
        orbitLight.Range = 15
        orbitLight.Color = orbitPart.Color
        orbitLight.Parent = orbitPart
        
        table.insert(orbitParts, {part = orbitPart, angle = angle, light = orbitLight})
        table.insert(activeEffects, orbitPart)
    end
    
    -- Create beams between orbit nodes
    local beams = {}
    for i = 1, #orbitParts do
        local nextIndex = i % #orbitParts + 1
        local beam, att1, att2 = createBeam(orbitParts[i].part, orbitParts[nextIndex].part, Color3.new(1, 1, 1))
        table.insert(beams, {beam = beam, att1 = att1, att2 = att2})
    end
    
    -- Orbit animation
    local startTime = tick()
    local orbitConnection
    orbitConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        
        if elapsed > CONFIG.EFFECT_DURATION then
            orbitConnection:Disconnect()
            
            -- Cleanup
            for _, effect in ipairs(activeEffects) do
                if effect and effect.Parent then
                    local fadeTween = TweenService:Create(effect, TweenInfo.new(1), {
                        Transparency = 1
                    })
                    fadeTween:Play()
                    fadeTween.Completed:Connect(function()
                        effect:Destroy()
                    end)
                end
            end
            
            for _, beamData in ipairs(beams) do
                beamData.beam:Destroy()
                beamData.att1:Destroy()
                beamData.att2:Destroy()
            end
            
            activeEffects = {}
            isActive = false
            return
        end
        
        -- Update orbit positions
        for i, orbitData in ipairs(orbitParts) do
            local currentAngle = orbitData.angle + elapsed * orbitSpeed
            local x = position.X + math.cos(currentAngle) * orbitRadius
            local y = position.Y + math.sin(elapsed * 2) * 3 + 5
            local z = position.Z + math.sin(currentAngle) * orbitRadius
            
            orbitData.part.Position = Vector3.new(x, y, z)
            
            -- Pulse effect
            local pulseFactor = math.sin(elapsed * 5 + i) * 0.5 + 1.5
            orbitData.part.Size = Vector3.new(2, 2, 2) * pulseFactor
            orbitData.light.Brightness = 3 * pulseFactor
        end
        
        -- Update core effects
        light.Brightness = 10 + math.sin(elapsed * 3) * 5
        emitter.Rate = 500 + math.sin(elapsed * 4) * 300
        
        -- Spawn random orbs
        if math.random() < 0.1 then
            local randomAngle = math.random() * math.pi * 2
            local randomDistance = math.random(5, 20)
            local startPos = position + Vector3.new(
                math.cos(randomAngle) * randomDistance,
                math.random(5, 15),
                math.sin(randomAngle) * randomDistance
            )
            local targetPos = position + Vector3.new(
                math.random(-10, 10),
                math.random(5, 15),
                math.random(-10, 10)
            )
            createOrb(startPos, targetPos, Color3.fromHSV(math.random(), 1, 1))
        end
        
        -- Periodic waves
        if elapsed % 2 < 0.05 then
            createWave(position, Color3.fromHSV((elapsed / CONFIG.EFFECT_DURATION) % 1, 1, 1))
        end
    end)
end

-- Setup for all players
local function setupPlayer(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        
        -- Create activation tool
        local tool = Instance.new("Tool")
        tool.Name = "MysticalActivator"
        tool.RequiresHandle = false
        tool.Parent = player.Backpack
        
        tool.Activated:Connect(function()
            activateEffect(character)
        end)
    end)
end

-- Connect all current and future players
Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end