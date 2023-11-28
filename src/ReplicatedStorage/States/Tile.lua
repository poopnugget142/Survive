local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stew = require(ReplicatedStorage.Packages.Stew)

local World = Stew.world()

local Module = {}

Module.World = World

--tile / priority components

Module.FrontierOpen = World.factory({
    add = function(_, Entity : any, Heat : number)
        return
        {
            Tile = Entity
            ,Heat = Heat
        }
    end;
})

Module.FrontierClosed = World.factory({
    add = function(_, Entity : any)
        return
        {
            Tile = Entity
        }
    end;
})

Module.NavData = World.factory({
    add = function(_, Entity : any, Cost : number)
        return
        {
            Tile = Entity
            ,Cost = Cost
            ,Heat = 0
        }
    end;
})

return Module