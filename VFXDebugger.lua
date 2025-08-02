-- ModuleScript in ReplicatedStorage
local VFXDebugger = {}

-- Debug function to analyze why VFX might not be visible
function VFXDebugger.analyzeVFX(vfxPart)
	print("\n🔍 VFX VISIBILITY ANALYSIS")
	print("========================")
	
	-- Check part properties
	print("📦 Part Properties:")
	print("  - Name:", vfxPart.Name)
	print("  - Position:", vfxPart.Position)
	print("  - Transparency:", vfxPart.Transparency)
	print("  - Anchored:", vfxPart.Anchored)
	print("  - CanCollide:", vfxPart.CanCollide)
	print("  - Parent:", vfxPart.Parent and vfxPart.Parent.Name or "nil")
	
	-- Analyze all particle emitters
	local emitterCount = 0
	local totalParticles = 0
	local issues = {}
	
	local function analyzeEmitter(emitter, path)
		emitterCount = emitterCount + 1
		print("\n🎨 Emitter:", emitter.Name, "at", path)
		
		-- Check enabled state
		print("  - Enabled:", emitter.Enabled)
		
		-- Check rate
		local rate = emitter.Rate
		print("  - Rate:", rate)
		if rate <= 0 then
			table.insert(issues, emitter.Name .. " has zero rate")
		end
		
		-- Check lifetime
		local lifetime = emitter.Lifetime
		print("  - Lifetime:", tostring(lifetime))
		if typeof(lifetime) == "NumberRange" and lifetime.Max < 0.1 then
			table.insert(issues, emitter.Name .. " has very short lifetime")
		end
		
		-- Check size
		local size = emitter.Size
		if typeof(size) == "NumberSequence" then
			local firstKeypoint = size.Keypoints[1]
			if firstKeypoint and firstKeypoint.Value <= 0 then
				table.insert(issues, emitter.Name .. " starts with zero size")
			end
		end
		
		-- Check transparency
		local transparency = emitter.Transparency
		if typeof(transparency) == "NumberSequence" then
			local firstKeypoint = transparency.Keypoints[1]
			if firstKeypoint and firstKeypoint.Value >= 1 then
				table.insert(issues, emitter.Name .. " starts fully transparent")
			end
		end
		
		-- Check texture
		local texture = emitter.Texture
		print("  - Texture:", texture or "NONE")
		if not texture or texture == "" then
			table.insert(issues, emitter.Name .. " has no texture")
		end
		
		-- Check color
		local color = emitter.Color
		print("  - Color:", tostring(color))
		
		-- Check light emission
		local lightEmission = emitter.LightEmission
		print("  - LightEmission:", lightEmission)
		
		-- Check ZOffset
		local zOffset = emitter.ZOffset
		print("  - ZOffset:", zOffset)
		
		-- Check if emitter would be visible
		local wouldBeVisible = rate > 0 and 
			(not texture or texture ~= "") and
			(typeof(lifetime) ~= "NumberRange" or lifetime.Max > 0.1)
		
		print("  - Would be visible:", wouldBeVisible)
		
		return wouldBeVisible
	end
	
	-- Recursively check all emitters
	local function checkObject(obj, path)
		path = path or obj.Name
		
		for _, child in pairs(obj:GetChildren()) do
			if child:IsA("ParticleEmitter") then
				analyzeEmitter(child, path)
			elseif child:IsA("Attachment") or child:IsA("BasePart") then
				checkObject(child, path .. "." .. child.Name)
			end
		end
	end
	
	checkObject(vfxPart)
	
	-- Summary
	print("\n📊 SUMMARY:")
	print("  - Total Emitters:", emitterCount)
	print("  - Issues Found:", #issues)
	
	if #issues > 0 then
		print("\n⚠️ ISSUES:")
		for _, issue in pairs(issues) do
			print("  -", issue)
		end
	end
	
	-- Suggestions
	print("\n💡 SUGGESTIONS:")
	if emitterCount == 0 then
		print("  - No particle emitters found! Check VFX structure")
	end
	if #issues > 0 then
		print("  - Fix the issues listed above")
	end
	print("  - Make sure VFX is in workspace or character")
	print("  - Check if particles are rendering behind objects")
	print("  - Verify graphics settings allow particles")
	
	print("========================\n")
	
	return issues
end

-- Function to make VFX more visible for debugging
function VFXDebugger.makeVisible(vfxPart)
	print("🔧 Making VFX more visible...")
	
	local function enhanceEmitter(emitter)
		-- Increase size if too small
		local size = emitter.Size
		if typeof(size) == "NumberSequence" then
			local keypoints = {}
			for i, kp in pairs(size.Keypoints) do
				local newValue = math.max(kp.Value, 2) -- Minimum size of 2
				table.insert(keypoints, NumberSequenceKeypoint.new(kp.Time, newValue, kp.Envelope))
			end
			emitter.Size = NumberSequence.new(keypoints)
		end
		
		-- Make fully opaque
		emitter.Transparency = NumberSequence.new(0)
		
		-- Increase light emission
		emitter.LightEmission = 1
		
		-- Set bright color
		emitter.Color = ColorSequence.new(Color3.new(1, 1, 0)) -- Yellow for visibility
		
		-- Increase rate for testing
		emitter.Rate = math.max(emitter.Rate, 50)
		
		-- Ensure reasonable lifetime
		emitter.Lifetime = NumberRange.new(1, 2)
		
		-- Add texture if missing
		if not emitter.Texture or emitter.Texture == "" then
			emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		end
		
		print("  ✅ Enhanced", emitter.Name)
	end
	
	-- Process all emitters
	local function processObject(obj)
		for _, child in pairs(obj:GetChildren()) do
			if child:IsA("ParticleEmitter") then
				enhanceEmitter(child)
			elseif child:IsA("Attachment") or child:IsA("BasePart") then
				processObject(child)
			end
		end
	end
	
	processObject(vfxPart)
	
	-- Add a visible part for reference
	local debugPart = Instance.new("Part")
	debugPart.Name = "VFX_DEBUG_MARKER"
	debugPart.Size = Vector3.new(2, 2, 2)
	debugPart.Material = Enum.Material.Neon
	debugPart.BrickColor = BrickColor.new("Lime green")
	debugPart.Transparency = 0.5
	debugPart.Anchored = true
	debugPart.CanCollide = false
	debugPart.Position = vfxPart.Position
	debugPart.Parent = vfxPart.Parent
	
	-- Add light
	local light = Instance.new("PointLight")
	light.Brightness = 5
	light.Color = Color3.new(1, 1, 0)
	light.Range = 50
	light.Parent = debugPart
	
	print("✅ VFX enhanced for visibility")
	print("🟢 Green marker added at VFX position")
	
	return debugPart
end

return VFXDebugger