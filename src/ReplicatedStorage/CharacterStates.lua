local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stew = require(ReplicatedStorage.Packages.Stew)

local World = Stew.World.Create()

World.Component.Build("Attacking")
World.Component.Build("Moving")
World.Component.Build("AutoRotate")

return World