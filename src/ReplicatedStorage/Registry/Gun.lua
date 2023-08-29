local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JunkFolder = workspace:WaitForChild("JunkFolder")

local Enums = require(ReplicatedStorage.Scripts.Enums)
local AlphaPart = require(ReplicatedStorage.Scripts.Util.AlphaPart)

--Perhaps move this to assets...
local bullet = Instance.new("Part")
bullet.Anchored = true 
bullet.CanCollide = false
bullet.Size = Vector3.new(0.2, 0.2, 2)
bullet.Color = Color3.fromRGB(255, 248, 35)
bullet.Material = Enum.Material.Neon

local BulletBehavior = AlphaPart.CreateAlphaBehavior()
BulletBehavior.CosmeticBulletTemplate = bullet
BulletBehavior.Container = JunkFolder
BulletBehavior.MoveFunction = function(origin : Vector3, target : Vector3, alpha : number)
    local alphaMax = math.min(alpha, 1)
    local position : Vector3 = origin:Lerp(target, alpha) --+ Vector3.yAxis*math.sin(alphaMax*math.pi)*(target-origin).Magnitude*0.5
    return position
end

local Module = {}

local TracerData : {[number] : {[number] : {} }} = {
    [Enums.Gun.M1911] = {
        [Enums.Bullet["9mmTracer"]] = {
            Speed = 200;
            Behavior = BulletBehavior;
        };
    }
}

Module.GetTracerData = function(GunEnum : number, BulletEnum : number)
    assert(TracerData[GunEnum], "GunEnum "..GunEnum.." has no bullets assigned to it")

    assert(TracerData[GunEnum][BulletEnum], "BulletEnum "..BulletEnum.." has no data")

    return TracerData[GunEnum][BulletEnum]
end

return Module