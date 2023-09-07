local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")
local Player = game:GetService("Players").LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Replicator = Player.PlayerScripts:WaitForChild("Replicator")

local Squash = require(ReplicatedStorage.Packages.Squash)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Enums = require(ReplicatedStorage.Scripts.Enums)

local NpcReplication : Script = Replicator:WaitForChild("NpcReplicator")

local UpdateNPCPosition : RemoteEvent = Remotes:WaitForChild("UpdateNPCPosition")
local RequestNPC : RemoteFunction = Remotes.RequestNPC
local NpcAction : RemoteEvent = Remotes.NpcAction

local CurrentCamera = workspace.CurrentCamera

local SharedNpcData = SharedTable.new()

SharedTableRegistry:SetSharedTable("NpcData", SharedNpcData)

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

        local EntityData = CharacterStates.World.get(Entity)

        SharedNpcData[tostring(NpcId)] = {
            Enum = NpcEnum;
            LastPosition = Position;
            LastTick = tick();
            NewPosition = Position;
            NewTick = tick();
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
    end
end)

--Later let's move this to be able to hook up to the enum so it can have custom actions
NpcAction.OnClientEvent:Connect(function(CompressedId, CompressedAction)
    local NpcId = Squash.uint.des(CompressedId, 2)
    local Action = Squash.uint.des(CompressedAction, 2)

    if Action == Enums.Action.Die then
        local Actor = BoundIds[NpcId]
        if Actor then
            Actor:SendMessage("RemoveNpc", NpcId)
            BoundIds[NpcId] = nil
        end
    end
end)

RunService.RenderStepped:Connect(function(DeltaTime)
    local CenterResult = workspace:Raycast(CurrentCamera.CFrame.Position, CurrentCamera.CFrame.LookVector * 1000, RaycastParams.new())
    local CenterPosition = CenterResult and CenterResult.Position or Vector3.zero
    SharedNpcData.CenterPosition = CenterPosition
end)

workspace.Characters.NPCs.ChildAdded:Connect(function(Character : Model)
    if not Character:FindFirstChild("Model") then
        task.wait()
        --You have to pause the thread to delete the character for some reason
        Character:Destroy()
    else
        local Entity = CharacterModule.GetEntityFromNpcId(tonumber(Character.Name))
        CharacterModule.RegisterCharacter(Entity, Character)
    end
end)