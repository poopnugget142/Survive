local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ReplicatedScripts = ReplicatedStorage.Scripts
--
local Pathfinding = require(ReplicatedScripts.Lib.AI.FastPathCore)
local PriorityQueueModule = require(ReplicatedScripts.Lib.PriorityQueue)

local newTilegrid = Pathfinding.BuildTileGrid("ZombieGeneric", Vector2.new(5,5)) :: Pathfinding.TileGrid

export type Front = Pathfinding.Front

for i = 0, (405-newTilegrid.TileSize.X), newTilegrid.TileSize.X do
    for j = 0, (405-newTilegrid.TileSize.Y), newTilegrid.TileSize.Y do
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
newTilegrid.AbstractionLayers[3] = {
    AbstractionGrid = {}
    ,AbstractionSize = Vector2.new(135,135)
}
task.wait(3)
newTilegrid:Abstract()




local Target = Vector2.new(400,400)
local HeuristicFn = function(Front : Front)
    local Difference = Target - Vector2.new(Front.Boundary.X, Front.Boundary.Y)
    return Difference.Magnitude*2
    --return math.abs(Difference.X) + math.abs(Difference.Y)
end
local Query = newTilegrid:AStarQuery(
    Pathfinding.BuildTarget(Vector2.new(0,0))
    ,Pathfinding.BuildTarget(Target)
    ,HeuristicFn
    ,true
)
print(Query)


--local newNavGrid : Pathfinding.NavGrid = newTilegrid:BuildNavGrid("test")
--local AbstractionMap = newNavGrid:MapAbstractions({Pathfinding.BuildTarget(Vector3.new(30,0,30))})
--print(AbstractionMap)