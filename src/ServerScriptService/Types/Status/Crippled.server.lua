local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

local Promise = require(ReplicatedStorage.Packages.Promise)

local World = CharacterStates.World

CharacterStates.Crippled = World.factory("Crippled", {
    add = function(Factory, Entity : Model, SlowFactor : number)
        if (World.get(Entity).WalkSpeed == nil) then return false end
        Promise.try(function(resolve, reject, onCancel)
            while true do
                local deltaTime = task.wait()
                local EntityData = World.get(Entity)
                if (EntityData.WalkSpeed == nil) then continue end
                CharacterModule.UpdateSpeed(Entity, EntityData.WalkSpeed.Base * (1-EntityData.Crippled))

                EntityData.Crippled -= deltaTime/5
                EntityData.Crippled = math.clamp(EntityData.Crippled, 0, 1)

                if (EntityData.Crippled <= 0) then
                    break
                end
            end
            
            CharacterStates.Crippled.remove(Entity)
            --resolve()
        end)
        return SlowFactor
    end;
})