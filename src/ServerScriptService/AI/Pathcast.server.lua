local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.Scripts

local Pathfinding = require(ReplicatedStorage.Scripts.Lib.AI.PathfindingCore)

local Promise = require(ReplicatedStorage.Packages.Promise)

local tileSize = Vector2.new(5,5)
local newTilegrid = Pathfinding.BuildTilegrid("ZombieGeneric",0,0,295,295,tileSize.X,tileSize.Y)
repeat task.wait() until newTilegrid ~= nil

local box = { --5x5 box creator
    Vector2.new(0,1),--0
--    Vector2.new(0,2),
--    Vector2.new(1,2),--30
    Vector2.new(1,1),--45
--    Vector2.new(2,2),
--    Vector2.new(2,1),--60
    Vector2.new(1,0),--90
--    Vector2.new(2,0),
--    Vector2.new(2,-1),--120
    Vector2.new(1,-1),--135
--    Vector2.new(2,-2),
--    Vector2.new(1,-2),--150
    Vector2.new(0,-1),--180
--    Vector2.new(0,-2),
--    Vector2.new(-1,-2),--210
    Vector2.new(-1,-1),--225
--    Vector2.new(-2,-2),
--    Vector2.new(-2,-1),--240
    Vector2.new(-1,0),--270
--    Vector2.new(-2,0),
--    Vector2.new(-2,1),--285
    Vector2.new(-1,1),--300
--    Vector2.new(-2,2),
--    Vector2.new(-1,2) --330
}


for i = 0, 200, tileSize.X do
    for j = 0, 200, tileSize.Y do
        local distance = (Vector2.new(100,100) - Vector2.new(i, j)).Magnitude
        if (distance < 40) then
            local query = newTilegrid:QueryPoint(i, j)
            if not query then continue end

            local tile = query.Tile
            if not tile then continue end

            tile.Interpolants.LowWall = 50

            local block = Instance.new("Part")
            block.Anchored = true
            block.Parent = workspace
            block.Position = Vector3.new(tile.Position.X, 0, tile.Position.Y)
            block.Size = Vector3.new(1, 10, 1)

            if distance < 10 then
                tile.Interpolants.HighWall = 100
                block.Size = Vector3.new(2, 30, 2)
            end
        end
    end
end


--[==[
for _ = 1, 100, 1 do
    local query = newTilegrid:QueryPoint(math.random(0,200/tileSize.X)*tileSize.X+100, math.random(0,200/tileSize.Y)*tileSize.Y+100)
    if not query then continue end

    local tile = query.Tile
    if not tile then continue end

    tile.Interpolants.LowWall = 200

    --[[for _, vertex in box do
        local adjacentQuery = newTilegrid:QueryPoint(tile.Position.X + vertex.X*tileSize.Y, tile.Position.Y + vertex.Y*tileSize.X)
        if not adjacentQuery then continue end

        local adjacentTile = adjacentQuery.Tile
        if not adjacentTile then continue end

        adjacentTile.Interpolants.Terrain = 100
        adjacentTile.Interpolants.LowWall = 100
        adjacentTile.Interpolants.HighWall = 100
    end]]

    local block = Instance.new("Part")
    block.Anchored = true
    block.Parent = workspace
    block.Position = Vector3.new(tile.Position.X, 0, tile.Position.Y)
    block.Size = Vector3.new(5, 10, 5)
end
]==]


repeat task.wait() until newTilegrid:Abstract(Vector2.new(20,20))

while true do
    local targets = workspace.Characters.Players:GetChildren()
    local parts = {}
    for _, target in targets do
        table.insert(parts, Pathfinding.BuildTarget(target.PrimaryPart))
    end

    local flowfield0 = newTilegrid:UniformCostSearch(
        "ZombieGeneric", 
        parts, 
        {
            Terrain = 1
            ,LowWall = 1
            ,HighWall = 1
        },
        {}
    )
    --[[
    local flowfield1 = newTilegrid:UniformCostSearch(
        "ZombieFlying", 
        parts, 
        {
            Terrain = 1
            ,LowWall = 0
            ,HighWall = 1
        },
        {}
    )
    ]]
    --repeat task.wait() until flowfield0-- or flowfield1
    task.wait(0.05)
end
