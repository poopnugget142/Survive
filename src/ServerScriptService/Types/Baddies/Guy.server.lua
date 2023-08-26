local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local serverScriptService = game:GetService("ServerScriptService")

local CharactersFolder = workspace:WaitForChild("Characters")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)
local pathfinding = require(serverScriptService.warmechanic.DjikstraPathfinding)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)

local function OnHit(Entity : Model)
    local HealthData = CharacterStates.Health.add(Entity, 100)

    --I'VE DIED NOOOOOOOOOOO
    if HealthData.Current <= 0 then
        print("Killed a dude")
        CharacterStates.World.kill(Entity)
        Entity:Destroy()
    end
end

CharacterStates[Enums.Baddies.Guy] = CharacterStates.World.factory(Enums.Baddies.Guy, {
    add = function(Factory, Entity : Model)
        local HealthData = CharacterStates.Health.add(Entity, 100)

        HealthData.Update:Connect(function() OnHit(Entity) end)

        CharacterStates.Character.add(Entity)
        CharacterStates.Baddie.add(Entity)

        CharacterStates.MovementData.add(Entity)
        CharacterStates.WalkSpeed.add(Entity, 20)
        CharacterStates.AutoRotate.add(Entity)
        CharacterStates.Moving.add(Entity)
        
        return true
    end
})

local NearbyParams = OverlapParams.new()
NearbyParams.FilterDescendantsInstances = {CharactersFolder.Baddies}
NearbyParams.FilterType = Enum.RaycastFilterType.Include
NearbyParams.RespectCanCollide = true


RunService.Heartbeat:Connect(function(deltaTime)
    
    for Character in CharacterStates.World.query{CharacterStates[Enums.Baddies.Guy]} do
        local targets = pathfinding.targets
	    local distanceThreshold = 10

        local finalTarget
        local finalDistance = distanceThreshold + 1

        local root : BasePart = Character.PrimaryPart

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

        --Get nearby parts that belong to baddies
        local NearbyBaddieParts = workspace:GetPartBoundsInRadius(root.Position, 3, NearbyParams)

        local NearbyBaddies = {}

        --Put all the characters into a list don't include repeating characters
        for i, Part : BasePart in NearbyBaddieParts do
            local OtherCharacter = CharacterModule.FindFirstCharacter(Part)

            if OtherCharacter == Character then continue end

            if table.find(NearbyBaddies, OtherCharacter) then continue end

            table.insert(NearbyBaddies, OtherCharacter)
        end

        --Calculate the average position
        local BaddieAveragePosition = Vector3.zero
        for i, OtherCharacter : Model in NearbyBaddies do
            local Difference = (OtherCharacter.PrimaryPart.Position-root.Position)/3
            BaddieAveragePosition += Difference*(3-Difference.Magnitude)^2
        end
        BaddieAveragePosition = BaddieAveragePosition/(math.max(#NearbyBaddies, 1))

        --Reverse the vector
        local MoveAwayVector
        if BaddieAveragePosition.Magnitude == 0 then
            MoveAwayVector = Vector3.zero
        else
            MoveAwayVector = -(BaddieAveragePosition)
        end

        if (travel ~= Vector3.zero and travel ~= nil) then
            local MovementData = CharacterStates.World.get(Character).MovementData
            MovementData.MoveDirection = ((travel*1)+(MoveAwayVector*1)).Unit
        end
	    --return travel
    end
end)