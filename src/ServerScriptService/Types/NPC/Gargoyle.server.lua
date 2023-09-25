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

local NpcEnum = Enums.NPC.Gargoyle
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

CharacterStates[NpcEnum] = CharacterStates.World.factory(NpcEnum, {
    add = function(Factory, Entity : any, SpawnPosition : Vector3)
        local NpcId = CharacterModule.RegisterNPC(Entity)

        local HealthData = CharacterStates.Health.add(Entity, 100)
        HealthData.Update:Connect(function() OnHit(Entity) end)

        --[[
        CharacterStates.Character.add(Entity)
        CharacterStates.Baddie.add(Entity)

        CharacterStates.MovementData.add(Entity)
        ]]
        CharacterStates.WalkSpeed.add(Entity, 12)
        CharacterStates.AutoRotate.add(Entity)
        CharacterStates.Moving.add(Entity)

        CharacterModule.CreatedMovementData(Entity, SpawnPosition)
        
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
        travel = Pathfinding.GetNavgrid("ZombieFlying"):KernalConvolute(Position + Velocity*0.1)
        if (finalTarget) then
            if (finalTarget.Part) then
                local theta = math.acos(travel:Dot(finalTarget.Position - Position))
                --print(math.deg(theta))
                if (theta <= math.rad(15)) then
                    travel = (finalTarget.Position - Position).Unit
                end
            end
        end

        if (travel ~= Vector3.zero and travel ~= nil) then
            local MoveDirection = travel.Unit
            CharacterController:SendMessage("UpdateMoveDirection", NpcId, MoveDirection)
            --MovementData.travel = travel
        end
	    --return travel
    end
end)