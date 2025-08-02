-- StarterPlayer.StarterPlayerScripts.UpairSlashClient
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer

-- Get RemoteEvent
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local upairSlashRemote = remotes:WaitForChild("UpairSlashRemote")

-- Input settings
local ABILITY_KEY = Enum.KeyCode.E
local lastUsed = 0
local CLIENT_COOLDOWN = 1.5 -- Match server cooldown

print("🎮 UpairSlashClient loaded")

-- Handle input
local function onKeyPressed(input, gameProcessed)
	-- Don't process if typing in chat or other UI
	if gameProcessed then return end
	
	-- Check if it's our ability key
	if input.KeyCode ~= ABILITY_KEY then return end
	
	-- Check local cooldown to prevent spam
	local currentTime = tick()
	if currentTime - lastUsed < CLIENT_COOLDOWN then
		print("⏰ Ability on client cooldown")
		return
	end
	
	-- Check if player has combat permission
	local canUseCombat = player:GetAttribute("CanUseCombat")
	if not canUseCombat then
		print("❌ Cannot use combat abilities - not in round")
		return
	end
	
	-- Check if player character exists and is alive
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	-- Update local cooldown
	lastUsed = currentTime
	
	-- Send request to server
	print("📤 Sending upair slash request to server")
	upairSlashRemote:FireServer()
end

-- Connect input handler
UserInputService.InputBegan:Connect(onKeyPressed)

print("✅ UpairSlashClient ready - Press E to use Upair Slash!")
print("⚠️ Make sure you're in a round (CanUseCombat = true) to use abilities!")