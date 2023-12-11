local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.Scripts

local CharacterModule = require(ReplicatedScripts.Class.Character)
local Enums = require(ReplicatedScripts.Registry.Enums)

return function (context, Type, Amount)
    local NPCEnum = Enums.NPC[Type]

    if not NPCEnum then
        error("what the heck, where is ze enemy")
    end

    for i = 1, Amount do
        CharacterModule.CreateNPC(NPCEnum, Vector3.new(20, 0.5, 20))

        task.wait()
    end
end