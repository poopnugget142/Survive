local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Stew = require(ReplicatedStorage.Packages.Stew)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Enums =  require(ReplicatedStorage.Scripts.Enums)

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
        return NpcId
    end;
})

Module.NPCType = World.factory("NPCType", {
    add = function(Factory, Entity : any, NpcType : number)
        return NpcType
    end;
})

Module.State = World.factory("State", {
    add = function(Factory, Entity : any, State : number)
        return State
    end;
})

Module.LoadedAnimations = World.factory("LoadedAnimations", {
    add = function(Factory, Entity : any, Animations : any)
        return Animations
    end;
})

Module.CurrentAnimation = World.factory("CurrentAnimation", {
    add = function(Factory, Entity : any, Animation : AnimationTrack)
        return Animation
    end;
})

for _, StateEnum in Enums.States do
    Module[StateEnum] = World.tag(StateEnum)
end

--// Status Effects
--[[
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
})
]]

Module.World = World

return Module