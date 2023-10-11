local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Equipment = require(ReplicatedStorage.Scripts.Equipment)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local CharacterAnimations = require(ReplicatedStorage.Scripts.Registry.Animations.Character)

local Player = Players.LocalPlayer

Player.CharacterAdded:Connect(function(Character)
    --temp

    local Entity = CharacterStates.World.entity()

    CharacterModule.RegisterCharacter(Entity, Character)

    local IKData = {
        ["LeftHand"] = CharacterAnimations.CreateLeftHandIK(Character)
        ,["RightHand"] = CharacterAnimations.CreateRightHandIK(Character)
    }

    CharacterStates.IKControllers.add(Entity, IKData)
    local GunEntity = Equipment.CreateEntity("Shotgun")
    CharacterStates.LookAtMouse.add(Character)
    CharacterStates.Stamina.add(Character, 5)
end)