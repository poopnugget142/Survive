local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Stew = require(ReplicatedStorage.Packages.Stew)
local Signal = require(ReplicatedStorage.Packages.Signal)

local World = Stew.world()

local Module = {}

Module.Moving = World.tag("Moving")
Module.AutoRotate = World.tag("AutoRotate")
Module.LookAtMouse = World.tag("LookAtMouse")
Module.Baddie = World.tag("Baddie")

Module.Health = World.factory("Health", {
    add = function(Factory, Entity : any, Health : number)
        return {
            Current = Health;
            Update = Signal.new();
        }
    end;

    remove = function(Factory, Entity : any)
        local HealthData = World.get(Entity).Health
        HealthData.Update:Destroy()
    end;
})

Module.Character = World.factory("Character", {
    add = function(Factory, Entity : any)
        local Character = World.get(Entity).Model

        CollectionService:AddTag(Character, "Character")

        return true
    end;

    remove = function(Factory, Entity : any)
        local Character = World.get(Entity).Model

        CollectionService:RemoveTag(Character, "Character")
    end;
})

Module.Hidden = World.factory("Hidden", {
    add = function(Factory, Entity : any)
        local BaddieModel = World.get(Entity).Model

        if not BaddieModel then
            error("No model to hide")
        end

        for _, Part in BaddieModel.Model:GetChildren() do
            if Part:IsA("BasePart") and Part ~= BaddieModel.Model.PrimaryPart then
                Part.Transparency = 1
            end
        end

        return true
    end;
    remove = function(Factory, Entity : any)
        local BaddieModel = World.get(Entity).Model

        for _, Part in BaddieModel.Model:GetChildren() do
            if Part:IsA("BasePart") and Part ~= BaddieModel.Model.PrimaryPart then
                Part.Transparency = 0
            end
        end

        return true
    end;
})

Module.Model = World.factory("Model", {
    add = function(Factory, Entity : any, Model : any)
        return Model
    end;

    remove = function(Factory, Entity : any)
        local Model = World.get(Entity).Model
        Model:Destroy()
    end;
})

Module.NPC = World.factory("NPC", {
    add = function(Factory, Entity : any, NpcId : number)
        local Character = World.get(Entity).Model

        --This is temp until we get k trees up
        if Character and RunService:IsServer() then
            CollectionService:AddTag(Character, "NPC")
        end

        return NpcId
    end;

    remove = function(Factory, Entity : any)
        local Character = World.get(Entity).Model

        if Character then
            CollectionService:RemoveTag(Character, "NPC")
        end
    end;
})

Module.NPCType = World.factory("NPCType", {
    add = function(Factory, Entity : any, NpcType : number)
        return NpcType
    end;
})

Module.World = World

return Module