UniversalLocalScripts
========================

UniversalLocalScripts is a module that allows Roblox LocalScripts to run in locations like the workspace, including the currentCamera and other player's characters.

### Why run local scripts in the workspace?

In other popular game engines -- such as Unity and Godot -- scripts will run regardless of what object they're attached to. This can make keeping code organized easier as any code relevant to an object and that operates on that object will likely be attached to it or decended from it instead of sitting in some random folder like StarterPlayerScripts.

#### Example

Imagine you want to make a particle effect play at a character's feet when they jump. Seems easy, right? 

First, have a server script weld a part to the player's HumanoidRootPart close to where their feet are

```lua
-- located in game.StarterPlayer.StarterCharacterScripts

local part = script.Part
part.Parent = script.Parent
part.LocalScript.Enabled = true

local weld = Instance.new("Weld")
weld.C1 = CFrame.new(0,-2.5,0)
weld.Part0 = part
weld.Part1 = script.Parent:WaitForChild("HumanoidRootPart")
weld.Parent = part

game.Debris:AddItem(script)

--[[
	Remember to make the part cancollide false and massless in the properties window.
]]
```

 give the part a particle emitter, and write a LocalScript to activate the particles

```lua
-- located in the part

local part = script.Parent
local particles = part:WaitForChild("ParticleEmitter")
local character = part.Parent
local humanoid : Humanoid = character:WaitForChild("Humanoid")

humanoid.Jumping:Connect(function()
	particles:Emit(3)
end)
```

And just like that, you have particles appear at your feet when you jump! But there's a problem: when another player connects, you don't see the particles appear on them when they jump. You only see them on your own character.

How do you fix this?

Well, you know how intuitive it was to place the script for your character's jumping particles somewhere in StarterCharacterScripts so there would be one of this script in everyone's character? Well fixing this the usual way without UniversalLocalScripts requires you to do away with that and instead place a LocalScript somewhere like StarterPlayerScripts with some code like this:

```lua
function monitorCharacter(character : Model)
	local part = character:WaitForChild("Part")
	local particles = part:WaitForChild("ParticleEmitter")
	local humanoid : Humanoid = character:WaitForChild("Humanoid")

	humanoid.Jumping:Connect(function()
		particles:Emit(3)
	end)
end

function monitorPlayer(player : Player)
	player.CharacterAdded:Connect(monitorCharacter)
	if player.Character then monitorCharacter(player.Character) end
end

game.Players.PlayerAdded:Connect(monitorPlayer)
for i, player in ipairs(game.Players:GetPlayers()) do
	monitorPlayer(player)
end
```
But this is somewhat awkward. With UniversalLocalScripts however we don't really need to modify much at all from the original example with the LocalScript copied into everyone's characters via StarterCharacterScripts! All we need to do is insert the UniversalLocalScripts module into ReplicatedFirst and add the following code to the top of the LocalScript:

```lua
local UniversalLocalScripts = require(game.ReplicatedFirst.UniversalLocalScripts)
local script = UniversalLocalScripts.GetOriginal(script) or script
local HasAuthority = UniversalLocalScripts.GetAuthoritativePlayer(script) == game.Players.LocalPlayer
```

And just like that the particles work for the local player's character as well as everybody else's character! It even would work unmodified for NPCs!

#### is pasting those 3 lines of code over and over a pain?

Not with the Roblox Studio plugin that I made. [Check out Default LocalScript changer](https://create.roblox.com/store/asset/6708420842/Default-LocalScript-changer)(source code coming soon). It's inteligent enough to only put in the needed lines of code in places a LocalScript would need them to run (such as when you create a new LocalScript in the workspace or StarterCharacterScripts and leave them out when created elsewhere. An added feature of this plugin is that you can customize the default contents of LocalScripts to be whatever you want! Just in case you want a little more than just `Print("Hello World!")`.

## Setup

1.)

1.a) If you're using Rojo, you can clone this repository. [Rojo](https://github.com/rojo-rbx/rojo) 7.4.1.

1.b) If you're just working in Roblox Studio, you can insert [this package](https://create.roblox.com/store/asset/16890358871/UniversalLocalScripts-v20) into ReplicatedFirst.

2.) Select the ModuleScript in ReplicatedFirst called UniversalLocalScripts and configure its attributes to your liking.

3.) Add the following code to the top of any LocalScripts that wouldn't normally run without UniversalLocalScripts but will now such as those in the workspace or StarterCharacterScripts:

```lua
local UniversalLocalScripts = require(game.ReplicatedFirst.UniversalLocalScripts)
local script = UniversalLocalScripts.GetOriginal(script) or script
local HasAuthority = UniversalLocalScripts.GetAuthoritativePlayer(script) == game.Players.LocalPlayer
```

If you don't want to manually do that every time, consider installing the [Default LocalScript changer Studio plugin](https://create.roblox.com/store/asset/6708420842/Default-LocalScript-changer) to auto-add this code to the top of all LocalScripts you create in the workspace/StarterCharacterScripts.

And that's it!