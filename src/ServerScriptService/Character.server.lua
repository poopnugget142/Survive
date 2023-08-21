local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Assets = ReplicatedStorage.Assets

local Equipment = require(ServerStorage.Scripts.Equipment)

Players.PlayerAdded:Connect(function(Player)
    Equipment.AddEquipment(Player, "M1911")
    Player.CharacterAdded:Connect(function(Character)
        task.wait()
        Character.Parent = workspace.Characters
    end)
end)