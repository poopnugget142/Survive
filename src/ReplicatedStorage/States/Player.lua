local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stew = require(ReplicatedStorage.Packages.Stew)

local World = Stew.world()

local Module = {}

Module.World = World

return Module