local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)

local serverScriptService = game:GetService("ServerScriptService")
local pathfinding = require(serverScriptService.warmechanic.DjikstraPathfinding)
local characterData = require(ReplicatedStorage.Scripts.CharacterData)
local CharacterController = require(ReplicatedStorage.Scripts.CharacterController)

CharacterStates[Enums.Baddies.Guy] = CharacterStates.World.factory(Enums.Baddies.Guy, {
    add = function(Factory, Entity : Model)
        local HealthData = CharacterStates.Health.add(Entity, 100)
        CharacterController.New(Entity)
        CharacterStates.Moving.add(Entity)
        

        CollectionService:AddTag(Entity, "Baddie")
        
        return true
    end
})


RunService.Heartbeat:Connect(function(deltaTime)
    
    for character in CharacterStates.World.query{CharacterStates[Enums.Baddies.Guy]} do
        local targets = pathfinding.targets
	    local distanceThreshold = 10

        local finalTarget
        local finalDistance = distanceThreshold + 1

        local root : BasePart = character.PrimaryPart

        for _, target in targets do
            if (type(target) == "userdata") then target = target.Position end
            local distance = (target - root.Position).Magnitude
            if distance < finalDistance then
                finalDistance = distance
                finalTarget = target
            end
        end

        --print(finalDistance)

        local travel = Vector3.zero
        if (finalDistance <= distanceThreshold) then
            travel = (finalTarget - root.Position).Unit
        else 
            travel = pathfinding.boxSolve(root.Position * Vector3.new(1,0,1))
        end

        if (travel ~= Vector3.zero and travel ~= nil) then 
            local charDatum = characterData.GetCharacterData(character)
            charDatum.MoveDirection = travel
        end
	    --return travel
    end
end)