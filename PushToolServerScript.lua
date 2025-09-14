-- Push Tool Server Script
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Configuration
local KNOCKBACK_DURATION = 1.5 -- How long the knockback effect lasts
local MAX_PUSH_DISTANCE = 15 -- Maximum allowed push distance
local PUSH_COOLDOWN_PER_PLAYER = {} -- Track cooldowns per player
local USE_SIMPLE_PUSH = true -- Use simple push without any ragdoll/sit

-- Debug mode
local DEBUG = true -- Set to false to hide debug messages

-- Debug print function
local function debugPrint(...)
	if DEBUG then
		print("[PUSH SERVER]", ...)
	end
end

debugPrint("Push server script starting...")

-- Create RemoteEvent
local pushRemote = Instance.new("RemoteEvent")
pushRemote.Name = "PushRemote"
pushRemote.Parent = ReplicatedStorage

debugPrint("RemoteEvent created")

-- SAFER APPROACH: Simple knockback without breaking joints
local function applyKnockback(character)
	debugPrint("Applying knockback to:", character.Name)
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then 
		debugPrint("No humanoid found!")
		return 
	end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		debugPrint("No HumanoidRootPart found!")
		return
	end
	
	-- Store current health to ensure no damage
	local currentHealth = humanoid.Health
	
	-- Simple knockback: Just make them fall over without breaking joints
	humanoid.Sit = true  -- Makes them sit/fall
	
	-- Wait a moment then stand them back up
	task.wait(0.1)
	
	-- Return function to recover
	return function()
		debugPrint("Recovering character:", character.Name)
		
		if not character.Parent then 
			debugPrint("Character no longer exists")
			return 
		end
		
		-- Stand back up
		if humanoid and humanoid.Parent then
			humanoid.Sit = false
			humanoid.Jump = true  -- Help them get up
			
			-- Restore health
			humanoid.Health = currentHealth
			
			-- Small upward impulse to help stand
			if rootPart and rootPart.Parent then
				rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + Vector3.new(0, 20, 0)
			end
		end
		
		debugPrint("Character recovered successfully")
	end
end

-- Handle push request
pushRemote.OnServerEvent:Connect(function(pusher, targetPlayer, direction, force)
	debugPrint("Push request from:", pusher.Name, "to:", targetPlayer and targetPlayer.Name or "nil")
	
	-- Check server-side cooldown
	local currentTime = tick()
	if PUSH_COOLDOWN_PER_PLAYER[pusher] and currentTime - PUSH_COOLDOWN_PER_PLAYER[pusher] < 2 then
		debugPrint("Player", pusher.Name, "is on cooldown")
		return
	end
	PUSH_COOLDOWN_PER_PLAYER[pusher] = currentTime
	
	-- Validate
	if not pusher.Character then
		debugPrint("Pusher has no character")
		return
	end
	
	if not targetPlayer or not targetPlayer.Character then
		debugPrint("Invalid target player or character")
		return
	end
	
	local pusherRoot = pusher.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
	
	if not pusherRoot or not targetRoot or not targetHumanoid then
		debugPrint("Missing HumanoidRootPart or Humanoid")
		return
	end
	
	-- Check distance
	local distance = (targetRoot.Position - pusherRoot.Position).Magnitude
	debugPrint("Push distance:", distance)
	
	if distance > MAX_PUSH_DISTANCE then
		debugPrint("Distance too far:", distance, ">", MAX_PUSH_DISTANCE)
		warn(pusher.Name, "attempted to push from too far!")
		return
	end
	
	-- Check if target is alive (but we won't damage them)
	if targetHumanoid.Health <= 0 then
		debugPrint("Target is already dead, can't push")
		return
	end
	
	-- Store health to ensure no damage
	local originalHealth = targetHumanoid.Health
	
	debugPrint("Applying push force...")
	
	-- Apply push force
	local actualForce = math.clamp(force or 50, 10, 100)
	local pushVelocity = (direction + Vector3.new(0, 0.3, 0)).Unit * actualForce
	
	if USE_SIMPLE_PUSH then
		-- SIMPLEST APPROACH: Just apply velocity, no ragdoll or sitting
		debugPrint("Using simple push (no ragdoll)")
		
		-- Method 1: Using AssemblyLinearVelocity (newer, more reliable)
		targetRoot.AssemblyLinearVelocity = pushVelocity
		
		-- Method 2: Using BodyVelocity for stronger effect
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(4000, 2000, 4000)
		bodyVelocity.Velocity = pushVelocity
		bodyVelocity.Parent = targetRoot
		
		-- Remove BodyVelocity after short time
		Debris:AddItem(bodyVelocity, 0.5)
		
		-- Just ensure health stays the same
		targetHumanoid.Health = originalHealth
		
		debugPrint("Simple push applied successfully")
	else
		-- Original approach with knockback
		-- Method 1: Using AssemblyLinearVelocity (newer, more reliable)
		targetRoot.AssemblyLinearVelocity = pushVelocity
		
		-- Method 2: Using BodyVelocity (backup method)
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
		bodyVelocity.Velocity = pushVelocity
		bodyVelocity.Parent = targetRoot
		
		-- Remove BodyVelocity after short time
		Debris:AddItem(bodyVelocity, 0.3)
		
		debugPrint("Push force applied successfully")
		
		-- Ensure no damage was done
		targetHumanoid.Health = originalHealth
		
		-- Apply knockback effect (safer than ragdoll)
		local recover = applyKnockback(targetPlayer.Character)
		
		-- Create a health protection loop
		local healthProtection = task.spawn(function()
			local protectionTime = 0
			while protectionTime < KNOCKBACK_DURATION + 0.5 do
				if targetHumanoid and targetHumanoid.Parent then
					-- Keep restoring health
					targetHumanoid.Health = originalHealth
					-- Prevent death
					if targetHumanoid.Health <= 0 then
						targetHumanoid.Health = originalHealth
						debugPrint("Prevented death, restored health to:", originalHealth)
					end
				else
					break
				end
				task.wait(0.1)
				protectionTime = protectionTime + 0.1
			end
		end)
		
		-- Schedule recovery
		task.wait(KNOCKBACK_DURATION)
		
		if recover then
			recover()
			-- Final health restore
			if targetHumanoid and targetHumanoid.Parent then
				targetHumanoid.Health = originalHealth
			end
		end
	end
end)

-- Clean up cooldowns when players leave
Players.PlayerRemoving:Connect(function(player)
	PUSH_COOLDOWN_PER_PLAYER[player] = nil
end)

debugPrint("Push server script loaded successfully!")
print("Push System Ready! Debug mode is ON - check output for detailed logs")
print("Push tool: NO DAMAGE, just physics push with ragdoll")