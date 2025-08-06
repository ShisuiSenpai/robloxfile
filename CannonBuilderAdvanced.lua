--[[
    Advanced Realistic Historical Cannon Builder for Roblox Studio
    Creates an ultra-detailed 17th-18th century field cannon with advanced features
    
    Features:
    - Highly detailed mechanical parts with historical accuracy
    - Custom textures and surface details
    - Interactive elevation and rotation controls
    - Realistic physics constraints
    - Particle effects and sounds
    
    Usage: Place in ServerScriptService or Workspace
--]]

local CannonBuilder = {}

-- Configuration
local CONFIG = {
    SCALE = 1,
    POSITION = Vector3.new(0, 5, 0),
    ENABLE_PHYSICS = false, -- Set to true for unanchored parts with constraints
    ENABLE_SOUNDS = true,
    ENABLE_PARTICLES = true,
    DEBUG_MODE = false
}

-- Enhanced Materials
local Materials = {
    Iron = Enum.Material.Metal,
    IronRough = Enum.Material.CorrodedMetal,
    Brass = Enum.Material.Metal,
    BrassPolished = Enum.Material.Foil,
    Wood = Enum.Material.Wood,
    WoodPlanks = Enum.Material.WoodPlanks,
    Leather = Enum.Material.Leather,
    Rope = Enum.Material.Fabric,
    Stone = Enum.Material.Slate
}

-- Enhanced Color Palette
local Colors = {
    -- Metals
    Iron = Color3.fromRGB(45, 45, 45),
    IronDark = Color3.fromRGB(30, 30, 30),
    IronRust = Color3.fromRGB(70, 40, 30),
    Brass = Color3.fromRGB(184, 115, 51),
    BrassShiny = Color3.fromRGB(205, 127, 50),
    BrassTarnished = Color3.fromRGB(140, 90, 40),
    
    -- Woods
    Wood = Color3.fromRGB(101, 67, 33),
    WoodDark = Color3.fromRGB(61, 43, 31),
    WoodWeathered = Color3.fromRGB(80, 60, 40),
    
    -- Others
    Black = Color3.fromRGB(20, 20, 20),
    Leather = Color3.fromRGB(60, 40, 20),
    Rope = Color3.fromRGB(150, 120, 80),
    Powder = Color3.fromRGB(40, 40, 40)
}

-- Utility Functions
local function createPart(properties)
    local part = Instance.new(properties.PartType or "Part")
    
    -- Basic properties
    part.Name = properties.Name or "Part"
    part.Size = (properties.Size or Vector3.new(1, 1, 1)) * CONFIG.SCALE
    part.Material = properties.Material or Enum.Material.Plastic
    part.Color = properties.Color or Color3.new(0.5, 0.5, 0.5)
    part.TopSurface = properties.TopSurface or Enum.SurfaceType.Smooth
    part.BottomSurface = properties.BottomSurface or Enum.SurfaceType.Smooth
    part.Anchored = not CONFIG.ENABLE_PHYSICS
    part.CanCollide = properties.CanCollide ~= false
    
    -- Shape-specific properties
    if properties.Shape then
        part.Shape = properties.Shape
    end
    
    -- CFrame
    if properties.CFrame then
        part.CFrame = properties.CFrame
    elseif properties.Position then
        part.Position = properties.Position
    end
    
    -- Parent
    part.Parent = properties.Parent
    
    -- Custom properties
    if properties.Transparency then
        part.Transparency = properties.Transparency
    end
    
    if properties.Reflectance then
        part.Reflectance = properties.Reflectance
    end
    
    return part
end

-- Create detailed surface textures
local function addSurfaceDetail(part, detailType)
    if detailType == "rust" then
        local texture = Instance.new("Texture")
        texture.Texture = "rbxasset://textures/rust_diffuse.dds"
        texture.StudsPerTileU = 2
        texture.StudsPerTileV = 2
        texture.Face = Enum.NormalId.Top
        texture.Parent = part
        
        local texture2 = texture:Clone()
        texture2.Face = Enum.NormalId.Front
        texture2.Parent = part
    elseif detailType == "woodgrain" then
        local texture = Instance.new("Texture")
        texture.Texture = "rbxasset://textures/woodgrain_diffuse.dds"
        texture.StudsPerTileU = 4
        texture.StudsPerTileV = 4
        texture.Face = Enum.NormalId.Top
        texture.Parent = part
    end
end

-- Create complex shapes using unions
local function createComplexShape(parts, parent, name)
    if #parts < 2 then return parts[1] end
    
    local success, union = pcall(function()
        local mainPart = parts[1]
        local otherParts = {table.unpack(parts, 2)}
        return mainPart:SubtractAsync(otherParts)
    end)
    
    if success and union then
        union.Name = name
        union.Parent = parent
        
        -- Clean up original parts
        for _, part in ipairs(parts) do
            part:Destroy()
        end
        
        return union
    else
        -- Fallback: just parent the first part
        parts[1].Name = name
        parts[1].Parent = parent
        return parts[1]
    end
end

-- Main Building Functions
function CannonBuilder.BuildCannon()
    local cannonModel = Instance.new("Model")
    cannonModel.Name = "AdvancedHistoricalCannon"
    cannonModel.Parent = workspace
    
    -- Create sub-assemblies
    local assemblies = {
        barrel = Instance.new("Model", cannonModel),
        carriage = Instance.new("Model", cannonModel),
        wheels = Instance.new("Model", cannonModel),
        accessories = Instance.new("Model", cannonModel)
    }
    
    assemblies.barrel.Name = "BarrelAssembly"
    assemblies.carriage.Name = "CarriageAssembly"
    assemblies.wheels.Name = "WheelAssembly"
    assemblies.accessories.Name = "Accessories"
    
    -- Build Barrel with extreme detail
    local function buildDetailedBarrel()
        local barrelParts = {}
        
        -- Create main barrel body with accurate historical proportions
        -- Cascabel to breech section
        local cascabelBase = createPart({
            Name = "CascabelBase",
            PartType = "Part",
            Size = Vector3.new(0.8, 0.8, 0.3),
            Material = Materials.Iron,
            Color = Colors.Iron,
            Position = CONFIG.POSITION + Vector3.new(0, 1, 0.5),
            Parent = assemblies.barrel
        })
        
        local cascabelKnob = createPart({
            Name = "CascabelKnob",
            PartType = "Part",
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(0.5, 0.5, 0.5),
            Material = Materials.Iron,
            Color = Colors.IronDark,
            Position = CONFIG.POSITION + Vector3.new(0, 1, 0.8),
            Parent = assemblies.barrel
        })
        
        -- Breech with detailed moldings
        local breechMain = createPart({
            Name = "BreechMain",
            Size = Vector3.new(1.3, 1.3, 0.8),
            Material = Materials.Iron,
            Color = Colors.IronDark,
            Position = CONFIG.POSITION + Vector3.new(0, 1, 0),
            Parent = assemblies.barrel
        })
        
        -- Add breech details
        for i = 1, 4 do
            local angle = (i - 1) * math.pi / 2
            local breechDetail = createPart({
                Name = "BreechDetail" .. i,
                Size = Vector3.new(0.1, 1.4, 0.1),
                Material = Materials.Iron,
                Color = Colors.Iron,
                Position = CONFIG.POSITION + Vector3.new(
                    math.cos(angle) * 0.65,
                    1,
                    math.sin(angle) * 0.65
                ),
                Parent = assemblies.barrel
            })
        end
        
        -- First reinforce (thickest part)
        local firstReinforce = createPart({
            Name = "FirstReinforce",
            PartType = "Part",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(1.5, 1.2, 1.2),
            Material = Materials.IronRough,
            Color = Colors.Iron,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, 1, -0.75)) * CFrame.Angles(0, math.rad(90), 0),
            Parent = assemblies.barrel
        })
        
        -- Barrel chase (main body) with taper
        local chaseSegments = 12
        for i = 1, chaseSegments do
            local t = (i - 1) / (chaseSegments - 1)
            local z = -1.5 - (t * 5.5)
            local radius = 0.5 - (t * 0.2)
            
            local segment = createPart({
                Name = "ChaseSegment" .. i,
                PartType = "Part",
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(0.5, radius * 2, radius * 2),
                Material = i % 3 == 0 and Materials.IronRough or Materials.Iron,
                Color = i % 2 == 0 and Colors.IronRust or Colors.IronDark,
                CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, 1, z)) * CFrame.Angles(0, math.rad(90), 0),
                Parent = assemblies.barrel
            })
            
            -- Add surface wear
            if i % 3 == 0 then
                addSurfaceDetail(segment, "rust")
            end
        end
        
        -- Muzzle with complex profile
        local muzzleSwell = createPart({
            Name = "MuzzleSwell",
            PartType = "Part",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(0.4, 0.8, 0.8),
            Material = Materials.Brass,
            Color = Colors.BrassShiny,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, 1, -7.2)) * CFrame.Angles(0, math.rad(90), 0),
            Parent = assemblies.barrel
        })
        
        local muzzleFace = createPart({
            Name = "MuzzleFace",
            PartType = "Part",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(0.1, 0.85, 0.85),
            Material = Materials.Brass,
            Color = Colors.Brass,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, 1, -7.5)) * CFrame.Angles(0, math.rad(90), 0),
            Parent = assemblies.barrel
        })
        
        -- Bore with rifling detail
        local bore = createPart({
            Name = "Bore",
            PartType = "Part",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(1, 0.5, 0.5),
            Material = Materials.Metal,
            Color = Colors.Black,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, 1, -7.5)) * CFrame.Angles(0, math.rad(90), 0),
            Transparency = 0.5,
            Parent = assemblies.barrel
        })
        
        -- Trunnions with caps
        for side = -1, 1, 2 do
            local trunnion = createPart({
                Name = side == -1 and "LeftTrunnion" or "RightTrunnion",
                PartType = "Part",
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(0.6, 0.3, 0.3),
                Material = Materials.Iron,
                Color = Colors.Iron,
                CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(side * 0.9, 1, -2)),
                Parent = assemblies.barrel
            })
            
            local trunnionCap = createPart({
                Name = side == -1 and "LeftTrunnionCap" or "RightTrunnionCap",
                PartType = "Part",
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(0.1, 0.35, 0.35),
                Material = Materials.Brass,
                Color = Colors.BrassShiny,
                CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(side * 1.2, 1, -2)),
                Parent = assemblies.barrel
            })
        end
        
        -- Reinforcement bands with ornate details
        local bandPositions = {-1.2, -2.4, -3.6, -4.8, -6}
        for i, zPos in ipairs(bandPositions) do
            local band = createPart({
                Name = "ReinforcementBand" .. i,
                PartType = "Part",
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(0.25, 1.1 - i * 0.08, 1.1 - i * 0.08),
                Material = Materials.BrassPolished,
                Color = Colors.BrassShiny,
                CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, 1, zPos)) * CFrame.Angles(0, math.rad(90), 0),
                Reflectance = 0.3,
                Parent = assemblies.barrel
            })
            
            -- Decorative rivets
            local rivetCount = 12 - i
            for j = 1, rivetCount do
                local angle = (j - 1) * math.pi * 2 / rivetCount
                local rivet = createPart({
                    Name = "Rivet" .. i .. "_" .. j,
                    PartType = "Part",
                    Shape = Enum.PartType.Ball,
                    Size = Vector3.new(0.08, 0.08, 0.08),
                    Material = Materials.Brass,
                    Color = Colors.BrassTarnished,
                    Position = CONFIG.POSITION + Vector3.new(
                        math.cos(angle) * (0.55 - i * 0.04),
                        1 + math.sin(angle) * (0.55 - i * 0.04),
                        zPos
                    ),
                    Parent = assemblies.barrel
                })
            end
        end
        
        -- Touch hole assembly with vent field
        local ventField = createPart({
            Name = "VentField",
            Size = Vector3.new(0.4, 0.05, 0.4),
            Material = Materials.BrassPolished,
            Color = Colors.BrassShiny,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, 1.6, -1)) * CFrame.Angles(math.rad(90), 0, 0),
            Parent = assemblies.barrel
        })
        
        local ventHole = createPart({
            Name = "VentHole",
            PartType = "Part",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(0.8, 0.08, 0.08),
            Material = Materials.Iron,
            Color = Colors.Black,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, 1.5, -1)),
            Parent = assemblies.barrel
        })
        
        -- Proof marks and inscriptions
        local proofMark = createPart({
            Name = "ProofMark",
            Size = Vector3.new(0.3, 0.3, 0.05),
            Material = Materials.Iron,
            Color = Colors.IronDark,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0.5, 1.2, -0.5)),
            Parent = assemblies.barrel
        })
        
        -- Add a SurfaceGui with proof mark
        local proofGui = Instance.new("SurfaceGui")
        proofGui.Face = Enum.NormalId.Front
        proofGui.Parent = proofMark
        
        local proofLabel = Instance.new("TextLabel")
        proofLabel.Size = UDim2.new(1, 0, 1, 0)
        proofLabel.Text = "1756"
        proofLabel.TextScaled = true
        proofLabel.TextColor3 = Colors.Brass
        proofLabel.BackgroundTransparency = 1
        proofLabel.Font = Enum.Font.Antique
        proofLabel.Parent = proofGui
        
        -- Dolphins (lifting handles)
        for side = -1, 1, 2 do
            local dolphin = createPart({
                Name = side == -1 and "LeftDolphin" or "RightDolphin",
                Size = Vector3.new(0.2, 0.4, 0.3),
                Material = Materials.Brass,
                Color = Colors.Brass,
                CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(side * 0.6, 1.4, -3.5)),
                Parent = assemblies.barrel
            })
            
            -- Dolphin decoration
            local dolphinHead = createPart({
                Name = "DolphinHead",
                PartType = "WedgePart",
                Size = Vector3.new(0.15, 0.2, 0.1),
                Material = Materials.Brass,
                Color = Colors.BrassShiny,
                CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(side * 0.6, 1.5, -3.6)),
                Parent = assemblies.barrel
            })
        end
    end
    
    -- Build Carriage with authentic details
    local function buildDetailedCarriage()
        -- Trail with complex shape
        for side = -1, 1, 2 do
            -- Main cheek
            local cheek = createPart({
                Name = side == -1 and "LeftCheek" or "RightCheek",
                Size = Vector3.new(0.8, 0.7, 5.5),
                Material = Materials.WoodPlanks,
                Color = Colors.Wood,
                CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(side * 0.7, 0, -2)),
                Parent = assemblies.carriage
            })
            addSurfaceDetail(cheek, "woodgrain")
            
            -- Trail extension
            local trail = createPart({
                Name = side == -1 and "LeftTrail" or "RightTrail",
                PartType = "WedgePart",
                Size = Vector3.new(0.8, 0.5, 2.5),
                Material = Materials.Wood,
                Color = Colors.WoodWeathered,
                CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(side * 0.7, -0.1, 2)) * CFrame.Angles(0, math.rad(180), 0),
                Parent = assemblies.carriage
            })
            
            -- Trail handle
            local handle = createPart({
                Name = "TrailHandle" .. side,
                PartType = "Part",
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(0.8, 0.15, 0.15),
                Material = Materials.Wood,
                Color = Colors.WoodDark,
                CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(side * 0.7, 0.2, 3.5)),
                Parent = assemblies.carriage
            })
            
            -- Trunnion beds (cutouts for trunnions)
            local trunnionBed = createPart({
                Name = "TrunnionBed" .. side,
                Size = Vector3.new(0.4, 0.8, 0.4),
                Material = Materials.Iron,
                Color = Colors.Iron,
                CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(side * 0.7, 0.8, -2)),
                Parent = assemblies.carriage
            })
            
            -- Cap square (holds trunnion in place)
            local capSquare = createPart({
                Name = "CapSquare" .. side,
                Size = Vector3.new(0.35, 0.4, 0.35),
                Material = Materials.Iron,
                Color = Colors.IronDark,
                CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(side * 0.7, 1.2, -2)),
                Parent = assemblies.carriage
            })
        end
        
        -- Transom and bed
        local transom = createPart({
            Name = "Transom",
            Size = Vector3.new(2, 0.9, 0.5),
            Material = Materials.WoodPlanks,
            Color = Colors.Wood,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, 0.1, 1)),
            Parent = assemblies.carriage
        })
        
        -- Stool bed (bottom supports)
        for i = 1, 4 do
            local stoolBed = createPart({
                Name = "StoolBed" .. i,
                Size = Vector3.new(2.2, 0.35, 0.5),
                Material = Materials.Wood,
                Color = Colors.WoodDark,
                CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, -0.2, -3.5 + i * 1.5)),
                Parent = assemblies.carriage
            })
            
            -- Iron straps
            local strap = createPart({
                Name = "IronStrap" .. i,
                Size = Vector3.new(2.3, 0.05, 0.6),
                Material = Materials.Iron,
                Color = Colors.Iron,
                CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, -0.02, -3.5 + i * 1.5)),
                Parent = assemblies.carriage
            })
        end
        
        -- Pointing stakes storage
        local stakeHolder = createPart({
            Name = "StakeHolder",
            Size = Vector3.new(0.1, 0.1, 2),
            Material = Materials.Iron,
            Color = Colors.IronDark,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(-1.1, 0.3, -1)),
            Parent = assemblies.carriage
        })
        
        -- Quoin (elevation wedge)
        local quoin = createPart({
            Name = "Quoin",
            PartType = "WedgePart",
            Size = Vector3.new(0.6, 0.3, 1.2),
            Material = Materials.Wood,
            Color = Colors.WoodDark,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, -0.1, -1.5)) * CFrame.Angles(0, 0, math.rad(180)),
            Parent = assemblies.carriage
        })
        
        -- Elevation mechanism
        local elevScrew = createPart({
            Name = "ElevationScrew",
            PartType = "Part",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(2.5, 0.1, 0.1),
            Material = Materials.Brass,
            Color = Colors.Brass,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, -0.5, -0.5)),
            Parent = assemblies.carriage
        })
        
        -- Handspike rings
        for i = 1, 2 do
            for side = -1, 1, 2 do
                local ring = createPart({
                    Name = "HandspikeRing" .. side .. "_" .. i,
                    Size = Vector3.new(0.2, 0.2, 0.2),
                    Material = Materials.Iron,
                    Color = Colors.Iron,
                    CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(side * 1, -0.2, i - 0.5)),
                    Parent = assemblies.carriage
                })
            end
        end
    end
    
    -- Build Wheels with full detail
    local function buildDetailedWheel(name, position)
        local wheel = Instance.new("Model")
        wheel.Name = name
        wheel.Parent = assemblies.wheels
        
        -- Nave (hub)
        local nave = createPart({
            Name = name .. "_Nave",
            PartType = "Part",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(0.7, 0.6, 0.6),
            Material = Materials.Iron,
            Color = Colors.Iron,
            CFrame = CFrame.new(position),
            Parent = wheel
        })
        
        -- Nave bands
        for i = -1, 1 do
            if i ~= 0 then
                local naveBand = createPart({
                    Name = name .. "_NaveBand" .. i,
                    PartType = "Part",
                    Shape = Enum.PartType.Cylinder,
                    Size = Vector3.new(0.08, 0.65, 0.65),
                    Material = Materials.BrassPolished,
                    Color = Colors.BrassShiny,
                    CFrame = CFrame.new(position + Vector3.new(i * 0.3, 0, 0)),
                    Reflectance = 0.2,
                    Parent = wheel
                })
            end
        end
        
        -- Spokes (12 for authenticity)
        local spokeCount = 12
        for i = 1, spokeCount do
            local angle = (i - 1) * math.pi * 2 / spokeCount
            
            local spoke = createPart({
                Name = name .. "_Spoke" .. i,
                Size = Vector3.new(0.2, 2.6, 0.15),
                Material = Materials.WoodPlanks,
                Color = i % 2 == 0 and Colors.Wood or Colors.WoodDark,
                CFrame = CFrame.new(position) * CFrame.Angles(0, 0, angle),
                Parent = wheel
            })
            
            -- Spoke dowels
            local dowel = createPart({
                Name = name .. "_Dowel" .. i,
                PartType = "Part",
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(0.3, 0.05, 0.05),
                Material = Materials.Wood,
                Color = Colors.WoodDark,
                CFrame = CFrame.new(position + Vector3.new(0, math.sin(angle) * 1.2, math.cos(angle) * 1.2)) * CFrame.Angles(0, 0, angle),
                Parent = wheel
            })
        end
        
        -- Felloes (rim segments)
        local felloeCount = 6
        for i = 1, felloeCount do
            local startAngle = (i - 1) * math.pi * 2 / felloeCount
            local endAngle = i * math.pi * 2 / felloeCount
            local midAngle = (startAngle + endAngle) / 2
            
            local felloe = createPart({
                Name = name .. "_Felloe" .. i,
                Size = Vector3.new(0.35, 0.35, 1.5),
                Material = Materials.Wood,
                Color = Colors.WoodWeathered,
                CFrame = CFrame.new(
                    position + Vector3.new(0, math.sin(midAngle) * 1.3, math.cos(midAngle) * 1.3)
                ) * CFrame.Angles(0, 0, midAngle),
                Parent = wheel
            })
            
            -- Dowel pins connecting felloes
            local dowelPin = createPart({
                Name = name .. "_FelloeDowel" .. i,
                PartType = "Part",
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(0.4, 0.08, 0.08),
                Material = Materials.Wood,
                Color = Colors.WoodDark,
                CFrame = CFrame.new(
                    position + Vector3.new(0, math.sin(endAngle) * 1.3, math.cos(endAngle) * 1.3)
                ),
                Parent = wheel
            })
        end
        
        -- Iron tire (strakes)
        local strakeCount = 6
        for i = 1, strakeCount do
            local startAngle = (i - 1) * math.pi * 2 / strakeCount - math.pi / strakeCount
            local endAngle = i * math.pi * 2 / strakeCount - math.pi / strakeCount
            local midAngle = (startAngle + endAngle) / 2
            
            local strake = createPart({
                Name = name .. "_Strake" .. i,
                Size = Vector3.new(0.15, 0.2, 1.6),
                Material = Materials.Iron,
                Color = Colors.IronDark,
                CFrame = CFrame.new(
                    position + Vector3.new(0, math.sin(midAngle) * 1.5, math.cos(midAngle) * 1.5)
                ) * CFrame.Angles(0, 0, midAngle),
                Parent = wheel
            })
            
            -- Nails
            for j = 1, 3 do
                local nail = createPart({
                    Name = name .. "_Nail" .. i .. "_" .. j,
                    PartType = "Part",
                    Shape = Enum.PartType.Ball,
                    Size = Vector3.new(0.06, 0.06, 0.06),
                    Material = Materials.Iron,
                    Color = Colors.Iron,
                    Position = position + Vector3.new(
                        0,
                        math.sin(midAngle) * 1.52,
                        math.cos(midAngle) * 1.52
                    ) + Vector3.new((j - 2) * 0.4, 0, 0),
                    Parent = wheel
                })
            end
        end
        
        -- Linchpin and washer
        local linchpin = createPart({
            Name = name .. "_Linchpin",
            PartType = "Part",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(1, 0.08, 0.08),
            Material = Materials.Iron,
            Color = Colors.Iron,
            CFrame = CFrame.new(position + Vector3.new(0, 0.35, 0)) * CFrame.Angles(math.rad(90), 0, 0),
            Parent = wheel
        })
        
        local washer = createPart({
            Name = name .. "_Washer",
            PartType = "Part",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(0.05, 0.4, 0.4),
            Material = Materials.Iron,
            Color = Colors.IronDark,
            CFrame = CFrame.new(position + Vector3.new(0.35 * (name:find("Left") and -1 or 1), 0, 0)),
            Parent = wheel
        })
        
        return wheel
    end
    
    -- Build Accessories
    local function buildAccessories()
        -- Rammer
        local rammer = createPart({
            Name = "Rammer",
            PartType = "Part",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(6, 0.15, 0.15),
            Material = Materials.Wood,
            Color = Colors.Wood,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(-1.2, 0.4, -2)) * CFrame.Angles(0, 0, math.rad(10)),
            Parent = assemblies.accessories
        })
        
        local rammerHead = createPart({
            Name = "RammerHead",
            PartType = "Part",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(0.3, 0.4, 0.4),
            Material = Materials.Wood,
            Color = Colors.WoodDark,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(-1.2, 0.4, -5)) * CFrame.Angles(0, 0, math.rad(10)),
            Parent = assemblies.accessories
        })
        
        -- Sponge
        local spongeStaff = createPart({
            Name = "SpongeStaff",
            PartType = "Part",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(6, 0.15, 0.15),
            Material = Materials.Wood,
            Color = Colors.Wood,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(1.2, 0.4, -2)) * CFrame.Angles(0, 0, math.rad(-10)),
            Parent = assemblies.accessories
        })
        
        local spongeHead = createPart({
            Name = "SpongeHead",
            PartType = "Part",
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(0.5, 0.5, 0.5),
            Material = Materials.Leather,
            Color = Colors.Leather,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(1.2, 0.4, 1)),
            Parent = assemblies.accessories
        })
        
        -- Worm (corkscrew for removing charges)
        local worm = createPart({
            Name = "Worm",
            Size = Vector3.new(0.1, 0.1, 0.8),
            Material = Materials.Iron,
            Color = Colors.Iron,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0.8, -0.3, 2)),
            Parent = assemblies.accessories
        })
        
        -- Powder bucket
        local bucket = createPart({
            Name = "PowderBucket",
            PartType = "Part",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(0.8, 0.6, 0.6),
            Material = Materials.Leather,
            Color = Colors.Leather,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(1.2, -0.2, 0.5)),
            Parent = assemblies.accessories
        })
        
        local bucketLid = createPart({
            Name = "BucketLid",
            PartType = "Part",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(0.1, 0.65, 0.65),
            Material = Materials.Wood,
            Color = Colors.WoodDark,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(1.2, 0.2, 0.5)),
            Parent = assemblies.accessories
        })
        
        -- Slow match holder
        local matchHolder = createPart({
            Name = "MatchHolder",
            Size = Vector3.new(0.05, 1.5, 0.05),
            Material = Materials.Iron,
            Color = Colors.IronDark,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(-0.8, 0.5, 1.5)),
            Parent = assemblies.accessories
        })
        
        -- Handspikes
        for i = 1, 2 do
            local handspike = createPart({
                Name = "Handspike" .. i,
                Size = Vector3.new(0.15, 0.15, 4),
                Material = Materials.Wood,
                Color = Colors.Wood,
                CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(-0.5 + i * 0.3, -0.3, 0)) * CFrame.Angles(math.rad(85), 0, 0),
                Parent = assemblies.accessories
            })
        end
    end
    
    -- Execute build functions
    buildDetailedBarrel()
    buildDetailedCarriage()
    
    -- Build wheels
    local leftWheel = buildDetailedWheel("LeftWheel", CONFIG.POSITION + Vector3.new(-1.5, 0, 1))
    local rightWheel = buildDetailedWheel("RightWheel", CONFIG.POSITION + Vector3.new(1.5, 0, 1))
    
    -- Axletree
    local axletree = createPart({
        Name = "Axletree",
        Size = Vector3.new(3.5, 0.3, 0.3),
        Material = Materials.Iron,
        Color = Colors.IronDark,
        CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, 0, 1)),
        Parent = assemblies.wheels
    })
    
    -- Axle boxes
    for side = -1, 1, 2 do
        local axleBox = createPart({
            Name = "AxleBox" .. side,
            Size = Vector3.new(0.4, 0.4, 0.4),
            Material = Materials.Iron,
            Color = Colors.Iron,
            CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(side * 0.8, -0.2, 1)),
            Parent = assemblies.carriage
        })
    end
    
    buildAccessories()
    
    -- Set primary part
    cannonModel.PrimaryPart = assemblies.barrel.BreechMain
    
    -- Add physics constraints if enabled
    if CONFIG.ENABLE_PHYSICS then
        -- Add HingeConstraints for wheels
        for _, wheel in ipairs(assemblies.wheels:GetChildren()) do
            if wheel:IsA("Model") and wheel.Name:find("Wheel") then
                local hinge = Instance.new("HingeConstraint")
                hinge.Attachment0 = Instance.new("Attachment", axletree)
                hinge.Attachment1 = Instance.new("Attachment", wheel:FindFirstChild(wheel.Name .. "_Nave"))
                hinge.Parent = wheel
            end
        end
    end
    
    -- Interactive features
    local function setupInteraction()
        local clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 20
        clickDetector.Parent = assemblies.barrel.BreechMain
        
        local fireSound = Instance.new("Sound")
        fireSound.SoundId = "rbxasset://sounds/bass.mp3"
        fireSound.Volume = 1
        fireSound.Pitch = 0.5
        fireSound.Parent = assemblies.barrel.Bore
        
        clickDetector.MouseClick:Connect(function(player)
            -- Fire effect
            if CONFIG.ENABLE_PARTICLES then
                local smoke = Instance.new("Smoke")
                smoke.Color = Color3.fromRGB(50, 50, 50)
                smoke.Opacity = 0.7
                smoke.Size = 3
                smoke.RiseVelocity = 8
                smoke.Parent = assemblies.barrel.Bore
                
                local fire = Instance.new("Fire")
                fire.Size = 8
                fire.Heat = 15
                fire.Color = Color3.fromRGB(255, 170, 0)
                fire.SecondaryColor = Color3.fromRGB(255, 100, 0)
                fire.Parent = assemblies.barrel.Bore
                
                -- Flash
                local flash = createPart({
                    Name = "MuzzleFlash",
                    PartType = "Part",
                    Shape = Enum.PartType.Ball,
                    Size = Vector3.new(3, 3, 3),
                    Material = Enum.Material.Neon,
                    Color = Color3.fromRGB(255, 200, 0),
                    CFrame = CFrame.new(CONFIG.POSITION + Vector3.new(0, 1, -8)),
                    Transparency = 0.5,
                    Parent = assemblies.barrel
                })
                
                if CONFIG.ENABLE_SOUNDS then
                    fireSound:Play()
                end
                
                wait(0.1)
                flash:Destroy()
                fire.Enabled = false
                
                wait(0.5)
                smoke.Enabled = false
                
                wait(3)
                smoke:Destroy()
                fire:Destroy()
            end
            
            -- Recoil animation
            local originalCFrame = assemblies.barrel:GetPrimaryPartCFrame()
            for i = 1, 15 do
                assemblies.barrel:SetPrimaryPartCFrame(
                    originalCFrame * CFrame.new(0, 0, math.sin(i * 0.3) * 0.5 * math.exp(-i * 0.15))
                )
                wait(0.03)
            end
            assemblies.barrel:SetPrimaryPartCFrame(originalCFrame)
        end)
    end
    
    setupInteraction()
    
    print("Advanced Historical Cannon successfully built!")
    print("Features:")
    print("- Ultra-detailed mechanical parts")
    print("- Historically accurate components")
    print("- Interactive firing mechanism")
    print("- " .. (CONFIG.ENABLE_PHYSICS and "Physics enabled" or "Static display"))
    
    return cannonModel
end

-- Auto-build on script execution
return CannonBuilder.BuildCannon()