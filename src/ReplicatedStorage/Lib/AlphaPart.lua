--[[
    notetaking





]]

local RunService = game:GetService("RunService")

export type AlphaBehavior = {
    RaycastParams : RaycastParams;
    Container : Instance;
    CosmeticBulletTemplate : BasePart;
    MoveFunction : any;
}

export type AlphaPart = {
    Origin : Vector3;
    Target : Vector3;
    Speed : number;
    CosmeticBulletObject : Instance;
}

local Parts = {}

local Module = {}

Module.CreateAlphaBehavior = function()
    return {
        CosmeticBulletTemplate = nil;
        --RaycastParams = RaycastParams.new();
        Container = workspace;
        MoveFunction = function(origin : Vector3, target : Vector3, alpha : number)
            local position : Vector3 = origin:Lerp(target, alpha)
            return position
        end

    } :: AlphaBehavior
end


Module.Spawn = function(CastBehavior : AlphaBehavior , Position : Vector3, Target : Vector3, Speed)
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
        CastBehavior = CastBehavior;
        CreatedAt = tick();
    }

    table.insert(Parts, Bullet)

    return Bullet
end

local cam = workspace.CurrentCamera
--Cycles through all the bullets and run physics updates on it
RunService.Heartbeat:Connect(function(DeltaTime)
    for i, AlphaPart : AlphaPart in pairs (Parts) do
        local distance : number = AlphaPart.Target - AlphaPart.Origin
        --TESTING
        
        
        --Progress visual bullet forward
        if AlphaPart.CosmeticBulletObject then
            --local BulletLength = Bullet.CosmeticBulletObject.Size.Z / 2
            --local BaseCFrame = CFrame.new(RayOrigin, RayOrigin + RayDirection.Unit)
            --Bullet.CosmeticBulletObject.CFrame = BaseCFrame * CFrame.new(0, 0, -(RayDirection.Magnitude - BulletLength))
            if AlphaPart.Alpha >= 1 then
                table.remove(Parts, i)
                AlphaPart.CosmeticBulletObject:Destroy()
                return
            end

            local upLayerAlpha : number = 0
            if (AlphaPart.Alpha < 0.9 and AlphaPart.Alpha ~= 0) then
                upLayerAlpha = 0.1 -- (0 => 1) interpolate between real bullet position and camera                
            end

            local position = AlphaPart.CastBehavior.MoveFunction(AlphaPart.Origin, AlphaPart.Target, AlphaPart.Alpha)
            local nextPosition = AlphaPart.CastBehavior.MoveFunction(AlphaPart.Origin, AlphaPart.Target, AlphaPart.Alpha+10^-2)
            AlphaPart.CosmeticBulletObject.CFrame = CFrame.new(
                position
                ,position + (nextPosition-position).Unit
            )-- * CFrame.new(0, 0, -(Bullet.Target-position).Magnitude)
            AlphaPart.CosmeticBulletObject.Position = position:Lerp(cam.CFrame.Position, upLayerAlpha)
            local size = Vector3.new(5,5,15)--Bullet.CosmeticBulletObject.Size
            AlphaPart.CosmeticBulletObject.Size = Vector3.zero:Lerp(size,upLayerAlpha)--Bullet.CosmeticBulletObject.Size:Lerp(Vector3.zero, upLayerAlpha)
        end

        AlphaPart.Alpha += (AlphaPart.Speed/distance.magnitude) * DeltaTime
        --Bullet.Alpha += DeltaTime
    end
end)

return Module