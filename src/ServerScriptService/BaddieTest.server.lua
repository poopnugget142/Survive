local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

local Nasty : Model = ReplicatedStorage.Assets.Characters.Nasty:Clone()

CharacterStates.Component.Create(Nasty, "Character")
CharacterStates.Component.Create(Nasty, "Baddie")

Nasty.Parent = workspace.Characters.Baddies