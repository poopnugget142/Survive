local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Remotes = ReplicatedStorage.Remotes

local ItemModule = require(ServerStorage.Scripts.Items)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

local UpdateHealth = Remotes.UpdateHealth

Players.PlayerAdded:Connect(function(Player)
    local function HealthUpdate(Entity, DamageAmount, DamageType)
        local HealthData = CharacterStates.World.get(Entity)[CharacterStates.Health]
        local CurrentHealth = HealthData.Current

        UpdateHealth:FireClient(Player, CurrentHealth, DamageType)
    end

    Player.CharacterAdded:Connect(function(Character)
        task.wait()
        Character.Parent = workspace.Characters.Players

        local Entity = CharacterStates.World.entity()
        CharacterModule.RegisterCharacter(Entity, Character)
        local HealthData = CharacterStates.Health.add(Entity, 200)
        HealthData.Update:Connect(HealthUpdate)
    end)
end)