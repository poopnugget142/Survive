local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage:WaitForChild("Scripts")

local Stew = require(ReplicatedStorage.Packages.Stew)
local Util = require(ReplicatedScripts.Lib.Util)
local Enums = require(ReplicatedScripts.Registry.Enums)

local World = Stew.world {}

local Module = {}

Module.Name = World.factory({
    add = Util.EasyStewReturn;
})

Module.Enum = World.factory({
    add = Util.EasyStewReturn;
})

Module.ItemID = World.factory({
    add = Util.EasyStewReturn;
})

Module.Model = World.factory({
    add = Util.EasyStewReturn;

    remove = function(Factory, Entity : any)
        local EntityData = World.get(Entity)
        local Model = EntityData[Module.Model]

        Model:Destroy()
    end
})

Module.Owner = World.factory({
    add = Util.EasyStewReturn;
})

Module.LoadingConnections = World.factory({
    add = Util.EasyStewReturn;

    remove = function(Factory, Entity : any, NewModel : Instance)
        local LoadingConnections = World.get(Entity)[Module.LoadingConnections]

        for _, Connection : RBXScriptConnection in LoadingConnections do
            Connection:Disconnect()
        end
    end;
})

--~Weapon~--
for  _, GunEnum in Enums.Item do
    Module[GunEnum] = World.tag {}
end

Module.Shooting = World.tag {}

Module.Cooldown = World.factory({
    add = Util.EasyStewReturn;
})

Module.Deviation = World.factory({
    add = Util.EasyStewReturn;
})

Module.Firerate = World.factory({
    add = Util.EasyStewReturn;
})

Module.World = World

return Module