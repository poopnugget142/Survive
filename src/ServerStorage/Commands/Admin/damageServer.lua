local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)

--Later lets just this apply to the thing your mouse is on
return function (context, Player, Amount)
    local Model = Player.Character

    if not Model then return end

    local Entity = CharacterModule.GetEntityFromCharacter(Model)

    if not Entity then return end

    CharacterModule.UpdateHealth(Entity, -Amount)
end