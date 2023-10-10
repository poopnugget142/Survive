local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GunModule = require(ReplicatedStorage.Scripts.Class.Gun)

local Remotes = ReplicatedStorage.Remotes

local CreateTracerRemote : RemoteEvent = Remotes.CreateTracer

CreateTracerRemote.OnClientEvent:Connect(function(Orgin, Target, GunEnum, BulletEnum)
    GunModule.CreateTracer(Orgin, Target, GunEnum, BulletEnum)
end)
