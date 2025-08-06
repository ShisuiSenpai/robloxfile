--[[
    Realistic Historical Cannon Builder for Roblox Studio
    Creates a highly detailed 17th-18th century field cannon
    Place this script in ServerScriptService or Workspace
--]]

local cannon = {}

-- Configuration
local SCALE = 1 -- Adjust this to scale the entire cannon
local POSITION = Vector3.new(0, 5, 0) -- Base position of the cannon

-- Material and color definitions
local Materials = {
    Iron = Enum.Material.Metal,
    Brass = Enum.Material.Metal,
    Wood = Enum.Material.Wood,
    WoodPlanks = Enum.Material.WoodPlanks,
    Rust = Enum.Material.CorrodedMetal
}

local Colors = {
    Iron = Color3.fromRGB(45, 45, 45),
    IronDark = Color3.fromRGB(30, 30, 30),
    Brass = Color3.fromRGB(184, 115, 51),
    BrassShiny = Color3.fromRGB(205, 127, 50),
    Wood = Color3.fromRGB(101, 67, 33),
    WoodDark = Color3.fromRGB(61, 43, 31),
    Black = Color3.fromRGB(20, 20, 20)
}

-- Helper function to create parts with common properties
local function createPart(name, size, material, color, parent)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size * SCALE
    part.Material = material
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Anchored = true
    part.CanCollide = true
    part.Parent = parent
    return part
end

-- Helper function to create cylinder parts
local function createCylinder(name, radius, height, material, color, parent)
    local part = Instance.new("Part")
    part.Name = name
    part.Shape = Enum.PartType.Cylinder
    part.Size = Vector3.new(height, radius * 2, radius * 2) * SCALE
    part.Material = material
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Anchored = true
    part.CanCollide = true
    part.Parent = parent
    return part
end

-- Helper function to create wedge parts
local function createWedge(name, size, material, color, parent)
    local part = Instance.new("WedgePart")
    part.Name = name
    part.Size = size * SCALE
    part.Material = material
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Anchored = true
    part.CanCollide = true
    part.Parent = parent
    return part
end

-- Create the main cannon model
function cannon.build()
    -- Create main model
    local cannonModel = Instance.new("Model")
    cannonModel.Name = "HistoricalCannon"
    cannonModel.Parent = workspace
    
    -- Create sub-models for organization
    local barrelAssembly = Instance.new("Model")
    barrelAssembly.Name = "BarrelAssembly"
    barrelAssembly.Parent = cannonModel
    
    local carriageAssembly = Instance.new("Model")
    carriageAssembly.Name = "CarriageAssembly"
    carriageAssembly.Parent = cannonModel
    
    local wheelAssembly = Instance.new("Model")
    wheelAssembly.Name = "WheelAssembly"
    wheelAssembly.Parent = cannonModel
    
    -- BUILD BARREL ASSEMBLY
    local function buildBarrel()
        -- Main barrel segments (tapered)
        local barrelSegments = {}
        local segmentCount = 8
        local barrelLength = 8
        
        for i = 1, segmentCount do
            local t = (i - 1) / (segmentCount - 1)
            local radius = 0.5 - t * 0.15 -- Taper from breech to muzzle
            local segmentLength = barrelLength / segmentCount
            
            local segment = createCylinder(
                "BarrelSegment" .. i,
                radius,
                segmentLength,
                Materials.Iron,
                Colors.IronDark,
                barrelAssembly
            )
            
            segment.CFrame = CFrame.new(POSITION + Vector3.new(0, 1, -i * segmentLength + segmentLength/2)) * 
                           CFrame.Angles(0, math.rad(90), 0)
            
            -- Add surface texture detail
            if i % 2 == 0 then
                segment.Material = Materials.Rust
            end
            
            table.insert(barrelSegments, segment)
        end
        
        -- Cascabel (decorative knob at rear)
        local cascabel = createPart(
            "Cascabel",
            Vector3.new(0.4, 0.4, 0.4),
            Materials.Iron,
            Colors.Iron,
            barrelAssembly
        )
        cascabel.Shape = Enum.PartType.Ball
        cascabel.CFrame = CFrame.new(POSITION + Vector3.new(0, 1, 0.5))
        
        -- Breech block
        local breech = createPart(
            "Breech",
            Vector3.new(1.2, 1.2, 0.6),
            Materials.Iron,
            Colors.IronDark,
            barrelAssembly
        )
        breech.CFrame = CFrame.new(POSITION + Vector3.new(0, 1, 0))
        
        -- Reinforcement bands
        for i = 1, 4 do
            local band = createCylinder(
                "ReinforcementBand" .. i,
                0.55 - i * 0.05,
                0.2,
                Materials.Brass,
                Colors.BrassShiny,
                barrelAssembly
            )
            band.CFrame = CFrame.new(POSITION + Vector3.new(0, 1, -i * 1.8)) * 
                         CFrame.Angles(0, math.rad(90), 0)
            
            -- Add decorative studs
            for j = 1, 8 do
                local angle = (j - 1) * math.pi * 2 / 8
                local stud = createPart(
                    "Stud" .. i .. "_" .. j,
                    Vector3.new(0.1, 0.1, 0.1),
                    Materials.Brass,
                    Colors.Brass,
                    barrelAssembly
                )
                stud.Shape = Enum.PartType.Ball
                local studRadius = 0.55 - i * 0.05
                stud.CFrame = CFrame.new(
                    POSITION + Vector3.new(
                        math.cos(angle) * studRadius,
                        1 + math.sin(angle) * studRadius,
                        -i * 1.8
                    )
                )
            end
        end
        
        -- Muzzle decoration
        local muzzle = createCylinder(
            "Muzzle",
            0.4,
            0.3,
            Materials.Brass,
            Colors.Brass,
            barrelAssembly
        )
        muzzle.CFrame = CFrame.new(POSITION + Vector3.new(0, 1, -barrelLength)) * 
                       CFrame.Angles(0, math.rad(90), 0)
        
        -- Bore (dark interior)
        local bore = createCylinder(
            "Bore",
            0.25,
            0.5,
            Materials.Metal,
            Colors.Black,
            barrelAssembly
        )
        bore.CFrame = CFrame.new(POSITION + Vector3.new(0, 1, -barrelLength - 0.15)) * 
                     CFrame.Angles(0, math.rad(90), 0)
        
        -- Trunnions (pivot cylinders)
        local leftTrunnion = createCylinder(
            "LeftTrunnion",
            0.15,
            0.5,
            Materials.Iron,
            Colors.Iron,
            barrelAssembly
        )
        leftTrunnion.CFrame = CFrame.new(POSITION + Vector3.new(-0.85, 1, -2))
        
        local rightTrunnion = createCylinder(
            "RightTrunnion",
            0.15,
            0.5,
            Materials.Iron,
            Colors.Iron,
            barrelAssembly
        )
        rightTrunnion.CFrame = CFrame.new(POSITION + Vector3.new(0.85, 1, -2))
        
        -- Touch hole assembly
        local touchHolePlate = createCylinder(
            "TouchHolePlate",
            0.15,
            0.05,
            Materials.Brass,
            Colors.BrassShiny,
            barrelAssembly
        )
        touchHolePlate.CFrame = CFrame.new(POSITION + Vector3.new(0, 1.5, -1)) * 
                               CFrame.Angles(math.rad(90), 0, 0)
        
        local touchHole = createCylinder(
            "TouchHole",
            0.04,
            0.5,
            Materials.Iron,
            Colors.Black,
            barrelAssembly
        )
        touchHole.CFrame = CFrame.new(POSITION + Vector3.new(0, 1.45, -1)) * 
                          CFrame.Angles(0, 0, 0)
    end
    
    -- BUILD CARRIAGE ASSEMBLY
    local function buildCarriage()
        -- Main side beams (cheeks)
        local leftCheek = createPart(
            "LeftCheek",
            Vector3.new(0.8, 0.6, 6),
            Materials.WoodPlanks,
            Colors.Wood,
            carriageAssembly
        )
        leftCheek.CFrame = CFrame.new(POSITION + Vector3.new(-0.7, 0, -2))
        
        local rightCheek = createPart(
            "RightCheek",
            Vector3.new(0.8, 0.6, 6),
            Materials.WoodPlanks,
            Colors.Wood,
            carriageAssembly
        )
        rightCheek.CFrame = CFrame.new(POSITION + Vector3.new(0.7, 0, -2))
        
        -- Trail (rear extensions)
        local leftTrail = createWedge(
            "LeftTrail",
            Vector3.new(0.8, 0.4, 2),
            Materials.Wood,
            Colors.WoodDark,
            carriageAssembly
        )
        leftTrail.CFrame = CFrame.new(POSITION + Vector3.new(-0.7, -0.1, 2)) * 
                          CFrame.Angles(0, math.rad(180), 0)
        
        local rightTrail = createWedge(
            "RightTrail",
            Vector3.new(0.8, 0.4, 2),
            Materials.Wood,
            Colors.WoodDark,
            carriageAssembly
        )
        rightTrail.CFrame = CFrame.new(POSITION + Vector3.new(0.7, -0.1, 2)) * 
                           CFrame.Angles(0, math.rad(180), 0)
        
        -- Cross beams
        for i = 1, 4 do
            local crossBeam = createPart(
                "CrossBeam" .. i,
                Vector3.new(2.2, 0.3, 0.4),
                Materials.Wood,
                Colors.WoodDark,
                carriageAssembly
            )
            crossBeam.CFrame = CFrame.new(POSITION + Vector3.new(0, -0.15, -3 + i * 1.5))
        end
        
        -- Transom (rear cross piece)
        local transom = createPart(
            "Transom",
            Vector3.new(2, 0.8, 0.4),
            Materials.Wood,
            Colors.Wood,
            carriageAssembly
        )
        transom.CFrame = CFrame.new(POSITION + Vector3.new(0, 0.1, 1))
        
        -- Metal brackets and reinforcements
        for side = -1, 1, 2 do
            for i = 1, 3 do
                local bracket = createPart(
                    "Bracket_" .. ((side + 1) / 2) .. "_" .. i,
                    Vector3.new(0.2, 0.8, 0.2),
                    Materials.Iron,
                    Colors.Iron,
                    carriageAssembly
                )
                bracket.CFrame = CFrame.new(POSITION + Vector3.new(side * 0.9, 0.1, -3 + i * 2))
                
                -- Add bolts
                for j = 1, 2 do
                    local bolt = createCylinder(
                        "Bolt_" .. ((side + 1) / 2) .. "_" .. i .. "_" .. j,
                        0.025,
                        0.3,
                        Materials.Iron,
                        Colors.IronDark,
                        carriageAssembly
                    )
                    bolt.CFrame = CFrame.new(
                        POSITION + Vector3.new(side * 0.9, -0.1 + j * 0.3, -3 + i * 2)
                    )
                end
            end
        end
        
        -- Trunnion supports
        local leftSupport = createPart(
            "LeftTrunnionSupport",
            Vector3.new(0.3, 1.2, 0.3),
            Materials.Iron,
            Colors.Iron,
            carriageAssembly
        )
        leftSupport.CFrame = CFrame.new(POSITION + Vector3.new(-0.7, 0.6, -2))
        
        local rightSupport = createPart(
            "RightTrunnionSupport",
            Vector3.new(0.3, 1.2, 0.3),
            Materials.Iron,
            Colors.Iron,
            carriageAssembly
        )
        rightSupport.CFrame = CFrame.new(POSITION + Vector3.new(0.7, 0.6, -2))
        
        -- Elevation mechanism
        local elevationScrew = createCylinder(
            "ElevationScrew",
            0.05,
            2,
            Materials.Brass,
            Colors.Brass,
            carriageAssembly
        )
        elevationScrew.CFrame = CFrame.new(POSITION + Vector3.new(0, -0.5, -1)) * 
                               CFrame.Angles(0, 0, 0)
        
        -- Elevation wheel
        local elevWheel = createCylinder(
            "ElevationWheel",
            0.3,
            0.1,
            Materials.Brass,
            Colors.BrassShiny,
            carriageAssembly
        )
        elevWheel.CFrame = CFrame.new(POSITION + Vector3.new(0, -1.5, -1))
        
        -- Wheel spokes
        for i = 1, 4 do
            local spoke = createPart(
                "ElevWheelSpoke" .. i,
                Vector3.new(0.6, 0.05, 0.05),
                Materials.Brass,
                Colors.Brass,
                carriageAssembly
            )
            spoke.CFrame = CFrame.new(POSITION + Vector3.new(0, -1.5, -1)) * 
                          CFrame.Angles(0, 0, math.rad(i * 90))
        end
    end
    
    -- BUILD WHEELS
    local function buildWheel(name, position)
        local wheel = Instance.new("Model")
        wheel.Name = name
        wheel.Parent = wheelAssembly
        
        -- Wheel rim (iron tire)
        local rim = createCylinder(
            name .. "_Rim",
            1.5,
            0.15,
            Materials.Iron,
            Colors.IronDark,
            wheel
        )
        rim.CFrame = CFrame.new(position)
        
        -- Inner rim
        local innerRim = createCylinder(
            name .. "_InnerRim",
            1.35,
            0.14,
            Materials.Iron,
            Colors.Iron,
            wheel
        )
        innerRim.CFrame = CFrame.new(position)
        
        -- Hub
        local hub = createCylinder(
            name .. "_Hub",
            0.3,
            0.6,
            Materials.Iron,
            Colors.Iron,
            wheel
        )
        hub.CFrame = CFrame.new(position)
        
        -- Hub bands
        for i = -1, 1, 2 do
            local hubBand = createCylinder(
                name .. "_HubBand" .. ((i + 1) / 2),
                0.325,
                0.05,
                Materials.Brass,
                Colors.BrassShiny,
                wheel
            )
            hubBand.CFrame = CFrame.new(position + Vector3.new(i * 0.25, 0, 0))
        end
        
        -- Spokes
        for i = 1, 6 do
            local angle = (i - 1) * math.pi / 3
            local spoke = createPart(
                name .. "_Spoke" .. i,
                Vector3.new(0.25, 2.4, 0.15),
                Materials.WoodPlanks,
                Colors.Wood,
                wheel
            )
            spoke.CFrame = CFrame.new(position) * 
                          CFrame.Angles(0, 0, angle)
        end
        
        -- Felloes (rim segments)
        for i = 1, 6 do
            local angle = (i - 1) * math.pi / 3
            local felloe = createPart(
                name .. "_Felloe" .. i,
                Vector3.new(0.3, 0.3, 1.4),
                Materials.Wood,
                Colors.WoodDark,
                wheel
            )
            local radius = 1.2
            felloe.CFrame = CFrame.new(
                position + Vector3.new(0, math.sin(angle + math.pi/6) * radius, math.cos(angle + math.pi/6) * radius)
            ) * CFrame.Angles(0, 0, angle + math.pi/6)
        end
        
        -- Metal studs
        for i = 1, 16 do
            local angle = (i - 1) * math.pi * 2 / 16
            local stud = createPart(
                name .. "_Stud" .. i,
                Vector3.new(0.1, 0.1, 0.1),
                Materials.Iron,
                Colors.Iron,
                wheel
            )
            stud.Shape = Enum.PartType.Ball
            local studRadius = 1.45
            stud.CFrame = CFrame.new(
                position + Vector3.new(0, math.sin(angle) * studRadius, math.cos(angle) * studRadius)
            )
        end
        
        -- Linchpin
        local linchpin = createCylinder(
            name .. "_Linchpin",
            0.04,
            0.8,
            Materials.Iron,
            Colors.Iron,
            wheel
        )
        linchpin.CFrame = CFrame.new(position + Vector3.new(0, 0.3, 0)) * 
                         CFrame.Angles(math.rad(90), 0, 0)
    end
    
    -- Build left and right wheels
    buildWheel("LeftWheel", POSITION + Vector3.new(-1.5, 0, 1))
    buildWheel("RightWheel", POSITION + Vector3.new(1.5, 0, 1))
    
    -- Axle
    local axle = createCylinder(
        "Axle",
        0.1,
        3.2,
        Materials.Iron,
        Colors.IronDark,
        wheelAssembly
    )
    axle.CFrame = CFrame.new(POSITION + Vector3.new(0, 0, 1))
    
    -- Axle brackets
    for side = -1, 1, 2 do
        local axleBracket = createPart(
            "AxleBracket" .. ((side + 1) / 2),
            Vector3.new(0.3, 0.3, 0.3),
            Materials.Iron,
            Colors.Iron,
            carriageAssembly
        )
        axleBracket.CFrame = CFrame.new(POSITION + Vector3.new(side * 0.7, -0.15, 1))
    end
    
    -- Build all components
    buildBarrel()
    buildCarriage()
    
    -- Add final details
    
    -- Rammer and sponge holder
    local toolHolder = createPart(
        "ToolHolder",
        Vector3.new(0.1, 0.1, 3),
        Materials.Iron,
        Colors.Iron,
        carriageAssembly
    )
    toolHolder.CFrame = CFrame.new(POSITION + Vector3.new(-1.2, 0.3, -0.5))
    
    -- Powder bucket hook
    local bucketHook = createPart(
        "BucketHook",
        Vector3.new(0.1, 0.3, 0.1),
        Materials.Iron,
        Colors.Iron,
        carriageAssembly
    )
    bucketHook.CFrame = CFrame.new(POSITION + Vector3.new(1.2, 0.2, 0))
    
    -- Set primary part for the model
    cannonModel.PrimaryPart = breech
    
    -- Position the entire cannon
    cannonModel:SetPrimaryPartCFrame(CFrame.new(POSITION))
    
    return cannonModel
end

-- Build the cannon when the script runs
local cannonModel = cannon.build()

-- Optional: Add a simple fire effect function
local function createFireEffect()
    local smoke = Instance.new("Smoke")
    smoke.Color = Color3.fromRGB(50, 50, 50)
    smoke.Opacity = 0.5
    smoke.Size = 2
    smoke.RiseVelocity = 5
    smoke.Parent = cannonModel.BarrelAssembly.Bore
    
    local fire = Instance.new("Fire")
    fire.Size = 5
    fire.Heat = 10
    fire.Color = Color3.fromRGB(255, 170, 0)
    fire.SecondaryColor = Color3.fromRGB(255, 255, 0)
    fire.Parent = cannonModel.BarrelAssembly.Bore
    
    wait(0.2)
    fire.Enabled = false
    
    wait(1)
    smoke.Enabled = false
    
    wait(3)
    smoke:Destroy()
    fire:Destroy()
end

-- Optional: Add interaction
local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 20
clickDetector.Parent = cannonModel.BarrelAssembly.Breech

clickDetector.MouseClick:Connect(function(player)
    createFireEffect()
    
    -- Recoil animation
    local originalCFrame = cannonModel.BarrelAssembly.Breech.CFrame
    for i = 1, 10 do
        cannonModel.BarrelAssembly:SetPrimaryPartCFrame(
            originalCFrame * CFrame.new(0, 0, math.sin(i * 0.3) * 0.3 * (1 - i/10))
        )
        wait(0.05)
    end
    cannonModel.BarrelAssembly:SetPrimaryPartCFrame(originalCFrame)
end)

print("Historical Cannon successfully built!")
print("Click the breech to fire the cannon!")

return cannon