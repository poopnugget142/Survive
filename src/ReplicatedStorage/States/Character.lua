local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Stew = require(ReplicatedStorage.Packages.Stew)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)

local World = Stew.world()

local Module = {}

Module.Moving = World.tag("Moving")
Module.AutoRotate = World.tag("AutoRotate")
Module.LookAtMouse = World.tag("LookAtMouse")
Module.Baddie = World.tag("Baddie")

Module.Health = World.factory("Health", {
    add = function(Factory, Entity : any, Health : number)
        return {
            Max = Health
            ;Current = 1 --current health stored as alpha 0 -> 1, makes all health buffs retroactive
            ;Update = Signal.new()
            ;
        }
    end;

    remove = function(Factory, Entity : any)
        local HealthData = World.get(Entity).Health
        HealthData.Update:Destroy()
    end;

})

Module.Character = World.factory("Character", {
    add = function(Factory, Entity : any)
        local Character = World.get(Entity).Model

        CollectionService:AddTag(Character, "Character")

        return true
    end;

    remove = function(Factory, Entity : any)
        local Character = World.get(Entity).Model

        CollectionService:RemoveTag(Character, "Character")
    end;
})

Module.WalkSpeed = World.factory("WalkSpeed", {
    add = function(Factory, Entity : Model, WalkSpeed : number)
        return {
            Base = WalkSpeed
            ;Current = WalkSpeed   
        }
    end;
})

Module.Model = World.factory("Model", {
    add = function(Factory, Entity : any, Model : any)
        return Model
    end;

    remove = function(Factory, Entity : any)
        local Model = World.get(Entity).Model
        Model:Destroy()
    end;
})

Module.NPC = World.factory("NPC", {
    add = function(Factory, Entity : any, NpcId : number)
        local Character = World.get(Entity).Model

        --This is temp until we get k trees up
        if Character and RunService:IsServer() then
            CollectionService:AddTag(Character, "NPC")
        end

        return NpcId
    end;

    remove = function(Factory, Entity : any)
        local Character = World.get(Entity).Model

        if Character then
            CollectionService:RemoveTag(Character, "NPC")
        end
    end;
})

Module.NPCType = World.factory("NPCType", {
    add = function(Factory, Entity : any, NpcType : number)
        return NpcType
    end;
})

--// Status Effects

Module.Crippled = World.factory("Crippled", {
    add = function(Factory, Entity : Model, SlowFactor : number)
        if (World.get(Entity).WalkSpeed == nil) then return false end
        Promise.try(function(resolve, reject, onCancel)
            while true do
                local deltaTime = task.wait()
                local EntityData = World.get(Entity)
                if (EntityData.WalkSpeed == nil) then continue end
                EntityData.WalkSpeed.Current = EntityData.WalkSpeed.Base * (1-EntityData.Crippled)
                EntityData.Crippled -= deltaTime/5
                EntityData.Crippled = math.clamp(EntityData.Crippled, 0, 1)

                if (EntityData.Crippled <= 0) then
                    break
                end
            end
            
            Module.Crippled.remove(Entity)
            --resolve()
        end)
        return SlowFactor
    end;

    --[[
    remove = function(Factory, Entity : Model, SlowFactor : number)
        if (World.get(Entity).WalkSpeed == nil) then return false end

        World.get(Entity).WalkSpeed /= 1-SlowFactor
        return true
    end;
    ]]
})

Module.Burning = World.factory("Burning", {
    add = function(Factory, Entity : Model, Damage : number)
        if (World.get(Entity).Health == nil) then return false end

        local fire = Instance.new("Fire")
        fire.Parent = Entity.PrimaryPart
        fire.Heat = 14

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
                fire.Size = EntityData.Burning*0.1
                print(EntityData.Health.Current)
                print(EntityData.Burning)

                if (EntityData.Burning <= 0) then
                    break
                end
            end
            
            fire:Destroy()
            Module.Burning.remove(Entity)
            --resolve()
        end)
        return Damage
    end;
})










Module.World = World

return Module