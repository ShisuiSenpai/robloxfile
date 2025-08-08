-- NPCFollowClient LocalScript (Optional)
-- Place in: StarterPlayer > StarterPlayerScripts > NPCFollowClient
-- This adds client-side visual enhancements and UI feedback

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for configuration
local NPCFollowModules = ReplicatedStorage:WaitForChild("NPCFollowModules")
local Config = require(NPCFollowModules:WaitForChild("NPCFollowConfig"))

-- Create main UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NPCFollowUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Follower count frame
local followerFrame = Instance.new("Frame")
followerFrame.Name = "FollowerCount"
followerFrame.Size = UDim2.new(0, 200, 0, 50)
followerFrame.Position = UDim2.new(1, -210, 0, 10)
followerFrame.BackgroundColor3 = Color3.new(0, 0, 0)
followerFrame.BackgroundTransparency = 0.3
followerFrame.BorderSizePixel = 0
followerFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = followerFrame

local followerLabel = Instance.new("TextLabel")
followerLabel.Size = UDim2.new(1, -10, 1, 0)
followerLabel.Position = UDim2.new(0, 5, 0, 0)
followerLabel.BackgroundTransparency = 1
followerLabel.Text = "Followers: 0"
followerLabel.TextColor3 = Color3.new(1, 1, 1)
followerLabel.TextScaled = true
followerLabel.Font = Enum.Font.SourceSansBold
followerLabel.Parent = followerFrame

-- Combat indicator frame
local combatFrame = Instance.new("Frame")
combatFrame.Name = "CombatIndicator"
combatFrame.Size = UDim2.new(0, 300, 0, 60)
combatFrame.Position = UDim2.new(0.5, -150, 0.8, 0)
combatFrame.BackgroundColor3 = Color3.new(0.8, 0, 0)
combatFrame.BackgroundTransparency = 0.5
combatFrame.BorderSizePixel = 0
combatFrame.Visible = false
combatFrame.Parent = screenGui

local combatCorner = Instance.new("UICorner")
combatCorner.CornerRadius = UDim.new(0, 12)
combatCorner.Parent = combatFrame

local combatLabel = Instance.new("TextLabel")
combatLabel.Size = UDim2.new(1, 0, 1, 0)
combatLabel.BackgroundTransparency = 1
combatLabel.Text = "INCOMING ATTACK!"
combatLabel.TextColor3 = Color3.new(1, 1, 1)
combatLabel.TextScaled = true
combatLabel.Font = Enum.Font.SourceSansBold
combatLabel.Parent = combatFrame

-- Damage indicator container
local damageContainer = Instance.new("Frame")
damageContainer.Name = "DamageContainer"
damageContainer.Size = UDim2.new(1, 0, 1, 0)
damageContainer.BackgroundTransparency = 1
damageContainer.Parent = screenGui

-- Hide frames initially
followerFrame.Visible = false

-- Track followers and combat
local followingNPCs = {}
local lastFollowerCount = 0
local combatIndicators = {}

-- Sound effects
local detectionSound = nil
if Config.PLAY_DETECTION_SOUND and Config.DETECTION_SOUND_ID ~= "" then
	detectionSound = Instance.new("Sound")
	detectionSound.SoundId = Config.DETECTION_SOUND_ID
	detectionSound.Volume = 0.3
	detectionSound.Parent = SoundService
end

-- Helper functions
local function createDamageIndicator(damage, position)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.StudsOffset = Vector3.new(math.random(-2, 2), math.random(2, 4), 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "-" .. tostring(damage)
	label.TextColor3 = Color3.new(1, 0.2, 0.2)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = billboard
	
	billboard.Adornee = workspace.Terrain
	billboard.Parent = damageContainer
	
	-- Position in world space
	local camera = workspace.CurrentCamera
	billboard.StudsOffsetWorldSpace = position + Vector3.new(0, 2, 0)
	
	-- Animate damage number
	local startTime = tick()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local progress = elapsed / 1.5 -- 1.5 second animation
		
		if progress >= 1 then
			billboard:Destroy()
			connection:Disconnect()
			return
		end
		
		-- Float up and fade out
		billboard.StudsOffsetWorldSpace = position + Vector3.new(0, 2 + progress * 3, 0)
		label.TextTransparency = progress
		label.TextStrokeTransparency = progress
		
		-- Scale effect
		local scale = 1 + progress * 0.5
		billboard.Size = UDim2.new(0, 100 * scale, 0, 50 * scale)
	end)
end

local function updateFollowerUI()
	local count = 0
	for _, _ in pairs(followingNPCs) do
		count = count + 1
	end

	followerLabel.Text = "Followers: " .. count

	-- Show/hide frame
	if count > 0 then
		if not followerFrame.Visible then
			followerFrame.Visible = true
			-- Slide in animation
			followerFrame.Position = UDim2.new(1, 0, 0, 10)
			local tween = TweenService:Create(
				followerFrame,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Position = UDim2.new(1, -210, 0, 10)}
			)
			tween:Play()
		end
	else
		if followerFrame.Visible then
			-- Slide out animation
			local tween = TweenService:Create(
				followerFrame,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(1, 0, 0, 10)}
			)
			tween:Play()
			tween.Completed:Connect(function()
				followerFrame.Visible = false
			end)
		end
	end

	-- Play sound on new follower
	if count > lastFollowerCount and detectionSound then
		detectionSound:Play()
	end

	lastFollowerCount = count
end

local function createProximityIndicator(npc)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ProximityIndicator"
	billboard.Size = UDim2.new(4, 0, 1, 0)
	billboard.StudsOffset = Vector3.new(0, -3, 0)
	billboard.AlwaysOnTop = false

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0.2, 0)
	bar.Position = UDim2.new(0, 0, 0.4, 0)
	bar.BackgroundColor3 = Color3.new(1, 1, 0)
	bar.BorderSizePixel = 0
	bar.Parent = billboard

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 4)
	barCorner.Parent = bar

	return billboard
end

local function showCombatWarning()
	combatFrame.Visible = true
	combatFrame.BackgroundTransparency = 0
	
	-- Flash animation
	local flashTween = TweenService:Create(
		combatFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 3, true),
		{BackgroundTransparency = 0.8}
	)
	flashTween:Play()
	
	task.wait(1)
	
	-- Fade out
	local fadeTween = TweenService:Create(
		combatFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 1}
	)
	fadeTween:Play()
	fadeTween.Completed:Connect(function()
		combatFrame.Visible = false
	end)
end

-- Monitor NPCs and combat
local lastHealthCheck = {}
local function checkNPCs()
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoidRootPart or not humanoid then return end

	-- Track health changes for damage indicators
	if not lastHealthCheck[player] then
		lastHealthCheck[player] = humanoid.Health
	end
	
	if humanoid.Health < lastHealthCheck[player] then
		local damage = lastHealthCheck[player] - humanoid.Health
		createDamageIndicator(math.floor(damage), humanoidRootPart.Position)
	end
	lastHealthCheck[player] = humanoid.Health

	local npcFolder = workspace:FindFirstChild(Config.NPC_FOLDER_NAME)
	if not npcFolder then return end

	local nearbyAttackers = 0
	
	for _, npcModel in pairs(npcFolder:GetChildren()) do
		if npcModel:IsA("Model") then
			local npcRoot = npcModel:FindFirstChild("HumanoidRootPart") or npcModel:FindFirstChild("Torso")
			local npcHumanoid = npcModel:FindFirstChildOfClass("Humanoid")

			if npcRoot and npcHumanoid then
				local distance = (npcRoot.Position - humanoidRootPart.Position).Magnitude

				-- Check if NPC is following (simplified check)
				if distance <= Config.LOSE_INTEREST_RADIUS and npcHumanoid.WalkSpeed > Config.WALK_SPEED * 0.5 then
					if not followingNPCs[npcModel] then
						followingNPCs[npcModel] = true

						-- Add proximity indicator
						if not npcRoot:FindFirstChild("ProximityIndicator") then
							local indicator = createProximityIndicator(npcModel)
							indicator.Parent = npcRoot
						end
					end
					
					-- Check if NPC is in attack range
					if distance <= Config.ATTACK_RANGE * 1.5 then
						nearbyAttackers = nearbyAttackers + 1
						
						-- Show attack indicator on NPC
						local attackIndicator = npcModel:FindFirstChild("AttackIndicator")
						if attackIndicator and attackIndicator.Transparency < 0.9 then
							if not combatIndicators[npcModel] then
								combatIndicators[npcModel] = true
								task.spawn(showCombatWarning)
							end
						else
							combatIndicators[npcModel] = nil
						end
					end
				else
					if followingNPCs[npcModel] then
						followingNPCs[npcModel] = nil
						combatIndicators[npcModel] = nil

						-- Remove proximity indicator
						local indicator = npcRoot:FindFirstChild("ProximityIndicator")
						if indicator then
							indicator:Destroy()
						end
					end
				end

				-- Update proximity indicator
				local indicator = npcRoot:FindFirstChild("ProximityIndicator")
				if indicator and followingNPCs[npcModel] then
					local bar = indicator:FindFirstChild("Frame")
					if bar then
						-- Update bar color based on distance
						local proximityRatio = 1 - (distance / Config.LOSE_INTEREST_RADIUS)
						
						-- Change color based on attack range
						if distance <= Config.ATTACK_RANGE then
							bar.BackgroundColor3 = Color3.new(1, 0, 0) -- Red when in attack range
						else
							bar.BackgroundColor3 = Color3.new(1, proximityRatio, 0) -- Yellow to orange
						end
						
						bar.Size = UDim2.new(proximityRatio, 0, 0.2, 0)
					end
				end
			end
		end
	end

	updateFollowerUI()
end

-- Screen effects for being stunned
local stunEffect = Instance.new("Frame")
stunEffect.Name = "StunEffect"
stunEffect.Size = UDim2.new(1, 0, 1, 0)
stunEffect.BackgroundColor3 = Color3.new(1, 1, 1)
stunEffect.BackgroundTransparency = 1
stunEffect.ZIndex = 10
stunEffect.Parent = screenGui

local lastWalkSpeed = 16
local function checkStunEffect()
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Detect stun by checking if walkspeed is 0
	if humanoid.WalkSpeed == 0 and lastWalkSpeed > 0 then
		-- Show stun effect
		stunEffect.BackgroundTransparency = 0.8
		local tween = TweenService:Create(
			stunEffect,
			TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 4, true),
			{BackgroundTransparency = 0.95}
		)
		tween:Play()
	elseif humanoid.WalkSpeed > 0 and lastWalkSpeed == 0 then
		-- Remove stun effect
		stunEffect.BackgroundTransparency = 1
	end
	
	lastWalkSpeed = humanoid.WalkSpeed
end

-- Run check loops
RunService.Heartbeat:Connect(function()
	checkNPCs()
	checkStunEffect()
end)

-- Clean up on character removal
player.CharacterRemoving:Connect(function()
	followingNPCs = {}
	combatIndicators = {}
	lastHealthCheck = {}
	updateFollowerUI()
end)

print("[NPCFollow] Client UI system with combat feedback loaded!")