local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)

local Nasty : Model = ReplicatedStorage.Assets.Characters.Nasty:Clone()

task.wait()
CharacterStates.Character.add(Nasty)
CharacterStates.Baddie.add(Nasty)
CharacterStates[Enums.Baddies.Guy].add(Nasty)

Nasty.Parent = workspace.Characters.Baddies