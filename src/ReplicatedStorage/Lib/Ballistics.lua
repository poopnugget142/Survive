--I took some concepts from fastcast that I liked and used it for my own system

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

export type Caster = {
    RayHit : Signal.Signal;
    Expired : Signal.Signal;
}

export type CastBehavior = {
    RaycastParams : RaycastParams;
    Container : Instance;
    CosmeticBulletTemplate : BasePart;
    LifeTime : number;
    Acceleration : Vector3;
}

export type Bullet = {
    Velocity : Vector3;
    Position : Vector3;
    CosmeticBulletObject : Instance;
    Caster : Caster;
    CreatedAt : number;
}

local Bullets = {}

local Module = {}

Module.CreateCaster = function()
    return {
        RayHit = Signal.new();
        Expired = Signal.new();
    } :: Caster
end

Module.CreateCastBehavior = function()
    return {
        CosmeticBulletTemplate = nil;
        RaycastParams = RaycastParams.new();
        Container = workspace;
        LifeTime = 2;
        Acceleration = Vector3.new(0, -workspace.Gravity, 0)
    } :: CastBehavior
end

Module.StopBullet = function(Bullet : Bullet)
    local TablePosition = table.find(Bullets, Bullet)

    if not TablePosition then warn("Bullet not able to remove!") end

    table.remove(Bullets, TablePosition)
end

--Adds a new bullet objecct into the array
Module.SpawnBullet = function(Caster : Caster, CastBehavior : CastBehavior , Orgin : Vector3, Velocity : Vector3)
    local CosmeticBulletObject = CastBehavior.CosmeticBulletTemplate:Clone()
    CosmeticBulletObject.CFrame = CFrame.new(Orgin, Orgin + Velocity.Unit)
    CosmeticBulletObject.Anchored = true
    CosmeticBulletObject.Parent = CastBehavior.Container

    local Bullet = {
        Velocity = Velocity;
        Position = Orgin;
        CosmeticBulletObject = CosmeticBulletObject;
        Caster = Caster;
        CastBehavior = CastBehavior;
        CreatedAt = tick();
    }

    table.insert(Bullets, Bullet)

    return Bullet
end

--Cycles through all the bullets and run physics updates on it
RunService.RenderStepped:Connect(function(DeltaTime)
    for i, Bullet : Bullet in pairs (Bullets) do
        local Caster : Caster = Bullet.Caster
        local CastBehavior : CastBehavior = Bullet.CastBehavior

        local NewPosition = Bullet.Position + (Bullet.Velocity * DeltaTime)

        local RayOrigin = Bullet.Position
        local RayDirection = NewPosition - RayOrigin

        local RayResult = game.Workspace:Raycast(RayOrigin, RayDirection, CastBehavior.RaycastParams)

        --On bullet hit
        if RayResult then
            Caster.RayHit:Fire(Bullet, RayResult)
        end

        --If bullet has exceded it's lifetime then stop bullet
        if tick() >= Bullet.CreatedAt + CastBehavior.LifeTime then
            Caster.Expired:Fire(Bullet)
            continue
        end

        --Progress visual bullet forward
        if Bullet.CosmeticBulletObject then
            local BulletLength = Bullet.CosmeticBulletObject.Size.Z / 2
            local BaseCFrame = CFrame.new(RayOrigin, RayOrigin + RayDirection.Unit)
            Bullet.CosmeticBulletObject.CFrame = BaseCFrame * CFrame.new(0, 0, -(RayDirection.Magnitude - BulletLength))
        end

        --Progress velocity
        local NewVelocity = Bullet.Velocity + (CastBehavior.Acceleration * DeltaTime)

        Bullet.Position = NewPosition
        Bullet.Velocity = NewVelocity
    end
end)

return Module