local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes
local CustomActions = Remotes.Custom

local EquipmentStates = require(ReplicatedStorage.Scripts.States.Equipment)

local Equipment = {}

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

--TODO: Add wait for Pending equipment here
Module.RegisterEquipment = function(Player : Player, ItemName : string, ...) : number
    local ItemID = NextId()
    local Entity = EquipmentStates.World.entity()

    EquipmentStates.ItemID.add(Entity, ItemID)

    EquipmentStates.Name.add(Entity, ItemName)
    EquipmentStates.Owner.add(Entity, Player)
    
    Equipment[ItemID] = Entity

    local EquipmentData = GetEquipmentData(ItemName)
    EquipmentData.Register(Entity, ...)

    return EquipmentStates.World.get(Entity)[EquipmentStates.ItemID]
end

Module.CustomAction = function(ActionName : string, Player : Player, ItemID : number, ...)
    local Entity = Equipment[ItemID]
    local EntityData = EquipmentStates.World.get(Entity)
    local ItemName = EntityData[EquipmentStates.Name]
    local EquipmentData = GetEquipmentData(ItemName)

    if not EquipmentData[ActionName] then
        error("Action "..ActionName.." does not exist")
    end

    EquipmentData[ActionName](Entity, ...)
end

Module.BackwardsAction = function(ActionName : string, Entity, ...)
    local EntityData = EquipmentStates.World.get(Entity)
    local ItemID = EntityData[EquipmentStates.ItemID]
    local Player = EntityData[EquipmentStates.Owner]

    local Action = CustomActions:FindFirstChild(ActionName)

    if not Action then
        error("Action "..ActionName.." does not exist")
    end

    Action:FireClient(Player, ItemID, ...)
end

return Module