local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)

return function (context)
    local Enemies = workspace.Characters.Baddies:GetChildren()
    for _, enemy in Enemies do
        CharacterStates.World.kill(enemy)
        enemy:Destroy()
    end
end