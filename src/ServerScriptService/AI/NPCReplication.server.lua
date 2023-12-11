local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local Remotes = ReplicatedStorage.Remotes

local Squash = require(ReplicatedStorage.Packages.Squash)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

local AllMovementData = SharedTableRegistry:GetSharedTable("AllMovementData")

local RequestNPC : RemoteFunction = Remotes.RequestNPC
local UpdateNPCPosition : RemoteEvent = ReplicatedStorage.Remotes.UpdateNPCPosition

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