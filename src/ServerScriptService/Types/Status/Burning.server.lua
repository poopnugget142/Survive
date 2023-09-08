local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

local Promise = require(ReplicatedStorage.Packages.Promise)

local World = CharacterStates.World

CharacterStates.Burning = World.factory("Burning", {
    add = function(Factory, Entity : Model, Damage : number)
        if (World.get(Entity).Health == nil) then return false end

        --local fire = Instance.new("Fire")
        --fire.Parent = Entity.PrimaryPart
        --fire.Heat = 14

        Promise.try(function(resolve, reject, onCancel)
            while true do
                local deltaTime = task.wait()
                local EntityData = World.get(Entity)
                if (EntityData.Health == nil) then continue end
                --Module.UpdateHealth(Entity, -EntityData.Burning*deltaTime)
                EntityData.Health.Current -= ((EntityData.Burning+1)*deltaTime)/EntityData.Health.Max --damage
                EntityData.Health.Update:Fire()
                if EntityData.Burning == nil then break end --quit if the entity died
                EntityData.Burning -= math.max(
                    (EntityData.Burning+0.5) * deltaTime --Burn falloff is a derivation of x(x+1)/2 --> x+1/2
                    ,0
                )
                --fire.Size = (EntityData.Burning)^0.5
                --print(EntityData.Health.Current)
                --print(EntityData.Burning)

                if (EntityData.Burning <= 0) then
                    break
                end
            end
            
            --fire:Destroy()
            CharacterStates.Burning.remove(Entity)
            --resolve()
        end)
        return Damage
    end;
})