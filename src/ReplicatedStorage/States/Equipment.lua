local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stew = require(ReplicatedStorage.Packages.Stew)

local World = Stew.World.Create()

local function EasyStewReturn(Entity : any, StewName : string, Item : any)
    return Item
end

World.Component.Build("Name", {
    Constructor = EasyStewReturn;
})

World.Component.Build("ItemID", {
    Constructor = EasyStewReturn;
})

World.Component.Build("Model", {
    Constructor = EasyStewReturn;

    Destructor = function(Entity : any, StewName : string)
        local Model = World.Component.Get(Entity, "Model")

        Model:Destroy()
    end;
})

World.Component.Build("Owner", {
    Constructor = EasyStewReturn;
})

World.Component.Build("CastBehavior", {
    Constructor = EasyStewReturn;
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
    Constructor = EasyStewReturn;

    Destructor = function(Entity : any, StewName : string)
        local LoadingConnections = World.Component.Get(Entity, "LoadingConnections")

        for _, Connection : RBXScriptConnection in LoadingConnections do
            Connection:Disconnect()
        end
    end;
})

return World