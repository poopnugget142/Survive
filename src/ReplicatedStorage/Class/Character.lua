local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = ReplicatedStorage.Remotes

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Squash = require(ReplicatedStorage.Packages.Squash)

local NpcAction : RemoteEvent = Remotes.NpcAction

local CharacterToEntity = {}
local IdToNpc = {}

local NpcId = 0

local Module = {}

Module.IdToNpc = IdToNpc

--Returns the first ancestor Model of Object that has an "Character" tag, nil if none are found
Module.FindFirstCharacter = function(Object : Instance)
    if CollectionService:HasTag(Object, "Character") then return Object end

    local Ancestor = Object:FindFirstAncestorWhichIsA("Model")
    if not Ancestor then return end

    return Module.FindFirstCharacter(Ancestor)
end

--Easy way to update health and update the event
Module.UpdateHealth = function(Entity : any, NewHealth : number)
    local HealthData = CharacterStates.World.get(Entity).Health

    --HealthData.Current = NewHealth
    HealthData.Current += NewHealth/HealthData.Max --damage
    HealthData.Update:Fire()
end

--Easy way to update health and update the event
Module.UpdateSpeed = function(Entity : any, NewSpeed : number)
    local CharacterController : Actor = ServerScriptService.CharacterController

    local EntityData = CharacterStates.World.get(Entity)
    local SpeedData = EntityData.WalkSpeed

    SpeedData.Current = NewSpeed
    CharacterController:SendMessage("UpdateWalkSpeed", EntityData.NPC, NewSpeed)
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
        CharacterStates.NPC.add(Entity, CustomId)
        return
    end

    NpcId += 1
    IdToNpc[NpcId] = Entity
    CharacterStates.NPC.add(Entity, NpcId)

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
    local EntityNpcId = CharacterData.NPC

    local CompressedId = Squash.uint.ser(EntityNpcId, 2)
    local CompressedAction = Squash.uint.ser(Action, 2)

    NpcAction:FireAllClients(CompressedId, CompressedAction)
end

return Module