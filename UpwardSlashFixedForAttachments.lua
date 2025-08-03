-- Fixed PlayVFX function for Part > Attachment > ParticleEmitter structure
-- Replace the PlayVFX function in your UpwardSlash module with this version

function UpwardSlash.PlayVFX(rootPart)
    -- Clone VFX
    local windEffect = jumpWindVFX:Clone()
    
    -- Ensure it's a Part with proper properties
    if windEffect:IsA("BasePart") then
        windEffect.CanCollide = false
        windEffect.CanTouch = false
        windEffect.CanQuery = false
        windEffect.Anchored = true
        windEffect.Transparency = 1 -- Make the part invisible since it's just a holder
    end
    
    -- Position at feet
    windEffect.CFrame = rootPart.CFrame * CFrame.new(0, -3, 0)
    windEffect.Parent = fxFolder
    
    -- Debug: Count what we have
    local attachmentCount = 0
    local emitterCount = 0
    local totalEmitted = 0
    
    -- Process all attachments and their particle emitters
    for _, child in pairs(windEffect:GetDescendants()) do
        if child:IsA("Attachment") then
            attachmentCount = attachmentCount + 1
            -- Attachments inherit the part's CFrame, but may have their own position offset
            -- No need to reposition them unless they have specific offsets you want to change
        elseif child:IsA("ParticleEmitter") then
            emitterCount = emitterCount + 1
            
            -- Get emit count from attribute
            local emitCount = child:GetAttribute("EmitCount")
            
            if emitCount and emitCount > 0 then
                -- Emit the particles
                child:Emit(emitCount)
                totalEmitted = totalEmitted + emitCount
                
                -- Debug output
                if DEBUG_MODE then
                    print(string.format("[VFX] Emitted %d particles from %s (Parent: %s)", 
                        emitCount, child.Name, child.Parent.Name))
                end
            else
                -- Fallback if no EmitCount attribute or it's 0
                local fallbackCount = 20
                child:Emit(fallbackCount)
                totalEmitted = totalEmitted + fallbackCount
                
                if DEBUG_MODE then
                    warn(string.format("[VFX] No EmitCount for %s, using fallback: %d", 
                        child.Name, fallbackCount))
                end
            end
        end
    end
    
    -- Debug summary
    if DEBUG_MODE then
        print(string.format("[VFX] Summary - Attachments: %d, Emitters: %d, Total Particles: %d", 
            attachmentCount, emitterCount, totalEmitted))
    end
    
    -- Cleanup after particles finish
    Debris:AddItem(windEffect, 3)
end

-- Alternative version with more detailed debugging
function UpwardSlash.PlayVFXDebug(rootPart)
    print("\n=== VFX Debug Emission ===")
    
    -- Clone VFX
    local windEffect = jumpWindVFX:Clone()
    print("Cloned:", windEffect.Name, windEffect.ClassName)
    
    -- Setup part properties
    if windEffect:IsA("BasePart") then
        windEffect.CanCollide = false
        windEffect.CanTouch = false
        windEffect.CanQuery = false
        windEffect.Anchored = true
        windEffect.Transparency = 1
        print("Part transparency:", windEffect.Transparency)
    end
    
    -- Position at feet
    windEffect.CFrame = rootPart.CFrame * CFrame.new(0, -3, 0)
    windEffect.Parent = fxFolder
    print("Positioned at:", windEffect.Position)
    
    -- Detailed structure analysis
    print("\n--- VFX Structure ---")
    local function analyzeStructure(obj, indent)
        indent = indent or ""
        print(indent .. obj.Name .. " (" .. obj.ClassName .. ")")
        
        if obj:IsA("Attachment") then
            print(indent .. "  Position:", tostring(obj.Position))
        elseif obj:IsA("ParticleEmitter") then
            local emitCount = obj:GetAttribute("EmitCount")
            print(indent .. "  Enabled:", obj.Enabled)
            print(indent .. "  Rate:", obj.Rate)
            print(indent .. "  EmitCount attr:", emitCount or "nil")
            print(indent .. "  Texture:", obj.Texture or "none")
            
            -- Check if texture exists
            if not obj.Texture or obj.Texture == "" then
                warn(indent .. "  WARNING: No texture!")
            end
            
            -- Check transparency
            local trans = obj.Transparency
            if trans and trans.Keypoints and trans.Keypoints[1] then
                local startTrans = trans.Keypoints[1].Value
                print(indent .. "  Start Transparency:", startTrans)
                if startTrans >= 1 then
                    warn(indent .. "  WARNING: Starts fully transparent!")
                end
            end
            
            -- Emit particles
            local count = emitCount or 30
            obj:Emit(count)
            print(indent .. "  >>> EMITTED", count, "particles")
        end
        
        for _, child in pairs(obj:GetChildren()) do
            analyzeStructure(child, indent .. "  ")
        end
    end
    
    analyzeStructure(windEffect)
    
    -- Keep visible for debugging
    print("\n=== VFX will be cleaned up in 5 seconds ===")
    Debris:AddItem(windEffect, 5)
end

-- Add this constant at the top of your UpwardSlash module
local DEBUG_MODE = true -- Set to false in production