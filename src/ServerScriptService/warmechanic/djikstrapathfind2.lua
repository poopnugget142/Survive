--[[ notetaking

    find a way to get the number of tiles

    add multiple layers of pathfinding grids eventually



]]

local module = { }

--initialise dependencies
local replicatedStorage = game:GetService("ReplicatedStorage")

local stew = require(replicatedStorage.Packages.Stew)
local world = stew.World.Create()
module.world = world

--tile / priority components
world.Component.Build("frontier_open", { --frontier is stored in stew components, can use getall frontier
    Constructor = function(Entity : any, name : string, heat : number)
        return
        {
            tile = Entity,
            _ = nil, --no names
            heat = heat
        }
    end
})
world.Component.Build("frontier_closed", { --empty component used for frontier ignorance
    Constructor = function(Entity : any, name : string)
        return
        {
            tile = Entity,
            _ = nil
        }
    end
})

world.Component.Build("tile_navData", { --navData stores tile cost and heat data on all layers
    Constructor = function(Entity : any, name : string, cost)
        return
        {
            tile = Entity,
            _ = nil, --no names
            cost = cost,
            heat = 0
        }
    end
})


-- priority queue for pathfinding quality ########################################################
-- special thanks https://youtu.be/M6OW0KNkhhs ###################################################
local frontier = {}
local length : number = 0

local printTally = 0

comparator = function(a, b)
    local _a = world.Component.Get(frontier[a], "frontier_open").heat
    local _b = world.Component.Get(frontier[b], "frontier_open").heat
    if (_a == nil or _b == nil) then
        return 0
    end
    --print(_a)

    return(_a - _b)
end

enqueue = function(value)
    if (frontier.length ~= nil) then
        if (frontier.length <= length) then --increase array length exponentially depending on value count
            frontier.length = math.max(1, frontier.length * 2)
        end
    else
        frontier.length = 1
    end
    frontier[length+1] = value --add
    length+=1 --add
    shiftUp()

    --print (tostring(value) .. " added to priority queue")
    return true
end

dequeue = function()
    if (length == 0) then return nil end --skip if theres nothing to remove

    local node = frontier[1] --look at our first value

    if (length == 1) then --if theres only one value, we require no further computations
        length = 0 
        frontier[1] = nil
        return node
    end

    --shiftDown()

    frontier[1] = frontier[length] --move the topmost value to the bottom of the binary tree, to do some swapping
    frontier[length] = nil
    length-=1
    shiftDown() --swapping function
    
    --print (tostring(node) .. " removed from priority queue")
    return node
end

heapSort = function()
    local out = {}
    for e = 1, length do
        table.insert(out, module.dequeue())
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

shiftUp = function() --move smaller frontier up the binary tree
    local index = length

    while (true) do
        local parentIndex = parent(index)

        if (parentIndex ~= nil and (comparator( index, parentIndex ) < 0) ) then
            local temp = frontier[index]
            frontier[index] = frontier[parentIndex]
            frontier[parentIndex] = temp
            continue
        end

        return
    end
end

shiftDown = function() --move bigger frontier down the binary tree
    local index = 1

    while true do
        local left = leftChild(index)
        local right = rightChild(index)
        
        local swapCandidiate = index
        if (left ~= nil and (comparator( swapCandidiate, left ) > 0) ) then
            swapCandidiate = left
        end
        if (right ~= nil and (comparator( swapCandidiate, right ) > 0) ) then
            swapCandidiate = right
        end
        if (swapCandidiate ~= index) then --check to see if swap candidate was altered by the two previous ifs
            local temp = frontier[index]
            frontier[index] = frontier[swapCandidiate]
            frontier[swapCandidiate] = temp
            index = swapCandidiate
            continue
        end

        return --otherwise break the operation
    end
end

-- tile functions ###################################################################################
local tileMap = {}

module.tileBuild = function(target:Vector3?, u:number?, v:number?, w:number?)
    local position = Vector3.zero
    if (target) then
        position = target
    else
        position = Vector3.new(u,v,w)
    end 


    world.Entity.Register(position)
    world.Component.Create(position, "tile_navData", 1)

    tileMap[position] = position --adding tileUV to a tileMap gives more options and allows for #tileMap

    return position
end

--destroy a tile at (u, v)
module.tileDestroy = function(target:Vector3?, u:number?, v:number?, w:number?)
    local position = Vector3.zero
    if (target) then
        position = target
    else
        position = Vector3.new(u,v,w)
    end 

    world.Entity.Delete(position)
    tileMap[position] = nil

    return true
end

--grid initialisation
--100x100 tiles
for i = 0, 100 do
	for j = 0, 100 do
        --if (i > 45 and i < 55 and j < 70) then
        --    continue
        --end
        local tile = module.tileBuild(_,i,0,j)
        local navData = world.Component.Get(tile, "tile_navData")
        if (i > 45 and i < 55 and j < 80) then
            navData.cost = 1000
        else
            navData.cost = 1
        end
	end
end


-- pathfinding ###################################################################################

local adjacents = {
    Vector3.new(0,0,1), -- 0
    Vector3.new(1,0,1), -- 45
    Vector3.new(1,0,0), -- 90
    Vector3.new(1,0,-1), -- 135
    Vector3.new(0,0,-1), -- 180
    Vector3.new(-1,0,-1), -- 225
    Vector3.new(-1,0,0), -- 270
    Vector3.new(-1,0,1) -- 315
}


module.pathfind = function(... :Vector3)
    print("Pathfinding Go!")
    local targets : Vector3 = { ... }

    --[[if (layer == nil) then
        layer = 1
    end]]

    --cleanup past frontier information
    local currentTiles = world.Collection.Get{"tile_navData"}
    for pastTile in currentTiles do
        world.Component.Delete(pastTile, "frontier_open")
        world.Component.Delete(pastTile, "frontier_closed")
    end

    local desiredTime = 2 -- desired time to finish tiling
    local desiredTileRate = math.max(1,(#currentTiles / desiredTime)) * 100
    --print (desiredTileRate)

    --start a new era of target position(s)
    for t, target in targets do
        local nav = world.Component.Get(target, "tile_navData")
        if (nav) then
            world.Component.Create(target, "frontier_open", 1)
            enqueue(target)
        end
        --print(frontier)
    end

    while (#frontier > 0) do
        for i = 1, desiredTileRate do --we need to make more than 1 tile in 0.01 seconds, use a loop here
            local current = dequeue() --pull the next frontier object from the priority queue
                if (current == nil) then 
                    print("missing entity anomaly")
                    continue end
            local currentEntity = world.Component.Get(current, "frontier_open")
                if (currentEntity == nil) then 
                    print("missing component anomaly")
                    continue end
            local currentNav = world.Component.Get(current, "tile_navData")
                if (currentNav == nil) then 
                    print("missing tile anomaly")
                    continue end
            
            local currentHeat = currentEntity.heat--[layer]

            world.Component.Create(current, "frontier_closed") --close this tile so it cannot be visited by other tiles

            for a, adjacent : Vector3 in adjacents do --check each adjacent tile (8 directional)
                local adjacentPosition = current + adjacent

                local adjacentNav = world.Component.Get(adjacentPosition, "tile_navData") 
                if (adjacentNav) then --ignore tiles that dont exist
                    local adjacentCost : number = adjacentNav.cost--[layer] --assign heat values to tiles
                    local newHeat = currentHeat + adjacentCost * adjacent.Magnitude --magnitude for euclidean distance

                    local exploreCheck = world.Component.Get(adjacentPosition, "frontier_closed") --do not re-add already witnessed tiles to the frontier
                    if (exploreCheck == nil or newHeat < currentHeat) then
                        adjacentNav.heat--[[layer]]= newHeat
                    end
                    if (exploreCheck == nil) then
                        if (world.Component.Get(adjacentPosition, "frontier_open") == nil) then 
                            world.Component.Create(adjacentPosition, "frontier_open", newHeat)
                                --world.Component.Create(adjacentPosition, "frontier_closed") --experimental
                            --print(tostring(frontier[1]) .. "; " .. tostring(currentNav.heat) .. " ; " .. tostring(printTally))
                            --printTally+=1
                            enqueue(adjacentPosition)
                        else 
                            --print("Duplicate Alert!")
                        end
                    end   
                end   
            end
            currentNav.heat--[[layer]] = currentHeat
            
            --[[
            local printer = {}
            for _, front : Vector3 in frontier do
                table.insert(printer, world.Component.Get(front, "frontier_open").heat)
            end
            print(printer)
            ]]
            if (#frontier == 0) then
                break
            end
        end
        task.wait(0.01)
    end
    return true
end

return module