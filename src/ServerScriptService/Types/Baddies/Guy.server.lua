local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

CharacterStates.Component.Build("Guy", {
    Constructor = function(Entity : any, Name : string)
        CollectionService:AddTag(Entity, "Baddie")

        return true
    end
})