local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Remotes = ReplicatedStorage.Remotes
local ReplicatedScripts = ReplicatedStorage.Scripts

local EquipmentModule = require(script.Parent)
local ItemStates = require(ReplicatedScripts.States.Item)
local CharacterStates = require(ReplicatedScripts.States.Character)
local CharacterModule = require(ReplicatedScripts.Class.Character)
local QuadtreeModule = require(ReplicatedScripts.Lib.Quadtree)
local GunModule = require(ReplicatedScripts.Class.Gun)
local Enums = require(ReplicatedScripts.Registry.Enums)
local Util = require(ReplicatedScripts.Lib.Util)

local CreateTracerRemote : RemoteEvent = Remotes.CreateTracer

local GunEnum = Enums.Item.Shotgun

local Module = {}

Module.Register = function(Entity)
end

Module.SetEquipmentModel = function(Entity)
    local EntityData = ItemStates.World.get(Entity)

    if EntityData[ItemStates.Model] then
        ItemStates.Model.remove(Entity)
        return
    end

    local Model = Assets.Guns.Shotgun:Clone()

    local Handle = Model.Handle
    local Grip = Handle.Grip

    local Player = EntityData[ItemStates.Owner]

    local Character = Player.Character

    Model.Parent = Character
    Grip.Part1 = Character.RightHand

    ItemStates.Model.add(Entity, Model)

    EquipmentModule.BackwardsAction("SetEquipmentModel", Entity, Model)
end

--In the future we can check if this really hit but for now we trust it
Module.Attack = function(Entity, MousePosition)
    local EquipmentData = ItemStates.World.get(Entity)
    local GunOwner = EquipmentData[ItemStates.Owner]
    local Model = EquipmentData[ItemStates.Model]

    local Origin = Model.Muzzle.Position

    local TracerPlayers = Util.GetAllPlayersExcept{GunOwner}

    --Explosions
    local TracerTargets = {}
    for _ = 1, 1, 1 do
        local BulletResult = GunModule.BulletShoot(Origin, MousePosition)
        if not BulletResult then continue end
        local HitPosition = BulletResult.TerrainResult.Position

        table.insert(TracerTargets, BulletResult.TerrainResult)


        for i, Player in TracerPlayers do
            CreateTracerRemote:FireClient(Player, Origin, HitPosition, GunEnum, Enums.Bullet["9mmTracer"])
        end

        --
        local Radius = 12

        local Quad = QuadtreeModule.GetQuadtree("GroundUnits")
        local NearbyPoints = Quad:QueryRange(QuadtreeModule.BuildCircle(HitPosition.X, HitPosition.Z, Radius))


        --[[ Base Implementation, damage closest enemy
        local NaiveDistanceCheck = {
            MinDistance = math.huge,
            MinTarget = nil
        }
        for _, Point in NearbyPoints do
            --print(Point)
            local Difference : Vector3= (Vector3.new(Point.X, 0, Point.Y) - HitPosition) * Vector3.new(1,0,1)
            if (Difference.Magnitude < NaiveDistanceCheck.MinDistance) then
                NaiveDistanceCheck.MinDistance = Difference.Magnitude
                NaiveDistanceCheck.MinTarget = Point.Data.NpcId
            end
        end
    
        local NpcId = NaiveDistanceCheck.MinTarget
        if not NpcId then return end
    
        local HitEntity = CharacterModule.GetEntityFromNpcId(NpcId)
        if not HitEntity then return end
    
        local HitData = CharacterStates.World.get(HitEntity)
        if not HitData.Health then return end
    
        --local CurrentHealth = HitData.Health.Current
    
        CharacterModule.UpdateHealth(HitEntity, -100)
        
        if (HitData.Crippled) then
            HitData.Crippled = math.max(HitData.Crippled, 0.5)
        else
            CharacterStates.Crippled.add(HitEntity, 0.5)
        end
        --]]


        --AoE implementation
        --
        local Victims = {}
        for _, Point in NearbyPoints do
            local HitEntity = Point.Data.Entity
            if not HitEntity then continue end

            local HitData = CharacterStates.World.get(HitEntity)
            if not HitData[ItemStates.Health] then return end

            CharacterModule.UpdateHealth(HitEntity, -100)
        end
        print("Hit ", #NearbyPoints, " enemies in an explosion")
        --]]

        -- Piercing implementation
        --[[
        local Victims = {}

        local PierceLength = 20
        local PierceWidth = 2
        local PierceCount = 3
        local PierceDirection = (HitPosition - Origin).Unit * Vector3.new(1,0,1)
        --print(PierceDirection)

        local Quad = QuadtreeModule.GetQuadtree("GroundUnits")
        local NearbyPoints = Quad:QueryRange(
            QuadtreeModule.BuildCircle(
                HitPosition.X + PierceDirection.X*PierceLength/2
                , HitPosition.Z + PierceDirection.Z*PierceLength/2
                , PierceLength/2 + PierceWidth
            )
        )
        local Queue = PriorityQueue.Create()
        Queue.ComparatorGetFunction = function(Value : any)
            local Point = Queue.Values[Value]
            local Vector = Vector3.new(Point.X, HitPosition.Y, Point.Y) - HitPosition

            local Dot --= HitPosition:Dot(Vector)
                        = PierceDirection:Dot(Vector)
            print(Dot)
            return Dot
        end

        for _, Point in NearbyPoints do
            Queue:Enqueue(Point)
        end
        if #Queue.Values > 0 then print(Queue) end
        local _PierceCount = 0
        while #Queue.Values > 0 and _PierceCount < PierceCount do
            local Point = Queue:Dequeue()
            if not (Point and Point.Data) then continue end

            local NpcId = Point.Data.NpcId
            if not NpcId then continue end

            local HitEntity = CharacterModule.GetEntityFromNpcId(NpcId)
            if not HitEntity then return end


            local WidthDot = (Vector3.new(Point.X, 0, Point.Y) - HitPosition):Dot(Vector3.new(-PierceDirection.Z, 0, PierceDirection.X))
            --print(WidthDot)
            if WidthDot > PierceWidth then continue end -- MISSING SHIT -> add reference to NPC radius to improve hit detection

            local HitData = CharacterStates.World.get(HitEntity)
            if not HitData.Health then return end

            CharacterModule.UpdateHealth(HitEntity, -100)
            if (HitData.Crippled) then
                HitData.Crippled = math.max(HitData.Crippled, 0.5)
            else
                CharacterStates.Crippled.add(HitEntity, 0.5)
            end
            _PierceCount += 1
        end
        --]]

        --[[
        if (HitData.Burning) then
            HitData.Burning += 100
        else
            CharacterStates.Burning.add(HitEntity, 100)
        end
        ]]
    end
end

return Module