-- VFX Debugger Script
-- Place this in ServerScriptService or run in Studio command bar to debug VFX issues

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Configuration
local DEBUG_CONFIG = {
    verboseLogging = true,
    highlightVFX = true,
    testEmission = true,
    checkProperties = true
}

local function log(message, ...)
    if DEBUG_CONFIG.verboseLogging then
        print("[VFX Debug]", string.format(message, ...))
    end
end

local function debugVFX()
    log("Starting VFX Debug...")
    
    -- Check if VFX exists
    local abilityVFX = ReplicatedStorage:FindFirstChild("AbilityVFX")
    if not abilityVFX then
        warn("[VFX Debug] AbilityVFX folder not found in ReplicatedStorage!")
        return
    end
    
    local jumpWindVFX = abilityVFX:FindFirstChild("jumpwind")
    if not jumpWindVFX then
        warn("[VFX Debug] jumpwind VFX not found in AbilityVFX folder!")
        return
    end
    
    log("Found jumpwind VFX: %s", jumpWindVFX:GetFullName())
    
    -- Analyze VFX structure
    log("\n=== VFX Structure Analysis ===")
    local particleEmitters = {}
    local attachments = {}
    local parts = {}
    
    for _, descendant in pairs(jumpWindVFX:GetDescendants()) do
        if descendant:IsA("ParticleEmitter") then
            table.insert(particleEmitters, descendant)
            log("Found ParticleEmitter: %s", descendant.Name)
            
            -- Check if enabled
            if not descendant.Enabled then
                warn("  - ParticleEmitter '%s' is DISABLED!", descendant.Name)
            end
            
            -- Check emission properties
            log("  - Rate: %.2f", descendant.Rate)
            log("  - Lifetime: %.2f - %.2f", descendant.Lifetime.Min, descendant.Lifetime.Max)
            log("  - EmissionDirection: %s", tostring(descendant.EmissionDirection))
            log("  - Speed: %.2f - %.2f", descendant.Speed.Min, descendant.Speed.Max)
            log("  - Transparency: %s", tostring(descendant.Transparency))
            log("  - Size: %s", tostring(descendant.Size))
            log("  - Texture: %s", descendant.Texture or "None")
            
            -- Check for EmitCount attribute
            local emitCount = descendant:GetAttribute("EmitCount")
            if emitCount then
                log("  - EmitCount attribute: %d", emitCount)
            else
                warn("  - No EmitCount attribute found!")
            end
            
        elseif descendant:IsA("Attachment") then
            table.insert(attachments, descendant)
            log("Found Attachment: %s", descendant.Name)
            
        elseif descendant:IsA("BasePart") then
            table.insert(parts, descendant)
            log("Found Part: %s (Transparency: %.2f)", descendant.Name, descendant.Transparency)
        end
    end
    
    log("\nSummary: %d ParticleEmitters, %d Attachments, %d Parts", 
        #particleEmitters, #attachments, #parts)
    
    -- Test emission in workspace
    if DEBUG_CONFIG.testEmission then
        log("\n=== Testing Emission ===")
        
        local testVFX = jumpWindVFX:Clone()
        local fxFolder = workspace:FindFirstChild("Fx") or Instance.new("Folder")
        fxFolder.Name = "Fx"
        fxFolder.Parent = workspace
        
        -- Make it visible and position it
        testVFX.Parent = fxFolder
        if testVFX:IsA("BasePart") then
            testVFX.CanCollide = false
            testVFX.Anchored = true
            testVFX.Position = Vector3.new(0, 10, 0)
            
            if DEBUG_CONFIG.highlightVFX then
                -- Add a highlight box for debugging
                local selectionBox = Instance.new("SelectionBox")
                selectionBox.Adornee = testVFX
                selectionBox.Color3 = Color3.new(0, 1, 0)
                selectionBox.LineThickness = 0.1
                selectionBox.Parent = testVFX
            end
        end
        
        -- Force enable all particle emitters and emit
        local emittedCount = 0
        for _, emitter in pairs(testVFX:GetDescendants()) do
            if emitter:IsA("ParticleEmitter") then
                log("Testing emitter: %s", emitter.Name)
                
                -- Store original state
                local originalEnabled = emitter.Enabled
                local originalRate = emitter.Rate
                
                -- Force enable and set high emission rate for testing
                emitter.Enabled = true
                emitter.Rate = 100
                
                -- Try different emission methods
                local emitCount = emitter:GetAttribute("EmitCount") or 50
                
                -- Method 1: Direct Emit
                emitter:Emit(emitCount)
                emittedCount = emittedCount + emitCount
                log("  - Emitted %d particles using Emit()", emitCount)
                
                -- Method 2: Enable for a short duration
                task.wait(0.1)
                
                -- Restore original state after brief test
                emitter.Enabled = originalEnabled
                emitter.Rate = originalRate
            end
        end
        
        log("Total particles emitted: %d", emittedCount)
        
        -- Keep VFX visible for inspection
        task.wait(5)
        testVFX:Destroy()
    end
    
    log("\n=== Debug Complete ===")
end

-- Run the debugger
debugVFX()

-- Additional helper function to monitor active VFX
local function monitorActiveVFX()
    log("\n=== Monitoring Active VFX ===")
    
    local fxFolder = workspace:FindFirstChild("Fx")
    if not fxFolder then
        warn("Fx folder not found in workspace!")
        return
    end
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        local vfxCount = 0
        local activeEmitters = 0
        
        for _, child in pairs(fxFolder:GetChildren()) do
            vfxCount = vfxCount + 1
            
            for _, emitter in pairs(child:GetDescendants()) do
                if emitter:IsA("ParticleEmitter") and emitter.Enabled then
                    activeEmitters = activeEmitters + 1
                end
            end
        end
        
        if vfxCount > 0 then
            log("Active VFX: %d, Active Emitters: %d", vfxCount, activeEmitters)
        end
    end)
    
    -- Stop monitoring after 10 seconds
    task.wait(10)
    connection:Disconnect()
    log("Monitoring stopped")
end

-- Uncomment to start monitoring
-- monitorActiveVFX()