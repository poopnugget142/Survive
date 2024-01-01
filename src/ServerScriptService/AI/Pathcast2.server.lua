local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ReplicatedScripts = ReplicatedStorage.Scripts
--
local Pathfinding = require(ReplicatedScripts.Lib.AI.PathfindingCore2)

local newTilegrid = Pathfinding.BuildTileGrid("ZombieGeneric", Vector2.new(5,5)) :: Pathfinding.TileGrid

for i = 0, (60-newTilegrid.TileSize.X), newTilegrid.TileSize.X do
    for j = 0, (60-newTilegrid.TileSize.Y), newTilegrid.TileSize.Y do
        --print(i,j)
        newTilegrid:BuildTile(i,j)
        task.wait(0.01)
    end
end

newTilegrid.AbstractionLayers[1] = {
    Abstractions = {}
    ,AbstractionSize = Vector2.new(10,10)
}
newTilegrid.AbstractionLayers[2] = {
    Abstractions = {}
    ,AbstractionSize = Vector2.new(30,30)
}
newTilegrid:Abstract()



print(newTilegrid)