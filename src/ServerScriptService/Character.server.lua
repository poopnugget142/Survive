local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Assets = ReplicatedStorage.Assets

local Equipment = require(ServerStorage.Scripts.Equipment)

Players.PlayerAdded:Connect(function(Player)
    
    local Character = Assets.Characters.Knight:Clone()
    Character:PivotTo(CFrame.new(0, 20, 0))
    Character.Parent = workspace.Characters
    Character.PrimaryPart:SetNetworkOwner(Player)

    Player.Character = Character

    task.wait(1)

    Equipment.AddEquipment(Player, "Gun")
end)