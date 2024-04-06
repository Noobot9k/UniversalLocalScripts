
local UniversalLocalScriptsOBJ = script.Parent -- game.ReplicatedFirst.UniversalLocalScripts
local UniversalLocalScripts = require(UniversalLocalScriptsOBJ)
local LocalPlayer = game.Players.LocalPlayer

local ReparentEvents : {RBXScriptConnection} = {}

_SilencePlacementWarning = UniversalLocalScriptsOBJ:FindFirstChild("IgnoreReplicatedFirst")
if UniversalLocalScriptsOBJ.Parent ~= game.ReplicatedFirst and not _SilencePlacementWarning then
	warn(UniversalLocalScriptsOBJ:GetFullName() .. " ideally should be placed in game.ReplicatedFirst.")
	warn("To silence the above warning, create a empty folder named 'IgnoreReplicatedFirst' inside of '" .. UniversalLocalScriptsOBJ:GetFullName().."'.")
end

function CanRun(Obj)
	-- These two need to run first.
	if LocalPlayer.Character and (Obj:IsDescendantOf(LocalPlayer.Character) or Obj == LocalPlayer.Character) then return false end
	if LocalPlayer:FindFirstChildOfClass("Backpack") and Obj:IsDescendantOf(LocalPlayer.Backpack) then return false end
	
	-- local canRun = true
	-- if UniversalLocalScriptsOBJ:GetAttribute("RunInPlayerCharacters") then canRun = canRun or IsDecendantOfAPlayerCharacter(Obj) end
	-- if UniversalLocalScriptsOBJ:GetAttribute("RunInPlayerBackpacks") then canRun = canRun or IsDecendantOfAPlayerBackpack(Obj) end
	-- if UniversalLocalScriptsOBJ:GetAttribute("RunInCurrentCamera") then canRun = canRun or Obj:IsDescendantOf(workspace.CurrentCamera) end
	-- if UniversalLocalScriptsOBJ:GetAttribute("RunInWorkspace") then canRun = canRun or Obj:IsDescendantOf(workspace) or Obj == workspace end -- this needs to be last

	local RunInPlayerCharacters = UniversalLocalScriptsOBJ:GetAttribute("RunInPlayerCharacters")
	local RunInPlayerBackpacks = UniversalLocalScriptsOBJ:GetAttribute("RunInPlayerBackpacks")
	local RunInCurrentCamera = UniversalLocalScriptsOBJ:GetAttribute("RunInCurrentCamera")
	local RunInWorkspace = UniversalLocalScriptsOBJ:GetAttribute("RunInWorkspace")

	if IsDecendantOfAPlayerCharacter(Obj) 					then return RunInPlayerCharacters	end -- this needs to run before the RunInWorkspace check.
	if IsDecendantOfAPlayerBackpack(Obj) 					then return RunInPlayerBackpacks 	end
	if Obj:IsDescendantOf(workspace.CurrentCamera) 			then return RunInCurrentCamera 		end -- this needs to run before the RunInWorkspace check.
	if Obj:IsDescendantOf(workspace) or Obj == workspace 	then return RunInWorkspace 			end -- this needs to be last.
	
	return false
end
function MonitorReparenting(localScript)
	if ReparentEvents[localScript] then ReparentEvents[localScript]:Disconnect() end
	ReparentEvents[localScript] = localScript.AncestryChanged:Connect(function(reparentedObj: Instance, newParent: Instance)
		if CanRun(reparentedObj) then return end
		if ReparentEvents[localScript] then ReparentEvents[localScript]:Disconnect() end

		UniversalLocalScripts.StopLocalScript(localScript)
	end)
end
function RunLocalScriptsRecursive(scope : Instance, _run)
	if _run == nil then _run = true end
	if _run and not CanRun(scope) then return end
	
	if scope:IsA("LocalScript") then
		if _run then
			if not UniversalLocalScripts.CheckIfRunning(scope) then
				UniversalLocalScripts.RunLocalScript(scope)
				
				MonitorReparenting(scope)
			end
		else
			if UniversalLocalScripts.CheckIfRunning(scope) then
				UniversalLocalScripts.StopLocalScript(scope)
			end
		end
	end
	for i, child in ipairs(scope:GetChildren()) do
		RunLocalScriptsRecursive(child, _run)
	end
end
function IsDecendantOfAPlayerCharacter(Obj)
	for i, player in ipairs(game.Players:GetPlayers()) do
		local character = player.Character
		if character and character:IsDescendantOf(workspace) then
			local IsDecendant = Obj:IsDescendantOf(player.Character) or Obj == player.Character
			if IsDecendant then return true end
		end
	end
	return false
end
function IsDecendantOfAPlayerBackpack(Obj : LocalScript)
	local backpack = Obj:FindFirstAncestorOfClass("Backpack")
	return backpack and backpack.Parent and backpack.Parent:IsA("Player")
	
	--for i, player in ipairs(game.Players:GetPlayers()) do
	--	if not player:FindFirstChildOfClass("Backpack") then continue end
		
	--	local IsDecendant = Obj:IsDescendantOf(player.Backpack) or Obj == player.Backpack
	--	if IsDecendant then return true end
	--end
	--return false
end
function RefreshCurrentCamera()
	--[[currently the enabled spaces for ULS are not either-or, so scripts should only run in these locations
		if RunInCurrentCamera or RunInPlayerCharacters are true, even though they're technically in the workspace and RunInWorkspace may be true]]
	RunLocalScriptsRecursive(workspace.CurrentCamera, UniversalLocalScriptsOBJ:GetAttribute("RunInCurrentCamera")) -- or UniversalLocalScriptsOBJ:GetAttribute("RunInWorkspace"))
end
function RefreshPlayerCharacters()
	for i, player in ipairs(game.Players:GetPlayers()) do
		if player.Character and player.Character:IsDescendantOf(workspace) then else continue end
		RunLocalScriptsRecursive(player.Character, UniversalLocalScriptsOBJ:GetAttribute("RunInPlayerCharacters") or UniversalLocalScriptsOBJ:GetAttribute("RunInWorkspace"))
	end
end
function RefreshPlayerBackpacks()
	for i, player in ipairs(game.Players:GetPlayers()) do
		local backpack = player:FindFirstChildOfClass("Backpack")
		if not backpack then continue end
		
		RunLocalScriptsRecursive(backpack, UniversalLocalScriptsOBJ:GetAttribute("RunInPlayerBackpacks"))
	end
end
function RefreshWorkspace()
	for i, child in ipairs(workspace:GetChildren()) do
		
		--[[currently the enabled spaces for ULS are not either-or, so scripts should only run in these locations
			if RunInCurrentCamera or RunInPlayerCharacters are true, even though they're technically in the workspace and RunInWorkspace may be true]]
		if child == workspace.CurrentCamera then continue end
		if game.Players:GetPlayerFromCharacter(child) then continue end
		
		RunLocalScriptsRecursive(child, UniversalLocalScriptsOBJ:GetAttribute("RunInWorkspace"))
	end
end

function RuntimeAttributeChangedWarning()
	warn("UniversalLocalScripts Attributes should not be changed at runtime and may cause unpredictable results.")
end
UniversalLocalScriptsOBJ:GetAttributeChangedSignal("RunInCurrentCamera"):Connect(RuntimeAttributeChangedWarning)
UniversalLocalScriptsOBJ:GetAttributeChangedSignal("RunInPlayerCharacters"):Connect(RuntimeAttributeChangedWarning)
UniversalLocalScriptsOBJ:GetAttributeChangedSignal("RunInPlayerBackpacks"):Connect(RuntimeAttributeChangedWarning)
UniversalLocalScriptsOBJ:GetAttributeChangedSignal("RunInWorkspace"):Connect(RuntimeAttributeChangedWarning)
--UniversalLocalScriptsOBJ:GetAttributeChangedSignal("RunInCurrentCamera"):Connect(RefreshCurrentCamera)
--UniversalLocalScriptsOBJ:GetAttributeChangedSignal("RunInPlayerCharacters"):Connect(RefreshPlayerCharacters)
--UniversalLocalScriptsOBJ:GetAttributeChangedSignal("RunInPlayerBackpacks"):Connect(RefreshPlayerBackpacks)
--UniversalLocalScriptsOBJ:GetAttributeChangedSignal("RunInWorkspace"):Connect(RefreshWorkspace)

function decendantAdded(NewDecendant)
	if not NewDecendant:IsA("LocalScript") then return end
	if not CanRun(NewDecendant) then return end
	if UniversalLocalScripts.CheckIfRunning(NewDecendant) then return end

	UniversalLocalScripts.RunLocalScript(NewDecendant)
	MonitorReparenting(NewDecendant)
end
workspace.DescendantAdded:Connect(decendantAdded)

function MonitorPlayer(player : Player)
	player.ChildAdded:Connect(function(newChild : Instance)
		if newChild:IsA("Backpack") then
			newChild.DescendantAdded:Connect(decendantAdded)
			
			if UniversalLocalScriptsOBJ:GetAttribute("RunInPlayerBackpacks") then
				RunLocalScriptsRecursive(newChild, true)
			end
		end
	end)
end
game.Players.PlayerAdded:Connect(MonitorPlayer)
for i, player in ipairs(game.Players:GetPlayers()) do MonitorPlayer(player) end

RunLocalScriptsRecursive(workspace, true)
RefreshPlayerBackpacks()


-- Testing
--print("Workspace",CanRun(workspace:WaitForChild("Baseplate")))
--repeat wait() until LocalPlayer.Character ~= nil
--print("PlayerCharacter", CanRun(LocalPlayer.Character))
--print("CurrentCam",CanRun(workspace.CurrentCamera:WaitForChild("TESTOBJ")))