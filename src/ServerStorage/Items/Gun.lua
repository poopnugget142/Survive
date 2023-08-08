local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local JunkFolder = workspace:WaitForChild("JunkFolder")

local Ballistics = require(ReplicatedStorage.Scripts.Ballistics)

local Module = {}

Module.Give = function(Character : Model)
    local Player = Players:GetPlayerFromCharacter(Character)
    print("Sever Gun Loaded")
end

return Module