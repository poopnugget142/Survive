local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Inventory = require(ServerStorage.Scripts.Inventory)

local Assets = ReplicatedStorage.Assets

Players.PlayerAdded:Connect(function(Player)
    local Character = Assets.Characters.Knight:Clone()
    Character:PivotTo(CFrame.new(0, 20, 0))
    Character.Parent = workspace
    Character.PrimaryPart:SetNetworkOwner(Player)

    Player.Character = Character

    task.wait(1)

    
end)