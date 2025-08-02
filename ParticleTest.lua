-- ServerScriptService.ParticleTest
-- Simple test to verify particles are rendering

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(2) -- Wait for character to load
		
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end
		
		print("🧪 Creating particle test above player...")
		
		-- Create a part above the player
		local testPart = Instance.new("Part")
		testPart.Name = "ParticleTestPart"
		testPart.Size = Vector3.new(2, 2, 2)
		testPart.Shape = Enum.PartType.Ball
		testPart.Material = Enum.Material.Neon
		testPart.BrickColor = BrickColor.new("Bright yellow")
		testPart.Transparency = 0.5
		testPart.Anchored = true
		testPart.CanCollide = false
		testPart.Parent = workspace
		
		-- Position above player
		local function updatePosition()
			if testPart and testPart.Parent and rootPart and rootPart.Parent then
				testPart.Position = rootPart.Position + Vector3.new(0, 5, 0)
			end
		end
		
		local connection = RunService.Heartbeat:Connect(updatePosition)
		updatePosition()
		
		-- Create attachment
		local attachment = Instance.new("Attachment")
		attachment.Parent = testPart
		
		-- Create a simple particle emitter
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "TestEmitter"
		emitter.Parent = attachment
		
		-- Use the most basic settings that should definitely work
		emitter.Texture = "rbxasset://textures/particles/fire_main.dds"
		emitter.Rate = 20
		emitter.Lifetime = NumberRange.new(2, 3)
		emitter.Size = NumberSequence.new(5)
		emitter.Color = ColorSequence.new(Color3.new(1, 0, 0)) -- Red
		emitter.Transparency = NumberSequence.new(0) -- Fully opaque
		emitter.LightEmission = 1
		emitter.LightInfluence = 0
		emitter.Speed = NumberRange.new(5)
		emitter.SpreadAngle = Vector2.new(45, 45)
		emitter.Enabled = true
		
		-- Add a light so we can see it
		local light = Instance.new("PointLight")
		light.Brightness = 2
		light.Color = Color3.new(1, 0, 0)
		light.Range = 15
		light.Parent = testPart
		
		print("✅ Test particle created!")
		print("🔴 You should see:")
		print("   - A glowing yellow ball above your head")
		print("   - Red fire particles coming from it")
		print("   - If you see the ball but NO particles:")
		print("     • Check Studio settings: File > Studio Settings > Rendering > ShowParticles")
		print("     • Check graphics quality isn't set too low")
		print("     • Try in actual game (not Studio) as rendering can differ")
		
		-- Clean up when character is removed
		character.AncestryChanged:Connect(function()
			if connection then
				connection:Disconnect()
			end
			if testPart and testPart.Parent then
				testPart:Destroy()
			end
		end)
	end)
end)

print("🧪 Particle test loaded - particles will appear above players")