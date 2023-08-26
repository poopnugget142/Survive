local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)

return function (context, Amount)
    for i = 1, Amount do
        local Nasty : Model = ReplicatedStorage.Assets.Characters.Nasty:Clone()
        Nasty:PivotTo(Nasty.PrimaryPart.CFrame*CFrame.new(20, 0, 20))
        
        CharacterStates[Enums.Baddies.Guy].add(Nasty)

        Nasty.Parent = workspace.Characters.Baddies
        Nasty.PrimaryPart:SetNetworkOwner(nil)
    end
end