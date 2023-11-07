local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Quadtree = require(ReplicatedStorage.Scripts.Util.Quadtree)

local Id = 0
local function NextId()
    Id += 1
    return Id
end

local GridventoryList = {}
local ItemList = {}