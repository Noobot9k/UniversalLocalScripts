-- Developed by Noobot9k

RunService = game:GetService("RunService")
if RunService:IsServer() then error(script:GetFullName() .. " cannot be run on the server.", 1) end

local module = {}
module.Environment = script.Environment

-- The key of each entry in module.RunningScripts is the original script and the value is the duplicate.
-- Example: module.RunningScripts[workspace.LocalScript] = Environment.LocalScript
-- Original, Duplicate
module.RunningScripts = { }

function module.StopLocalScript(localScript)
	local FoundDuplicate = module.RunningScripts[localScript]
	if FoundDuplicate then -- passed localScript is the original.
		FoundDuplicate:Destroy()
		module.RunningScripts[localScript] = nil
	else
		-- DONE! TODO fix the below line lol
		local FoundOriginal = module.GetOriginal(localScript, true) --table.find(module.RunningScripts, localScript)
		if FoundOriginal then -- passed localScript is the duplicate.
			module.RunningScripts[FoundOriginal] = nil
			localScript:Destroy()
		end
	end
end
function module.RunLocalScript(localScript : LocalScript)
	--print("Cloning and running", localScript:GetFullName())
	module.StopLocalScript(localScript)
	
	--[[
		it's easier to start using a module like ULC if it doesn't break too much existing code.
		Trying to run any LocalScript in the workspace such as LocalScripts in dropped tools could break things.
		It's best to only run scripts designed with the intention of using ULC.
	]]
	if localScript:GetAttribute("DontRunUniversally") == nil and localScript:GetAttribute("RunUniversally") == nil then return end
	if localScript:GetAttribute("DontRunUniversally") then return end -- old attribute name support.
	if localScript:GetAttribute("RunUniversally") == false then return end
	
	if localScript:FindFirstAncestorOfClass("Actor") then
		warn("UniversalLocalScripts does not work with Parallel LUAU.", localScript:GetFullName(), "is in an Actor but will just run as if it's not. task.desynchronize() will not work within this script.")
	end
	
	local ClonedScript = localScript:Clone()
	ClonedScript.Name = localScript:GetFullName()
	ClonedScript.Disabled = localScript.Disabled
	ClonedScript:ClearAllChildren()
	module.RunningScripts[localScript] = ClonedScript
	ClonedScript.Parent = module.Environment
	
	localScript.AncestryChanged:Connect(function(_, NewAncestor)
		if not NewAncestor then
			module.StopLocalScript(localScript)
		end
	end)
	-- This was excessive
	--localScript.Changed:Connect(function(PropertyChanged)
	--	print(PropertyChanged, localScript[PropertyChanged])
	--	if PropertyChanged ~= "Parent" then
	--		ClonedScript[PropertyChanged] = localScript[PropertyChanged]
	--	end
	--end)
	localScript:GetPropertyChangedSignal("Disabled"):Connect(function()
		ClonedScript.Disabled = localScript.Disabled
	end)
end
function module.CheckIfRunning(localScript)
	local FoundDuplicate = module.RunningScripts[localScript]
	--print("Is", localScript, "running?		", FoundDuplicate)
	if FoundDuplicate then return true else return false end
end
--function module.GetOriginal(Duplicate)
--	local FoundOriginal = table.find(module.RunningScripts, Duplicate)
--	if not FoundOriginal then error(Duplicate:GetFullName() .. " is not being run by UniversalLocalScripts at the moment.", 2) end
--	-- TODO this probably shouldn't throw an exception and instead just return Duplicate. Make it still warn though.
--	return FoundOriginal
--end
function module.GetOriginal(targetDuplicate, _silent) -- TODO this can be vastly improved performance-wise.
	if _silent == nil then _silent = true end
	
	for Original, Duplicate in pairs(module.RunningScripts) do
		if Duplicate == targetDuplicate then
			return Original
		end
	end
	
	if not _silent then warn(targetDuplicate:GetFullName() .. " is not being run by UniversalLocalScripts at the moment. Returning nil.") end
	return nil --targetDuplicate
	
	--error(targetDuplicate:GetFullName() .. " is not being run by UniversalLocalScripts at the moment.", 2)
	-- DONE! TODO this probably shouldn't throw an exception and instead just return targetDuplicate or nil. Make it still warn though.
end
function module.HasAuthority(localScript)
	local LocalPlayer = game.Players.LocalPlayer
	return localScript:IsDescendantOf(LocalPlayer)
		or (LocalPlayer.Character
			and ( localScript:IsDescendantOf(LocalPlayer.Character) or localScript == LocalPlayer.Character) ) 
end
function module.GetAuthoritativePlayer(localScript : LocalScript) : Player?
	local authorityPlayer = localScript:FindFirstAncestorOfClass("Player")
	
	if not authorityPlayer then
		for i, player in ipairs(game.Players:GetPlayers()) do
			if not player.Character then continue end
			if not localScript:IsDescendantOf(player.Character) then continue end
			
			authorityPlayer = player
			break
		end
	end
	
	return authorityPlayer -- or game.Players.LocalPlayer
	--[[ I worry returning LocalPlayer could cause confusion.
		LocalPlayer will only be returned if we're either their decendant or their character's decendant.]]
end

return module
