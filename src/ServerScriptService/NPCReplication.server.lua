local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes

local Squash = require(ReplicatedStorage.Packages.Squash)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

local RequestNPC : RemoteFunction = Remotes.RequestNPC

RequestNPC.OnServerInvoke = function(Player, NpcId)
    local Entity = CharacterModule.GetEntityFromNpcId(NpcId)
    local EntityData = CharacterStates.World.get(Entity)

    local NpcEnum = EntityData.NPCType

    assert(NpcEnum, "No NPC enum")

    local CompressedEnum = Squash.uint.ser(NpcEnum, 2)
    
    return CompressedEnum, NpcEnum
end