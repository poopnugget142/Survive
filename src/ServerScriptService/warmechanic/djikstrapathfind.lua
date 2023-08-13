--[[
    notetaking

    fix assumption about multiple components existing

    add multiple layers of pathfinding grids, a new one swaps out an old one after it is produced

    move adjacent checker to module script for access by other scripts

    priority queue for cost comparison (binary trees)

    everything is a fucking mess, fix it eventually
]]

local module = { }

--initialise dependencies
local replicatedStorage = game:GetService("ReplicatedStorage")

local stew = require(replicatedStorage.Packages.Stew)
local world = stew.World.Create()
module.world = world

--local priorityQueue = require(replicatedStorage.Scripts.warmechanic.priorityqueue)


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
for i = 0, 80 do
	for j = 0, 80 do
        if (i > 45 and i < 55 and j < 70) then
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

local desiredTime = 0.5 -- desired time to complete a path request
local tileCount
local desiredTiles





















comparator = function(values, a, b)
    if (values == nil) then return 0 end

    local _a = values[a]
    local _b = values[b]
    return(_a - _b)
end

local length : number = 0

enqueue = function(values, value)
    if (values.length ~= nil) then
        if (values.length <= length) then --increase array length exponentially depending on value count
            values.length = math.max(1, values.length * 2)
        end
    else
        values.length = 1
    end
    values[length+1] = value --add
    length+=1 --add
    shiftUp()

    print (tostring(value) .. " added to priority queue")
    return values
end

dequeue = function(values)
    if (length == 0) then return nil end --skip if theres nothing to remove

    local node = values[1] --look at our first value

    if (length == 1) then --if theres only one value, we require no further computations
        length = 0 
        values[1] = nil
        return node
    end

    shiftDown()

    values[1] = values[length] --move the topmost value to the bottom of the binary tree, to do some swapping
    values[length] = nil
    length-=1
    --shiftDown() --swapping function
    
    print (tostring(node) .. " removed from priority queue")
    return node
end

heapSort = function(values)
    local out = {}
    for e = 1, length do
        table.insert(out, module.dequeue(values))
    end

    return out
end


parent = function(nodeIndex : number) --called for a child to get the node in the tree level above it
    if (nodeIndex == 1) then return nil end
    return math.floor(nodeIndex/2)
end
leftChild = function(nodeIndex : number) --called for a parent to get the left child
    local child = (nodeIndex*2)
    if (child >= length) then return nil end
    return child
end
rightChild = function(nodeIndex : number) --called for a parent to get the right child
    local child = (nodeIndex*2)+1
    if (child >= length) then return nil end
    return child
end

shiftUp = function(values) --move smaller values up the binary tree
    local index = length

    while (true) do
        local parentIndex = parent(index)

        if (parentIndex ~= nil and (comparator( values, index, parentIndex ) < 0) ) then
            local temp = values[index]
            values[index] = values[parentIndex]
            values[parentIndex] = temp
            continue
        end

        return
    end
end

shiftDown = function(values) --move bigger values down the binary tree
    local index = 1

    while true do
        local left = leftChild(index)
        local right = rightChild(index)
        
        local swapCandidiate = index
        if (left ~= nil and (comparator( values, swapCandidiate, left ) > 0) ) then
            swapCandidiate = left
        end
        if (right ~= nil and (comparator( values, swapCandidiate, right ) > 0) ) then
            swapCandidiate = right
        end
        if (swapCandidiate ~= index) then --check to see if swap candidate was altered by the two previous ifs
            local temp = values[index]
            values[index] = values[swapCandidiate]
            values[swapCandidiate] = temp
            index = swapCandidiate
            continue
        end

        return --otherwise break the operation
    end
end

























--generates tilemap + djikstra's algorithm
module.pathfind = function( ... : Vector2 )
	print("Pathfinding Go!")
    --system enables for multiple pathfinding destinations
    local frontier = { ... }
    --frontier = {Vector2.new(0,0)}
    local frontierHeat = {}
        for i, _ in frontier do
            frontierHeat[i] = 1
        end

    --wipe path data and start fresh (system relies on non-existence of pathData to function)
    tileCount = 0
    for _, tile in tileMap do
        --local pathData = world.Component.Get(tile, "pathData")
        tileCount+=1
        world.Component.Delete(tile, "pathData")
    end
    desiredTiles = (tileCount / desiredTime) * 0.01
    print(desiredTiles)

    --main stuff
    while (#frontier > 0) do
        --for _ = 1, desiredTiles do
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

                --[[
                local adjacentCost : number = math.huge -- default pathfind cost to a really big number
                    if (adjacentNav) then adjacentCost = adjacentNav.cost end
                ]]
                local adjacentCost : number = adjacentNav.cost
                
                --assign heat values to tiles
                local newcost = currentHeat + adjacentCost
                if newcost <= currentHeat then
                    currentHeat = newcost
                end

                local adjacentPath = world.Component.Get(adjacentTile, "pathData") --do not re-add already witnessed tiles to the frontier
                    if (adjacentPath) then 
                        continue 
                    else
                        adjacentPath = world.Component.Create(adjacentTile, "pathData")
                    end  

                table.insert(frontier, adjacentPosition)
                table.insert(frontierHeat, newcost)

                --enqueue(frontier, adjacentPosition)
                --enqueue(frontierHeat, newcost)
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

            --dequeue(frontier)
            --dequeue(frontierHeat)
            --print(frontierHeat)

            --for f, _ in frontier do
            --    priorityQueue.enqueue(frontier[f])
            --end
            --frontier = priorityQueue.heapSort()

            --for f, _ in frontierHeat do
            --    priorityQueue.enqueue(frontierHeat[f])
            --end
            --frontierHeat = priorityQueue.heapSort()
        --end
        --task.wait(0.01) --why does this throw errors?!??!
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