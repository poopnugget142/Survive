--[[
    Tilegrid Notetaking

    Port Djikstra UCS

    Implement A* Pathfinding

    Use A* Pathfinding to implement Hierarchial Abstraction

    Experiment with Cumulative A* ???
]]

local function mathsummation(... : number)
    local values = {...}
    local out = 0
    for value : number in values do
        out += value
    end
    return out
end


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PriorityQueue = require(ReplicatedStorage.Scripts.Util.PriorityQueue)
local Promise = require(ReplicatedStorage.Packages.Promise)

local Tilegrid = {}
Tilegrid.__index = Tilegrid
local AllTilegrids = {}

local Navgrid = {}
Navgrid.__index = Navgrid
local AllNavgrids = {}

local Module = {}

export type Tile = {
    Position : Vector2 --the position of a tile
    ,Adjacents : table --a list of all adjacent tiles available for pathfinding
    ,Interpolants : table --additive list of pathfinding cost weights
}

export type Front = { --Frontier tile
    Tile : Tile
    ,InterpolantWeightings : table
    ,CumulativeCost : number
}

--[[export type Adjacent = {
    Offset : Vector2
    ,Cost : number
}]]

export type Target = {
    Position : Vector2
    ,Velocity : Vector2
    ,Part : Part -- optional, if the target has a part
    ,InterpolantWeightings : table
}


--[[export type Point = {
    X : number
    ,Y : number
    ,Data : any
}]]


function Tilegrid:GetTile(TileX:number,TileY:number)
    local Tile 
    if (self.Tiles[TileX]) then
        Tile = self.Tiles[TileX][TileY]     
        if (Tile) then
            --warn( "A Tile was found at ("..tostring(TileX)..", "..tostring(TileY)..")" )
            --print(Tile)
            return Tile :: Tile
        end
    end
    

    --get tile within a child Tilegrid



    --if all else, return nothing
    --warn( "No Tile was found at ("..tostring(TileX)..", "..tostring(TileY)..")" )
    return nil
end

function Tilegrid:BakeTileCount()
    local count = 0
    for _, X in self.Tiles do
        for _, Y in X do
            count += 1
        end
    end
    self.TileCount = count
    return count
end

function Tilegrid:Abstract()
    --create children Tilegrids with a set size

    self.Children = {}
end

function Tilegrid:UniformCostSearch(
    Name : string, 
    Targets : table, 
    InterpolantWeightings : table
)
    local NewNavgrid = setmetatable({}, Tilegrid)

    local Frontier = PriorityQueue.Create() --SHOULD I BE CREATING NEW PRIORITY QUEUES ALL THE TIME???
    Frontier.ComparatorGetFunction = function(Value : any)
        return Frontier.Values[Value].CumulativeCost -- tiles
    end
    local ClosedFronts = {}

    for t, target : Target in Targets do --create nav requests for all good results
        local _target = Vector2.new(
            math.round(math.clamp((target.Position.X+target.Velocity.X)/(self.MapParams.TileSize.X or 1), self.MapParams.OriginCorner.X, self.MapParams.LeadingCorner.X))*(self.MapParams.TileSize.X or 1)
            ,math.round(math.clamp((target.Position.Y+target.Velocity.Y)/(self.MapParams.TileSize.Y or 1), self.MapParams.OriginCorner.Y, self.MapParams.LeadingCorner.Y))*(self.MapParams.TileSize.Y or 1)
        )
        --print(_target)
        local Tile = self:GetTile(_target.X, _target.Y)
        if (Tile ~= nil) then
            local newFront = {
                Tile = Tile
                ,InterpolantWeightings = InterpolantWeightings -- does not account for cost weightings from a target
                ,CumulativeCost = 0
            } :: Front
            Frontier:Enqueue(newFront)
        end
    end
    --print(#Frontier.Values)
    local tileCount = self:BakeTileCount() 

    local desiredTime = 0.1 --desired time to finish tiling
    local desiredTileRate = math.max(1,(tileCount / desiredTime) * (1/200)) 
    local generationTime = 0
    while #Frontier.Values > 0 do
        for i = 1, desiredTileRate, 1 do
            debug.profilebegin("pathfind_tile2")
            local current = Frontier:Dequeue()
            local currentTile = current.Tile
            local currentHeat = current.CumulativeCost
            if ClosedFronts[currentTile.Position.X] == nil then ClosedFronts[currentTile.Position.X] = {} end
            ClosedFronts[currentTile.Position.X][currentTile.Position.Y] = current

            --[[if i == 1 then
                print(ClosedFronts)
            end]]

            for a, adjacent in currentTile.Adjacents do --check each adjacent tile (8 directional)
                local adjacentTile = self:GetTile(adjacent.Position.X,adjacent.Position.Y)
                if (not adjacentTile) then
                    continue
                end
                local adjacentCost : number = mathsummation(adjacent.Costs) --[layer] --assign heat values to tiles
                local newHeat = currentHeat + adjacentCost * (adjacent.Position-currentTile.Position).magnitude --magnitude for euclidean distance

                --do not re-add already witnessed tiles to the frontier
                local adjacentClosed 
                if (ClosedFronts[adjacent.Position.X]) then
                    adjacentClosed = ClosedFronts[adjacent.Position.X][adjacent.Position.Y]
                end
                if (adjacentClosed) then
                    --warn("Attempted to backtrack!")
                    if newHeat < adjacentClosed.CumulativeCost then
                        adjacentClosed.CumulativeCost = newHeat
                    end
                    continue
                elseif (not adjacentClosed) then
                    --print("Enqueue!")
                    local newFront = {
                        Tile = adjacentTile
                        ,InterpolantWeightings = InterpolantWeightings -- does not account for cost weightings from a target
                        ,CumulativeCost = newHeat
                    }::Front

                    if (ClosedFronts[adjacent.Position.X] == nil ) then ClosedFronts[adjacent.Position.X] = {} end
                    ClosedFronts[adjacent.Position.X][adjacent.Position.Y] = newFront
                    Frontier:Enqueue(newFront)
                end
            end

            debug.profileend()
            if (#Frontier.Values == 0) then
                break
            end
        end
        --print(#Frontier.Values)
        generationTime += task.wait()
    end
    print("Finished Pathfinding query: " .. Name .. " in " .. tostring(generationTime) .. " seconds")

    NewNavgrid.Tilegrid = self
    NewNavgrid.Map = ClosedFronts

    if (Name) then
        AllNavgrids[Name] = NewNavgrid
    end
    return NewNavgrid
end

Module.BuildTileSizeXY = function(X:number,Y:number)
    --print(X, y, w, h)
    return {
        Position = Vector2.new(X,Y)
        ;Adjacents = {}
        ;Interpolants = {
            Terrain = 1
        }
        ;
    } :: Tile
end
local StandardAdjacents = {
    Vector2.new(0,1),   -- 12 o'clock
    Vector2.new(1,1),   --
    Vector2.new(1,0),   -- 3  o'clock
    Vector2.new(1,-1),  --
    Vector2.new(0,-1),  -- 6  o'clock
    Vector2.new(-1,-1), --
    Vector2.new(-1,0),  -- 9  o'clock
    Vector2.new(-1,1)   --
}


Module.BuildTilegrid = function(
    Name : string,
    X1 : number, Y1 : number, --origin corner
    X2 : number, Y2 : number, --leading corner
    TileSizeX : number?, TileSizeY : number? --tile size
)
    --failsafe, ensure that TileSizeX and TileSizeY are positive
    TileSizeX = math.abs(TileSizeX or 1)
    TileSizeY = math.abs(TileSizeY or 1)

    local NewTilegrid = setmetatable({}, Tilegrid)

    local TileGrid = {} 
    local TileCount = 0
    --create tiles
    for i = X1, X2, math.sign(X2-X1) * TileSizeX do
        if TileGrid[i] == nil then TileGrid[i] = {} end
        for j = Y1, Y2, math.sign(Y2-Y1) * TileSizeY do
            local newTile = Module.BuildTileSizeXY(i,j)
            TileGrid[i][j] = newTile
            TileCount+=1
        end
    end
    --populate tile adjacents
    for i = X1, X2, TileSizeX do
        for j = Y1, Y2, TileSizeY do
            local AdjacentBuilder = {}

            --cycle through table of standard adjacents and store adjacent tiles in each tile
            for _, Adjacent : Vector2 in StandardAdjacents do
                local AdjacentTile
                if TileGrid[i+Adjacent.X*TileSizeX] then --check to see if X exists to avoid error
                    AdjacentTile = TileGrid[i+Adjacent.X*TileSizeX][j+Adjacent.Y*TileSizeY]
                    if (AdjacentTile) then
                        table.insert(
                            AdjacentBuilder, 
                            { --we just take the offset and the Costs to avoid a table cycle
                                Position = AdjacentTile.Position
                                ,Costs = AdjacentTile.Interpolants
                            }
                        )
                    end
                end
            end

            TileGrid[i][j].Adjacents = AdjacentBuilder
        end
    end

    NewTilegrid.Tiles = TileGrid --contains tiles (duh)
    NewTilegrid.TileCount = TileCount
    NewTilegrid.MapParams = {
        OriginCorner = Vector2.new(X1,Y1)
        ,LeadingCorner = Vector2.new(X2,Y2)
        ,TileSize = Vector2.new(TileSizeX,TileSizeY)
    }
    NewTilegrid.Adjacents = {} --contains adjacent Tilegrid on the same abstraction layer
    NewTilegrid.Children = {} --leave blank for child abstraction navlayers

    
    if (Name) then
        AllTilegrids[Name] = NewTilegrid
    end
    
    
    return NewTilegrid
end

Module.GetTilegrid = function(Name : string)
    return AllTilegrids[Name]
end


Module.BuildTarget = function(Input)
    local targetType = type(Input)
    local output = {}

    if (targetType == type(Vector3.zero)) then --all vector3s are accepted
        output.Position = Input
    elseif (targetType == "userdata") then --basepart positions are accepted - !!! we cant use parts anymore, refactor later
        output.Position = Input.Position
        output.Velocity = Input:GetVelocityAtPosition(Input.Position)
        output.Part = Input
    else
        return false
    end

    local deltaTime = task.wait()
    return {
        Position = Vector2.new(output.Position.X, output.Position.Z)
        ,Velocity = Vector2.new(output.Velocity.X, output.Velocity.Z) * 0.1 * deltaTime/(1/60)
        ,Part = output.Part or nil
    } :: Target
end

Module.GetNavgrid = function(Name : string)
    return AllNavgrids[Name]
end

local box = { --5x5 box solve
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
Module.KernalConvolute = function(Name, Position)
        --[[
    DO SOMETHING
    Pick a tile, and cycle through all of its adjacents to find the lowest heat
    ]]
    local Navgrid = Module.GetNavgrid(Name)
    local MapParams = Navgrid.Tilegrid.MapParams
    local TileSizeX = (MapParams.TileSize.X or 1)
    local TileSizeY = (MapParams.TileSize.Y or 1)
    --print(Navgrid)
    Position = Vector2.new(
        math.round(math.clamp(Position.X/MapParams.TileSize.X,MapParams.OriginCorner.X,MapParams.LeadingCorner.X))* TileSizeX
        ,math.round(math.clamp(Position.Z/MapParams.TileSize.Y,MapParams.OriginCorner.Y,MapParams.LeadingCorner.Y))* TileSizeY
    ) 

    local vectors = {}
    for v, vertex : Vector2 in box do
        vertex = Vector2.new(
            vertex.X * TileSizeX
            ,vertex.Y * TileSizeY
        )
		local adjacentPosition = Position + vertex
        --print(adjacentPosition)

        local path
        if Navgrid.Map[adjacentPosition.X] then
            path = Navgrid.Map[adjacentPosition.X][adjacentPosition.Y]
            --print(path)
        end
		
		--print(path.heat)
		vectors[v] = vertex--*100
		if (path) then
			vectors[v] = vertex.Unit * path.CumulativeCost
		end
	end
    local finalVector = Vector3.zero
	for v, vector in vectors do
		finalVector += Vector3.new(vector.X, 0, vector.Y) or Vector3.zero
        --print(finalVector)
	end
    if (finalVector.Magnitude ~= 0) then
        finalVector = -finalVector.Unit
    end
    --print(finalVector)

    return finalVector
end

return Module