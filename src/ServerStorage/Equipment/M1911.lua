local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EquipmentStates = require(ReplicatedStorage.Scripts.States.Equipment)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)

local Module = {}

Module.Create = function(Entity)
    
end

Module.LoadModel = function(Entity)
    
end

--In the future we can check if this really hit but for now we trust it
Module.Attack = function(Entity, HitCharacter)
    local HitData = CharacterStates.World.get(HitCharacter)

    if not HitData.Character then return end

    local CurrentHealth = HitData.Health.Current

    CharacterModule.UpdateHealth(HitCharacter, CurrentHealth-100)
end

return Module