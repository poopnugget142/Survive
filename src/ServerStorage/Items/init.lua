local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes
local CustomActions = Remotes.Custom

local RegisterEquipment : RemoteFunction = Remotes.RegisterEquipment

local ItemStates = require(ReplicatedStorage.Scripts.States.Item)
local Enums = require(ReplicatedStorage.Scripts.Enums)

local Equipment = {}

local Id = 0

local AllItemData = {}
local ItemNames = {}

for ItemName, ItemEnum : EnumItem in Enums.Item do
    ItemNames[ItemEnum] = ItemName
end

for _, Item : ModuleScript in pairs(script:GetChildren()) do
    AllItemData[Enums.Item[Item.Name]] = Item
end

--Creates a custom id for each Equipment that we have
local function NextId()
    Id += 1
    return Id
end

--Gets the corresponding module script with the item name
local function GetItemData(ItemEnum : number) : table
    local ItemData = AllItemData[ItemEnum]
    if not ItemData then
        return nil
    end
    return require(ItemData)
end

local function GetItemName(ItemEnum : number) : string
    return ItemNames[ItemEnum]
end

local Module = {}

--TODO: Add wait for Pending equipment here
Module.RegisterEquipment = function(Player : Player, ItemEnum : number, ...) : number
    local ItemID = NextId()
    local Entity = ItemStates.World.entity()

    ItemStates.ItemID.add(Entity, ItemID)

    ItemStates.Enum.add(Entity, ItemEnum)
    ItemStates.Name.add(Entity, GetItemName(ItemEnum))
    ItemStates.Owner.add(Entity, Player)
    
    Equipment[ItemID] = Entity

    local EquipmentData = GetItemData(ItemEnum)
    EquipmentData.Register(Entity, ...)

    return ItemStates.World.get(Entity)[ItemStates.ItemID]
end

Module.CustomAction = function(ActionName : string, Player : Player, ItemID : number, ...)
    local Entity = Equipment[ItemID]
    local EntityData = ItemStates.World.get(Entity)
    local ItemEnum = EntityData[ItemStates.Enum]
    local EquipmentData = GetItemData(ItemEnum)

    if not EquipmentData[ActionName] then
        error("Action "..ActionName.." does not exist")
    end

    EquipmentData[ActionName](Entity, ...)
end

Module.BackwardsAction = function(ActionName : string, Entity, ...)
    local EntityData = ItemStates.World.get(Entity)
    local ItemID = EntityData[ItemStates.ItemID]
    local Player = EntityData[ItemStates.Owner]

    local Action = CustomActions:FindFirstChild(ActionName)

    if not Action then
        error("Action "..ActionName.." does not exist")
    end

    Action:FireClient(Player, ItemID, ...)
end

RegisterEquipment.OnServerInvoke = Module.RegisterEquipment

for _, Remote : RemoteEvent in CustomActions:GetChildren() do
    Remote.OnServerEvent:Connect(function(Player : Player, ItemID : number, ...)
        Module.CustomAction(Remote.Name, Player, ItemID, ...)
    end)
end

return Module