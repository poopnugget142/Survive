local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)

return function (context)
    local Enemies = CharacterStates.World.query{CharacterStates[Enums.NPC.Guy]}
    --print(Enemies)
    for _, enemy in Enemies do
        --local Entity = CharacterModule.GetEntityFromCharacter(enemy)
        --CharacterStates.World.kill(Entity)
        enemy.Health.Current = 0
        enemy.Health.Update:Fire()
    end
end