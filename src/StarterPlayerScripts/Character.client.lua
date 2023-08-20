local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterController = require(ReplicatedStorage.Scripts.CharacterController)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local PlayerStates = require(ReplicatedStorage.Scripts.States.Player)
local Equipment = require(ReplicatedStorage.Scripts.Equipment)

local Player = Players.LocalPlayer

Player.CharacterAdded:Connect(function(Character)
    --[[
    CharacterController.New(Character)

    CharacterStates.Moving.add(Character)

    PlayerStates.ControllMovement.add(Player)
    ]]

    --temp
    local Entity = Equipment.CreateEntity("Gun")
end)