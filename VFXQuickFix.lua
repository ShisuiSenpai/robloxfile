-- Quick VFX Fix Script
-- Run this in Studio command bar to diagnose and fix common VFX issues

local function quickFixVFX()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local abilityVFX = ReplicatedStorage:WaitForChild("AbilityVFX")
    local jumpWindVFX = abilityVFX:WaitForChild("jumpwind")
    
    print("\n=== VFX Quick Diagnosis ===")
    
    -- Common Issue #1: ParticleEmitters are disabled
    local disabledEmitters = 0
    local noTextureEmitters = 0
    local transparentEmitters = 0
    local zeroRateEmitters = 0
    local totalEmitters = 0
    
    for _, desc in pairs(jumpWindVFX:GetDescendants()) do
        if desc:IsA("ParticleEmitter") then
            totalEmitters = totalEmitters + 1
            
            -- Check if disabled
            if not desc.Enabled then
                disabledEmitters = disabledEmitters + 1
                print("❌ Disabled emitter:", desc.Name)
            end
            
            -- Check for missing texture
            if not desc.Texture or desc.Texture == "" then
                noTextureEmitters = noTextureEmitters + 1
                print("❌ No texture:", desc.Name)
            end
            
            -- Check if fully transparent
            local firstKeypoint = desc.Transparency.Keypoints[1]
            if firstKeypoint and firstKeypoint.Value >= 1 then
                transparentEmitters = transparentEmitters + 1
                print("❌ Fully transparent:", desc.Name)
            end
            
            -- Check if Rate is 0
            if desc.Rate == 0 and desc.Enabled then
                zeroRateEmitters = zeroRateEmitters + 1
                print("❌ Zero emission rate:", desc.Name)
            end
            
            -- Check EmitCount attribute
            local emitCount = desc:GetAttribute("EmitCount")
            if not emitCount then
                print("⚠️ No EmitCount attribute:", desc.Name)
            elseif emitCount == 0 then
                print("❌ EmitCount is 0:", desc.Name)
            end
        end
    end
    
    print("\n=== Summary ===")
    print("Total ParticleEmitters:", totalEmitters)
    print("Disabled:", disabledEmitters)
    print("No Texture:", noTextureEmitters)
    print("Fully Transparent:", transparentEmitters)
    print("Zero Rate:", zeroRateEmitters)
    
    -- Common Issue #2: VFX structure problems
    print("\n=== VFX Structure ===")
    print("VFX Type:", jumpWindVFX.ClassName)
    
    if jumpWindVFX:IsA("Model") then
        print("Primary Part:", jumpWindVFX.PrimaryPart and jumpWindVFX.PrimaryPart.Name or "None")
        local partCount = 0
        for _, child in pairs(jumpWindVFX:GetDescendants()) do
            if child:IsA("BasePart") then
                partCount = partCount + 1
            end
        end
        print("Parts in model:", partCount)
    end
    
    -- Test emission
    print("\n=== Testing Emission ===")
    local testClone = jumpWindVFX:Clone()
    testClone.Parent = workspace
    
    if testClone:IsA("Model") and testClone.PrimaryPart then
        testClone:SetPrimaryPartCFrame(CFrame.new(0, 10, 0))
    elseif testClone:IsA("BasePart") then
        testClone.Position = Vector3.new(0, 10, 0)
        testClone.Anchored = true
    end
    
    local emittedSomething = false
    for _, emitter in pairs(testClone:GetDescendants()) do
        if emitter:IsA("ParticleEmitter") then
            -- Force emission
            emitter.Enabled = true
            emitter:Emit(50)
            emittedSomething = true
            print("✅ Force emitted from:", emitter.Name)
        end
    end
    
    if not emittedSomething then
        print("❌ No ParticleEmitters found to emit from!")
    end
    
    -- Keep test visible for 5 seconds
    task.wait(5)
    testClone:Destroy()
    
    print("\n=== Diagnosis Complete ===")
end

-- Run the diagnosis
quickFixVFX()