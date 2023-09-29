local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local CharacterAssets = Assets.Characters

local Enums = require(ReplicatedStorage.Scripts.Enums)

local Module = {}

local BaddieModels = {
    [Enums.NPC.Guy] = CharacterAssets.Nasty;
    [Enums.NPC.Gargoyle] = CharacterAssets.Gargoyle;
    [Enums.NPC.Big] = CharacterAssets.Big;
}

Module.GetBaddieModel = function(BaddieEnum : number)
    assert(BaddieModels[BaddieEnum], "BaddieEnum "..BaddieEnum.." has no model")

    return BaddieModels[BaddieEnum]
end

--Defines the distance for a npc to be considered close to another one and move away
local NearbyNpcDistance = {
    [Enums.NPC.Guy] = 1.5;
    [Enums.NPC.Big] = 4
}

Module.GetNearbyNpcDistance = function(BaddieEnum : number)
    --assert(NearbyNpcDistance[BaddieEnum], "BaddieEnum "..BaddieEnum.." has no nearby npc distance")

    return NearbyNpcDistance[BaddieEnum]
end

local Mass = {
    [Enums.NPC.Guy] = 1;
    [Enums.NPC.Big] = 10
}

Module.GetMass = function(BaddieEnum : number)
    --assert(Mass[BaddieEnum], "BaddieEnum "..BaddieEnum.." has no mass")

    return Mass[BaddieEnum]
end

local AttackRange = {
    [Enums.NPC.Guy] = 10;
    [Enums.NPC.Gargoyle] = 10;
    [Enums.NPC.Big] = 10
}

Module.GetAttackRange = function(BaddieEnum : number)
    assert(AttackRange[BaddieEnum], "BaddieEnum "..BaddieEnum.." has no attack range")

    return AttackRange[BaddieEnum]
end

return Module