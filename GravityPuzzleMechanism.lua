-- Advanced Gravity Manipulation Puzzle System
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")

-- Physics groups
PhysicsService:CreateCollisionGroup("GravityObjects")
PhysicsService:CreateCollisionGroup("GravityFields")
PhysicsService:CollisionGroupSetCollidable("GravityObjects", "GravityFields", false)

-- Configuration
local GRID_SIZE = 4
local CELL_SIZE = 8
local GRAVITY_STRENGTH = 50
local OBJECT_MASS = 10

-- Variables
local puzzleRooms = {}
local activeConnections = {}

-- Create gravity field visualizer (subtle)
local function createFieldVisualizer(part, direction)
    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Top
    surface.Parent = part
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 0.7
    frame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
    frame.Parent = surface
    
    -- Direction indicator
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(1, 0, 1, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "↓"
    arrow.TextScaled = true
    arrow.TextColor3 = Color3.new(0.5, 0.5, 0.7)
    arrow.Font = Enum.Font.SourceSans
    arrow.Parent = frame
    
    -- Rotate arrow based on gravity direction
    if direction == Vector3.new(1, 0, 0) then
        arrow.Rotation = -90
    elseif direction == Vector3.new(-1, 0, 0) then
        arrow.Rotation = 90
    elseif direction == Vector3.new(0, 0, 1) then
        arrow.Rotation = 180
    elseif direction == Vector3.new(0, 0, -1) then
        arrow.Rotation = 0
    elseif direction == Vector3.new(0, 1, 0) then
        arrow.Text = "•"
    end
    
    return surface
end

-- Create gravity-affected object
local function createGravityObject(position, color, shape)
    local object = Instance.new("Part")
    object.Name = "GravityObject"
    object.Size = Vector3.new(3, 3, 3)
    object.Position = position
    object.Material = Enum.Material.Neon
    object.Color = color
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    
    if shape == "sphere" then
        object.Shape = Enum.PartType.Ball
    elseif shape == "cylinder" then
        object.Shape = Enum.PartType.Cylinder
        object.Size = Vector3.new(3, 3, 3)
    end
    
    -- Physics setup
    object.CustomPhysicalProperties = PhysicalProperties.new(
        OBJECT_MASS,  -- Density
        0.5,          -- Friction  
        0.2,          -- Elasticity
        1,            -- FrictionWeight
        1             -- ElasticityWeight
    )
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = object
    
    local bodyPosition = Instance.new("BodyPosition")
    bodyPosition.MaxForce = Vector3.new(0, 0, 0)
    bodyPosition.Parent = object
    
    CollectionService:AddTag(object, "GravityObject")
    PhysicsService:SetPartCollisionGroup(object, "GravityObjects")
    
    object.Parent = workspace
    return object
end

-- Create gravity field
local function createGravityField(position, size, gravityDirection)
    local field = Instance.new("Part")
    field.Name = "GravityField"
    field.Size = size
    field.Position = position
    field.Anchored = true
    field.CanCollide = false
    field.Transparency = 0.8
    field.Material = Enum.Material.ForceField
    field.Color = Color3.new(0.3, 0.3, 0.5)
    
    -- Store gravity data
    local gravityData = Instance.new("Vector3Value")
    gravityData.Name = "GravityDirection"
    gravityData.Value = gravityDirection
    gravityData.Parent = field
    
    CollectionService:AddTag(field, "GravityField")
    PhysicsService:SetPartCollisionGroup(field, "GravityFields")
    
    createFieldVisualizer(field, gravityDirection)
    
    field.Parent = workspace
    return field
end

-- Create interactive switch
local function createSwitch(position, fieldToControl, newGravityDirection)
    local switch = Instance.new("Part")
    switch.Name = "GravitySwitch"
    switch.Size = Vector3.new(4, 1, 4)
    switch.Position = position
    switch.Anchored = true
    switch.Material = Enum.Material.Diamond
    switch.Color = Color3.new(0.8, 0.3, 0.3)
    switch.Parent = workspace
    
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 10
    clickDetector.Parent = switch
    
    local isActivated = false
    
    clickDetector.MouseClick:Connect(function()
        isActivated = not isActivated
        
        if isActivated then
            switch.Color = Color3.new(0.3, 0.8, 0.3)
            fieldToControl.GravityDirection.Value = newGravityDirection
            
            -- Update visualizer
            fieldToControl:FindFirstChild("SurfaceGui"):Destroy()
            createFieldVisualizer(fieldToControl, newGravityDirection)
        else
            switch.Color = Color3.new(0.8, 0.3, 0.3)
            fieldToControl.GravityDirection.Value = Vector3.new(0, -1, 0) -- Reset to normal
            
            fieldToControl:FindFirstChild("SurfaceGui"):Destroy()
            createFieldVisualizer(fieldToControl, Vector3.new(0, -1, 0))
        end
        
        -- Animate switch
        local tween = TweenService:Create(switch, TweenInfo.new(0.1), {
            Size = Vector3.new(4, 0.5, 4)
        })
        tween:Play()
        wait(0.1)
        local tween2 = TweenService:Create(switch, TweenInfo.new(0.1), {
            Size = Vector3.new(4, 1, 4)
        })
        tween2:Play()
    end)
    
    return switch
end

-- Create pressure plate
local function createPressurePlate(position, callback)
    local plate = Instance.new("Part")
    plate.Name = "PressurePlate"
    plate.Size = Vector3.new(6, 0.5, 6)
    plate.Position = position
    plate.Anchored = true
    plate.Material = Enum.Material.Metal
    plate.Color = Color3.new(0.5, 0.5, 0.5)
    plate.Parent = workspace
    
    local isPressed = false
    local objectsOnPlate = {}
    
    plate.Touched:Connect(function(hit)
        if CollectionService:HasTag(hit, "GravityObject") and not objectsOnPlate[hit] then
            objectsOnPlate[hit] = true
            
            if not isPressed then
                isPressed = true
                plate.Color = Color3.new(0.3, 0.7, 0.3)
                local tween = TweenService:Create(plate, TweenInfo.new(0.2), {
                    Size = Vector3.new(6, 0.2, 6),
                    Position = position - Vector3.new(0, 0.15, 0)
                })
                tween:Play()
                callback(true)
            end
        end
    end)
    
    -- Check if objects left the plate
    RunService.Heartbeat:Connect(function()
        for obj, _ in pairs(objectsOnPlate) do
            if not obj.Parent or (obj.Position - plate.Position).Magnitude > 5 then
                objectsOnPlate[obj] = nil
            end
        end
        
        if next(objectsOnPlate) == nil and isPressed then
            isPressed = false
            plate.Color = Color3.new(0.5, 0.5, 0.5)
            local tween = TweenService:Create(plate, TweenInfo.new(0.2), {
                Size = Vector3.new(6, 0.5, 6),
                Position = position
            })
            tween:Play()
            callback(false)
        end
    end)
    
    return plate
end

-- Create goal receptor
local function createGoalReceptor(position, requiredColor)
    local receptor = Instance.new("Part")
    receptor.Name = "GoalReceptor"
    receptor.Size = Vector3.new(5, 5, 5)
    receptor.Position = position
    receptor.Anchored = true
    receptor.Transparency = 0.5
    receptor.Material = Enum.Material.ForceField
    receptor.Color = requiredColor
    receptor.Shape = Enum.PartType.Cylinder
    receptor.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    receptor.Parent = workspace
    
    local completed = false
    
    receptor.Touched:Connect(function(hit)
        if CollectionService:HasTag(hit, "GravityObject") and hit.Color == requiredColor and not completed then
            completed = true
            
            -- Success effect
            local successTween = TweenService:Create(receptor, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), {
                Size = Vector3.new(6, 6, 6),
                Transparency = 0
            })
            successTween:Play()
            
            wait(0.5)
            hit:Destroy()
            
            local fadeTween = TweenService:Create(receptor, TweenInfo.new(1), {
                Transparency = 1
            })
            fadeTween:Play()
        end
    end)
    
    return receptor
end

-- Create a puzzle room
local function createPuzzleRoom(centerPosition)
    local room = {
        parts = {},
        connections = {}
    }
    
    -- Floor
    local floor = Instance.new("Part")
    floor.Name = "PuzzleFloor"
    floor.Size = Vector3.new(60, 2, 60)
    floor.Position = centerPosition - Vector3.new(0, 10, 0)
    floor.Anchored = true
    floor.Material = Enum.Material.Concrete
    floor.Color = Color3.new(0.3, 0.3, 0.3)
    floor.Parent = workspace
    table.insert(room.parts, floor)
    
    -- Walls
    local wallPositions = {
        {centerPosition + Vector3.new(30, 5, 0), Vector3.new(2, 30, 60)},
        {centerPosition + Vector3.new(-30, 5, 0), Vector3.new(2, 30, 60)},
        {centerPosition + Vector3.new(0, 5, 30), Vector3.new(60, 30, 2)},
        {centerPosition + Vector3.new(0, 5, -30), Vector3.new(60, 30, 2)}
    }
    
    for _, wallData in ipairs(wallPositions) do
        local wall = Instance.new("Part")
        wall.Name = "PuzzleWall"
        wall.Size = wallData[2]
        wall.Position = wallData[1]
        wall.Anchored = true
        wall.Material = Enum.Material.Concrete
        wall.Color = Color3.new(0.4, 0.4, 0.4)
        wall.Parent = workspace
        table.insert(room.parts, wall)
    end
    
    -- Create main gravity field
    local mainField = createGravityField(
        centerPosition,
        Vector3.new(50, 25, 50),
        Vector3.new(0, -1, 0)
    )
    table.insert(room.parts, mainField)
    
    -- Create side gravity fields
    local leftField = createGravityField(
        centerPosition + Vector3.new(-20, 5, 0),
        Vector3.new(15, 20, 40),
        Vector3.new(1, 0, 0)
    )
    table.insert(room.parts, leftField)
    
    local rightField = createGravityField(
        centerPosition + Vector3.new(20, 5, 0),
        Vector3.new(15, 20, 40),
        Vector3.new(-1, 0, 0)
    )
    table.insert(room.parts, rightField)
    
    -- Create objects
    local object1 = createGravityObject(
        centerPosition + Vector3.new(-15, 10, -15),
        Color3.new(1, 0.3, 0.3),
        "sphere"
    )
    table.insert(room.parts, object1)
    
    local object2 = createGravityObject(
        centerPosition + Vector3.new(15, 10, -15),
        Color3.new(0.3, 1, 0.3),
        "cube"
    )
    table.insert(room.parts, object2)
    
    local object3 = createGravityObject(
        centerPosition + Vector3.new(0, 10, -15),
        Color3.new(0.3, 0.3, 1),
        "cylinder"
    )
    table.insert(room.parts, object3)
    
    -- Create switches
    local switch1 = createSwitch(
        centerPosition + Vector3.new(-20, -8, -20),
        leftField,
        Vector3.new(0, 1, 0)
    )
    table.insert(room.parts, switch1)
    
    local switch2 = createSwitch(
        centerPosition + Vector3.new(20, -8, -20),
        rightField,
        Vector3.new(0, 0, 1)
    )
    table.insert(room.parts, switch2)
    
    -- Create pressure plates and doors
    local door = Instance.new("Part")
    door.Name = "Door"
    door.Size = Vector3.new(10, 15, 2)
    door.Position = centerPosition + Vector3.new(0, -2, 20)
    door.Anchored = true
    door.Material = Enum.Material.Metal
    door.Color = Color3.new(0.6, 0.6, 0.6)
    door.Parent = workspace
    table.insert(room.parts, door)
    
    local plate = createPressurePlate(
        centerPosition + Vector3.new(0, -8, 0),
        function(pressed)
            if pressed then
                local tween = TweenService:Create(door, TweenInfo.new(1), {
                    Position = centerPosition + Vector3.new(0, 10, 20)
                })
                tween:Play()
            else
                local tween = TweenService:Create(door, TweenInfo.new(1), {
                    Position = centerPosition + Vector3.new(0, -2, 20)
                })
                tween:Play()
            end
        end
    )
    table.insert(room.parts, plate)
    
    -- Create goal receptors
    local receptor1 = createGoalReceptor(
        centerPosition + Vector3.new(-20, -6, 20),
        Color3.new(1, 0.3, 0.3)
    )
    table.insert(room.parts, receptor1)
    
    local receptor2 = createGoalReceptor(
        centerPosition + Vector3.new(0, -6, 20),
        Color3.new(0.3, 1, 0.3)
    )
    table.insert(room.parts, receptor2)
    
    local receptor3 = createGoalReceptor(
        centerPosition + Vector3.new(20, -6, 20),
        Color3.new(0.3, 0.3, 1)
    )
    table.insert(room.parts, receptor3)
    
    return room
end

-- Physics simulation
local function applyGravityToObject(object, gravityDirection, strength)
    local bodyVelocity = object:FindFirstChild("BodyVelocity")
    if bodyVelocity then
        local currentVelocity = bodyVelocity.Velocity
        local gravityVelocity = gravityDirection * strength
        
        -- Apply gravity while maintaining some of the current velocity
        bodyVelocity.Velocity = currentVelocity * 0.95 + gravityVelocity * 0.05
    end
end

-- Main physics loop
RunService.Heartbeat:Connect(function()
    local gravityObjects = CollectionService:GetTagged("GravityObject")
    local gravityFields = CollectionService:GetTagged("GravityField")
    
    for _, object in ipairs(gravityObjects) do
        if object.Parent then
            local netGravity = Vector3.new(0, 0, 0)
            local inAnyField = false
            
            for _, field in ipairs(gravityFields) do
                if field.Parent then
                    -- Check if object is inside field
                    local relative = object.Position - field.Position
                    local halfSize = field.Size / 2
                    
                    if math.abs(relative.X) <= halfSize.X and
                       math.abs(relative.Y) <= halfSize.Y and
                       math.abs(relative.Z) <= halfSize.Z then
                        
                        inAnyField = true
                        local gravityDir = field:FindFirstChild("GravityDirection")
                        if gravityDir then
                            netGravity = netGravity + gravityDir.Value
                        end
                    end
                end
            end
            
            if inAnyField then
                applyGravityToObject(object, netGravity.Unit, GRAVITY_STRENGTH)
            else
                -- Default gravity
                applyGravityToObject(object, Vector3.new(0, -1, 0), GRAVITY_STRENGTH)
            end
        end
    end
end)

-- Create the puzzle room
createPuzzleRoom(Vector3.new(0, 20, 0))

-- Player respawn handling
local function onCharacterAdded(character)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    wait(1)
    humanoidRootPart.CFrame = CFrame.new(0, 15, -40) -- Spawn outside looking in
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(onCharacterAdded)
end)

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        onCharacterAdded(player.Character)
    end
end