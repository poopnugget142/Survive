local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Equipment = require(ReplicatedStorage.Scripts.Equipment)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

local Player = Players.LocalPlayer

Player.CharacterAdded:Connect(function(Character)
    --temp
    local Entity = Equipment.CreateEntity("M1911")
    CharacterStates.LookAtMouse.add(Character)
end)