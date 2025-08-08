-- NPCAnimationFixer Script
-- This script ensures NPC animations work by properly managing movement states
-- Place in ServerScriptService

local RunService = game:GetService("RunService")

-- This script ensures NPC animations work properly with the default Animate script
local function setupAnimationFixer()
    local npcsFolder = workspace:WaitForChild("NPCS", 5)
    if not npcsFolder then
        warn("[NPCAnimationFixer] NPCS folder not found")
        return
    end
    
    local npcData = {}
    
    local function fixNPCAnimation(npc)
        if npcData[npc] then return end
        
        local humanoid = npc:FindFirstChildOfClass("Humanoid")
        local rootPart = npc:FindFirstChild("HumanoidRootPart")
        local animateScript = npc:FindFirstChild("Animate")
        
        if not humanoid or not rootPart then
            return
        end
        
        -- Ensure Animator exists
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = humanoid
            print("[NPCAnimationFixer] Added Animator to " .. npc.Name)
        end
        
        npcData[npc] = {
            humanoid = humanoid,
            rootPart = rootPart,
            animator = animator,
            animateScript = animateScript,
            lastPosition = rootPart.Position,
            lastVelocity = Vector3.new(0, 0, 0),
            currentState = "idle",
            stateStartTime = tick()
        }
        
        -- If Animate script exists, ensure it has the msg StringValue
        if animateScript then
            local msgValue = animateScript:FindFirstChild("msg")
            if not msgValue then
                msgValue = Instance.new("StringValue")
                msgValue.Name = "msg"
                msgValue.Parent = animateScript
                print("[NPCAnimationFixer] Added msg StringValue to " .. npc.Name .. "'s Animate script")
            end
        end
    end
    
    -- Setup existing NPCs
    for _, npc in pairs(npcsFolder:GetChildren()) do
        if npc:IsA("Model") then
            fixNPCAnimation(npc)
        end
    end
    
    -- Setup new NPCs
    npcsFolder.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            task.wait(0.1)
            fixNPCAnimation(child)
        end
    end)
    
    -- Main update loop
    RunService.Heartbeat:Connect(function(deltaTime)
        for npc, data in pairs(npcData) do
            if npc.Parent and data.humanoid.Parent and data.rootPart.Parent then
                local currentPosition = data.rootPart.Position
                local velocity = (currentPosition - data.lastPosition) / deltaTime
                local speed = velocity.Magnitude
                
                -- Update stored data
                data.lastPosition = currentPosition
                data.lastVelocity = velocity
                
                -- Determine animation state based on movement
                local newState = "idle"
                if speed > 0.5 then
                    if speed > data.humanoid.WalkSpeed * 1.5 then
                        newState = "run"
                    else
                        newState = "walk"
                    end
                end
                
                -- If state changed and we have an Animate script with msg value
                if newState ~= data.currentState and data.animateScript then
                    local msgValue = data.animateScript:FindFirstChild("msg")
                    if msgValue then
                        -- The Animate script listens to msg.Changed
                        if newState == "walk" or newState == "run" then
                            -- Trigger movement animation
                            msgValue.Value = ""
                            task.wait()
                            msgValue.Value = "PlayAnimation"
                        end
                    end
                    
                    data.currentState = newState
                    data.stateStartTime = tick()
                end
                
                -- For server-side NPCs, we need to ensure physics velocity is set
                -- This helps the Animate script detect movement
                if speed > 0.1 and data.rootPart.AssemblyLinearVelocity.Magnitude < 0.1 then
                    -- Set a small physics velocity to trigger movement detection
                    local moveDirection = velocity.Unit
                    if moveDirection.Magnitude > 0 then
                        data.rootPart.AssemblyLinearVelocity = moveDirection * data.humanoid.WalkSpeed
                    end
                end
                
                -- Clean up physics velocity when stopped
                if speed < 0.1 and data.rootPart.AssemblyLinearVelocity.Magnitude > 0 then
                    data.rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            else
                -- NPC was removed
                npcData[npc] = nil
            end
        end
    end)
    
    print("[NPCAnimationFixer] Animation fixer initialized - monitoring " .. #npcData .. " NPCs")
end

-- Initialize the fixer
setupAnimationFixer()