local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stew = require(ReplicatedStorage.Packages.Stew)
local Util = require(ReplicatedStorage.Scripts.Util)

local World = Stew.World.Create()

World.Component.Build("Name", {
    Constructor = Util.EasyStewReturn;
})

World.Component.Build("ItemID", {
    Constructor = Util.EasyStewReturn;
})

World.Component.Build("Model", {
    Constructor = Util.EasyStewReturn;

    Destructor = function(Entity : any, StewName : string)
        local Model = World.Component.Get(Entity, "Model")

        Model:Destroy()
    end;
})

World.Component.Build("Owner", {
    Constructor = Util.EasyStewReturn;
})

World.Component.Build("CastBehavior", {
    Constructor = Util.EasyStewReturn;
})

--Creates a temporary model that will be destroyed once the server loads its version
World.Component.Build("LoadingItem", {
    Constructor = function(Entity : any, StewName : string, Model : Instance)
        World.Component.Create(Entity, "Model", Model)

        return Model
    end;

    Destructor = function(Entity : any, StewName : string, NewModel : Instance)
        World.Component.Delete(Entity, "Model")

        World.Component.Create(Entity, "Model", NewModel)
    end;
})

World.Component.Build("LoadingConnections", {
    Constructor = Util.EasyStewReturn;

    Destructor = function(Entity : any, StewName : string)
        local LoadingConnections = World.Component.Get(Entity, "LoadingConnections")

        for _, Connection : RBXScriptConnection in LoadingConnections do
            Connection:Disconnect()
        end
    end;
})

return World