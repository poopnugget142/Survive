local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Equipment = require(ReplicatedStorage.Scripts.Equipment)

local Player = Players.LocalPlayer

Player.CharacterAdded:Connect(function(Character)
    --temp
    local Entity = Equipment.CreateEntity("Gun")
end)