local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local CharacterAssets = Assets.Characters

local Enums = require(ReplicatedStorage.Scripts.Enums)

local Module = {}

local BaddieModels = {
    [Enums.NPC.Guy] = CharacterAssets.Nasty;
    [Enums.NPC.Gargoyle] = CharacterAssets.Gargoyle;
}

Module.GetBaddieModel = function(BaddieEnum : number)
    assert(BaddieModels[BaddieEnum], "BaddieEnum "..BaddieEnum.." has no model")

    return BaddieModels[BaddieEnum]
end

--Defines the distance for a npc to be considered close to another one and move away
local NearbyNpcDistance = {
    [Enums.NPC.Guy] = 3;
}

Module.GetNearbyNpcDistance = function(BaddieEnum : number)
    assert(NearbyNpcDistance[BaddieEnum], "BaddieEnum "..BaddieEnum.." has no nearby npc distance")

    return NearbyNpcDistance[BaddieEnum]
end

local AttackRange = {
    [Enums.NPC.Guy] = 10;
    [Enums.NPC.Gargoyle] = 10;
}

Module.GetAttackRange = function(BaddieEnum : number)
    assert(AttackRange[BaddieEnum], "BaddieEnum "..BaddieEnum.." has no attack range")

    return AttackRange[BaddieEnum]
end

return Module