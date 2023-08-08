local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerMovement = require(ReplicatedStorage.Scripts.PlayerMovement)
local CharacterController = require(ReplicatedStorage.Scripts.CharacterController)
local CharacterStates = require(ReplicatedStorage.Scripts.CharacterStates)
local Gun = require(ReplicatedStorage.Scripts.Items.Gun)

local Player = Players.LocalPlayer

Player.CharacterAdded:Connect(function(Character)
    CharacterController.New(Character)
    CharacterStates.Component.Create(Character, "Moving")

    PlayerMovement.Component.Create(Player, "PlayerMovement")

    --temp
    Gun.Give(Character)
end)