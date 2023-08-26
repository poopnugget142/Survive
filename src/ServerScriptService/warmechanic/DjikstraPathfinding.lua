--[[ notetaking

    find a way to get the number of tiles

    add multiple layers of pathfinding grids eventually

    add support for pathfinding to models (enemies can never catch up to a moving player)

    break when frontier reaches furthest enemy (save time)
]]

local module = { }

--initialise dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TileStates = require(ReplicatedStorage.Scripts.States.Tile)
local PriorityQueue = require(ReplicatedStorage.Scripts.Util.PriorityQueue)

local world = TileStates.World
module.world = world

-- priority queue for pathfinding quality ########################################################
-- special thanks https://youtu.be/M6OW0KNkhhs ###################################################
local frontier = PriorityQueue.Create()
frontier.ComparatorGetFunction = function(Value : any)
    return world.get(frontier.Values[Value]).FrontierOpen.Heat
end

local printTally = 0

-- tile functions ###################################################################################
local tileMap = {}

module.tileBuild = function(target:Vector3?, u:number?, v:number?, w:number?)
    local position = Vector3.zero
    if (target) then
        position = target
    else
        position = Vector3.new(u,v,w)
    end 


    world.entity(position)
    TileStates.NavData.add(position, 1)
    --tile_navData.add(position, 1)
    --world.Component.Create(position, "tile_navData", 1)

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
local TileSize = Vector3.new(5,5,5)
for i = 0, 100 do
	for j = 0, 100 do
        --if (i > 45 and i < 55 and j < 70) then
        --    continue
        --end
        local Tile = module.tileBuild(_,i,0,j)
        local NavData = world.get(Tile).NavData
        if (i > 45/TileSize.X and i < 55/TileSize.X and j < 70/TileSize.Z) then
            NavData.Cost = 1000
        else
            NavData.Cost = 1
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

local targets = {}
module.targets = targets

module.pathfind = function(...)
    targets = { ... }
    module.targets = targets

    --[[if (layer == nil) then
        layer = 1
    end]]

    --cleanup past frontier information
    local currentTiles = world.query{TileStates.NavData}
    for pastTile in currentTiles do
        TileStates.FrontierOpen.remove(pastTile)
        TileStates.FrontierClosed.remove(pastTile)
    end

    local desiredTime = 0.2 -- desired time to finish tiling
    local desiredTileRate = math.max(1,(--[[#currentTiles]]5000 / desiredTime) * 0.01) 
    --print (desiredTileRate)

    --start a new era of target position(s)
    local filterKeys = {} --interpret target types, 
    local _targets : Vector3 = {} -- ...
    for t, target in targets do --and filter out invalid options
        local targetType = type(target)
        if (targetType == type(Vector3.zero)) then --all vector3s are accepted
            table.insert(_targets, target)
        else
            if (targetType == "userdata") then --basepart positions are accepted
                table.insert(_targets, target.Position + target:GetVelocityAtPosition(target.Position) * desiredTime)
            else 
                table.insert(filterKeys, t) --remove everything else
                continue
            end
        end
    end
    for i, key in filterKeys do --remove bad results
        table.remove(targets, key - (i-1))
    end
    --print(targets)
    --print(_targets)

    for t, target in _targets do --create nav requests for all good results
        local target = Vector3.new(
            math.round(target.X/TileSize.X)
            ,0--math.round(target.Y)
            ,math.round(target.Z/TileSize.Z)
        )
        local nav = world.get(target).NavData
        if (nav) then
            TileStates.FrontierOpen.add(target, 1)
            frontier:Enqueue(target)
        end
    end

    while (#frontier.Values > 0) do
        for _ = 1, desiredTileRate, 1 do --we need to make more than 1 tile in 0.01 seconds, use a loop here
            debug.profilebegin("pathfind_tile")
            local current = frontier:Dequeue() --pull the next frontier object from the priority queue
                if (current == nil) then 
                    print("missing entity anomaly")
                    continue end
            local currentEntity = world.get(current).FrontierOpen
                if (currentEntity == nil) then 
                    print("missing component anomaly")
                    continue end
            local currentNav = world.get(current).NavData
                if (currentNav == nil) then 
                    print("missing tile anomaly")
                    continue end
            
            local currentHeat = currentEntity.Heat--[layer]
            --print(currentHeat) ---<<<<----

            TileStates.FrontierClosed.add(current) --close this tile so it cannot be visited by other tiles

            for a, adjacent : Vector3 in adjacents do --check each adjacent tile (8 directional)
                local adjacentPosition = current + adjacent

                local adjacentNav = world.get(adjacentPosition).NavData
                if (adjacentNav) then --ignore tiles that dont exist
                    local adjacentCost : number = adjacentNav.Cost--[layer] --assign heat values to tiles
                    local newHeat = currentHeat + adjacentCost * adjacent.Magnitude --magnitude for euclidean distance

                    local exploreCheck = world.get(adjacentPosition).FrontierClosed --do not re-add already witnessed tiles to the frontier
                    if (exploreCheck == nil or newHeat < currentHeat) then
                        adjacentNav.Heat--[[layer]]= newHeat
                    end
                    if (exploreCheck == nil) then
                        if (world.get(adjacentPosition).FrontierOpen == nil) then 
                            TileStates.FrontierOpen.add(adjacentPosition, newHeat)
                                --world.Component.Create(adjacentPosition, "frontier_closed") --experimental
                            --print(tostring(frontier[1]) .. "; " .. tostring(currentNav.heat) .. " ; " .. tostring(printTally))
                            --printTally+=1
                            frontier:Enqueue(adjacentPosition)
                        else 
                            --print("Duplicate Alert!")
                        end
                    end   
                else
                    currentHeat += 10000
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
            debug.profileend()
            if (#frontier.Values == 0) then
                break
            end
        end
        --if (#frontier == 0) then
        --    print("Breaker!")
        --    break
        --end
        task.wait(0.01)
    end

    return true
end

local box = { --5x5 box solve
    Vector3.new(0,0,1),--0
    Vector3.new(0,0,2),
    Vector3.new(1,0,2),--30
    Vector3.new(1,0,1),--45
    Vector3.new(2,0,2),
    Vector3.new(2,0,1),--60
    Vector3.new(1,0,0),--90
    Vector3.new(2,0,0),
    Vector3.new(2,0,-1),--120
    Vector3.new(1,0,-1),--135
    Vector3.new(2,0,-2),
    Vector3.new(1,0,-2),--150
    Vector3.new(0,0,-1),--180
    Vector3.new(0,0,-2),
    Vector3.new(-1,0,-2),--210
    Vector3.new(-1,0,-1),--225
    Vector3.new(-2,0,-2),
    Vector3.new(-2,0,-1),--240
    Vector3.new(-1,0,0),--270
    Vector3.new(-2,0,0),
    Vector3.new(-2,0,1),--285
    Vector3.new(-1,0,1),--300
    Vector3.new(-2,0,2),
    Vector3.new(-1,0,2) --330
}

module.boxSolve = function(position : Vector3)
    position = Vector3.new(
        math.round(position.X/TileSize.X),
        math.round(position.Y/TileSize.Y),
        math.round(position.Z/TileSize.Z)
    ) 

    local vectors = { }
    for v, vertex in box do
		local adjacentPosition = position + vertex.Unit

		local path = world.get(adjacentPosition).NavData
		--print(path.heat)
		vectors[v] = adjacents[v]--*100
		if (path) then
			vectors[v] = vertex * path.Heat            
		end
	end
    local finalVector = Vector3.zero
	for v, vector in vectors do
		finalVector += vector
	end
	finalVector = -finalVector.Unit

    return finalVector
end

return module