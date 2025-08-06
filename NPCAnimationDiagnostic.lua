-- NPCAnimationDiagnostic Script
-- This script helps diagnose why NPC animations might not be working
-- Place in ServerScriptService

local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage:WaitForChild("NPCFollowModules"):WaitForChild("NPCFollowConfig"))

print("[AnimationDiagnostic] Starting NPC Animation Diagnostic...")

-- Function to check if an NPC has proper animation setup
local function checkNPCAnimation(npcModel)
	print("\n=== Checking NPC:", npcModel.Name, "===")
	
	-- Check for Humanoid
	local humanoid = npcModel:FindFirstChild("Humanoid")
	if not humanoid then
		print("❌ No Humanoid found!")
		return
	end
	print("✓ Humanoid found")
	
	-- Check for HumanoidRootPart
	local rootPart = npcModel:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		print("❌ No HumanoidRootPart found!")
		return
	end
	print("✓ HumanoidRootPart found")
	
	-- Check for Animate script
	local animateScript = npcModel:FindFirstChild("Animate")
	if not animateScript then
		print("❌ No Animate script found!")
	else
		print("✓ Animate script found - Type:", animateScript.ClassName)
		
		-- Check for animation StringValues
		local animations = {
			"idle", "walk", "run", "jump", "climb", "sit", "toolnone", "toolslash", "toollunge", "wave", "point", "dance", "dance2", "dance3", "laugh", "cheer"
		}
		
		for _, animName in ipairs(animations) do
			local animValue = animateScript:FindFirstChild(animName)
			if animValue then
				print("  ✓ Found animation:", animName)
			end
		end
	end
	
	-- Check for Animator
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		print("⚠ No Animator found - creating one...")
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	print("✓ Animator present")
	
	-- Monitor movement for this NPC
	local lastPosition = rootPart.Position
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not rootPart.Parent then
			connection:Disconnect()
			return
		end
		
		local currentPosition = rootPart.Position
		local deltaPosition = (currentPosition - lastPosition)
		local speed = deltaPosition.Magnitude * 30 -- Convert to studs/second
		
		if speed > 0.1 then
			print("\n[", npcModel.Name, "] Movement detected:")
			print("  - Speed:", speed, "studs/second")
			print("  - Humanoid WalkSpeed:", humanoid.WalkSpeed)
			print("  - Humanoid MoveDirection:", humanoid.MoveDirection)
			print("  - Humanoid Moving:", humanoid.MoveDirection.Magnitude > 0)
			
			-- Instead of firing the event, we need to ensure MoveDirection is set
			-- The Animate script should automatically detect movement through MoveDirection
			if humanoid.MoveDirection.Magnitude == 0 then
				print("  ⚠ MoveDirection is zero despite movement!")
				print("  ⚠ This prevents the Animate script from detecting movement")
				
				-- Calculate and set move direction based on velocity
				local moveDir = deltaPosition.Unit
				if moveDir.Magnitude > 0 then
					-- We can't directly set MoveDirection, but we can ensure MoveTo is being called properly
					print("  💡 NPCFollowServer should be using Humanoid:MoveTo() to ensure proper MoveDirection")
				end
			end
		end
		
		lastPosition = currentPosition
	end)
	
	-- Wait a moment then disconnect to avoid spam
	task.wait(5)
	connection:Disconnect()
	print("[", npcModel.Name, "] Diagnostic complete")
end

-- Check all NPCs
task.wait(2) -- Wait for NPCs to load
local npcFolder = workspace:WaitForChild(Config.NPC_FOLDER_NAME, 10)
if npcFolder then
	for _, npcModel in pairs(npcFolder:GetChildren()) do
		if npcModel:IsA("Model") then
			checkNPCAnimation(npcModel)
			task.wait(1)
		end
	end
end

print("\n[AnimationDiagnostic] Diagnostic complete!")