local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stew = require(ReplicatedStorage.Packages.Stew)

local World = Stew.world()

local Module = {}

Module.World = World

--tile / priority components

Module.FrontierOpen = World.factory("FrontierOpen", {
    add = function(_, Entity : any, Heat : number)
        return
        {
            tile = Entity
            ,heat = Heat
        }
    end;
})

Module.FrontierClosed = World.factory("FrontierClosed", {
    add = function(_, Entity : any)
        return
        {
            tile = Entity
        }
    end;
})

Module.NavData = World.factory("NavData", {
    add = function(_, Entity : any, Cost : number)
        return
        {
            tile = Entity
            ,cost = Cost
            ,heat = 0
        }
    end;
})

return Module