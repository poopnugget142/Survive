local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes

local EquipmentStates = require(ReplicatedStorage.Scripts.States.Equipment)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local Util = require(ReplicatedStorage.Scripts.Util)
local Enums = require(ReplicatedStorage.Scripts.Enums)

local CreateTracerRemote : RemoteEvent = Remotes.CreateTracer

local GunEnum = Enums.Gun.M1911

local Module = {}

Module.Create = function(Entity)
    
end

Module.LoadModel = function(Entity)
    
end

--In the future we can check if this really hit but for now we trust it
Module.Attack = function(Entity, HitPosition, HitCharacter)
    local GunOwner = EquipmentStates.World.get(Entity).Owner

    local Character = GunOwner.Character
    local HumanoidRootPart = Character.PrimaryPart
    local Origin = HumanoidRootPart.Position

    local TracerPlayers = Util.GetAllPlayersExcept{GunOwner}

    for i, Player in TracerPlayers do
        CreateTracerRemote:FireClient(Player, Origin, HitPosition, GunEnum, Enums.Bullet["9mmTracer"])
    end

    if not HitCharacter then return end

    local HitData = CharacterStates.World.get(HitCharacter)

    if not HitData.Character then return end

    local CurrentHealth = HitData.Health.Current

    --CharacterModule.UpdateHealth(HitCharacter, -40)
    
    if (HitData.Crippled) then
        HitData.Crippled = math.max(HitData.Crippled, 0.9)
    else
        CharacterStates.Crippled.add(HitCharacter, 0.9)
    end
    
    if (HitData.Burning) then
        HitData.Burning += 100
    else
        CharacterStates.Burning.add(HitCharacter, 100)
    end
end

return Module