local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes

local EquipmentStates = require(ReplicatedStorage.Scripts.States.Equipment)
local Promise = require(ReplicatedStorage.Packages.Promise)

local SetEquipmentModel : RemoteEvent = Remotes.SetEquipmentModel

local Equipment = {}

local PendingEquipment = {}

local Id = 0

--Creates a custom id for each Equipment that we have
local function NextId()
    Id += 1
    return Id
end

--Gets the corresponding module script with the item name
local function GetEquipmentData(ItemName) : table
    local ItemData = script:FindFirstChild(ItemName)
    if not ItemData then
        error(ItemName.." does not exist")
    end
    return require(ItemData)
end

local Module = {}

Module.AddEquipment = function(Player : Player, ItemName : string, ItemID : number?, ...)
    local Entity = Equipment[ItemID]

    if not Entity then
        ItemID = NextId()
        Entity = EquipmentStates.Entity.Create()

        EquipmentStates.Component.Create(Entity, "ItemID", ItemID)
    else
        EquipmentStates.Component.Delete(Entity, "Owner")
        EquipmentStates.Component.Create(Entity, "Owner", Player)
        return
    end

    EquipmentStates.Component.Create(Entity, "Name", ItemName)
    EquipmentStates.Component.Create(Entity, "Owner", Player)
    
    Equipment[ItemID] = Entity

    if not PendingEquipment[Player] then
        PendingEquipment[Player] = {}
    end

    PendingEquipment[Player][ItemName] = Entity

    local EquipmentData = GetEquipmentData(ItemName)
    EquipmentData.Create(Entity, ...)

    return Entity
end

--TODO: Add wait for Pending equipment here
Module.CreateEquipment = function(Player : Player, ItemName : string) : number
    if not PendingEquipment[Player] then
        PendingEquipment[Player] = {}
    end

    local Entity = PendingEquipment[Player][ItemName]


    --If not entity wait for it
    if not Entity then
        local Worked
        Worked, Entity = Promise.new(function(resolve, reject, onCancel)
            repeat task.wait()
                
            until PendingEquipment[Player][ItemName]

            resolve(PendingEquipment[Player][ItemName])
        end):timeout(10):await()
 
        if not Worked then
            error(Entity)
        end
    end

    local Entity = PendingEquipment[Player][ItemName]
    PendingEquipment[Player][ItemName] = nil

    return EquipmentStates.Component.Get(Entity, "ItemID")
end

Module.SetEquipmentModel = function(Player : Player, ItemID : number)
    local Entity = Equipment[ItemID]
    local ItemName = EquipmentStates.Component.Get(Entity, "Name")
    local EquipmentData = GetEquipmentData(ItemName)
    local Model : Model = EquipmentData.LoadModel(Entity)
    EquipmentStates.Component.Create(Entity, "Model", Model)
    Model:SetAttribute("ItemID", ItemID)

    SetEquipmentModel:FireClient(Player, Model, ItemID)
end

Module.CustomAction = function(ActionName : string, Player : Player, ItemID : number, ...)
    local Entity = Equipment[ItemID]
    local ItemName = EquipmentStates.Component.Get(Entity, "Name")
    local EquipmentData = GetEquipmentData(ItemName)
    EquipmentData[ActionName](Entity, ...)
end

return Module