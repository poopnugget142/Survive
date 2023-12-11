local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes
local CustomActions = Remotes.Custom
local ReplicatedScripts = ReplicatedStorage.Scripts

local Promise = require(ReplicatedStorage.Packages.Promise)
local ItemStates = require(ReplicatedScripts.States.Item)
local Enums = require(ReplicatedScripts.Registry.Enums)
local EventHandler = require(ReplicatedScripts.Lib.Util.EventHandler)

local RegisterEquipment : RemoteFunction = Remotes.RegisterEquipment

local EquipmentIDs : { [any] : number? }= {}
local EquipmentEntitys : { [number] : any } = {}

local AllItemData = {}
local ItemNames = {}

for ItemName, ItemEnum : EnumItem in Enums.Item do
    ItemNames[ItemEnum] = ItemName
end

for _, Item : ModuleScript in pairs(script:GetChildren()) do
    AllItemData[Enums.Item[Item.Name]] = Item
end

local Module = {}

Module.States = ItemStates

--Gets the corresponding module script with the item name
local function GetItemData(ItemEnum : number) : table
    local ItemData = AllItemData[ItemEnum]
    if not ItemData then
        return nil
    end
    return require(ItemData)
end

local function GetDataFromEntity(Entity : any) : table
    local EntityData = ItemStates.World.get(Entity)
    local ItemEnum = EntityData[ItemStates.Enum]
    return GetItemData(ItemEnum)
end

local function GetItemName(ItemEnum : number) : string
    return ItemNames[ItemEnum]
end
    

local function SetItemID(Entity : any, ItemEnum : number?)
    local ItemID = EquipmentIDs[Entity]
    if ItemID then
        return ItemID
    end

    --Asks server for ItemID to mark item with
    local ItemPromise = Promise.new(function(resolve)
        ItemID = RegisterEquipment:InvokeServer(ItemEnum)

        EquipmentEntitys[ItemID] = Entity
        EquipmentIDs[Entity] = ItemID

        ItemStates.ItemID.add(Entity, ItemID)

        local ItemData = GetItemData(ItemEnum)

        ItemData.ServerGotItemID(Entity, ItemID)

        resolve(ItemID)
	end)

    EquipmentIDs[Entity] = ItemPromise
end

Module.CreateEntity = function(ItemEnum : number, ItemID : number?, ...)
    local Entity = Module.GetEntity(ItemID)

    --Entity does not exist on this client
    if not Entity then
        Entity = ItemStates.World.entity()

        ItemStates.Enum.add(Entity, ItemEnum)
        ItemStates.Name.add(Entity, GetItemName(ItemEnum))

        if ItemID then
            --Entity exists on server
            ItemStates.ItemID.add(Entity, ItemID)
        else
            --Entity does not exist on server
            --Requests item id from server
            SetItemID(Entity, ItemEnum)
        end
    end

    local ItemData = GetItemData(ItemEnum)

    if ItemData then
        ItemData.Give(Entity, ...)
    end

    EventHandler.FireEvent("Item", "Add", Entity)

    return Entity
end

Module.RemoveEntity = function(Entity : any)
    local ItemData = GetDataFromEntity(Entity)

    if ItemData then
        ItemData.Remove(Entity)
    end

    ItemStates.kill(Entity)
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

Module.Equip = function(Entity : any, ...)
    local ItemData = GetDataFromEntity(Entity)
    ItemData.Equip(Entity, ...)
end

Module.Unequip = function(Entity : any, ...)
    local ItemData = GetDataFromEntity(Entity)
    ItemData.Unequip(Entity, ...)
end

Module.FireCustomAction = function(Entity : any, ActionName : string, ...)
    local EntityData = ItemStates.World.get(Entity)
    local ItemID = EntityData[ItemStates.ItemID]

    local Action = CustomActions:FindFirstChild(ActionName)

    if not Action then
        error("Action "..ActionName.." does not exist")
    end

    Action:FireServer(ItemID, ...)
end

for _, Action : RemoteFunction in pairs(CustomActions:GetChildren()) do
    Action.OnClientEvent:Connect(function(ItemID, ...)
        local Entity = Module.GetEntity(ItemID)
        local ItemData = GetDataFromEntity(Entity)
        return ItemData[Action.Name](Entity, ...)
    end)
end

return Module