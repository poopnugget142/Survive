local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ReplicatedScripts = ReplicatedStorage.Scripts

local Util = require(ReplicatedScripts.Lib.Util)
local CharacterStates = require(ReplicatedScripts.States.Character)
local Enums = require(ReplicatedScripts.Registry.Enums)
--local Pathfinding = require(ReplicatedScripts.Lib.AI.PathfindingCore)
local Pathfinding2 = require(ReplicatedScripts.Lib.AI.FastPathCore)
local CharacterModule = require(ReplicatedScripts.Class.Character)
local NpcRegistry = require(ReplicatedScripts.Registry.NPC)
local QuadtreeModule = require(ReplicatedScripts.Lib.Quadtree)
local PriorityQueueModule = require(ReplicatedScripts.Lib.PriorityQueue)

local NpcEnum = Enums.NPC.Guy
print(NpcEnum)

local AttackRange = NpcRegistry.GetAttackRange(NpcEnum)

local function OnHit(Entity : any)
    local HealthData = CharacterStates.Health.add(Entity, 100)

    --I'VE DIED NOOOOOOOOOOO
    if HealthData.Current <= 0 then
        print("Killed a dude")
        CharacterModule.RemoveMovementData(Entity)
        CharacterStates.World.kill(Entity)
    end
end

local function OnAttack(Entity : any)
    CharacterModule.Action(Entity, Enums.Action.Attack)

    task.wait(1)
    local MovementData = CharacterModule.GetMovementData(Entity)
    local Position = MovementData.Position

    local Quad = QuadtreeModule.GetQuadtree("GroundUnits")
    local NearbyHostiles = CharacterModule.GetNearbyHostiles(Quad, Entity, Position, AttackRange)

    for _, OtherEntity in NearbyHostiles do
        CharacterModule.UpdateHealth(OtherEntity, -10, Enums.DamageType.Physical)
    end

    task.wait(0.6)

    CharacterModule.SetState(Entity, Enums.States.Walking)
end

local function OnWalk(Entity : any)
    CharacterModule.Action(Entity, Enums.Action.Walk)
end

CharacterStates[NpcEnum] = CharacterStates.World.factory({
    add = function(Factory, Entity : any, SpawnPosition : Vector3)
        local NpcId = CharacterModule.RegisterNPC(Entity)

        local AttackData = CharacterModule.GetStateData(Entity, Enums.States.Attacking)
        AttackData.Enter:Connect(OnAttack)

        local WalkData = CharacterModule.GetStateData(Entity, Enums.States.Walking)
        WalkData.Enter:Connect(OnWalk)

        CharacterModule.SetState(Entity, Enums.States.Walking)

        local HealthData = CharacterStates.Health.add(Entity, 100)
        HealthData.Update:Connect(function() OnHit(Entity) end)
        
        CharacterStates.WalkSpeed.add(Entity, 10)
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
        local MovementData = CharacterModule.GetMovementData(Entity)
        local Position = MovementData.Position
        local Velocity = MovementData.Velocity
        local NPCId = EntityData[CharacterStates.NPCId]

        --[==[
        local Navgrid = Pathfinding.GetNavgrid("ZombieGeneric")

        if not Navgrid then continue end

        local targets = Navgrid.Targets
        --print(Navgrid.Targets)
	    local distanceThreshold = math.huge

        local finalTarget
        local finalDistance = distanceThreshold

        if not targets or #targets == 0 then continue end
        for _, target in targets do
            --[[
            if (type(target) == "userdata") then target = target.Position end
            local distance = (target - Position).Magnitude
            if distance < finalDistance then
                finalDistance = distance
                finalTarget = target
            end
            ]]
            --target = Pathfinding.BuildTarget(target)
            local distance = (
                target.Position3
                + target.Velocity3
                - Position
            ).Magnitude
            if (distance < finalDistance) then
                finalDistance = distance
                finalTarget = target
            end
        end

        --print(finalDistance)

        local travel = Vector3.zero
        local displacement : Vector3
        if (finalTarget) then
            displacement = (finalTarget.Position3 + finalTarget.Velocity3 - Position) * Vector3.new(1,0,1)
        end

        travel = Navgrid:KernalConvolute(Position + Velocity*0.1)
        if (finalTarget) then
            if (finalTarget.Part) then
                local theta = math.acos(travel:Dot(finalTarget.Position3 - Position))
                --print(math.deg(theta))
                if (theta <= math.rad(15)) then
                    travel = (finalTarget.Position3 - Position).Unit
                end
            end
        end
        ]==]

        local Targets = PriorityQueueModule.BuildPriorityQueue(function(a, b)
            local A = (a - Position).Magnitude
            local B = (b - Position).Magnitude 
            return A - B
        end)
        for _, Player : Player in Players:GetPlayers() do
            if not Player.Character then continue end
            local Target = Player.Character.PrimaryPart.CFrame.Position
            Targets:Enqueue(Target)
        end 

        local TileGrid : Pathfinding2.TileGrid = Pathfinding2.GetTileGrid("ZombieGeneric")
        local Target = Targets:Dequeue()

        local HeuristicFn = function(Front)
            return Vector2.new(Target.X - Front.Boundary.X, Target.Z - Front.Boundary.Y).Magnitude*2*(Front.Node.Layer+1)
        end
        local Query = TileGrid:AStarQuery(Pathfinding2.BuildTarget(Position), Pathfinding2.BuildTarget(Target), HeuristicFn, true)
        local Direction = Query.Direction.Unit

        local Delta = (Target - Position)
        local travel = (Vector3.new(Direction.X, 0, Query.Direction.Y) 
            + Delta.Unit*25/Delta.Magnitude
        ).Unit


        --[[NOTE
            if the travel's angle is within THETA of the player, snap the move direction towards the player
        ]]

        local Quad = QuadtreeModule.GetQuadtree("GroundUnits")

        local NearbyHostiles = CharacterModule.GetNearbyHostiles(Quad, Entity, Position, AttackRange)

        if #NearbyHostiles > 0 then
            CharacterModule.SetState(Entity, Enums.States.Attacking)
        end

        local MoveAwayVector = CharacterModule.GetMoveAwayVector(Quad, Entity)

        if not travel then travel = Vector3.zero end
        local MoveDirection = ((travel*1)+(MoveAwayVector*2.25)).Unit
        CharacterModule.UpdateMoveDirection(Entity, MoveDirection)
    end
end)