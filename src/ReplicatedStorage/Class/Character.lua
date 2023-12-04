local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local Remotes = ReplicatedStorage.Remotes

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Squash = require(ReplicatedStorage.Packages.Squash)
local Signal = require(ReplicatedStorage.Packages.Signal)
local EventHandler = require(ReplicatedStorage.Scripts.Util.EventHandler)
local QuadtreeModule = require(ReplicatedStorage.Scripts.Util.Quadtree)
local NpcRegistry = require(ReplicatedStorage.Scripts.Registry.NPC)
local Enums = require(ReplicatedStorage.Scripts.Enums)

local NpcAction : RemoteEvent = Remotes.NpcAction

local AllMovementData = SharedTable.new()
SharedTableRegistry:SetSharedTable("AllMovementData", AllMovementData)

local CharacterToEntity = {}
local IdToNpc = {}
local CharacterStateData = {}

local NpcId = 0

local Module = {}

Module.States = CharacterStates

Module.IdToNpc = IdToNpc

--Returns the first ancestor Model of Object that has an "Character" tag, nil if none are found
Module.FindFirstCharacter = function(Object : Instance)
    if CollectionService:HasTag(Object, "Character") then return Object end

    local Ancestor = Object:FindFirstAncestorWhichIsA("Model")
    if not Ancestor then return end

    return Module.FindFirstCharacter(Ancestor)
end

--Easy way to update health and update the event
Module.UpdateHealth = function(Entity : any, HealthDifference : number, DamageType : number?)
    local HealthData = CharacterStates.World.get(Entity)[CharacterStates.Health]

    if (HealthData) then
        local DamageAmount = HealthDifference/HealthData.Max
        HealthData.Current += DamageAmount --damage
        HealthData.Update:Fire(Entity, DamageAmount, DamageType)
    else
        warn("Attempted to damage an entity with no health!")
    end
end

--Easy way to update health and update the event
Module.UpdateSpeed = function(Entity : any, NewSpeed : number)
    local CharacterController : Actor = ServerScriptService.CharacterController

    local EntityData = CharacterStates.World.get(Entity)
    local SpeedData = EntityData[CharacterStates.WalkSpeed]

    SpeedData.Current = NewSpeed
    CharacterController:SendMessage("UpdateWalkSpeed", EntityData.NPCId, NewSpeed)
end

--Adds all proper tags to the character and registers it's entity to it's model
Module.RegisterCharacter = function(Entity : any, Character : Model)
    CharacterToEntity[Character] = Entity

    CharacterStates.Model.add(Entity, Character)
    CharacterStates.Character.add(Entity)
end

--Returns entity from character
Module.GetEntityFromCharacter = function(Character : Model)
    return CharacterToEntity[Character]
end

--Assigns a baddie a custom ID and gives it it's tags
Module.RegisterNPC = function(Entity : any, CustomId : number?)
    if CustomId then
        IdToNpc[CustomId] = Entity
        CharacterStates.NPCId.add(Entity, CustomId)
        return
    end

    NpcId += 1
    IdToNpc[NpcId] = Entity
    CharacterStates.NPCId.add(Entity, NpcId)

    return NpcId
end

--Returns entity from baddie id
Module.GetEntityFromNpcId = function(EntityNpcId : number)
    return IdToNpc[EntityNpcId]
end

Module.CreateNPC = function(NpcEnum : number, SpawnLocation : CFrame?)
    local Entity = CharacterStates.World.entity()
    CharacterStates.NPCType.add(Entity, NpcEnum)
    CharacterStates[NpcEnum].add(Entity, SpawnLocation)

    return Entity
end

Module.Action = function(Entity : any, Action : number)
    local CharacterData = CharacterStates.World.get(Entity)
    local EntityNpcId = CharacterData[CharacterStates.NPCId]

    local CompressedId = Squash.uint.ser(EntityNpcId, 2)
    local CompressedAction = Squash.uint.ser(Action, 2)

    NpcAction:FireAllClients(CompressedId, CompressedAction)
end

Module.CreateMovementData = function(Entity : any, SpawnPosition : Vector3?)
    local CharacterData = CharacterStates.World.get(Entity)

    local WalkSpeed = CharacterData[CharacterStates.WalkSpeed].Current
    local EntityNpcId = CharacterData[CharacterStates.NPCId]

    AllMovementData[EntityNpcId] = {
        MoveDirection =  Vector3.new()
        ;LookDirection = Vector3.new()
        ;Velocity = Vector3.new()
        ;AccumulatedTime = 0
        ;Position = SpawnPosition or Vector3.zero
        ;WalkSpeed = WalkSpeed or 16
    }
end

Module.RemoveMovementData = function(Entity : any)
    local CharacterData = CharacterStates.World.get(Entity)
    local EntityNpcId = CharacterData[CharacterStates.NPCId]

    AllMovementData[EntityNpcId] = nil
end

Module.GetPosition = function(Entity : any)
    local CharacterData = CharacterStates.World.get(Entity)
    local EntityNpcId = CharacterData[CharacterStates.NPCId]

    return AllMovementData[EntityNpcId].Position
end

Module.GetMovementData = function(Entity : any)
    local CharacterData = CharacterStates.World.get(Entity)
    local EntityNpcId = CharacterData[CharacterStates.NPCId]

    return AllMovementData[EntityNpcId]
end

Module.PlayAnimation = function(Entity : any, State: number)
    local EntityData = CharacterStates.World.get(Entity)
    local LoadedAnimations = EntityData[CharacterStates.LoadedAnimations]
    local CurrentAnimation = EntityData[CharacterStates.CurrentAnimation]

    if CurrentAnimation then
        CurrentAnimation:Stop()
    end

    CurrentAnimation = LoadedAnimations[State]

    EntityData[CharacterStates.CurrentAnimation] = CurrentAnimation
    CurrentAnimation:Play()
end

Module.SetState = function(Entity: any, State : number, ...)
    local EntityData = CharacterStates.World.get(Entity)

    if not EntityData[CharacterStates.State] then
        --There was no previous state
        CharacterStates.State.add(Entity, State)
    else
        local LastState = EntityData[CharacterStates.State]

        if LastState == State then return end

        EntityData[CharacterStates.State] = State

        local LastStateData = Module.GetStateData(Entity, LastState)
        LastStateData.Leave:Fire(Entity)
    end

    CharacterStates[State].add(Entity)
    local StateData = Module.GetStateData(Entity, State)
    StateData.Enter:Fire(Entity, ...)

    EventHandler.FireEvent(Entity, "SetState", State)

    return StateData
end

local function CreateStateData()
    return {
        Leave = Signal.new()
        ;Enter = Signal.new()
    }
end

Module.GetStateData = function(Entity : any, State : number)
    if not CharacterStateData[Entity] then
        CharacterStateData[Entity] = {}
    end

    if not CharacterStateData[Entity][State] then
        CharacterStateData[Entity][State] = CreateStateData()
    end

    return CharacterStateData[Entity][State]
end

Module.GetMoveAwayVector = function(Quad, Entity : any)
    local EntityData = CharacterStates.World.get(Entity)
    local NpcEnum = EntityData[CharacterStates.NPCType]

    local MovementData = Module.GetMovementData(Entity)
    local Position = MovementData.Position

    local CollisionRadius = NpcRegistry.GetCollisionRadius(NpcEnum)

    local NearbyPoints = Quad:QueryRange(QuadtreeModule.BuildCircle(Position.X, Position.Z, CollisionRadius))
    print(NearbyPoints)

    local BaddieCumulativePosition = Vector3.zero
    for _, Point in NearbyPoints do

        if Point.Data.Entity == Entity then continue end

        local OtherEntity = Point.Data.Entity
        local OtherEntityData = CharacterStates.World.get(OtherEntity)
        local OtherEntityEnum = OtherEntityData[CharacterStates.NPCType]

        --If other entity is not an npc, continue
        if not OtherEntityData[CharacterStates.NPCId] then continue end

        local Difference = (Vector3.new(Point.X, 0, Point.Y) - Position) * Vector3.new(1,0,1)
        BaddieCumulativePosition += Difference*
            ((NpcRegistry.GetMass(OtherEntityEnum) or 1) / (NpcRegistry.GetMass(NpcEnum) or 1))*
            (math.max(0.001, 1-Difference.Magnitude/(CollisionRadius + (NpcRegistry.GetCollisionRadius(OtherEntityEnum) or 0))))^0.5
    end

    --Reverse the vector
    local MoveAwayVector
    if BaddieCumulativePosition.Magnitude == 0 then
        MoveAwayVector = Vector3.zero
    else
        MoveAwayVector = -(BaddieCumulativePosition)
    end

    return MoveAwayVector
end

Module.GetNearbyHostiles = function(Quad, Entity : any, Position : Vector3, Radius : number)
    local NearbyPoints = Quad:QueryRange(QuadtreeModule.BuildCircle(Position.X, Position.Z, Radius))

    local NearbyHostiles = {}
    for _, Point in NearbyPoints do
        --Need a way to check if entity is hostile perhaps a team system
        if Point.Data.Entity == Entity then continue end

        local OtherEntity = Point.Data.Entity
        local OtherEntityData = CharacterStates.World.get(OtherEntity)

        if OtherEntityData[CharacterStates.NPCId] then continue end

        table.insert(NearbyHostiles, OtherEntity)
    end

    return NearbyHostiles
end

return Module