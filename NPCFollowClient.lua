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

-- Create UI for follower count
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NPCFollowUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

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

-- Hide frame initially
followerFrame.Visible = false

-- Track followers
local followingNPCs = {}
local lastFollowerCount = 0

-- Sound effects
local detectionSound = nil
if Config.PLAY_DETECTION_SOUND and Config.DETECTION_SOUND_ID ~= "" then
	detectionSound = Instance.new("Sound")
	detectionSound.SoundId = Config.DETECTION_SOUND_ID
	detectionSound.Volume = 0.3
	detectionSound.Parent = SoundService
end

-- Helper functions
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

-- Monitor NPCs
local function checkNPCs()
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	local npcFolder = workspace:FindFirstChild(Config.NPC_FOLDER_NAME)
	if not npcFolder then return end
	
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
				else
					if followingNPCs[npcModel] then
						followingNPCs[npcModel] = nil
						
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
						bar.BackgroundColor3 = Color3.new(1, proximityRatio, 0)
						bar.Size = UDim2.new(proximityRatio, 0, 0.2, 0)
					end
				end
			end
		end
	end
	
	updateFollowerUI()
end

-- Run check loop
RunService.Heartbeat:Connect(checkNPCs)

-- Clean up on character removal
player.CharacterRemoving:Connect(function()
	followingNPCs = {}
	updateFollowerUI()
end)

print("[NPCFollow] Client UI system loaded!")