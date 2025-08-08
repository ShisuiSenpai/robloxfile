-- NPCCombatClient Script
-- Place in: StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remotes
local remotes = ReplicatedStorage:WaitForChild("NPCRemotes")
local damageRemote = remotes:WaitForChild("NPCDamage")
local combatRemote = remotes:WaitForChild("NPCCombat")

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NPCCombatUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Damage numbers container
local damageContainer = Instance.new("Frame")
damageContainer.Size = UDim2.new(1, 0, 1, 0)
damageContainer.BackgroundTransparency = 1
damageContainer.Name = "DamageNumbers"
damageContainer.Parent = screenGui

-- Combat warning
local warningFrame = Instance.new("Frame")
warningFrame.Size = UDim2.new(0, 300, 0, 60)
warningFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
warningFrame.BackgroundColor3 = Color3.new(0.8, 0, 0)
warningFrame.BorderSizePixel = 0
warningFrame.BackgroundTransparency = 1
warningFrame.Parent = screenGui

local warningCorner = Instance.new("UICorner")
warningCorner.CornerRadius = UDim.new(0, 12)
warningCorner.Parent = warningFrame

local warningText = Instance.new("TextLabel")
warningText.Size = UDim2.new(1, 0, 1, 0)
warningText.BackgroundTransparency = 1
warningText.Text = "⚠️ INCOMING ATTACK! ⚠️"
warningText.TextScaled = true
warningText.TextColor3 = Color3.new(1, 1, 1)
warningText.Font = Enum.Font.SourceSansBold
warningText.Parent = warningFrame

-- Hit counter
local hitFrame = Instance.new("Frame")
hitFrame.Size = UDim2.new(0, 200, 0, 50)
hitFrame.Position = UDim2.new(0.5, -100, 0.3, 0)
hitFrame.BackgroundColor3 = Color3.new(0, 0, 0)
hitFrame.BackgroundTransparency = 0.5
hitFrame.BorderSizePixel = 0
hitFrame.Visible = false
hitFrame.Parent = screenGui

local hitCorner = Instance.new("UICorner")
hitCorner.CornerRadius = UDim.new(0, 8)
hitCorner.Parent = hitFrame

local hitText = Instance.new("TextLabel")
hitText.Size = UDim2.new(1, 0, 1, 0)
hitText.BackgroundTransparency = 1
hitText.Text = "HIT 1/5"
hitText.TextScaled = true
hitText.TextColor3 = Color3.new(1, 0.8, 0)
hitText.Font = Enum.Font.SourceSansBold
hitText.Parent = hitFrame

-- Screen flash effect
local flashFrame = Instance.new("Frame")
flashFrame.Size = UDim2.new(1, 0, 1, 0)
flashFrame.BackgroundColor3 = Color3.new(1, 0, 0)
flashFrame.BackgroundTransparency = 1
flashFrame.ZIndex = 10
flashFrame.Parent = screenGui

-- Functions
local function createDamageNumber(damage, position)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Position = position + Vector3.new(math.random(-2, 2), 2, math.random(-2, 2))
	part.Parent = workspace
	
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(2, 0, 1, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "-" .. tostring(damage)
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 0.2, 0.2)
	label.Font = Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = billboard
	
	-- Animate
	local startPos = part.Position
	local endPos = startPos + Vector3.new(0, 5, 0)
	
	local tween = TweenService:Create(
		part,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = endPos}
	)
	
	local fadeTween = TweenService:Create(
		label,
		TweenInfo.new(1.5, Enum.EasingStyle.Linear),
		{TextTransparency = 1, TextStrokeTransparency = 1}
	)
	
	tween:Play()
	fadeTween:Play()
	
	Debris:AddItem(part, 2)
end

local function flashScreen()
	flashFrame.BackgroundTransparency = 0.7
	local tween = TweenService:Create(
		flashFrame,
		TweenInfo.new(0.1, Enum.EasingStyle.Linear),
		{BackgroundTransparency = 1}
	)
	tween:Play()
end

local function showWarning()
	warningFrame.BackgroundTransparency = 0.2
	warningText.TextTransparency = 0
	
	-- Pulse animation
	local pulseTween = TweenService:Create(
		warningFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 3, true),
		{BackgroundTransparency = 0.5}
	)
	pulseTween:Play()
	
	task.wait(1)
	
	local fadeTween = TweenService:Create(
		warningFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad),
		{BackgroundTransparency = 1}
	)
	
	local textFadeTween = TweenService:Create(
		warningText,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad),
		{TextTransparency = 1}
	)
	
	fadeTween:Play()
	textFadeTween:Play()
end

local comboCount = 0

-- Handle damage
damageRemote.OnClientEvent:Connect(function(damage, npcPosition)
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			createDamageNumber(damage, root.Position)
			flashScreen()
			
			-- Update combo counter
			comboCount = comboCount + 1
			hitFrame.Visible = true
			hitText.Text = "HIT " .. comboCount .. "/5"
			
			-- Hide after delay
			task.wait(2)
			if comboCount >= 5 then
				hitFrame.Visible = false
				comboCount = 0
			end
		end
	end
end)

-- Handle combat events
combatRemote.OnClientEvent:Connect(function(event, npc)
	if event == "combo_start" then
		comboCount = 0
		task.spawn(showWarning)
	elseif event == "combo_end" then
		task.wait(0.5)
		hitFrame.Visible = false
		comboCount = 0
	end
end)

-- Add proximity indicators for NPCs
local indicators = {}

local function updateIndicators()
	local character = player.Character
	if not character then return end
	
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	-- Look for NPCs
	for _, model in ipairs(workspace:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") and model ~= character then
			local npcRoot = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
			if npcRoot and (model.Name:lower():find("npc") or model.Name:lower():find("noob")) then
				local dist = (npcRoot.Position - root.Position).Magnitude
				
				if dist < 100 then -- Within tracking range
					if not indicators[model] then
						-- Create indicator
						local billboard = Instance.new("BillboardGui")
						billboard.Size = UDim2.new(4, 0, 0.5, 0)
						billboard.StudsOffset = Vector3.new(0, -3, 0)
						billboard.AlwaysOnTop = false
						billboard.Parent = npcRoot
						
						local bar = Instance.new("Frame")
						bar.Size = UDim2.new(1, 0, 1, 0)
						bar.BackgroundColor3 = Color3.new(1, 1, 0)
						bar.BorderSizePixel = 0
						bar.Parent = billboard
						
						local corner = Instance.new("UICorner")
						corner.CornerRadius = UDim.new(0, 4)
						corner.Parent = bar
						
						indicators[model] = {billboard = billboard, bar = bar}
					end
					
					-- Update indicator
					local indicator = indicators[model]
					if indicator then
						local proximityRatio = 1 - (dist / 100)
						indicator.bar.Size = UDim2.new(proximityRatio, 0, 1, 0)
						
						-- Color based on distance
						if dist < 6 then
							indicator.bar.BackgroundColor3 = Color3.new(1, 0, 0) -- Red when close
						elseif dist < 20 then
							indicator.bar.BackgroundColor3 = Color3.new(1, 0.5, 0) -- Orange
						else
							indicator.bar.BackgroundColor3 = Color3.new(1, 1, 0) -- Yellow
						end
					end
				else
					-- Remove indicator if too far
					if indicators[model] then
						indicators[model].billboard:Destroy()
						indicators[model] = nil
					end
				end
			end
		end
	end
	
	-- Clean up indicators for removed NPCs
	for model, indicator in pairs(indicators) do
		if not model.Parent then
			indicator.billboard:Destroy()
			indicators[model] = nil
		end
	end
end

-- Update loop for indicators
RunService.Heartbeat:Connect(updateIndicators)

-- Clean up on character removal
player.CharacterRemoving:Connect(function()
	for _, indicator in pairs(indicators) do
		indicator.billboard:Destroy()
	end
	indicators = {}
	comboCount = 0
	hitFrame.Visible = false
end)

print("NPC Combat Client loaded!")