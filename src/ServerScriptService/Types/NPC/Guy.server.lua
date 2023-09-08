local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local CharactersFolder = workspace:WaitForChild("Characters")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)
local pathfinding = require(ServerScriptService.warmechanic.DjikstraPathfinding)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local BaddieRegistry = require(ReplicatedStorage.Scripts.Registry.NPC)

local CharacterController = ServerScriptService.CharacterController

local NpcEnum = Enums.NPC.Guy

local Nasty : Model = BaddieRegistry.GetBaddieModel(NpcEnum):Clone()
Nasty.Model:Destroy()

local function OnHit(Entity : any)
    local HealthData = CharacterStates.Health.add(Entity, 100)

    --I'VE DIED NOOOOOOOOOOO
    if HealthData.Current <= 0 then
        print("Killed a dude")
        CharacterStates.World.kill(Entity)
    end
end

CharacterStates[NpcEnum] = CharacterStates.World.factory(NpcEnum, {
    add = function(Factory, Entity : any, SpawnPosition : CFrame?)
        local NastyModel = Nasty:Clone()
        NastyModel.Parent = workspace.Characters.NPCs

        if SpawnPosition then
            NastyModel:PivotTo(SpawnPosition)
        else
            SpawnPosition = NastyModel.WorldPivot
        end

        CharacterModule.RegisterCharacter(Entity, NastyModel)
        local NpcId = CharacterModule.RegisterNPC(Entity)

        local HealthData = CharacterStates.Health.add(Entity, 100)

        HealthData.Update:Connect(function() OnHit(Entity) end)

        --[[
        CharacterStates.Character.add(Entity)
        CharacterStates.Baddie.add(Entity)

        CharacterStates.MovementData.add(Entity)
        ]]
        CharacterStates.WalkSpeed.add(Entity, 10)
        CharacterStates.AutoRotate.add(Entity)
        CharacterStates.Moving.add(Entity)

        CharacterController:SendMessage("CreateMovementData", NpcId, NastyModel, SpawnPosition.Position, 14)
        
        return true
    end;
    remove = function(Factory, Entity : any)
        CharacterModule.Action(Entity, Enums.Action.Die)
    end;
})

local NearbyParams = OverlapParams.new()
NearbyParams.FilterDescendantsInstances = {CharactersFolder.NPCs}
NearbyParams.FilterType = Enum.RaycastFilterType.Include
NearbyParams.RespectCanCollide = false


RunService.Heartbeat:Connect(function(deltaTime)
    
    for Entity in CharacterStates.World.query{CharacterStates[NpcEnum]} do
        local EntityData = CharacterStates.World.get(Entity)
        local Character = EntityData.Model

        local targets = pathfinding.targets
	    local distanceThreshold = math.huge

        local finalTarget
        local finalDistance = distanceThreshold

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
        local displacement : Vector3
        if (finalTarget) then
            displacement = (finalTarget - root.Position) * Vector3.new(1,0,1)
        end
        --if (finalDistance <= distanceThreshold) then
        --    travel = (finalTarget - root.Position).Unit
        --else
        if (pathfinding.getTile(root.Position * Vector3.new(1,0,1) )) then
            travel = pathfinding.boxSolve(root.Position * Vector3.new(1,0,1))
            if (displacement) then
                local theta = math.acos(travel:Dot(displacement.Unit))
                --print(math.deg(theta))
                if (theta <= math.rad(45)) then
                    travel = displacement.Unit
                end
            end
        else
            travel = -root.Position.Unit
        end
        --end

        --[[NOTE
            if the travel's angle is within THETA of the player, snap the move direction towards the player
        ]]


        --Get nearby parts that belong to baddies
        local NearbyBaddieDistance = 2
        local NearbyBaddieParts = workspace:GetPartBoundsInRadius(root.Position, NearbyBaddieDistance, NearbyParams)

        local NearbyBaddies = {}

        --Put all the characters into a list don't include repeating characters
        for i, Part : BasePart in NearbyBaddieParts do
            local OtherCharacter = CharacterModule.FindFirstCharacter(Part)

            if OtherCharacter == Character then continue end

            if table.find(NearbyBaddies, OtherCharacter) then continue end

            table.insert(NearbyBaddies, OtherCharacter)
        end

        --Calculate the average position
        local BaddieCumulativePosition = Vector3.zero
        for i, OtherCharacter : Model in NearbyBaddies do
            local Difference = (OtherCharacter.PrimaryPart.Position-root.Position)
            BaddieCumulativePosition += Difference*(math.max(0.001, 1-Difference.Magnitude/NearbyBaddieDistance))^0.5
        end
        BaddieCumulativePosition = BaddieCumulativePosition--/(math.max(#NearbyBaddies, 1))

        --Reverse the vector
        local MoveAwayVector
        if BaddieCumulativePosition.Magnitude == 0 then
            MoveAwayVector = Vector3.zero
        else
            MoveAwayVector = -(BaddieCumulativePosition)
        end

        if (travel ~= Vector3.zero and travel ~= nil) then
            local MoveDirection = ((travel*1)+(MoveAwayVector*3)).Unit
            CharacterController:SendMessage("UpdateMoveDirection", EntityData.NPC, MoveDirection)
            --MovementData.travel = travel
        end
	    --return travel
    end
end)