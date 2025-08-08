-- NPC Debug Script
-- Place this in ServerScriptService temporarily to debug

local Players = game:GetService("Players")

print("=== NPC DEBUG START ===")

-- Check for NPCS folder
local npcsFolder = workspace:FindFirstChild("NPCS")
if npcsFolder then
	print("✓ Found NPCS folder")
	print("  Children count:", #npcsFolder:GetChildren())
	
	for i, child in ipairs(npcsFolder:GetChildren()) do
		print("  Child", i, ":", child.Name, "- Type:", child.ClassName)
		
		if child:IsA("Model") then
			local humanoid = child:FindFirstChildOfClass("Humanoid")
			local rootPart = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso") or child:FindFirstChild("UpperTorso")
			
			print("    Has Humanoid:", humanoid ~= nil)
			print("    Has RootPart:", rootPart ~= nil)
			
			if humanoid then
				print("    Humanoid Health:", humanoid.Health)
				print("    Humanoid MaxHealth:", humanoid.MaxHealth)
			end
		end
	end
else
	print("✗ NPCS folder not found!")
	print("Looking for any models with Humanoid in workspace...")
	
	local count = 0
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
			local isPlayer = false
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character == obj then
					isPlayer = true
					break
				end
			end
			
			if not isPlayer then
				count = count + 1
				print("  Found potential NPC:", obj:GetFullName())
			end
		end
	end
	print("  Total potential NPCs found:", count)
end

print("=== NPC DEBUG END ===")

-- Self-destruct after 5 seconds
task.wait(5)
script:Destroy()