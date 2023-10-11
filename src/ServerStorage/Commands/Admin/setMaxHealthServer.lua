local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

--Later lets just this apply to the thing your mouse is on
return function (context, Player, Amount)
    local Model = Player.Character

    if not Model then return end

    local Entity = CharacterModule.GetEntityFromCharacter(Model)

    if not Entity then return end

    local EntityData = CharacterStates.World.get(Entity)
    local HealthData = EntityData.Health

    HealthData.Max = Amount
end