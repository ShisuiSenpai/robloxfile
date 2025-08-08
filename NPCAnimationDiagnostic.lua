-- NPCAnimationDiagnostic Script
-- This script helps diagnose why NPC animations might not be working
-- Place in ServerScriptService

local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage:WaitForChild("NPCFollowModules"):WaitForChild("NPCFollowConfig"))

print("[AnimationDiagnostic] Starting NPC Animation Diagnostic...")

-- Diagnostic script to debug NPC animation issues
local function setupDiagnostics()
    local npcsFolder = workspace:WaitForChild("NPCS", 5)
    if not npcsFolder then
        warn("[NPCAnimationDiagnostic] NPCS folder not found")
        return
    end
    
    local diagnosticData = {}
    
    local function monitorNPC(npc)
        if diagnosticData[npc] then return end
        
        local humanoid = npc:FindFirstChildOfClass("Humanoid")
        local rootPart = npc:FindFirstChild("HumanoidRootPart")
        local animateScript = npc:FindFirstChild("Animate")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        
        if not humanoid or not rootPart then
            warn("[NPCAnimationDiagnostic] " .. npc.Name .. " missing Humanoid or HumanoidRootPart")
            return
        end
        
        diagnosticData[npc] = {
            lastPosition = rootPart.Position,
            lastVelocity = Vector3.new(0, 0, 0),
            lastMoveDirection = Vector3.new(0, 0, 0),
            lastSpeed = 0,
            animateScriptExists = animateScript ~= nil,
            animatorExists = animator ~= nil,
            lastDebugTime = 0
        }
        
        -- Monitor animation tracks
        if animator then
            animator.AnimationPlayed:Connect(function(animTrack)
                print("[NPCAnimationDiagnostic] " .. npc.Name .. " playing animation: " .. tostring(animTrack.Animation.AnimationId))
            end)
        end
        
        -- Monitor humanoid events
        humanoid.Running:Connect(function(speed)
            diagnosticData[npc].lastSpeed = speed
            if speed > 0.1 then
                print("[NPCAnimationDiagnostic] " .. npc.Name .. " Running event fired with speed: " .. speed)
            end
        end)
        
        humanoid.StateChanged:Connect(function(old, new)
            print("[NPCAnimationDiagnostic] " .. npc.Name .. " state changed from " .. tostring(old) .. " to " .. tostring(new))
        end)
    end
    
    -- Monitor existing NPCs
    for _, npc in pairs(npcsFolder:GetChildren()) do
        if npc:IsA("Model") then
            monitorNPC(npc)
        end
    end
    
    -- Monitor new NPCs
    npcsFolder.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            task.wait(0.1) -- Wait for NPC to be fully set up
            monitorNPC(child)
        end
    end)
    
    -- Diagnostic heartbeat
    local lastDiagnosticPrint = 0
    RunService.Heartbeat:Connect(function()
        local now = tick()
        
        for npc, data in pairs(diagnosticData) do
            if npc.Parent and npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChildOfClass("Humanoid") then
                local humanoid = npc:FindFirstChildOfClass("Humanoid")
                local rootPart = npc.HumanoidRootPart
                local animateScript = npc:FindFirstChild("Animate")
                
                -- Calculate actual velocity
                local currentPosition = rootPart.Position
                local velocity = (currentPosition - data.lastPosition) / RunService.Heartbeat:Wait()
                local speed = velocity.Magnitude
                
                -- Calculate movement direction
                local moveDirection = humanoid.MoveDirection
                local lookDirection = rootPart.CFrame.LookVector
                
                -- Update data
                data.lastPosition = currentPosition
                data.lastVelocity = velocity
                data.lastMoveDirection = moveDirection
                
                -- Check if Animate script exists and has proper values
                if animateScript then
                    local walkAnim = animateScript:FindFirstChild("walk")
                    local runAnim = animateScript:FindFirstChild("run")
                    local idleAnim = animateScript:FindFirstChild("idle")
                    
                    -- Print detailed diagnostic every 2 seconds if moving
                    if now - data.lastDebugTime > 2 and speed > 0.1 then
                        data.lastDebugTime = now
                        print(string.format(
                            "[NPCAnimationDiagnostic] %s - Speed: %.2f, MoveDirection: %s, WalkSpeed: %.1f, Animator: %s, AnimateScript: %s",
                            npc.Name,
                            speed,
                            tostring(moveDirection),
                            humanoid.WalkSpeed,
                            tostring(data.animatorExists),
                            tostring(data.animateScriptExists)
                        ))
                        
                        -- Check animation values
                        if walkAnim then
                            print("  - Walk animation found: " .. tostring(walkAnim:FindFirstChild("WalkAnim")))
                        end
                        if runAnim then
                            print("  - Run animation found: " .. tostring(runAnim:FindFirstChild("RunAnim")))
                        end
                        if idleAnim then
                            print("  - Idle animation found: " .. tostring(idleAnim:FindFirstChild("Animation1")))
                        end
                        
                        -- Check if movement state is correct
                        print("  - Humanoid State: " .. tostring(humanoid:GetState()))
                        print("  - RootPart Velocity: " .. tostring(rootPart.AssemblyLinearVelocity))
                    end
                end
                
                -- Manually update MoveDirection based on velocity if it's not being set
                if speed > 0.1 and moveDirection.Magnitude < 0.1 then
                    -- Calculate move direction from velocity
                    local flatVelocity = Vector3.new(velocity.X, 0, velocity.Z)
                    if flatVelocity.Magnitude > 0.1 then
                        local normalizedVelocity = flatVelocity.Unit
                        -- This is diagnostic only - we'll fix this in the fixer script
                        print(string.format(
                            "[NPCAnimationDiagnostic] %s - MoveDirection is zero but velocity is %.2f. Calculated direction: %s",
                            npc.Name,
                            speed,
                            tostring(normalizedVelocity)
                        ))
                    end
                end
            else
                -- NPC was removed
                diagnosticData[npc] = nil
            end
        end
    end)
end

setupDiagnostics()

print("[NPCAnimationDiagnostic] Diagnostic system initialized - monitoring NPC animations")