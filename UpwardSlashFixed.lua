-- Fixed PlayVFX function for UpwardSlash
-- Replace the PlayVFX function in your UpwardSlash module with this version

function UpwardSlash.PlayVFX(rootPart)
    -- Clone VFX
    local windEffect = jumpWindVFX:Clone()
    
    -- Debug: Check what we cloned
    print("[VFX] Cloned:", windEffect.Name, windEffect.ClassName)
    
    -- Handle different VFX structures
    local vfxRoot = windEffect
    
    -- If the VFX is a model, we need to handle it differently
    if windEffect:IsA("Model") then
        -- Position the model
        windEffect:SetPrimaryPartCFrame(rootPart.CFrame * CFrame.new(0, -3, 0))
        
        -- Make all parts non-collidable
        for _, part in pairs(windEffect:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
                part.Anchored = true
            end
        end
    elseif windEffect:IsA("BasePart") then
        -- Handle single part VFX
        windEffect.CanCollide = false
        windEffect.CanTouch = false
        windEffect.CanQuery = false
        windEffect.Anchored = true
        windEffect.CFrame = rootPart.CFrame * CFrame.new(0, -3, 0)
    end
    
    -- Parent to workspace
    windEffect.Parent = fxFolder
    
    -- Count emitters for debugging
    local emitterCount = 0
    local totalEmitted = 0
    
    -- Emit particles with multiple fallback methods
    for _, descendant in pairs(windEffect:GetDescendants()) do
        if descendant:IsA("ParticleEmitter") then
            emitterCount = emitterCount + 1
            
            -- Debug info
            print(string.format("[VFX] Found emitter: %s (Enabled: %s, Rate: %.2f)", 
                descendant.Name, 
                tostring(descendant.Enabled), 
                descendant.Rate))
            
            -- Method 1: Check for EmitCount attribute
            local emitCount = descendant:GetAttribute("EmitCount")
            
            -- Method 2: If no attribute, calculate based on Rate
            if not emitCount then
                -- Estimate particles based on a typical burst duration
                emitCount = math.max(10, descendant.Rate * 0.5)
                print("[VFX] No EmitCount attribute, using Rate-based calculation:", emitCount)
            end
            
            -- Method 3: Ensure we have a reasonable minimum
            emitCount = math.max(emitCount or 10, 10)
            
            -- Store original state
            local wasEnabled = descendant.Enabled
            local originalRate = descendant.Rate
            
            -- Force enable the emitter temporarily
            descendant.Enabled = true
            
            -- Emit particles
            if emitCount > 0 then
                descendant:Emit(emitCount)
                totalEmitted = totalEmitted + emitCount
                print(string.format("[VFX] Emitted %d particles from %s", emitCount, descendant.Name))
            end
            
            -- If the emitter was originally disabled, disable it again after emission
            if not wasEnabled then
                -- Wait a frame to ensure emission happens
                task.defer(function()
                    if descendant and descendant.Parent then
                        descendant.Enabled = false
                    end
                end)
            end
            
            -- Additional burst emission for emitters that should stay enabled
            if wasEnabled and originalRate > 0 then
                -- Keep it enabled for continuous emission
                descendant.Rate = originalRate
            end
        end
    end
    
    print(string.format("[VFX] Total: %d emitters, %d particles emitted", emitterCount, totalEmitted))
    
    -- Cleanup after longer duration to ensure all particles finish
    Debris:AddItem(windEffect, 5)
end

-- Alternative comprehensive fix that handles more edge cases
function UpwardSlash.PlayVFXComprehensive(rootPart)
    -- Clone VFX
    local windEffect = jumpWindVFX:Clone()
    
    -- Create attachment if VFX needs one
    local attachment
    if windEffect:IsA("Attachment") then
        -- VFX is an attachment, needs a parent part
        local vfxPart = Instance.new("Part")
        vfxPart.Name = "VFXHolder"
        vfxPart.Size = Vector3.new(1, 1, 1)
        vfxPart.Transparency = 1
        vfxPart.CanCollide = false
        vfxPart.CanTouch = false
        vfxPart.CanQuery = false
        vfxPart.Anchored = true
        vfxPart.CFrame = rootPart.CFrame * CFrame.new(0, -3, 0)
        vfxPart.Parent = fxFolder
        
        windEffect.Parent = vfxPart
        attachment = windEffect
    else
        -- Standard handling
        if windEffect:IsA("Model") then
            windEffect:SetPrimaryPartCFrame(rootPart.CFrame * CFrame.new(0, -3, 0))
        elseif windEffect:IsA("BasePart") then
            windEffect.CFrame = rootPart.CFrame * CFrame.new(0, -3, 0)
            windEffect.CanCollide = false
            windEffect.CanTouch = false
            windEffect.CanQuery = false
            windEffect.Anchored = true
        end
        windEffect.Parent = fxFolder
    end
    
    -- Force emit all particles
    local function emitFromAllEmitters(parent)
        for _, obj in pairs(parent:GetDescendants()) do
            if obj:IsA("ParticleEmitter") then
                -- Check texture
                if not obj.Texture or obj.Texture == "" then
                    warn("[VFX] ParticleEmitter has no texture:", obj.Name)
                end
                
                -- Get emit count
                local emitCount = obj:GetAttribute("EmitCount") or 
                                obj:GetAttribute("BurstCount") or 
                                obj:GetAttribute("EmitAmount") or 
                                20
                
                -- Ensure visibility
                if obj.Transparency.Keypoints[1].Value >= 1 then
                    warn("[VFX] ParticleEmitter is fully transparent:", obj.Name)
                end
                
                -- Force emit
                local wasEnabled = obj.Enabled
                obj.Enabled = true
                obj:Emit(emitCount)
                
                -- Handle burst emitters
                if not wasEnabled then
                    task.wait()
                    obj.Enabled = false
                end
            end
        end
    end
    
    emitFromAllEmitters(windEffect)
    
    -- Cleanup
    Debris:AddItem(windEffect.Parent or windEffect, 5)
end