local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)

return function (context, Amount)
    for i = 1, Amount do
        CharacterModule.CreateNPC(Enums.NPC.Guy, Vector3.new(20, 0.5, 20))

        task.wait()
    end
end