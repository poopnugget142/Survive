--initialise dependencies
local replicatedStorage = game:GetService("ReplicatedStorage")

local stew = require(replicatedStorage.Packages.Stew)
local world = stew.World.Create()

--tileMap entity will contain tile components that hold information
--local tileMap : any = world.Entity.Create()

--helper function
function tileUV(u, v)
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
function tileBuild(u, v)
    world.Entity.Register(tileUV(u,v))
    world.Component.Create(tileUV(u,v), "navData")

    tileMap[tileUV(u,v)] = tileUV(u,v) --adding tileUV to a tileMap gives more options and allows for #tileMap

    return tileUV(u,v)
end
--destroy a tile at (u, v)
function tileDestroy(u, v)
    world.Entity.Delete(tileUV(u,v))
    tileMap[tileUV(u,v)] = nil

    return true
end

--end of initialisation

--100x100 tiles
for i = 0, 100 do
	for j = 0, 100 do
        local tile = tileBuild(i,j)
        local navData = world.Component.Get(tile, "navData")
        navData.cost = 1
	end
end

--generates tilemap + djikstra's algorithm
function Pathfind(... : Vector2)
	print("Pathfinding Go!")
    --system enables for multiple pathfinding destinations
    local frontier = {...}
    local frontierHeat = {}
        for i, _ in frontier do
            frontierHeat[i] = 0
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
        local currentTile = tileUV(current.X, current.Y)

        --check (1,0), (0,1), (-1,0) and (0,-1)
        for _, adjacent in adjacents do
			local adjacentPosition : Vector2= current + adjacent

            local adjacentTile = tileUV(adjacentPosition.X, adjacentPosition.Y) 
            
            local adjacentNav = world.Component.Get(adjacentTile, "navData") --ignore tiles that dont exist
                if (not adjacentNav) then 
                    continue 
                end 
            local adjacentPath = world.Component.Get(adjacentTile, "pathData") --skip instances that have already been witnessed
			    if (adjacentPath) then 
                    continue 
                else
                    adjacentPath = world.Component.Create(adjacentTile, "pathData")
                end  

			local adjacentCost : number = math.huge -- default to pathfind cost to a really big number
				if (adjacentNav) then adjacentCost = adjacentNav.cost end
			
            --assign heat values to tiles
			local newcost = currentHeat + adjacentCost
			if newcost < currentHeat then
				currentHeat = newcost
			end

			frontier[#frontier+1] = adjacentPosition
			frontierHeat[#frontierHeat+1] = newcost
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
    end

    return true
end

repeat task.wait() until Pathfind(Vector2.new(0,0), Vector2.new(100,100))

local printPath = world.Component.Get(tileUV(0,0), "pathData")
print(printPath.heat)
printPath = world.Component.Get(tileUV(25,25), "pathData")
print(printPath.heat)
printPath = world.Component.Get(tileUV(50,50), "pathData")
print(printPath.heat)
printPath = world.Component.Get(tileUV(75,75), "pathData")
print(printPath.heat)
printPath = world.Component.Get(tileUV(100,100), "pathData")
print(printPath.heat)