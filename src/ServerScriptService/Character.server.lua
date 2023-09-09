local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Assets = ReplicatedStorage.Assets

local Equipment = require(ServerStorage.Scripts.Equipment)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

Players.PlayerAdded:Connect(function(Player)
    Equipment.AddEquipment(Player, "Shotgun")
    Player.CharacterAdded:Connect(function(Character)
        task.wait()
        Character.Parent = workspace.Characters.Players

        local Entity = CharacterStates.World.entity()
        CharacterModule.RegisterCharacter(Entity, Character)
    end)
end)