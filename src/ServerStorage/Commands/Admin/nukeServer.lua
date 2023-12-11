local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.Scripts

local CharacterStates = require(ReplicatedScripts.States.Character)
local Enums = require(ReplicatedScripts.Registry.Enums)
local CharacterModule = require(ReplicatedScripts.Class.Character)

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