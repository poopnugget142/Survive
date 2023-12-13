--[[
    NOTETAKING

    store way more data, make the system more robust
        dont use step up/down logic, index every position with a tile for abstraction

    
--]]

local function mathsummation(values : table | number)
    local out = 0
    for _, value : number in values do
        out += value
    end
    return out
end


local ReplicatedStorage = game:GetService("ReplicatedStorage")


local PriorityQueueModule = require(ReplicatedStorage.Scripts.Lib.PriorityQueue)
local QuadtreeModule = require(ReplicatedStorage.Scripts.Lib.Quadtree)
local Promise = require(ReplicatedStorage.Packages.Promise)

local Tilegrid = {}
Tilegrid.__index = Tilegrid
local AllTilegrids = {}

local Navgrid = {}
Navgrid.__index = Navgrid
local AllNavgrids = {}

local Module = {}

Module.BuildTile = function(U,V)
    return {



    }
end



return Module