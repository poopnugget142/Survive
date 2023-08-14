local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerMovement = require(ReplicatedStorage.Scripts.PlayerMovement)
local CharacterController = require(ReplicatedStorage.Scripts.CharacterController)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Equipment = require(ReplicatedStorage.Scripts.Equipment)

local Player = Players.LocalPlayer

Player.CharacterAdded:Connect(function(Character)
    CharacterController.New(Character)
    CharacterStates.Component.Create(Character, "Moving")

    PlayerMovement.Component.Create(Player, "PlayerMovement")

    --temp
    local Entity = Equipment.CreateEntity("Gun")
end)