local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local CharactersFolder = workspace:WaitForChild("Characters")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)
local pathfinding = require(ServerScriptService.warmechanic.DjikstraPathfinding)
local Pathfinding = require(ReplicatedStorage.Scripts.Util.PathfindingCore)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local NpcRegistry = require(ReplicatedStorage.Scripts.Registry.NPC)

local QuadtreeModule = require(ReplicatedStorage.Scripts.Util.Quadtree)

local CharacterController = ServerScriptService.CharacterController

local NpcEnum = Enums.NPC.Guy
local NearbyBaddieDistance = NpcRegistry.GetNearbyNpcDistance(NpcEnum)
local AttackRange = NpcRegistry.GetAttackRange(NpcEnum)
local Nasty : Model = NpcRegistry.GetBaddieModel(NpcEnum):Clone()
Nasty.Model:Destroy()

local function OnHit(Entity : any)
    local HealthData = CharacterStates.Health.add(Entity, 100)

    --I'VE DIED NOOOOOOOOOOO
    if HealthData.Current <= 0 then
        print("Killed a dude")
        CharacterModule.RemoveMovementData(Entity)
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

        local NpcId = CharacterModule.RegisterNPC(Entity)
        NastyModel.Name = NpcId

        CharacterModule.RegisterCharacter(Entity, NastyModel)

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

        CharacterModule.CreatedMovementData(Entity, SpawnPosition.Position)
        
        return true
    end;
    remove = function(Factory, Entity : any)
        CharacterModule.Action(Entity, Enums.Action.Die)
    end;
})

local AttackRange = 4

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
            --[[
            if (type(target) == "userdata") then target = target.Position end
            local distance = (target - root.Position).Magnitude
            if distance < finalDistance then
                finalDistance = distance
                finalTarget = target
            end
            ]]
            target = Pathfinding.BuildTarget(target)
            local distance = (target.Position + target.Velocity - root.Position).Magnitude
            if (distance < finalDistance) then
                finalDistance = distance
                finalTarget = target
            end
        end

        --print(finalDistance)

        local travel = Vector3.zero
        local displacement : Vector3
        if (finalTarget) then
            displacement = (finalTarget.Position + finalTarget.Velocity - root.Position) * Vector3.new(1,0,1)
        end
        --if (finalDistance <= distanceThreshold) then
        --    travel = (finalTarget - root.Position).Unit
        --else
        --if (Pathfinding.GetTilegrid("ZombieGeneric"):GetTile(Vector2.new(math.round(root.Position.X), math.round(root.Position.Z)))) then
            --travel = pathfinding.boxSolve(root.Position * Vector3.new(1,0,1))
            travel = Pathfinding.KernalConvolute("ZombieGeneric", root.Position)
            if (finalTarget) then
                if (finalTarget.Part) then
                    local theta = math.acos(travel:Dot(finalTarget.Position - root.Position))
                    --print(math.deg(theta))
                    if (theta <= math.rad(15)) then
                        travel = (finalTarget.Position - root.Position).Unit
                    end
                end
            end
        --else
        --    travel = -root.Position.Unit
        --end
        --end

        --[[NOTE
            if the travel's angle is within THETA of the player, snap the move direction towards the player
        ]]

        local Quad = QuadtreeModule.GetQuadtree("GroundUnits")
        local NearbyPoints = Quad:QueryRange(QuadtreeModule.BuildBox(root.Position.X, root.Position.Z, NearbyBaddieDistance, NearbyBaddieDistance))
        --print(NearbyPoints)

        local BaddieCumulativePosition = Vector3.zero
        for _, Point in NearbyPoints do
            local Difference = (Vector3.new(Point.X, 0, Point.Y) - root.Position) * Vector3.new(1,0,1)
            BaddieCumulativePosition += Difference*(math.max(0.001, 1-Difference.Magnitude/NearbyBaddieDistance))^0.5 
        end
        --print(BaddieCumulativePosition)

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