local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Stew = require(ReplicatedStorage.Packages.Stew)
local Signal = require(ReplicatedStorage.Packages.Signal)

local World = Stew.world()

local Module = {}

Module.Moving = World.tag("Moving")
Module.AutoRotate = World.tag("AutoRotate")
Module.LookAtMouse = World.tag("LookAtMouse")

Module.Health = World.factory("Health", {
    add = function(Factory, Entity : Model, Health : number)
        return {
            Current = Health;
            Update = Signal.new();
        }
    end;

    remove = function(Factory, Entity : Model)
        local HealthData = World.get(Entity).Health
        HealthData.Update:Destroy()
    end;
})

Module.Character = World.factory("Character", {
    add = function(Factory, Entity : Model)
        CollectionService:AddTag(Entity, "Character")

        return true
    end;

    remove = function(Factory, Entity : Model)
        CollectionService:RemoveTag(Entity, "Character")
    end;
})

Module.MovementData = World.factory("MovementData", {
    add = function(Factory, Entity : Model)
        return {
            MoveDirection =  Vector3.new()
            ;LookDirection = Vector3.new()
            ;travel = Vector3.new()
            ;Velocity = Vector3.new()
            ;Acceleration = Vector3.new()
            ;AccumulatedTime = 0
        }
    end;
})

Module.WalkSpeed = World.factory("WalkSpeed", {
    add = function(Factory, Entity : Model, WalkSpeed : number)
        return WalkSpeed
    end;
})

Module.Baddie = World.factory("Baddie", {
    add = function(Factory, Entity : Model)
        CollectionService:AddTag(Entity, "Baddie")

        return true
    end;

    remove = function(Factory, Entity : Model)
        CollectionService:RemoveTag(Entity, "Baddie")
    end;
})

Module.World = World

return Module