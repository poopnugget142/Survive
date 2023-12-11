local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataFolder = ReplicatedStorage.Data
local ReplicatedScripts = ReplicatedStorage.Scripts

local CharacterModule = require(ReplicatedScripts.Class.Character)
local Enums = require(ReplicatedScripts.Registry.Enums)

local WaveNumber = DataFolder.Wave

while true do
    --Setup
    task.wait(3)

    --Begin Wave
    local Amount = WaveNumber.Value * 5

    for i = 1, Amount do
        CharacterModule.CreateNPC(Enums.NPC.Guy, Vector3.new(20, 0.5, 20))

        task.wait()
    end

    --Wait for wave to end
    task.wait(15)

    --Next Wave
    WaveNumber.Value += 1
end