local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Stew = require(ReplicatedStorage.Packages.Stew)
local Signal = require(ReplicatedStorage.Packages.Signal)

local World = Stew.world()

local Module = {}

Module.Moving = World.tag("Moving")
Module.AutoRotate = World.tag("AutoRotate")

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
})

Module.Baddie = World.factory("Baddie", {
    add = function(Factory, Entity : Model)
        CollectionService:AddTag(Entity, "Baddie")

        return true
    end;
})

Module.World = World

return Module