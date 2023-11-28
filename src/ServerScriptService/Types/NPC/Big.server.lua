local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)
local pathfinding = require(ServerScriptService.warmechanic.DjikstraPathfinding)
local Pathfinding = require(ReplicatedStorage.Scripts.Util.PathfindingCore)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local NpcRegistry = require(ReplicatedStorage.Scripts.Registry.NPC)

local QuadtreeModule = require(ReplicatedStorage.Scripts.Util.Quadtree)

local CharacterController = ServerScriptService.CharacterController

local NpcEnum = Enums.NPC.Big
local CollisionRadius = NpcRegistry.GetCollisionRadius(NpcEnum)
local AttackRange = NpcRegistry.GetAttackRange(NpcEnum)

local function OnHit(Entity : any)
    local HealthData = CharacterStates.Health.add(Entity, 1000)

    --I'VE DIED NOOOOOOOOOOO
    if HealthData.Current <= 0 then
        print("Killed a dude")
        CharacterModule.RemoveMovementData(Entity)
        CharacterStates.World.kill(Entity)
    end
end

CharacterStates[NpcEnum] = CharacterStates.World.factory({
    add = function(Factory, Entity : any, SpawnPosition : Vector3)
        local NpcId = CharacterModule.RegisterNPC(Entity)

        local HealthData = CharacterStates.Health.add(Entity, 1000)
        HealthData.Update:Connect(function() OnHit(Entity) end)

        --[[
        CharacterStates.Character.add(Entity)
        CharacterStates.Baddie.add(Entity)

        CharacterStates.MovementData.add(Entity)
        ]]
        CharacterStates.WalkSpeed.add(Entity, 6)
        CharacterStates.AutoRotate.add(Entity)
        CharacterStates.Moving.add(Entity)

        CharacterModule.CreateMovementData(Entity, SpawnPosition)
        
        return true
    end;
    remove = function(Factory, Entity : any)
        CharacterModule.Action(Entity, Enums.Action.Die)
    end;
})

RunService.Heartbeat:Connect(function(deltaTime) 
    for Entity in CharacterStates.World.query{CharacterStates[NpcEnum]} do
        local EntityData = CharacterStates.World.get(Entity)

        if not EntityData[NpcEnum] then continue end

        local MovementData = CharacterModule.GetMovementData(Entity)
        local Position = MovementData.Position
        local Velocity = MovementData.Velocity
        local NpcId = EntityData.NPC

        local targets = pathfinding.targets
	    local distanceThreshold = math.huge

        local finalTarget
        local finalDistance = distanceThreshold

        for _, target in targets do
            --[[
            if (type(target) == "userdata") then target = target.Position end
            local distance = (target - Position).Magnitude
            if distance < finalDistance then
                finalDistance = distance
                finalTarget = target
            end
            ]]
            target = Pathfinding.BuildTarget(target)
            local distance = (target.Position + target.Velocity - Position).Magnitude
            if (distance < finalDistance) then
                finalDistance = distance
                finalTarget = target
            end
        end

        --print(finalDistance)

        local travel = Vector3.zero
        local displacement : Vector3
        if (finalTarget) then
            displacement = (finalTarget.Position + finalTarget.Velocity - Position) * Vector3.new(1,0,1)
        end
        travel = Pathfinding.GetNavgrid("ZombieGeneric"):KernalConvolute(Position + Velocity*0.1)
        if (finalTarget) then
            if (finalTarget.Part) then
                local theta = math.acos(travel:Dot(finalTarget.Position - Position))
                --print(math.deg(theta))
                if (theta <= math.rad(15)) then
                    travel = (finalTarget.Position - Position).Unit
                end
            end
        end


        --[[NOTE
            if the travel's angle is within THETA of the player, snap the move direction towards the player
        ]]

        local Quad = QuadtreeModule.GetQuadtree("GroundUnits")
        local NearbyPoints = Quad:QueryRange(QuadtreeModule.BuildCircle(Position.X, Position.Z, CollisionRadius))
        --print(NearbyPoints)

        local BaddieCumulativePosition = Vector3.zero
        for _, Point in NearbyPoints do
            --print(Point)
            if Point.Data.Entity == Entity then continue end

            local OtherEntity = Point.Data.Entity
            local OtherEntityData = CharacterStates.World.get(OtherEntity)
            local OtherEntityEnum = OtherEntityData.NPCType

            --If other entity is not an npc, continue
            if not OtherEntityData.NPC then continue end

            local Difference = (Vector3.new(Point.X, 0, Point.Y) - Position) * Vector3.new(1,0,1)
            BaddieCumulativePosition += Difference*
                ((NpcRegistry.GetMass(OtherEntityEnum) or 1) / (NpcRegistry.GetMass(NpcEnum) or 1))*
                (math.max(0.001, 1-Difference.Magnitude/(CollisionRadius + (NpcRegistry.GetCollisionRadius(OtherEntityEnum) or 0))))^0.5 
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
            local MoveDirection = ((travel*1)+(MoveAwayVector*2.25)).Unit
            CharacterController:SendMessage("UpdateMoveDirection", NpcId, MoveDirection)
            --MovementData.travel = travel
        end
	    --return travel
    end
end)