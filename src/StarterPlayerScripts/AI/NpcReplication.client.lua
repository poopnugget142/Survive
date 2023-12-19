local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")
local Player = game:GetService("Players").LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Replicator = Player.PlayerScripts.AI:WaitForChild("Replicator")

local ReplicatedScripts = ReplicatedStorage.Scripts

local Squash = require(ReplicatedStorage.Packages.Squash)
local Promise = require(ReplicatedStorage.Packages.Promise)

local CharacterModule = require(ReplicatedScripts.Class.Character)
local CharacterStates = require(ReplicatedScripts.States.Character)
local Enums = require(ReplicatedScripts.Registry.Enums)
local EventHandler = require(ReplicatedScripts.Lib.Util.EventHandler)

local NpcReplication : Script = Replicator:WaitForChild("NpcReplicator")

local UpdateNPCPosition : RemoteEvent = Remotes:WaitForChild("UpdateNPCPosition")
local RequestNPC : RemoteFunction = Remotes.RequestNPC
local NpcAction : RemoteEvent = Remotes.NpcAction

local CurrentCamera = workspace.CurrentCamera

local SharedNpcData = SharedTable.new()
local QueryNpcModels = SharedTable.new()

SharedTableRegistry:SetSharedTable("NpcData", SharedNpcData)
SharedTableRegistry:SetSharedTable("QueryNpcModels", QueryNpcModels)

local DeleteNpc = EventHandler.CreateEvent("DeleteNpc")

local NumberOfActors = 64
local CoreNumber = 0
local Workers = {}
local BoundIds = {}

while #Workers < NumberOfActors do
    local Actor = Instance.new("Actor")
    NpcReplication:Clone().Parent = Actor
    table.insert(Workers, Actor)
    Actor.Parent = Replicator
end

local function CreateNewNpc(NpcId : number, Position : Vector3)
    CharacterModule.IdToNpc[NpcId] = Promise.try(function()
        local CompressedEnum = RequestNPC:InvokeServer(NpcId)
        local NpcEnum = Squash.uint.des(CompressedEnum, 2)

        local Entity = CharacterStates.World.entity()
        CharacterModule.RegisterNPC(Entity, NpcId)
        CharacterStates[NpcEnum].add(Entity, Position)

        SharedNpcData[tostring(NpcId)] = {
            Enum = NpcEnum;
            LastPosition = Position;
            LastTick = tick();
            NewPosition = Position;
            NewTick = tick();
            Alpha = 0;
            Hidden = true;
        }

        local RandomActor = Workers[CoreNumber % NumberOfActors + 1]
        CoreNumber += 1

        BoundIds[NpcId] = RandomActor
        RandomActor:SendMessage("AddNpc", NpcId)

        return Entity
    end)
end

UpdateNPCPosition.OnClientEvent:Connect(function(PositionDataArray)
    for i = 1, #PositionDataArray, 2  do
        local NpcId = Squash.uint.des(PositionDataArray[i], 2)
        local Position = Squash.Vector3.des(PositionDataArray[i + 1])

        local Entity = CharacterModule.GetEntityFromNpcId(NpcId)

        if Promise:is(Entity) then
            --It's still loading it's model
            continue
        end

        if not Entity then
            Entity = CreateNewNpc(NpcId, Position)
            continue
        end

        local NpcData = SharedNpcData[tostring(NpcId)]

        if not NpcData then continue end

        NpcData.LastPosition = NpcData.NewPosition
        NpcData.LastTick = NpcData.NewTick
        NpcData.NewPosition = Position
        NpcData.NewTick = tick()
        NpcData.Alpha = 0
    end
end)

DeleteNpc:Connect(function(_, NpcId : number)
    local Actor = BoundIds[NpcId]
    if Actor then
        Actor:SendMessage("RemoveNpc", NpcId)
        BoundIds[NpcId] = nil
    end
end)

NpcAction.OnClientEvent:Connect(function(CompressedId, CompressedAction)
    local NpcId = Squash.uint.des(CompressedId, 2)
    local Action = Squash.uint.des(CompressedAction, 2)

    local Entity = CharacterModule.GetEntityFromNpcId(NpcId)

    if not Entity then return end

    EventHandler.FireEvent(Entity, "Action", Action)
end)

RunService.RenderStepped:Connect(function(DeltaTime)
    local CenterResult = workspace:Raycast(CurrentCamera.CFrame.Position, CurrentCamera.CFrame.LookVector * 1000, RaycastParams.new())
    local CenterPosition = CenterResult and CenterResult.Position or Vector3.zero
    SharedNpcData.CenterPosition = CenterPosition

    --When the actor queries to create a new npc, it will do so here
    for NpcId, Value in QueryNpcModels do
        QueryNpcModels[NpcId] = nil
        
        local Entity = CharacterModule.GetEntityFromNpcId(NpcId)

        if not Entity then continue end

        if not Value then
            EventHandler.FireEntityEvent(Entity, "RemoveModel")
            continue
        end
        
        EventHandler.FireEntityEvent(Entity, "CreateModel", Value)
    end
end)