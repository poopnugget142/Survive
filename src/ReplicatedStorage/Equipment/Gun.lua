local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage.Remotes

local Equipment = require(script.Parent)
local KeyBindings = require(ReplicatedStorage.Scripts.KeyBindings)

local World = Equipment.World

local Attack : RemoteEvent = Remotes.Custom.Attack
local SetEquipmentModel : RemoteEvent = Remotes.SetEquipmentModel

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local Module = {}

Module.Give = function(Entity, ItemModel)

    KeyBindings.BindAction("Attack", Enum.UserInputState.Begin, function()
        
    end)
end

Module.ServerGotItemID = function(Entity, ItemID)
    KeyBindings.BindAction("Attack", Enum.UserInputState.Begin, function()
        Attack:FireServer(ItemID, Mouse.Hit.Position)
    end)
    --SetEquipmentModel:FireServer(ItemID)
end

Module.ServerLoadModel = function(Entity, ItemModel : Model)
    
end

return Module