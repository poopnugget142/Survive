--[[
    notetaking

    fix assumption about multiple components existing

    add multiple layers of pathfinding grids, a new one swaps out an old one after it is produced

    move adjacent checker to module script for access by other scripts

    priority queue for cost comparison (binary trees)
]]

local module = { }

--initialise dependencies
local replicatedStorage = game:GetService("ReplicatedStorage")

local stew = require(replicatedStorage.Packages.Stew)
local world = stew.World.Create()
module.world = world

local priorityQueue = require(replicatedStorage.Scripts.warmechanic.priorityqueue)

--tileMap entity will contain tile components that hold information
--local tileMap : any = world.Entity.Create()

--helper function
module.tileUV = function(u, v)
    return tostring(Vector2.new(u,v))
end
local adjacents : Vector2 = { --when doing math with 2d positions, use vector2.new() and finalise with tileUV()
	Vector2.new(1,0),
	Vector2.new(0,1),
	Vector2.new(-1,0),
	Vector2.new(0,-1),
}

--navData components
world.Component.Build("navData", {
    Constructor = function(tile : any, name : string, layer : string, cost : number)
        return
        {
            self = tile,
            _ = nil, --no names
            layer = layer,
            cost = cost
        }
    end
})
world.Component.Build("pathData", {
    Constructor = function(tile : any, name : string, layer : string, heat : number)
        return
        {
            self = tile,
            _ = nil, --no names
            layer = layer,
            heat = heat
        }
    end
})

--tileMap functions
local tileMap = {}
--build a tile at (u, v)
module.tileBuild = function(u, v)
    world.Entity.Register(module.tileUV(u,v))
    world.Component.Create(module.tileUV(u,v), "navData")

    tileMap[module.tileUV(u,v)] = module.tileUV(u,v) --adding tileUV to a tileMap gives more options and allows for #tileMap

    return module.tileUV(u,v)
end
--destroy a tile at (u, v)
module.tileDestroy = function(u, v)
    world.Entity.Delete(module.tileUV(u,v))
    tileMap[module.tileUV(u,v)] = nil

    return true
end

--end of initialisation

--100x100 tiles
for i = 0, 100 do
	for j = 0, 100 do
        if (i > 45 and i < 55 and j < 80) then
            continue
        end
        local tile = module.tileBuild(i,j)
        local navData = world.Component.Get(tile, "navData")
        --if (i > 45 and i < 55 and j < 80) then
        --    navData.cost = 1000
        --else
            navData.cost = 1
        --end
	end
end

--generates tilemap + djikstra's algorithm
module.pathfind = function( ... : Vector2 )
	print("Pathfinding Go!")
    --system enables for multiple pathfinding destinations
    local frontier = { ... }
    local frontierHeat = {}
        for i, _ in frontier do
            frontierHeat[i] = 1
        end

    --wipe path data and start fresh (system relies on non-existence of pathData to function)
    for _, tile in tileMap do
        --local pathData = world.Component.Get(tile, "pathData")

        world.Component.Delete(tile, "pathData")
    end

    --main stuff
    while (#frontier > 0) do
        local current : Vector2 = frontier[1]
        local currentHeat : number = frontierHeat[1]
        local currentTile = module.tileUV(current.X, current.Y)

        --check (1,0), (0,1), (-1,0) and (0,-1)
        for _, adjacent in adjacents do
			local adjacentPosition : Vector2= current + adjacent

            local adjacentTile = module.tileUV(adjacentPosition.X, adjacentPosition.Y) 
            
            local adjacentNav = world.Component.Get(adjacentTile, "navData") --ignore tiles that dont exist
                if (not adjacentNav) then 
                    continue 
                end 
            local adjacentPath = world.Component.Get(adjacentTile, "pathData") --do not re-add already witnessed tiles to the frontier
			    if (adjacentPath) then 
                    continue 
                else
                    adjacentPath = world.Component.Create(adjacentTile, "pathData")
                end  

            --[[
            local adjacentCost : number = math.huge -- default pathfind cost to a really big number
				if (adjacentNav) then adjacentCost = adjacentNav.cost end
            ]]
            local adjacentCost : number = adjacentNav.cost
            
            --assign heat values to tiles
            local newcost = currentHeat + adjacentCost
            if newcost < currentHeat then
                currentHeat = newcost
            end

            table.insert(frontier, adjacentPosition)
            table.insert(frontierHeat, newcost)
		end

        --set and forget current tile's path data
        local currentPath = world.Component.Get(currentTile, "pathData")
        if (not currentPath) then
            currentPath = world.Component.Create(currentTile, "pathData")
        end
        currentPath.heat = currentHeat
        
        --print (current)
        table.remove(frontier, 1)
        table.remove(frontierHeat, 1)

        --print(frontierHeat)
    end

    return true
end

--[[
local solveBox = { --5x5 box solve
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
local solveAngs = { --16 angles from 16 outer cells
    0, -- 0,2
    30,-- 1,2
    45,-- 2,2
    60,-- 2,1
    90,-- 2,0
    120,-- 2,-1
    135,-- 2,-2
    150,-- 1,-2
    180,-- 0,-2
    210,-- -1,-2
    225,-- -2,-2
    240,-- -2,-1
    270,-- -2,0
    285,-- -2,1
    300,-- -2,2
    330 -- -1,2
}
]]

module.solveVector = function(searchPosition : Vector2)
    --do stuff
end

return module