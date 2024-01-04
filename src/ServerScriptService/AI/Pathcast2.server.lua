local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ReplicatedScripts = ReplicatedStorage.Scripts
--
local Pathfinding = require(ReplicatedScripts.Lib.AI.FastPathCore)
local PriorityQueueModule = require(ReplicatedScripts.Lib.PriorityQueue)

local newTilegrid = Pathfinding.BuildTileGrid("ZombieGeneric", Vector2.new(5,5)) :: Pathfinding.TileGrid

export type Front = Pathfinding.Front

for i = 0, (45-newTilegrid.TileSize.X), newTilegrid.TileSize.X do
    for j = 0, (45-newTilegrid.TileSize.Y), newTilegrid.TileSize.Y do
        --print(i,j)
        local newTile = newTilegrid:BuildTile(i,j)
        newTile.Interpolants["floor"] = 1
    end
end

newTilegrid.AbstractionLayers[1] = {
    AbstractionGrid = {}
    ,AbstractionSize = Vector2.new(15,15)
}
newTilegrid.AbstractionLayers[2] = {
    AbstractionGrid = {}
    ,AbstractionSize = Vector2.new(45,45)
}
task.wait(3)
newTilegrid:Abstract()

--[[
local Target = Vector2.new(50,50)
local HeuristicFn = function(Front : Front)
    local Difference = Target - Vector2.new(Front.CurrentBoundary.X, Front.CurrentBoundary.Y)
    return Difference.Magnitude*2
    --return math.abs(Difference.X) + math.abs(Difference.Y)
end
local Query = newTilegrid:AStarQuery(
    Vector2.new(0,0)
    ,Vector2.new(30,30)
    ,HeuristicFn
)
print(Query)
]]

--print(newTilegrid)