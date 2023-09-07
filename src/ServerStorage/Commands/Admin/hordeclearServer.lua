local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)

return function (context)
    local Enemies = workspace.Characters.NPCs:GetChildren()
    for _, enemy in Enemies do
        local Entity = CharacterModule.GetEntityFromCharacter(enemy)
        CharacterStates.World.kill(Entity)
    end
end