local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Equipment = require(ServerStorage.Scripts.Equipment)

local Remotes = ReplicatedStorage.Remotes
local CustomActions = Remotes.Custom

local RegisterEquipment : RemoteFunction = Remotes.RegisterEquipment

RegisterEquipment.OnServerInvoke = Equipment.RegisterEquipment

for _, Remote : RemoteEvent in CustomActions:GetChildren() do
    Remote.OnServerEvent:Connect(function(Player : Player, ItemID : number, ...)
        Equipment.CustomAction(Remote.Name, Player, ItemID, ...)
    end)
end