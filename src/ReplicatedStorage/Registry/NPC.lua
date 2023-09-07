local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local CharacterAssets = Assets.Characters

local Enums = require(ReplicatedStorage.Scripts.Enums)

local Module = {}

local BaddieModels = {
    [Enums.NPC.Guy] = CharacterAssets.Nasty;
}

Module.GetBaddieModel = function(BaddieEnum : number)
    assert(BaddieModels[BaddieEnum], "BaddieEnum "..BaddieEnum.." has no model")

    return BaddieModels[BaddieEnum]
end

return Module