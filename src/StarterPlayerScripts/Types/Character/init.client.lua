local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Equipment = require(ReplicatedStorage.Scripts.Equipment)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

local Player = Players.LocalPlayer

Player.CharacterAdded:Connect(function(Character)
    --temp
    local Entity = Equipment.CreateEntity("Shotgun")
    CharacterStates.LookAtMouse.add(Character)
    CharacterStates.Stamina.add(Character, 5)
end)