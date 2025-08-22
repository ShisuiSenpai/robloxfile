-- Red Light Green Light Game Script (ServerScriptService)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Game Configuration
local GAME_CONFIG = {
    GAME_TIME = 60, -- seconds
    RED_LIGHT_MIN = 2, -- minimum red light duration
    RED_LIGHT_MAX = 5, -- maximum red light duration
    GREEN_LIGHT_MIN = 3, -- minimum green light duration
    GREEN_LIGHT_MAX = 7, -- maximum green light duration
    DAMAGE_PER_SHOT = 20,
    DETECTION_THRESHOLD = 0.5, -- movement speed threshold during red light
    BULLET_SPEED = 100,
    FIRE_RATE = 0.2, -- time between shots
}

-- Game State
local gameState = {
    isRunning = false,
    isRedLight = false,
    timeRemaining = GAME_CONFIG.GAME_TIME,
    players = {},
}

-- Create game workspace structure
local gameFolder = workspace:FindFirstChild("RedLightGreenLight") or Instance.new("Folder")
gameFolder.Name = "RedLightGreenLight"
gameFolder.Parent = workspace

-- Create turret model
local function createTurret()
    local turret = Instance.new("Model")
    turret.Name = "Turret"
    
    -- Base
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(4, 1, 4)
    base.Material = Enum.Material.Metal
    base.BrickColor = BrickColor.new("Dark grey")
    base.TopSurface = Enum.SurfaceType.Smooth
    base.BottomSurface = Enum.SurfaceType.Smooth
    base.Anchored = true
    base.Parent = turret
    
    -- Turret body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(3, 3, 3)
    body.Material = Enum.Material.Metal
    body.BrickColor = BrickColor.new("Black")
    body.Shape = Enum.PartType.Cylinder
    body.TopSurface = Enum.SurfaceType.Smooth
    body.BottomSurface = Enum.SurfaceType.Smooth
    body.Anchored = true
    body.CFrame = base.CFrame * CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(90))
    body.Parent = turret
    
    -- Barrel
    local barrel = Instance.new("Part")
    barrel.Name = "Barrel"
    barrel.Size = Vector3.new(1, 1, 4)
    barrel.Material = Enum.Material.Metal
    barrel.BrickColor = BrickColor.new("Really black")
    barrel.Shape = Enum.PartType.Cylinder
    barrel.TopSurface = Enum.SurfaceType.Smooth
    barrel.BottomSurface = Enum.SurfaceType.Smooth
    barrel.Anchored = true
    barrel.CFrame = body.CFrame * CFrame.new(0, 0, -2.5) * CFrame.Angles(math.rad(90), 0, 0)
    barrel.Parent = turret
    
    -- Red warning light
    local light = Instance.new("Part")
    light.Name = "WarningLight"
    light.Size = Vector3.new(1, 1, 1)
    light.Material = Enum.Material.Neon
    light.BrickColor = BrickColor.new("Really red")
    light.Shape = Enum.PartType.Ball
    light.TopSurface = Enum.SurfaceType.Smooth
    light.BottomSurface = Enum.SurfaceType.Smooth
    light.Anchored = true
    light.CFrame = body.CFrame * CFrame.new(0, 1.5, 0)
    light.Parent = turret
    
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 2
    pointLight.Color = Color3.new(1, 0, 0)
    pointLight.Range = 20
    pointLight.Parent = light
    
    return turret
end

-- Create bullet
local function createBullet(origin, direction)
    local bullet = Instance.new("Part")
    bullet.Name = "Bullet"
    bullet.Size = Vector3.new(0.3, 0.3, 1)
    bullet.Material = Enum.Material.Neon
    bullet.BrickColor = BrickColor.new("New Yeller")
    bullet.TopSurface = Enum.SurfaceType.Smooth
    bullet.BottomSurface = Enum.SurfaceType.Smooth
    bullet.CanCollide = false
    bullet.CFrame = CFrame.lookAt(origin, origin + direction)
    bullet.Parent = gameFolder
    
    -- Add trail effect
    local attachment0 = Instance.new("Attachment")
    attachment0.Position = Vector3.new(0, 0, -0.5)
    attachment0.Parent = bullet
    
    local attachment1 = Instance.new("Attachment")
    attachment1.Position = Vector3.new(0, 0, 0.5)
    attachment1.Parent = bullet
    
    local trail = Instance.new("Trail")
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Lifetime = 0.2
    trail.MinLength = 0
    trail.FaceCamera = true
    trail.Color = ColorSequence.new(Color3.new(1, 1, 0))
    trail.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    }
    trail.Parent = bullet
    
    -- Bullet physics
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = direction * GAME_CONFIG.BULLET_SPEED
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Parent = bullet
    
    -- Bullet hit detection
    bullet.Touched:Connect(function(hit)
        local humanoid = hit.Parent:FindFirstChild("Humanoid")
        if humanoid and humanoid.Parent ~= bullet then
            humanoid:TakeDamage(GAME_CONFIG.DAMAGE_PER_SHOT)
            
            -- Create hit effect
            local hitEffect = Instance.new("Part")
            hitEffect.Name = "HitEffect"
            hitEffect.Size = Vector3.new(1, 1, 1)
            hitEffect.Material = Enum.Material.Neon
            hitEffect.BrickColor = BrickColor.new("Really red")
            hitEffect.Anchored = true
            hitEffect.CanCollide = false
            hitEffect.CFrame = bullet.CFrame
            hitEffect.Transparency = 0.5
            hitEffect.Parent = gameFolder
            
            local hitLight = Instance.new("PointLight")
            hitLight.Brightness = 5
            hitLight.Color = Color3.new(1, 0, 0)
            hitLight.Range = 10
            hitLight.Parent = hitEffect
            
            -- Tween hit effect
            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Out)
            local tween = TweenService:Create(hitEffect, tweenInfo, {
                Size = Vector3.new(3, 3, 3),
                Transparency = 1
            })
            tween:Play()
            
            Debris:AddItem(hitEffect, 0.5)
            bullet:Destroy()
        end
    end)
    
    -- Clean up bullet after 5 seconds
    Debris:AddItem(bullet, 5)
    
    return bullet
end

-- Player tracking system
local function trackPlayer(player)
    if not player.Character then return end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    -- Store player data
    gameState.players[player] = {
        lastPosition = rootPart.Position,
        lastFireTime = 0,
        violations = 0
    }
end

-- Check player movement during red light
local function checkPlayerMovement(player, turret)
    local playerData = gameState.players[player]
    if not playerData then return end
    
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local currentPosition = rootPart.Position
    local movement = (currentPosition - playerData.lastPosition).Magnitude
    
    -- During red light, check for movement
    if gameState.isRedLight and movement > GAME_CONFIG.DETECTION_THRESHOLD then
        local currentTime = tick()
        
        -- Fire turret if cooldown has passed
        if currentTime - playerData.lastFireTime > GAME_CONFIG.FIRE_RATE then
            playerData.lastFireTime = currentTime
            playerData.violations = playerData.violations + 1
            
            -- Calculate shot direction
            local turretBarrel = turret:FindFirstChild("Barrel")
            if turretBarrel then
                local origin = turretBarrel.Position
                local direction = (rootPart.Position - origin).Unit
                
                -- Create and fire bullet
                createBullet(origin, direction)
                
                -- Turret fire effect
                local muzzleFlash = Instance.new("Part")
                muzzleFlash.Name = "MuzzleFlash"
                muzzleFlash.Size = Vector3.new(2, 2, 2)
                muzzleFlash.Material = Enum.Material.Neon
                muzzleFlash.BrickColor = BrickColor.new("New Yeller")
                muzzleFlash.Anchored = true
                muzzleFlash.CanCollide = false
                muzzleFlash.CFrame = turretBarrel.CFrame * CFrame.new(0, 0, -2)
                muzzleFlash.Parent = gameFolder
                
                local flashLight = Instance.new("PointLight")
                flashLight.Brightness = 10
                flashLight.Color = Color3.new(1, 1, 0)
                flashLight.Range = 20
                flashLight.Parent = muzzleFlash
                
                Debris:AddItem(muzzleFlash, 0.1)
            end
        end
    end
    
    -- Update last position
    playerData.lastPosition = currentPosition
end

-- Create game UI
local function createGameUI()
    -- Create ScreenGui in ReplicatedStorage to clone to players
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RedLightGreenLightUI"
    screenGui.ResetOnSpawn = false
    
    -- Light indicator
    local lightFrame = Instance.new("Frame")
    lightFrame.Name = "LightIndicator"
    lightFrame.Size = UDim2.new(0, 300, 0, 100)
    lightFrame.Position = UDim2.new(0.5, -150, 0, 50)
    lightFrame.BackgroundColor3 = Color3.new(0, 1, 0)
    lightFrame.BorderSizePixel = 5
    lightFrame.BorderColor3 = Color3.new(1, 1, 1)
    lightFrame.Parent = screenGui
    
    local lightLabel = Instance.new("TextLabel")
    lightLabel.Name = "LightText"
    lightLabel.Size = UDim2.new(1, 0, 1, 0)
    lightLabel.BackgroundTransparency = 1
    lightLabel.Text = "GREEN LIGHT"
    lightLabel.TextColor3 = Color3.new(0, 0, 0)
    lightLabel.TextScaled = true
    lightLabel.Font = Enum.Font.SourceSansBold
    lightLabel.Parent = lightFrame
    
    -- Timer
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "Timer"
    timerLabel.Size = UDim2.new(0, 200, 0, 50)
    timerLabel.Position = UDim2.new(0.5, -100, 0, 160)
    timerLabel.BackgroundColor3 = Color3.new(0, 0, 0)
    timerLabel.BackgroundTransparency = 0.3
    timerLabel.BorderSizePixel = 3
    timerLabel.BorderColor3 = Color3.new(1, 1, 1)
    timerLabel.Text = "Time: 60s"
    timerLabel.TextColor3 = Color3.new(1, 1, 1)
    timerLabel.TextScaled = true
    timerLabel.Font = Enum.Font.SourceSansBold
    timerLabel.Parent = screenGui
    
    -- Health bar
    local healthFrame = Instance.new("Frame")
    healthFrame.Name = "HealthBar"
    healthFrame.Size = UDim2.new(0, 300, 0, 30)
    healthFrame.Position = UDim2.new(0.5, -150, 0.9, 0)
    healthFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    healthFrame.BorderSizePixel = 3
    healthFrame.BorderColor3 = Color3.new(1, 1, 1)
    healthFrame.Parent = screenGui
    
    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.new(0, 1, 0)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthFrame
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthText"
    healthLabel.Size = UDim2.new(1, 0, 1, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "Health: 100"
    healthLabel.TextColor3 = Color3.new(1, 1, 1)
    healthLabel.TextScaled = true
    healthLabel.Font = Enum.Font.SourceSansBold
    healthLabel.Parent = healthFrame
    
    screenGui.Parent = ReplicatedStorage
    return screenGui
end

-- Update UI for all players
local function updateUI()
    for _, player in pairs(Players:GetPlayers()) do
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            local gui = playerGui:FindFirstChild("RedLightGreenLightUI")
            if gui then
                local lightFrame = gui:FindFirstChild("LightIndicator")
                local lightText = lightFrame and lightFrame:FindFirstChild("LightText")
                local timer = gui:FindFirstChild("Timer")
                
                if lightFrame and lightText then
                    if gameState.isRedLight then
                        lightFrame.BackgroundColor3 = Color3.new(1, 0, 0)
                        lightText.Text = "RED LIGHT"
                        lightText.TextColor3 = Color3.new(1, 1, 1)
                    else
                        lightFrame.BackgroundColor3 = Color3.new(0, 1, 0)
                        lightText.Text = "GREEN LIGHT"
                        lightText.TextColor3 = Color3.new(0, 0, 0)
                    end
                end
                
                if timer then
                    timer.Text = string.format("Time: %ds", math.ceil(gameState.timeRemaining))
                end
            end
        end
    end
end

-- Initialize game
local function initializeGame()
    -- Create turret
    local turret = createTurret()
    turret:SetPrimaryPartCFrame(CFrame.new(0, 5, -50))
    turret.Parent = gameFolder
    
    -- Create UI template
    createGameUI()
    
    -- Give UI to all players
    for _, player in pairs(Players:GetPlayers()) do
        local screenGui = ReplicatedStorage:FindFirstChild("RedLightGreenLightUI")
        if screenGui then
            local guiClone = screenGui:Clone()
            guiClone.Parent = player.PlayerGui
            
            -- Update health bar when player takes damage
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.HealthChanged:Connect(function(health)
                        local healthBar = guiClone:FindFirstChild("HealthBar")
                        if healthBar then
                            local healthFill = healthBar:FindFirstChild("HealthFill")
                            local healthText = healthBar:FindFirstChild("HealthText")
                            
                            if healthFill and healthText then
                                local healthPercent = health / humanoid.MaxHealth
                                healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
                                healthText.Text = string.format("Health: %d", math.floor(health))
                                
                                -- Change color based on health
                                if healthPercent > 0.5 then
                                    healthFill.BackgroundColor3 = Color3.new(0, 1, 0)
                                elseif healthPercent > 0.25 then
                                    healthFill.BackgroundColor3 = Color3.new(1, 1, 0)
                                else
                                    healthFill.BackgroundColor3 = Color3.new(1, 0, 0)
                                end
                            end
                        end
                    end)
                end
            end
        end
        
        trackPlayer(player)
    end
    
    return turret
end

-- Main game loop
local function startGame()
    gameState.isRunning = true
    gameState.timeRemaining = GAME_CONFIG.GAME_TIME
    
    local turret = initializeGame()
    
    -- Game timer
    spawn(function()
        while gameState.isRunning and gameState.timeRemaining > 0 do
            wait(1)
            gameState.timeRemaining = gameState.timeRemaining - 1
            updateUI()
            
            if gameState.timeRemaining <= 0 then
                gameState.isRunning = false
                -- Victory condition
                for _, player in pairs(Players:GetPlayers()) do
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        if player.Character.Humanoid.Health > 0 then
                            -- Player survived!
                            print(player.Name .. " survived!")
                        end
                    end
                end
            end
        end
    end)
    
    -- Light switching loop
    spawn(function()
        while gameState.isRunning do
            -- Green light phase
            gameState.isRedLight = false
            updateUI()
            
            local greenDuration = math.random(
                GAME_CONFIG.GREEN_LIGHT_MIN, 
                GAME_CONFIG.GREEN_LIGHT_MAX
            )
            wait(greenDuration)
            
            if not gameState.isRunning then break end
            
            -- Red light phase
            gameState.isRedLight = true
            updateUI()
            
            -- Update turret light
            local warningLight = turret:FindFirstChild("WarningLight")
            if warningLight then
                local pointLight = warningLight:FindFirstChild("PointLight")
                if pointLight then
                    pointLight.Enabled = true
                end
            end
            
            local redDuration = math.random(
                GAME_CONFIG.RED_LIGHT_MIN, 
                GAME_CONFIG.RED_LIGHT_MAX
            )
            wait(redDuration)
            
            -- Turn off turret light
            if warningLight then
                local pointLight = warningLight:FindFirstChild("PointLight")
                if pointLight then
                    pointLight.Enabled = false
                end
            end
        end
    end)
    
    -- Movement detection loop
    spawn(function()
        while gameState.isRunning do
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character then
                    checkPlayerMovement(player, turret)
                end
            end
            wait(0.1)
        end
    end)
end

-- Handle new players joining
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(1) -- Wait for character to load
        
        if gameState.isRunning then
            trackPlayer(player)
            
            -- Give UI
            local screenGui = ReplicatedStorage:FindFirstChild("RedLightGreenLightUI")
            if screenGui then
                local guiClone = screenGui:Clone()
                guiClone.Parent = player.PlayerGui
            end
        end
    end)
end)

-- Start game command (you can trigger this however you want)
-- For testing, let's start when script runs
wait(5) -- Give time for players to load
startGame()