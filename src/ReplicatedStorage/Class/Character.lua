local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

local Module = {}

--Returns the first ancestor Model of Object that has an "Character" tag, nil if none are found
Module.FindFirstCharacter = function(Object : Instance)
    if CollectionService:HasTag(Object, "Character") then return Object end

    local Ancestor = Object:FindFirstAncestorWhichIsA("Model")
    if not Ancestor then return end

    return Module.FindFirstCharacter(Ancestor)
end

Module.UpdateHealth = function(Character : Model, NewHealth : number)
    local HealthData = CharacterStates.World.get(Character).Health

    --HealthData.Current = NewHealth
    HealthData.Current += NewHealth/HealthData.Max --damage
    HealthData.Update:Fire()
end

return Module 