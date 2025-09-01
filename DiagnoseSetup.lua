-- DiagnoseSetup.lua
-- Place in ServerScriptService to diagnose setup issues

local ServerScriptService = game:GetService("ServerScriptService")

print("\n[DIAGNOSE] === CHECKING SCRIPT SETUP ===")

-- Check for old scripts
local oldScripts = {
	"PokerGameServer",
	"CardOrientationFixer", -- old single-table version
	"TableCameraScript",
	"GameStartScript"
}

for _, scriptName in ipairs(oldScripts) do
	local script = ServerScriptService:FindFirstChild(scriptName)
	if script then
		if script.Disabled then
			print("[DIAGNOSE] ⚠️  Found DISABLED old script:", scriptName)
		else
			warn("[DIAGNOSE] ❌ Found ENABLED old script:", scriptName, "- MUST BE DISABLED/DELETED!")
		end
	end
end

-- Check for required scripts
local requiredScripts = {
	{name = "PokerGameServerMulti", type = "Script"},
	{name = "TableManager", type = "ModuleScript"},
	{name = "WinsLeaderstat", type = "Script"},
	{name = "CardOrientationFixerMulti", type = "Script"},
	{name = "QuickMatchServerV2", type = "Script"},
	{name = "WinStreakSystem", type = "Script"},
}

for _, scriptInfo in ipairs(requiredScripts) do
	local script = ServerScriptService:FindFirstChild(scriptInfo.name)
	if not script then
		warn("[DIAGNOSE] ❌ MISSING required script:", scriptInfo.name)
	elseif script.ClassName ~= scriptInfo.type then
		warn("[DIAGNOSE] ❌ Wrong type for", scriptInfo.name, "- Should be", scriptInfo.type, "but is", script.ClassName)
	elseif script:IsA("Script") and script.Disabled then
		warn("[DIAGNOSE] ❌", scriptInfo.name, "is DISABLED - must be ENABLED!")
	else
		print("[DIAGNOSE] ✅", scriptInfo.name, "found and correct")
	end
end

-- Check TableManager module
local success, TableManager = pcall(function()
	return require(ServerScriptService:WaitForChild("TableManager", 2))
end)

if success then
	print("[DIAGNOSE] ✅ TableManager module loads successfully")
	local tables = TableManager.getAllTables()
	local tableCount = 0
	for _ in pairs(tables) do
		tableCount = tableCount + 1
	end
	print("[DIAGNOSE] TableManager has", tableCount, "active tables")
else
	warn("[DIAGNOSE] ❌ TableManager module failed to load:", TableManager)
end

print("[DIAGNOSE] === DIAGNOSIS COMPLETE ===\n")