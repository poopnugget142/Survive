local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)

local GuysSpawn = 300

for x = 1, math.sqrt(GuysSpawn) do
    task.wait()
    for y = 1, math.sqrt(GuysSpawn) do
        local Nasty : Model = ReplicatedStorage.Assets.Characters.Nasty:Clone()
        Nasty:PivotTo(Nasty.PrimaryPart.CFrame*CFrame.new(x, 0, y))
        CharacterStates.Character.add(Nasty)
        CharacterStates.Baddie.add(Nasty)
        CharacterStates[Enums.Baddies.Guy].add(Nasty)

        Nasty.Parent = workspace.Characters.Baddies
        Nasty.PrimaryPart:SetNetworkOwner(nil)
    end
end