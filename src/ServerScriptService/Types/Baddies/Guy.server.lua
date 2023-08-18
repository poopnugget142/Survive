local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)

CharacterStates[Enums.Baddies.Guy] = CharacterStates.World.factory(Enums.Baddies.Guy, {
    add = function(Factory, Entity : Model)
        local HealthData = CharacterStates.Health.add(Entity, 100)

        CollectionService:AddTag(Entity, "Baddie")

        return true
    end
})