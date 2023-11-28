local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Stew = require(ReplicatedStorage.Packages.Stew)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Enums =  require(ReplicatedStorage.Scripts.Enums)

local World = Stew.world()

local Module = {}

Module.Moving = World.tag()
Module.AutoRotate = World.tag()
Module.LookAtMouse = World.tag()
Module.Baddie = World.tag()

for _, StateEnum in Enums.States do
    Module[StateEnum] = World.tag()
end

Module.Health = World.factory({
    add = function(Factory, Entity : any, Health : number)
        return {
            Max = Health
            ;Current = 1 --current health stored as alpha 0 -> 1, makes all health buffs retroactive
            ;Update = Signal.new()
            ;
        }
    end;

    remove = function(Factory, Entity : any)
        local HealthData = World.get(Entity)
        HealthData.Update:Destroy()
    end;

})

Module.Character = World.factory({
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

Module.WalkSpeed = World.factory({
    add = function(Factory, Entity : Model, WalkSpeed : number)
        return {
            Base = WalkSpeed
            ;Current = WalkSpeed   
        }
    end;
})

Module.Model = World.factory({
    add = function(Factory, Entity : any, Model : any)
        return Model
    end;

    remove = function(Factory, Entity : any)
        local Model = World.get(Entity).Model
        Model:Destroy()
    end;
})

Module.NPCId = World.factory({
    add = function(Factory, Entity : any, NpcId : number)
        return NpcId
    end;
})

Module.NPCType = World.factory({
    add = function(Factory, Entity : any, NpcType : number)
        return NpcType
    end;
})

Module.State = World.factory({
    add = function(Factory, Entity : any, State : number)
        return State
    end;
})

Module.LoadedAnimations = World.factory({
    add = function(Factory, Entity : any, Animations : any)
        return Animations
    end;
})

Module.CurrentAnimation = World.factory({
    add = function(Factory, Entity : any, Animation : AnimationTrack)
        return Animation
    end;
})

Module.IKControllers = World.factory({
    add = function(Factory, Entity : any, IKControllers : any)
        return IKControllers
    end;
})

Module.World = World

return Module