local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes
local CustomActions = Remotes.Custom

local Promise = require(ReplicatedStorage.Packages.Promise)
local EquipmentStates = require(ReplicatedStorage.Scripts.States.Equipment)

local RegisterEquipment : RemoteFunction = Remotes.RegisterEquipment
local SetEquipmentModel : RemoteEvent = Remotes.SetEquipmentModel

local EquipmentIDs : { [any] : number? }= {}
local EquipmentEntitys : { [number] : any } = {}

local Module = {}

Module.States = EquipmentStates

--Gets the corresponding module script with the item name
local function GetEquipmentData(ItemName : string) : table
    local ItemData = script:FindFirstChild(ItemName)
    if not ItemData then
        error(ItemName.." does not exist")
    end
    return require(ItemData)
end

local function SetItemID(Entity : any, ItemName : string?)
    local ItemID = EquipmentIDs[Entity]
    if ItemID then
        return ItemID
    end

    --Asks server for ItemID to mark item with
    local ItemPromise = Promise.new(function(resolve)
        ItemID = RegisterEquipment:InvokeServer(ItemName)

        EquipmentEntitys[ItemID] = Entity
        EquipmentIDs[Entity] = ItemID

        EquipmentStates.ItemID.add(Entity, ItemID)

        local ItemData = GetEquipmentData(ItemName)

        ItemData.ServerGotItemID(Entity, ItemID)

        resolve(ItemID)
	end)

    EquipmentIDs[Entity] = ItemPromise
end

Module.CreateEntity = function(ItemName : string, ItemID : number?, ...)
    local Entity = Module.GetEntity(ItemID)

    --Entity does not exist on this client
    if not Entity then
        Entity = EquipmentStates.World.entity()

        EquipmentStates.Name.add(Entity, ItemName)

        if ItemID then
            --Entity exists on server
            EquipmentStates.ItemID.add(Entity, ItemID)
        else
            --Entity does not exist on server
            --Requests item id from server
            SetItemID(Entity, ItemName)
        end
    end

    local ItemData = GetEquipmentData(ItemName)

    ItemData.Give(Entity, ...)

    return Entity
end

Module.WaitUntilItemID = function(Entity : any) : number?
    local ItemID = EquipmentIDs[Entity]

    if not Promise.is(ItemID) then
        return ItemID
    end

    ItemID = ItemID:await()

    return ItemID
end

Module.GetEntity = function(ItemId : number) : any
    return EquipmentEntitys[ItemId]
end

Module.FireCustomAction = function(Entity : any, ActionName : string, ...)
    local EntityData = EquipmentStates.World.get(Entity)
    local ItemID = EntityData.ItemID

    local Action = CustomActions:FindFirstChild(ActionName)

    if not Action then
        error("Action "..ActionName.." does not exist")
    end

    Action:FireServer(ItemID, ...)
end

Module.Equip = function(Entity : any, ...)
    local EntityData = EquipmentStates.World.get(Entity)
    local ItemName = EntityData.Name
    local ItemData = GetEquipmentData(ItemName)
    ItemData.Equip(Entity, ...)
end

Module.Unequip = function(Entity : any, ...)
    local EntityData = EquipmentStates.World.get(Entity)
    local ItemName = EntityData.Name
    local ItemData = GetEquipmentData(ItemName)
    ItemData.Unequip(Entity, ...)
end

--Asks server to load model
Module.RequestModel = function(Entity : any, ...)
    local EntityData = EquipmentStates.World.get(Entity)
    local ItemID = EntityData.ItemID

    SetEquipmentModel:FireServer(ItemID, ...)
end

SetEquipmentModel.OnClientEvent:Connect(function(Instance, ItemID)
    local Entity = Module.GetEntity(ItemID)
    local EntityData = EquipmentStates.World.get(Entity)
    local ItemName = EntityData.Name
    local ItemData = GetEquipmentData(ItemName)
    ItemData.ServerLoadModel(Entity, Instance)
end)

return Module