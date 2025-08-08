-- NPCAnimationController: Directly controls NPC animations based on movement
-- Place in ServerScriptService

local RunService = game:GetService("RunService")

local WALK_SPEED_THRESHOLD = 1 -- Speed to trigger walk animation
local RUN_SPEED_THRESHOLD = 16 -- Speed to trigger run animation

local function setupAnimationController()
    local npcsFolder = workspace:WaitForChild("NPCS", 5)
    if not npcsFolder then
        warn("[NPCAnimationController] NPCS folder not found")
        return
    end
    
    local npcControllers = {}
    
    local function createController(npc)
        if npcControllers[npc] then return end
        
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
        end
        
        local controller = {
            npc = npc,
            humanoid = humanoid,
            rootPart = rootPart,
            animator = animator,
            animateScript = animateScript,
            lastPosition = rootPart.Position,
            currentAnimation = nil,
            currentAnimTrack = nil,
            animations = {}
        }
        
        -- Load animations from the Animate script
        if animateScript then
            -- Load idle animation
            local idleAnim = animateScript:FindFirstChild("idle")
            if idleAnim then
                local anim1 = idleAnim:FindFirstChild("Animation1")
                if anim1 and anim1:FindFirstChild("AnimationId") then
                    local animation = Instance.new("Animation")
                    animation.AnimationId = anim1.AnimationId.Value
                    controller.animations.idle = animator:LoadAnimation(animation)
                end
            end
            
            -- Load walk animation
            local walkAnim = animateScript:FindFirstChild("walk")
            if walkAnim then
                local walkAnimObj = walkAnim:FindFirstChild("WalkAnim")
                if walkAnimObj and walkAnimObj:FindFirstChild("AnimationId") then
                    local animation = Instance.new("Animation")
                    animation.AnimationId = walkAnimObj.AnimationId.Value
                    controller.animations.walk = animator:LoadAnimation(animation)
                end
            end
            
            -- Load run animation
            local runAnim = animateScript:FindFirstChild("run")
            if runAnim then
                local runAnimObj = runAnim:FindFirstChild("RunAnim")
                if runAnimObj and runAnimObj:FindFirstChild("AnimationId") then
                    local animation = Instance.new("Animation")
                    animation.AnimationId = runAnimObj.AnimationId.Value
                    controller.animations.run = animator:LoadAnimation(animation)
                end
            end
        end
        
        -- Function to play animation
        function controller:PlayAnimation(animName)
            if self.currentAnimation == animName then return end
            
            -- Stop current animation
            if self.currentAnimTrack then
                self.currentAnimTrack:Stop(0.2)
            end
            
            -- Play new animation
            local animTrack = self.animations[animName]
            if animTrack then
                animTrack:Play(0.2)
                self.currentAnimTrack = animTrack
                self.currentAnimation = animName
                
                -- Set looping for movement animations
                if animName == "walk" or animName == "run" or animName == "idle" then
                    animTrack.Looped = true
                end
            end
        end
        
        npcControllers[npc] = controller
        
        -- Play idle animation initially
        controller:PlayAnimation("idle")
        
        print("[NPCAnimationController] Set up controller for " .. npc.Name)
    end
    
    -- Setup existing NPCs
    for _, npc in pairs(npcsFolder:GetChildren()) do
        if npc:IsA("Model") then
            createController(npc)
        end
    end
    
    -- Setup new NPCs
    npcsFolder.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            task.wait(0.1)
            createController(child)
        end
    end)
    
    -- Update loop
    RunService.Heartbeat:Connect(function(deltaTime)
        for npc, controller in pairs(npcControllers) do
            if npc.Parent and controller.humanoid.Parent and controller.rootPart.Parent then
                local currentPosition = controller.rootPart.Position
                local velocity = (currentPosition - controller.lastPosition) / deltaTime
                local speed = velocity.Magnitude
                
                -- Determine which animation to play
                local targetAnimation = "idle"
                if speed > WALK_SPEED_THRESHOLD then
                    if speed >= RUN_SPEED_THRESHOLD then
                        targetAnimation = "run"
                    else
                        targetAnimation = "walk"
                    end
                end
                
                -- Play the appropriate animation
                controller:PlayAnimation(targetAnimation)
                
                -- Update last position
                controller.lastPosition = currentPosition
            else
                -- Clean up removed NPC
                if controller.currentAnimTrack then
                    controller.currentAnimTrack:Stop()
                end
                npcControllers[npc] = nil
            end
        end
    end)
    
    print("[NPCAnimationController] Animation controller initialized")
end

-- Initialize
setupAnimationController()