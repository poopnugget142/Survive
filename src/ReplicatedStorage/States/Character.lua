local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Stew = require(ReplicatedStorage.Packages.Stew)
local Util = require(ReplicatedStorage.Scripts.Util)

local World = Stew.World.Create()

World.Component.Build("Moving")
World.Component.Build("AutoRotate")

World.Component.Build("Health", {
    Constructor = Util.EasyStewReturn;
})

World.Component.Build("Character", {
    Constructor = function(Entity : Model, Name : string)
        CollectionService:AddTag(Entity, "Character")

        return true
    end;
})

World.Component.Build("Baddie", {
    Constructor = function(Entity : Model, Name : string)
        CollectionService:AddTag(Entity, "Baddie")

        return true
    end;
})

return World