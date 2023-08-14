local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JunkFolder = workspace:WaitForChild("JunkFolder")
local CharactersFolder = workspace:WaitForChild("Characters")

local EquipmentStates = require(ReplicatedStorage.Scripts.States.Equipment)
local Ballistics = require(ReplicatedStorage.Scripts.Ballistics)

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

Module.Attack = function(Entity, AimPosition)
    local CastBehavior = EquipmentStates.Component.Get(Entity, "CastBehavior")

    local Player = EquipmentStates.Component.Get(Entity, "Owner")
    
    local Character = Player.Character

    local HumanoidRootPart = Character.Model.PrimaryPart

    local Orgin = HumanoidRootPart.Position

    local DistanceToAim = (Orgin-AimPosition).Magnitude

    local Circularity = math.rad( math.random(0, 180) )

    local SpreadAim = AimPosition +
    ( Vector3.new(math.random(-100, 100)*0.01*math.sin(Circularity), 0, math.random(-100, 100)*0.01*math.cos(Circularity))
    *(DistanceToAim*math.tan(math.rad(25)/2)) )

    local Direction = CFrame.new(Orgin, SpreadAim).LookVector

    local Bullet = Ballistics.SpawnBullet(Caster, CastBehavior, Orgin, Direction*200)
end

return Module