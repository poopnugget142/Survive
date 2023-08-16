local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JunkFolder = workspace:WaitForChild("JunkFolder")
local CharactersFolder = workspace:WaitForChild("Characters")

local EquipmentStates = require(ReplicatedStorage.Scripts.States.Equipment)
local Ballistics = require(ReplicatedStorage.Scripts.Util.Ballistics)

local Caster : Ballistics.Caster = Ballistics.CreateCaster()

Caster.RayHit:Connect(function(Bullet, RayResult)
    Ballistics.StopBullet(Bullet)
    Bullet.CosmeticBulletObject:Destroy()
end)

Caster.Expired:Connect(function(Bullet)
    Ballistics.StopBullet(Bullet)
    Bullet.CosmeticBulletObject:Destroy()
end)

local Round = Instance.new("Part")
Round.Size = Vector3.new(1, 1, 2)
Round.CanCollide = false
Round.CastShadow = false
Round.CanTouch = false
Round.CanQuery = false

local ZeroY = Vector3.new(1, 0, 1)

local Module = {}

Module.Create = function(Entity)
    local CasterParams = RaycastParams.new()
    CasterParams.IgnoreWater = true
    CasterParams.FilterType = Enum.RaycastFilterType.Exclude
    CasterParams.FilterDescendantsInstances = {JunkFolder, CharactersFolder}

    local CastBehavior = Ballistics.CreateCastBehavior()
    CastBehavior.RaycastParams = CasterParams
    CastBehavior.Container = JunkFolder
    CastBehavior.CosmeticBulletTemplate = Round
    CastBehavior.LifeTime = 10
    CastBehavior.Acceleration = Vector3.new(0, 0, 0)

    EquipmentStates.Component.Create(Entity, "CastBehavior", CastBehavior)
end

Module.LoadModel = function(Entity)
    
end

--In the future we can check if this really hit but for now we trust it
Module.Attack = function(Entity, HitCharacter)
    print(HitCharacter)
end

return Module