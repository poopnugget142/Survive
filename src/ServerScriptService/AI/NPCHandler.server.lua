local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local Remotes = ReplicatedStorage.Remotes

local Squash = require(ReplicatedStorage.Packages.Squash)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local EventHandler = require(ReplicatedStorage.Scripts.Lib.Util.EventHandler)

local CharacterControllerWorkers = ServerScriptService.AI.CharacterControllerWorkers
local CharacterController = CharacterControllerWorkers.CharacterController

local AllMovementData = SharedTableRegistry:GetSharedTable("AllMovementData")

local RequestNPC : RemoteFunction = Remotes.RequestNPC
local UpdateNPCPosition : RemoteEvent = ReplicatedStorage.Remotes.UpdateNPCPosition

local CreateMovementData = EventHandler.CreateEvent("CreateMovementData")
local RemoveMovementData = EventHandler.CreateEvent("RemoveMovementData")

local NumberOfActors = 64
local CoreNumber = 0
local Workers = {}
local BoundIds = {}

while #Workers < NumberOfActors do
    local Actor = Instance.new("Actor")
    CharacterController:Clone().Parent = Actor
    table.insert(Workers, Actor)
    Actor.Parent = CharacterControllerWorkers
end

CreateMovementData:Connect(function(Entity)
    local EntityData = CharacterStates.World.get(Entity)
    local NpcId = EntityData[CharacterStates.NPCId]

    local RandomActor = Workers[CoreNumber % NumberOfActors + 1]
    CoreNumber += 1

    BoundIds[NpcId] = RandomActor
    RandomActor:SendMessage("AddNpc", NpcId)
end)

RemoveMovementData:Connect(function(Entity)
    local EntityData = CharacterStates.World.get(Entity)
    local NpcId = EntityData[CharacterStates.NPCId]

    local Actor = BoundIds[NpcId]
    if Actor then
        Actor:SendMessage("RemoveNpc", NpcId)
    end
end)

--Using the NpcId, we can get the NPC enum from the server
RequestNPC.OnServerInvoke = function(Player, NpcId)
    local Entity = CharacterModule.GetEntityFromNpcId(NpcId)
    local EntityData = CharacterStates.World.get(Entity)

    local NpcEnum = EntityData[CharacterStates.NPCType]

    assert(NpcEnum, "No NPC enum")

    local CompressedEnum = Squash.uint.ser(NpcEnum, 2)
    
    return CompressedEnum
end

--Sends the position of all NPCs to the client
while task.wait(0.05) do
    local PositionDataArray = {}
    for NpcId, MovementData in AllMovementData do
        local Position = MovementData.Position
        table.insert(PositionDataArray, Squash.uint.ser(NpcId, 2))
        table.insert(PositionDataArray, Squash.Vector3.ser(Position))
    end

    if #PositionDataArray == 0 then continue end

    UpdateNPCPosition:FireAllClients(PositionDataArray)
end