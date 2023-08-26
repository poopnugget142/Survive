--[[
    notetaking





]]


local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

--[[
export type Caster = {
    RayHit : Signal.Signal;
}
]]

export type CastBehavior = {
    RaycastParams : RaycastParams;
    Container : Instance;
    CosmeticBulletTemplate : BasePart;
    MoveFunction : any;
}

export type Bullet = {
    Origin : Vector3;
    Target : Vector3;
    Speed : number;
    CosmeticBulletObject : Instance;
    --Caster : Caster;
    --CreatedAt : number;
}

local Bullets = {}

local Module = {}

--[[
Module.CreateCaster = function()
    return {
        RayHit = Signal.new();
        Expired = Signal.new();
    } :: Caster
end
]]

Module.CreateCastBehavior = function()
    return {
        CosmeticBulletTemplate = nil;
        --RaycastParams = RaycastParams.new();
        Container = workspace;
        MoveFunction = function(origin : Vector3, target : Vector3, alpha : number)
            local position : Vector3 = origin:Lerp(target, alpha)
            return position
        end

    } :: CastBehavior
end


Module.SpawnBullet = function(CastBehavior : CastBehavior , Position : Vector3, Target : Vector3, Speed)
    local CosmeticBulletObject = CastBehavior.CosmeticBulletTemplate:Clone()
    CosmeticBulletObject.CFrame = CFrame.new(Position, Position + CastBehavior.MoveFunction(Position, Target, 10^-2))
    CosmeticBulletObject.Anchored = true
    CosmeticBulletObject.Parent = CastBehavior.Container

    local Bullet = {
        Origin = Position;
        Target = Target;
        Speed = Speed;
        Alpha = 0;
        CosmeticBulletObject = CosmeticBulletObject;
        --Caster = Caster;
        CastBehavior = CastBehavior;
        CreatedAt = tick();
    }

    table.insert(Bullets, Bullet)

    return Bullet
end

local cam = workspace.CurrentCamera
--Cycles through all the bullets and run physics updates on it
RunService.Heartbeat:Connect(function(DeltaTime)
    for i, Bullet : Bullet in pairs (Bullets) do
        --local Caster : Caster = Bullet.Caster
        --local CastBehavior : CastBehavior = Bullet.CastBehavior

        local distance : number = Bullet.Target - Bullet.Origin
        --TESTING
        
        
        --Progress visual bullet forward
        if Bullet.CosmeticBulletObject then
            --local BulletLength = Bullet.CosmeticBulletObject.Size.Z / 2
            --local BaseCFrame = CFrame.new(RayOrigin, RayOrigin + RayDirection.Unit)
            --Bullet.CosmeticBulletObject.CFrame = BaseCFrame * CFrame.new(0, 0, -(RayDirection.Magnitude - BulletLength))
            if Bullet.Alpha >= 1 then
                table.remove(Bullets, i)
                Bullet.CosmeticBulletObject:Destroy()
                return
            end

            local upLayerAlpha : number = 0
            if (Bullet.Alpha < 0.9 and Bullet.Alpha ~= 0) then
                upLayerAlpha = 0.1 -- (0 => 1) interpolate between real bullet position and camera                
            end

            local position = Bullet.CastBehavior.MoveFunction(Bullet.Origin, Bullet.Target, Bullet.Alpha)
            local nextPosition = Bullet.CastBehavior.MoveFunction(Bullet.Origin, Bullet.Target, Bullet.Alpha+10^-2)
            Bullet.CosmeticBulletObject.CFrame = CFrame.new(
                position
                ,position + (nextPosition-position).Unit
            )-- * CFrame.new(0, 0, -(Bullet.Target-position).Magnitude)
            Bullet.CosmeticBulletObject.Position = position:Lerp(cam.CFrame.Position, upLayerAlpha)
            local size = Vector3.new(5,5,15)--Bullet.CosmeticBulletObject.Size
            Bullet.CosmeticBulletObject.Size = Vector3.zero:Lerp(size,upLayerAlpha)--Bullet.CosmeticBulletObject.Size:Lerp(Vector3.zero, upLayerAlpha)
        end

        Bullet.Alpha += (Bullet.Speed/distance.magnitude) * DeltaTime
        --Bullet.Alpha += DeltaTime
    end
end)

return Module