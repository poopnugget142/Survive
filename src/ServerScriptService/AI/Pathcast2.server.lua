local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ReplicatedScripts = ReplicatedStorage.Scripts
--
local Pathfinding = require(ReplicatedScripts.Lib.AI.PathfindingCore2)

local newTilegrid = Pathfinding.BuildTileGrid("ZombieGeneric", Vector2.new(5,5)) :: Pathfinding.TileGrid

for i = 0, 20, newTilegrid.TileSize.X do
    for j = 0, 20, newTilegrid.TileSize.Y do
        print(i,j)
        newTilegrid:BuildTile(i,j)
        task.wait(0.01)
    end
end