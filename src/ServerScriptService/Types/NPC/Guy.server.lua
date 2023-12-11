local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.Scripts

local CharacterStates = require(ReplicatedScripts.States.Character)
local Enums = require(ReplicatedScripts.Registry.Enums)
local Pathfinding = require(ReplicatedScripts.Lib.AI.PathfindingCore)
local CharacterModule = require(ReplicatedScripts.Class.Character)
local NpcRegistry = require(ReplicatedScripts.Registry.NPC)
local QuadtreeModule = require(ReplicatedScripts.Lib.Quadtree)

local CharacterController = ServerScriptService.AI.CharacterController

local NpcEnum = Enums.NPC.Guy

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

        local targets = Pathfinding.targets
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

        local Navgrid = Pathfinding.GetNavgrid("ZombieGeneric")

        if not Navgrid then continue end

        travel = Navgrid:KernalConvolute(Position + Velocity*0.1)
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

        local NearbyHostiles = CharacterModule.GetNearbyHostiles(Quad, Entity, Position, AttackRange)

        if #NearbyHostiles > 0 then
            CharacterModule.SetState(Entity, Enums.States.Attacking)
        end

        local MoveAwayVector = CharacterModule.GetMoveAwayVector(Quad, Entity)

        if (travel ~= Vector3.zero and travel ~= nil) then
            local MoveDirection = ((travel*1)+(MoveAwayVector*2.25)).Unit
            CharacterController:SendMessage("UpdateMoveDirection", NPCId, MoveDirection)
        end
    end
end)