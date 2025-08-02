-- ServerScriptService.VFXDiagnostics
-- Run this as a separate script to test VFX visibility

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Test command to spawn VFX manually
game.Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		if msg:lower() == "/testvfx" then
			print("\n🔍 RUNNING VFX DIAGNOSTICS...")
			
			local character = player.Character
			if not character then
				warn("No character found!")
				return
			end
			
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if not rootPart then
				warn("No HumanoidRootPart!")
				return
			end
			
			-- Test 1: Simple particle test
			print("\n📝 TEST 1: Creating simple test particle...")
			local testPart = Instance.new("Part")
			testPart.Name = "TestParticle"
			testPart.Size = Vector3.new(1, 1, 1)
			testPart.Transparency = 1
			testPart.Anchored = true
			testPart.CanCollide = false
			testPart.Position = rootPart.Position + Vector3.new(0, -3, 0)
			testPart.Parent = workspace
			
			local attachment = Instance.new("Attachment")
			attachment.Parent = testPart
			
			local emitter = Instance.new("ParticleEmitter")
			emitter.Texture = "rbxasset://textures/particles/fire_main.dds"
			emitter.Rate = 50
			emitter.Lifetime = NumberRange.new(1, 2)
			emitter.Size = NumberSequence.new(3)
			emitter.Color = ColorSequence.new(Color3.new(1, 1, 0))
			emitter.LightEmission = 1
			emitter.Parent = attachment
			
			print("✅ Test particle created - can you see yellow particles?")
			
			Debris:AddItem(testPart, 3)
			
			-- Test 2: Check original VFX structure
			task.wait(1)
			print("\n📝 TEST 2: Checking original VFX...")
			
			local success, vfxOriginal = pcall(function()
				return ReplicatedStorage
					:WaitForChild("Assets", 1)
					:WaitForChild("Abilities", 1)
					:WaitForChild("VFX", 1)
					:WaitForChild("UpSlashAbility", 1)
					:WaitForChild("jumpwind", 1)
			end)
			
			if not success then
				warn("❌ Could not find VFX at expected path!")
				print("Expected: ReplicatedStorage.Assets.Abilities.VFX.UpSlashAbility.jumpwind")
				return
			end
			
			print("✅ Found VFX object:", vfxOriginal.Name)
			print("   Class:", vfxOriginal.ClassName)
			print("   Children:", #vfxOriginal:GetChildren())
			
			-- Test 3: Clone and analyze
			print("\n📝 TEST 3: Cloning and analyzing VFX...")
			local vfxClone = vfxOriginal:Clone()
			vfxClone.Parent = workspace
			vfxClone.Position = rootPart.Position + Vector3.new(5, -3, 0)
			
			-- Count emitters
			local emitterInfo = {}
			local function analyzeObject(obj, path)
				path = path or ""
				for _, child in pairs(obj:GetChildren()) do
					if child:IsA("ParticleEmitter") then
						table.insert(emitterInfo, {
							name = child.Name,
							path = path .. "/" .. child.Name,
							texture = child.Texture or "NO TEXTURE",
							rate = child.Rate,
							enabled = child.Enabled,
							size = tostring(child.Size),
							transparency = tostring(child.Transparency)
						})
					elseif child:IsA("Attachment") or child:IsA("BasePart") then
						analyzeObject(child, path .. "/" .. child.Name)
					end
				end
			end
			
			analyzeObject(vfxClone)
			
			print("📊 Found", #emitterInfo, "particle emitters:")
			for i, info in pairs(emitterInfo) do
				if i <= 5 then -- Show first 5
					print("\n   Emitter #" .. i .. ":")
					print("   - Name:", info.name)
					print("   - Path:", info.path)
					print("   - Texture:", info.texture)
					print("   - Rate:", info.rate)
					print("   - Enabled:", info.enabled)
					print("   - Has Size Issues:", info.size:find("0") ~= nil)
					print("   - Has Transparency Issues:", info.transparency:find("1") ~= nil)
				end
			end
			
			if #emitterInfo > 5 then
				print("\n   ... and", #emitterInfo - 5, "more emitters")
			end
			
			-- Test 4: Try to make visible
			print("\n📝 TEST 4: Attempting to make VFX visible...")
			local visibleCount = 0
			
			for _, child in pairs(vfxClone:GetDescendants()) do
				if child:IsA("ParticleEmitter") then
					-- Force visible settings
					child.Enabled = true
					child.Rate = 100
					child.Lifetime = NumberRange.new(2, 3)
					child.Size = NumberSequence.new(5)
					child.Transparency = NumberSequence.new(0)
					child.Color = ColorSequence.new(Color3.new(1, 0, 0)) -- Red
					child.LightEmission = 1
					
					if not child.Texture or child.Texture == "" then
						child.Texture = "rbxasset://textures/particles/fire_main.dds"
					end
					
					visibleCount = visibleCount + 1
				end
			end
			
			print("🔧 Modified", visibleCount, "emitters to be visible")
			print("🔴 All particles should now be RED and LARGE")
			
			-- Add marker
			local marker = Instance.new("Part")
			marker.Name = "VFX_Location"
			marker.Size = Vector3.new(10, 1, 10)
			marker.Material = Enum.Material.Neon
			marker.BrickColor = BrickColor.new("Bright red")
			marker.Transparency = 0.5
			marker.Anchored = true
			marker.CanCollide = false
			marker.Position = vfxClone.Position
			marker.Parent = workspace
			
			print("\n🔴 Red platform marks VFX location")
			print("📍 If you see NO particles above the red platform,")
			print("   the issue might be:")
			print("   - Graphics settings too low")
			print("   - Particles disabled in settings")
			print("   - VFX object structure issue")
			print("   - Rendering bug")
			
			Debris:AddItem(vfxClone, 10)
			Debris:AddItem(marker, 10)
			
			print("\n✅ Diagnostics complete! Objects will be removed in 10 seconds.")
		end
	end)
end)

print("🔍 VFX Diagnostics loaded!")
print("💬 Type '/testvfx' in chat to run diagnostics")