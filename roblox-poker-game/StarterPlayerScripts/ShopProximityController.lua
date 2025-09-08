-- ShopProximityController.lua
-- Handles proximity-based shop opening when player is within the OpenShopPart bounds
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Get the shop part
local map = workspace:WaitForChild("Map")
local shop = map:WaitForChild("Shop")
local openShopPart = shop:WaitForChild("OpenShopPart")

-- Get GUI elements
local playerGui = player:WaitForChild("PlayerGui")
local shopGui = playerGui:WaitForChild("LimitedStoreGUI")
local openButton = shopGui:WaitForChild("OpenShopbtn")

-- Debug mode
local DEBUG_MODE = true
local function debugPrint(...)
	if DEBUG_MODE then
		print("[Shop Proximity]", ...)
	end
end

-- State tracking
local isInZone = false
local wasInZone = false
local checkConnection = nil
local shopController = nil

-- Try to get the shop controller to use its functions
local function getShopController()
	-- Look for the shop controller in player scripts
	for _, script in ipairs(player.PlayerScripts:GetChildren()) do
		if script.Name == "ShopController" then
			-- We can't directly access another script's functions, so we'll use a workaround
			return true
		end
	end
	return false
end

-- Function to check if player is within the part bounds (not just touching)
local function isPlayerInBounds()
	if not character or not humanoidRootPart then
		return false
	end
	
	-- Get the part's CFrame and size
	local partCFrame = openShopPart.CFrame
	local partSize = openShopPart.Size
	
	-- Get player position relative to the part
	local relativePosition = partCFrame:PointToObjectSpace(humanoidRootPart.Position)
	
	-- Check if player is within the part's bounding box
	-- We check if the player is above the surface (Y > 0) and within X/Z bounds
	local halfSize = partSize / 2
	
	local withinX = math.abs(relativePosition.X) <= halfSize.X
	local withinZ = math.abs(relativePosition.Z) <= halfSize.Z
	
	-- Check if player is on or slightly above the surface (not below)
	-- Allow some height above the part (like 10 studs) but must be above it
	local onSurface = relativePosition.Y >= -1 and relativePosition.Y <= halfSize.Y + 10
	
	return withinX and withinZ and onSurface
end

-- Function to open shop via proximity
local function openShopProximity()
	if isInZone then return end
	isInZone = true
	
	debugPrint("Player entered shop zone")
	
	-- Hide the open button
	openButton.Visible = false
	
	-- Fire a remote event to open the shop (if you have one)
	-- Or directly manipulate the shop UI
	local mainFrame = shopGui:FindFirstChild("MainFrame")
	if mainFrame then
		-- Make sure we're not already animating
		mainFrame.Visible = true
		mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		
		-- Animate open (slide from right)
		mainFrame.Position = UDim2.new(-0.5, 0, 0.5, 0)
		local openTween = TweenService:Create(
			mainFrame,
			TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Position = UDim2.new(0.5, 0, 0.5, 0)}
		)
		openTween:Play()
		
		debugPrint("Shop opened via proximity")
	end
end

-- Function to close shop via proximity
local function closeShopProximity()
	if not isInZone then return end
	isInZone = false
	
	debugPrint("Player left shop zone")
	
	-- Show the open button again
	openButton.Visible = true
	
	-- Close the shop
	local mainFrame = shopGui:FindFirstChild("MainFrame")
	if mainFrame then
		-- Animate close (slide to right)
		local closeTween = TweenService:Create(
			mainFrame,
			TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Position = UDim2.new(1.5, 0, 0.5, 0)}
		)
		closeTween:Play()
		
		closeTween.Completed:Connect(function()
			mainFrame.Visible = false
		end)
		
		debugPrint("Shop closed via proximity")
	end
end

-- Main proximity check loop
local function startProximityCheck()
	checkConnection = RunService.Heartbeat:Connect(function()
		local inBounds = isPlayerInBounds()
		
		-- Check for state change
		if inBounds and not wasInZone then
			-- Just entered the zone
			openShopProximity()
			wasInZone = true
		elseif not inBounds and wasInZone then
			-- Just left the zone
			closeShopProximity()
			wasInZone = false
		end
	end)
	
	debugPrint("Proximity checking started")
end

-- Stop proximity checking
local function stopProximityCheck()
	if checkConnection then
		checkConnection:Disconnect()
		checkConnection = nil
		debugPrint("Proximity checking stopped")
	end
end

-- Handle character respawn
local function onCharacterAdded(newCharacter)
	character = newCharacter
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	-- Reset state
	isInZone = false
	wasInZone = false
	
	-- Restart proximity checking
	stopProximityCheck()
	wait(1) -- Give character time to load
	startProximityCheck()
	
	debugPrint("Character respawned, restarted proximity check")
end

-- Handle character removal
local function onCharacterRemoving()
	stopProximityCheck()
	
	-- Close shop if it was open via proximity
	if isInZone then
		closeShopProximity()
	end
	
	debugPrint("Character removing, stopped proximity check")
end

-- Visualize the detection zone (DEBUG ONLY - Remove in production)
local function createDebugVisualization()
	if not DEBUG_MODE then return end
	
	-- Create a semi-transparent part to show the detection zone
	local debugPart = Instance.new("Part")
	debugPart.Name = "ShopZoneDebug"
	debugPart.Size = openShopPart.Size
	debugPart.CFrame = openShopPart.CFrame
	debugPart.Anchored = true
	debugPart.CanCollide = false
	debugPart.Transparency = 0.8
	debugPart.BrickColor = BrickColor.new("Lime green")
	debugPart.Material = Enum.Material.ForceField
	debugPart.Parent = workspace
	
	-- Update position if the shop part moves
	RunService.Heartbeat:Connect(function()
		if debugPart and debugPart.Parent and openShopPart and openShopPart.Parent then
			debugPart.CFrame = openShopPart.CFrame
		end
	end)
	
	debugPrint("Debug visualization created")
end

-- Initialize
player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(onCharacterRemoving)

-- Start checking if character already exists
if character and humanoidRootPart then
	startProximityCheck()
end

-- Create debug visualization
createDebugVisualization()

-- Make the OpenShopPart invisible (it's just a trigger zone)
openShopPart.Transparency = 1
openShopPart.CanCollide = false

debugPrint("Shop Proximity Controller initialized")
debugPrint("Debug mode:", DEBUG_MODE and "ON" or "OFF")
print("[Shop Proximity] Stand on the shop area to auto-open the shop!")