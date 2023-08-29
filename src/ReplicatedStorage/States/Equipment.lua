local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stew = require(ReplicatedStorage.Packages.Stew)
local Util = require(ReplicatedStorage.Scripts.Util)

local World = Stew.world()

local Module = {}

Module.Shooting = World.tag("Shooting")

Module.Name = World.factory("Name", {
    add = Util.EasyStewReturn;
})

Module.ItemID = World.factory("ItemID", {
    add = Util.EasyStewReturn;
})

Module.Model = World.factory("Model", {
    add = Util.EasyStewReturn;

    remove = function(Factory, Entity : any)
        local Model = World.Component.Get(Entity, "Model")

        Model:Destroy()
    end
})

Module.Owner = World.factory("Owner", {
    add = Util.EasyStewReturn;
})

--Creates a temporary model that will be destroyed once the server loads its version
Module.LoadingItem = World.factory("LoadingItem", {
    add = function(Factory, Entity : any, Model : Instance)

        Module.Model.add(Entity, Model)

        return Model
    end;

    remove = function(Factory, Entity : any, NewModel : Instance)
        Module.Model.remove(Entity)
        
        Module.Model.add(Entity, NewModel)
    end;
})

Module.LoadingConnections = World.factory("LoadingConnections", {
    add = Util.EasyStewReturn;

    remove = function(Factory, Entity : any, NewModel : Instance)
        local LoadingConnections = World.get(Entity).LoadingConnections

        for _, Connection : RBXScriptConnection in LoadingConnections do
            Connection:Disconnect()
        end
    end;
})

Module.World = World

return Module