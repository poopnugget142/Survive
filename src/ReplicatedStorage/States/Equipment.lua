local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stew = require(ReplicatedStorage.Packages.Stew)
local Util = require(ReplicatedStorage.Scripts.Util)
local Enums = require(ReplicatedStorage.Scripts.Enums)

local World = Stew.world()

local Module = {}

Module.Name = World.factory("Name", {
    add = Util.EasyStewReturn;
})

Module.ItemID = World.factory("ItemID", {
    add = Util.EasyStewReturn;
})

Module.Model = World.factory("Model", {
    add = Util.EasyStewReturn;

    remove = function(Factory, Entity : any)
        local EntityData = World.get(Entity)
        local Model = EntityData.Model

        Model:Destroy()
    end
})

Module.Owner = World.factory("Owner", {
    add = Util.EasyStewReturn;
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

--~Weapon~--
for  _, GunEnum in Enums.Gun do
    Module[GunEnum] = World.tag(GunEnum)
end

Module.Shooting = World.tag("Shooting")

Module.Cooldown = World.factory("Cooldown", {
    add = Util.EasyStewReturn;
})

Module.Deviation = World.factory("Deviation", {
    add = Util.EasyStewReturn;
})

Module.Firerate = World.factory("Firerate", {
    add = Util.EasyStewReturn;
})

Module.World = World

return Module