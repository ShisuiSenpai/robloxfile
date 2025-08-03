-- Comprehensive VFX Testing Script
-- Run this in Studio's command bar to test your VFX

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

-- Get the VFX
local abilityVFX = ReplicatedStorage:WaitForChild("AbilityVFX")
local jumpWindVFX = abilityVFX:WaitForChild("jumpwind")

-- Create Fx folder if needed
local fxFolder = workspace:FindFirstChild("Fx") or Instance.new("Folder")
fxFolder.Name = "Fx"
fxFolder.Parent = workspace

print("\n========== VFX COMPREHENSIVE TEST ==========")

-- Test 1: Check Original VFX Properties
print("\n[TEST 1] Checking original VFX structure...")
print("VFX Type:", jumpWindVFX.ClassName)
if jumpWindVFX:IsA("BasePart") then
    print("Part Properties:")
    print("  - Transparency:", jumpWindVFX.Transparency)
    print("  - Size:", tostring(jumpWindVFX.Size))
    print("  - CanCollide:", jumpWindVFX.CanCollide)
end

-- Count components
local originalEmitters = {}
for _, desc in pairs(jumpWindVFX:GetDescendants()) do
    if desc:IsA("ParticleEmitter") then
        table.insert(originalEmitters, desc)
    end
end
print("Total ParticleEmitters found:", #originalEmitters)

-- Test 2: Clone and Position
print("\n[TEST 2] Cloning and positioning VFX...")
local testVFX = jumpWindVFX:Clone()
testVFX.Name = "TestVFX"
testVFX.CFrame = CFrame.new(0, 5, 0)
testVFX.Parent = fxFolder

-- Make visible for testing
if testVFX:IsA("BasePart") then
    -- Add a selection box to see where it is
    local selBox = Instance.new("SelectionBox")
    selBox.Adornee = testVFX
    selBox.Color3 = Color3.new(0, 1, 0)
    selBox.LineThickness = 0.05
    selBox.Parent = testVFX
end

-- Test 3: Check Each ParticleEmitter
print("\n[TEST 3] Testing each ParticleEmitter individually...")
local workingEmitters = 0
local brokenEmitters = 0

for i, emitter in pairs(testVFX:GetDescendants()) do
    if emitter:IsA("ParticleEmitter") then
        print(string.format("\nEmitter #%d: %s (in %s)", i, emitter.Name, emitter.Parent.Name))
        
        -- Check basic properties
        local issues = {}
        
        -- Check if enabled
        if not emitter.Enabled then
            table.insert(issues, "Disabled by default")
        end
        
        -- Check texture
        if not emitter.Texture or emitter.Texture == "" then
            table.insert(issues, "No texture")
        else
            print("  ✓ Texture:", emitter.Texture)
        end
        
        -- Check rate
        if emitter.Rate == 0 then
            table.insert(issues, "Zero emission rate")
        else
            print("  ✓ Rate:", emitter.Rate)
        end
        
        -- Check transparency
        if emitter.Transparency and emitter.Transparency.Keypoints then
            local firstKey = emitter.Transparency.Keypoints[1]
            if firstKey and firstKey.Value >= 0.99 then
                table.insert(issues, "Starts nearly/fully transparent")
            else
                print("  ✓ Start transparency:", firstKey and firstKey.Value or "unknown")
            end
        end
        
        -- Check size
        if emitter.Size and emitter.Size.Keypoints then
            local firstSize = emitter.Size.Keypoints[1]
            if firstSize and firstSize.Value <= 0.01 then
                table.insert(issues, "Very small size")
            else
                print("  ✓ Start size:", firstSize and firstSize.Value or "unknown")
            end
        end
        
        -- Check lifetime
        if emitter.Lifetime.Min <= 0 then
            table.insert(issues, "Zero or negative lifetime")
        else
            print("  ✓ Lifetime:", emitter.Lifetime.Min, "-", emitter.Lifetime.Max)
        end
        
        -- Check EmitCount attribute
        local emitCount = emitter:GetAttribute("EmitCount")
        if not emitCount then
            table.insert(issues, "No EmitCount attribute")
        elseif emitCount == 0 then
            table.insert(issues, "EmitCount is 0")
        else
            print("  ✓ EmitCount:", emitCount)
        end
        
        -- Report issues
        if #issues > 0 then
            print("  ⚠ ISSUES:")
            for _, issue in ipairs(issues) do
                print("    -", issue)
            end
            brokenEmitters = brokenEmitters + 1
        else
            print("  ✅ No issues detected")
            workingEmitters = workingEmitters + 1
        end
        
        -- Force test emission
        print("  🔧 Force testing emission...")
        emitter.Enabled = true
        local testEmitCount = emitCount or 50
        emitter:Emit(testEmitCount)
        print("    Emitted", testEmitCount, "particles")
    end
end

print(string.format("\n[SUMMARY] Working: %d, Potentially Broken: %d", workingEmitters, brokenEmitters))

-- Test 4: Create reference particle emitter for comparison
print("\n[TEST 4] Creating reference particle emitter...")
local refPart = Instance.new("Part")
refPart.Name = "ReferenceVFX"
refPart.Size = Vector3.new(1, 1, 1)
refPart.Transparency = 1
refPart.Anchored = true
refPart.CanCollide = false
refPart.Position = Vector3.new(10, 5, 0)
refPart.Parent = fxFolder

local refEmitter = Instance.new("ParticleEmitter")
refEmitter.Name = "ReferenceEmitter"
refEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
refEmitter.Rate = 50
refEmitter.Lifetime = NumberRange.new(1, 2)
refEmitter.Speed = NumberRange.new(5)
refEmitter.SpreadAngle = Vector2.new(360, 360)
refEmitter.Enabled = true
refEmitter.Parent = refPart

print("✅ Reference emitter created at (10, 5, 0) - you should see sparkles")

-- Test 5: Check if particles are rendering
print("\n[TEST 5] Waiting 3 seconds to observe particles...")
print("Look for:")
print("  - Green selection box at (0, 5, 0) - your VFX")
print("  - Sparkles at (10, 5, 0) - reference VFX")
print("  - Any particles from your VFX emitters")

task.wait(3)

-- Cleanup
print("\n[CLEANUP] Removing test objects in 5 seconds...")
task.wait(5)
testVFX:Destroy()
refPart:Destroy()

print("\n========== TEST COMPLETE ==========")
print("\nIf you saw the reference sparkles but not your VFX particles, the issue is likely:")
print("  1. Missing or invalid texture on ParticleEmitters")
print("  2. Particles are fully transparent")
print("  3. Particles are too small or have zero lifetime")
print("  4. EmitCount attributes are 0 or missing")
print("\nCheck the emitter issues reported above for specific problems.")