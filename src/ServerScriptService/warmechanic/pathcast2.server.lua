local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Pathfinding = require(ReplicatedStorage.Scripts.Util.PathfindingCore)

local newTilegrid = Pathfinding.BuildTilegrid("ZombieGeneric",0,0,140,140,2,2)
--local testTile = newTilegrid:GetTile(1,1)
--print(testTile)
--[[
newTilegrid = Pathfinding.BuildNavgrid(100,100,0,0)
testTile = newTilegrid:GetTile(0,0)
print(testTile)
]]

local box = { --5x5 box creator
    Vector2.new(0,1),--0
    Vector2.new(0,2),
    Vector2.new(1,2),--30
    Vector2.new(1,1),--45
    Vector2.new(2,2),
    Vector2.new(2,1),--60
    Vector2.new(1,0),--90
    Vector2.new(2,0),
    Vector2.new(2,-1),--120
    Vector2.new(1,-1),--135
    Vector2.new(2,-2),
    Vector2.new(1,-2),--150
    Vector2.new(0,-1),--180
    Vector2.new(0,-2),
    Vector2.new(-1,-2),--210
    Vector2.new(-1,-1),--225
    Vector2.new(-2,-2),
    Vector2.new(-2,-1),--240
    Vector2.new(-1,0),--270
    Vector2.new(-2,0),
    Vector2.new(-2,1),--285
    Vector2.new(-1,1),--300
    Vector2.new(-2,2),
    Vector2.new(-1,2) --330
}

for i = 1, 200, 1 do
    local tile = newTilegrid:GetTile(math.random(0,140), math.random(0,140))
    if (tile) then
        tile.Interpolants.Terrain = 10000

        for _, vertex in box do
            local adjacentTile = newTilegrid:GetTile(tile.Position.X + vertex.X, tile.Position.Y + vertex.Y)
            if (adjacentTile) then
                adjacentTile.Interpolants.Wall = 10000 
            end
        end

        local block = Instance.new("Part")
        block.Anchored = true
        block.Parent = workspace
        block.Position = Vector3.new(tile.Position.X, 0, tile.Position.Y)
        block.Size = Vector3.new(3, 10, 3)
    end
end


while true do
    local targets = workspace.Characters.Players:GetChildren()
    local parts = {}
    for _, target in targets do
        table.insert(parts, Pathfinding.BuildTarget(target.PrimaryPart))
    end

    local flowfield = newTilegrid:UniformCostSearch(
        "ZombieGeneric", 
        parts, 
        {
            Terrain  = 1
        }
    )

    repeat task.wait() until flowfield
end