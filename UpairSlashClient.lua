-- StarterPlayerScripts.UpairSlashClient
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Get RemoteEvent
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local upairSlashRemote = remotes:WaitForChild("UpairSlashRemote")

-- Attack settings
local COOLDOWN_TIME = 1.5 -- Adjust as needed
local lastAttackTime = 0
local isAttacking = false

-- Check if player can attack
local function canAttack()
	-- Check if on cooldown
	if tick() - lastAttackTime < COOLDOWN_TIME then
		return false
	end

	-- Check if already attacking
	if isAttacking then
		return false
	end

	-- Check if character is valid
	if not Character or not Humanoid or Humanoid.Health <= 0 then
		return false
	end

	-- Check if player is in round (using your existing attribute system)
	local canUseCombat = Player:GetAttribute("CanUseCombat")
	if not canUseCombat then
		return false
	end

	return true
end

-- Handle E key press
local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E then
		if canAttack() then
			-- Update cooldown and state immediately
			lastAttackTime = tick()
			isAttacking = true

			-- Tell server to perform attack
			upairSlashRemote:FireServer()

			-- FIXED: Reset attacking state using spawn instead of blocking wait
			task.spawn(function()
				task.wait(COOLDOWN_TIME) -- Use cooldown time instead of hardcoded 1 second
				isAttacking = false
			end)
		end
	end
end

-- Handle character respawn
local function onCharacterAdded(newCharacter)
	Character = newCharacter
	Humanoid = Character:WaitForChild("Humanoid")
	isAttacking = false
	lastAttackTime = 0
end

-- Connect events
UserInputService.InputBegan:Connect(onInputBegan)
Player.CharacterAdded:Connect(onCharacterAdded)