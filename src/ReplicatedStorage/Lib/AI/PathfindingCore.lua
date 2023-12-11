--[[
    Tilegrid Notetaking

    Hierarchial Abstraction
        Add an abstraction step down function (abstraction -> tilegrid)
        Add a re/calculate adjacent costs for abstraction layers

    Refactor code to use generic quadtree library
]]

local function mathsummation(values : table | number)
    local out = 0
    for _, value : number in values do
        out += value
    end
    return out
end


local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage:WaitForChild("Scripts")

local PriorityQueue = require(ReplicatedScripts.Lib.PriorityQueue)
local Promise = require(ReplicatedStorage.Packages.Promise)

local Tilegrid = {}
Tilegrid.__index = Tilegrid
local AllTilegrids = {}

local Navgrid = {}
Navgrid.__index = Navgrid
local AllNavgrids = {}

local Module = {}

export type Tile = {
    Parent : any
    ,Position : Vector2 --the position of a tile
    ,Adjacents : table | Vector2 --a list of all adjacent tiles available for pathfinding
    ,Interpolants : table | number --additive list of pathfinding cost weights
}
export type Tilegrid = {
    Parent : any
    ,TileGrid : table
    ,TileCount : number
    ,MapParams : table
    ,Adjacents : table
    ,Abstraction : table
}

export type Front = { --Frontier tile
    Tile : Tile | Tilegrid
    ,Position : Vector2
    ,CameFrom : Vector2
    ,InterpolantMultipliers : table | number
    ,CumulativeCost : number
    --,ClosedFronts : table | Front--used only for A*, can be shorthanded in UCS
}

--[[export type Adjacent = {
    Offset : Vector2
    ,Costs : number
}]]

export type Target = {
    Position : Vector2
    ,Velocity : Vector2
    ,Part : Part -- optional, if the target has a part
    ,InterpolantMultipliers : table | number
}

--[[export type Point = {
    X : number
    ,Y : number
    ,Data : any
}]]

export type MapParams = {
    OriginCorner : Vector2
    ,LeadingCorner : Vector2
    ,Midpoint : Vector2
    ,TileSize : Vector2
}

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
local AbstractAdjacents = { --it is far easier to compute adjacent edges for a navgrid than it is to compute adjacent corners
    Vector2.new(0,1)
    ,Vector2.new(1,0)
    ,Vector2.new(0,-1)
    ,Vector2.new(-1,0)
}

local ConvolutionAdjacents = { --5x5 box solve
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

function Tilegrid:IntersectCheck(X,Y)
    return not (
        self.MapParams.OriginCorner.X > X or
        self.MapParams.LeadingCorner.X < X or
        self.MapParams.OriginCorner.Y > Y or
        self.MapParams.LeadingCorner.Y < Y
    )
end

function Tilegrid:QueryPoint(X:number,Y:number)
    local out = {
        Tile = nil
        ,AbstractChild = nil
    }

    --abort if requested point is outside Tilegrid bounds
    if not self:IntersectCheck(X,Y) then return out end

    --first, attempt to find a tile
    if self.Tiles ~= nil then
        if self.Tiles[X] then
            local Tile = self.Tiles[X][Y]   
            if Tile then
                --warn( "A Tile was found at ("..tostring(X)..", "..tostring(Y)..")" )
                --print(Tile)
                out.Tile = Tile
                return out
            end
        end
    end

    --if we cannot find a tile, check abstraction layers for a tile
    --do we have abstraction layers?
    if self.Abstraction.Size == nil or self.Abstraction.Children == nil then 
        warn("No tiles, no children") 
        return out 
    end

    --check every abstract child for point
    for i, _ in self.Abstraction.Children do
        for j, Child in self.Abstraction.Children[i] do
            --print("Searching Children")
            local Query = Child:QueryPoint(X, Y)

            if Query then
                out.AbstractChild = self.Abstraction.Children[i][j]
                if Query.Tile then
                    out.Tile = Query.Tile
                    return out
                end
            end
        end 
    end

    --if all else, return whatever we have
    --warn( "No Tile was found at ("..tostring(X)..", "..tostring(Y)..")" )
    return out
end

function Tilegrid:BakeTileCount()
    local count = 0
    if self.Tiles == nil then return count end

    for _, X in self.Tiles do
        for _, Y in X do
            count += 1
        end
    end
    self.TileCount = count
    return count
end

function Tilegrid:GetEdgeTiles()
    local out = {}

    if self.Tiles == nil then return out end

    --print(self.Tiles)

    out[self.MapParams.OriginCorner.X] = self.Tiles[self.MapParams.OriginCorner.X] --left edge
    out[self.MapParams.LeadingCorner.X] = self.Tiles[self.MapParams.LeadingCorner.X] -- right edge

    --top and bottom
    for i = self.MapParams.OriginCorner.X+self.MapParams.TileSize.X, self.MapParams.LeadingCorner.X-self.MapParams.TileSize.X, self.MapParams.TileSize.X do
        if self.Tiles[i] == nil then continue end
        out[i] = {}

        out[i][self.MapParams.OriginCorner.Y] = self.Tiles[i][self.MapParams.OriginCorner.Y] --top edge
        out[i][self.MapParams.LeadingCorner.Y] = self.Tiles[i][self.MapParams.LeadingCorner.Y] --bottom edge
    end

    return out
end

function Tilegrid:Abstract(AbstractionSize : Vector2)
    --create children Tilegrids with a set size
    self.Abstraction.Size = AbstractionSize
    self.Abstraction.Children = {}

    for i = self.MapParams.OriginCorner.X, self.MapParams.LeadingCorner.X, AbstractionSize.X do
        if self.Abstraction.Children[i] == nil then self.Abstraction.Children[i] = {} end
        for j = self.MapParams.OriginCorner.X, self.MapParams.LeadingCorner.Y, AbstractionSize.Y do
            local NewTilegrid = setmetatable({}, Tilegrid)

            local TileGrid = {}
            local TileCount = 0

            for u = 0, AbstractionSize.X-1, self.MapParams.TileSize.X or 1 do --AbstractionSize-1 because duplicate tiles occur with overlapping points
                local horizontal = i + u

                if self.Tiles[horizontal] == nil then self.Tiles[horizontal] = {} end
                for v = 0, AbstractionSize.Y-1, self.MapParams.TileSize.Y or 1 do
                    local vertical = j + v

                    if vertical - j > AbstractionSize.Y then
                        continue
                    end

                    if self.Tiles[horizontal][vertical] then
                        if TileGrid[horizontal] == nil then TileGrid[horizontal] = {} end
                        TileGrid[horizontal][vertical] = self.Tiles[horizontal][vertical]
                        TileGrid[horizontal][vertical].Parent = NewTilegrid
                        --print(self.Tiles[u][v])
                        TileCount += 1
                        --self.TileCount -= 1 --not reducing tile counts is spaghetti to fix another bug -> turn tile count into an array later to fix
                    end
                end
            end

            --very similar to creating a tilemap, except it inherits information rather than creating it

            NewTilegrid.Parent = self
            NewTilegrid.Tiles = TileGrid --contains tiles (duh)
            --print (TileGrid)
            NewTilegrid.TileCount = TileCount
            NewTilegrid.MapParams = {
                OriginCorner = Vector2.new(i,j)
                ,LeadingCorner = Vector2.new(i+AbstractionSize.X-self.MapParams.TileSize.X,j+AbstractionSize.Y-self.MapParams.TileSize.Y)
                ,Midpoint = Vector2.new(i,j) + AbstractionSize * 0.5
                ,TileSize = Vector2.new(self.MapParams.TileSize.X,self.MapParams.TileSize.Y)
            } :: MapParams
            NewTilegrid.Adjacents = {} --contains adjacent Tilegrid on the same abstraction layer
            NewTilegrid.Abstraction = { --leave blank for child abstraction navlayers
                Size = nil
                ,Children = nil
            }
            self.Abstraction.Children[i][j] = NewTilegrid
            task.wait()
        end
    end

    self.Tiles = nil

    --connect adjacent abstractions
    for i = self.MapParams.OriginCorner.X, self.MapParams.LeadingCorner.X, self.Abstraction.Size.X do --Self Abstraction X
        for j = self.MapParams.OriginCorner.Y, self.MapParams.LeadingCorner.Y, self.Abstraction.Size.Y do --Self Abstraction Y
            local Abstract = self.Abstraction.Children[i][j]
            local Edge = Abstract:GetEdgeTiles() --Edge tiles to detect adjacent abstracts
            for _, Child in Edge do --X
                for _, Child in Child do --Y
                   local Position = Child.Position
                   for _, adjacent : Vector2 in StandardAdjacents do
                        local query = self:QueryPoint(Position.X + adjacent.X*self.MapParams.TileSize.X, Position.Y + adjacent.Y*self.MapParams.TileSize.Y)
                        if query.Tile == nil then continue end --if the point extends out of the tilemap, ignore
                        if query.AbstractChild then
                            local QueryAbstract = query.AbstractChild
                            --print(query) 
                            if QueryAbstract.MapParams == nil then continue end
                            if QueryAbstract.MapParams == Abstract.MapParams then continue end --if the queried abstract is the current abstract, ignore

                            local continue2 = false
                            for _, TestAbstract in Abstract.Adjacents do
                                if QueryAbstract.MapParams.OriginCorner == TestAbstract.Position then continue2 = true break end --test abstracts table for duplicate abstracts
                            end
                            if continue2 then
                                continue
                            end       

                            table.insert(Abstract.Adjacents, {
                                Position = QueryAbstract.MapParams.OriginCorner
                                ,Midpoint = QueryAbstract.MapParams.OriginCorner + self.Abstraction.Size * 0.5
                                ,Costs = {} --IMPLEMENT ABSTRACTION COSTS!!!!
                            })
                        end
                   end
                end
            end

            --TEMP COST, CHANGE WITH COST CALCULATION FUNCTION LATER
            local newCost = {}
            for u, _ in Abstract.Tiles do --get the cost of all interpolants in the abstraction
                for v, _ in Abstract.Tiles[u] do
                    local Child = Abstract.Tiles[u][v]
                    for InterpolantName, Interpolant in Child.Interpolants do
                        --local newCost = {}

                        if not newCost[InterpolantName] then newCost[InterpolantName] = 0 end
                        newCost[InterpolantName] += Interpolant
                        --[[
                        if u < 0.5 then

                        else

                        end
                        if v < 0.5 then

                        else

                        end
                        ]]
                    end
                    --print(Child.Interpolants)
                end
            end
            for InterpolantName, Interpolant in newCost do --square root all costs
                newCost[InterpolantName] ^= 2
            end
            --print(mathsummation(newCost))

            for _, Adjacent in Abstract.Adjacents do
                Adjacent.Costs = newCost
            end

            task.wait()
        end
    end

    --print(self)
    return true
end

function Tilegrid:UniformCostSearch(
    Name : string, 
    Targets : table, 
    InterpolantMultipliers : table?,
    Details : table? --zombies that use the tilegrid
)
    return Promise.new(function(resolve, reject, onCancel)
    local NewNavgrid = setmetatable({}, Navgrid)

    local Frontier = PriorityQueue.Create() --SHOULD I BE CREATING NEW PRIORITY QUEUES ALL THE TIME???
    Frontier.ComparatorGetFunction = function(Value : any)
        return -Frontier.Values[Value].CumulativeCost -- tiles
    end
    local ClosedFronts : table | Front = {}

    for t, target : Target in Targets do --create nav requests for all good results
        local _target = Vector2.new(
            math.round(math.clamp((target.Position.X+target.Velocity.X)/(self.MapParams.TileSize.X or 1), self.MapParams.OriginCorner.X, self.MapParams.LeadingCorner.X))*(self.MapParams.TileSize.X or 1)
            ,math.round(math.clamp((target.Position.Y+target.Velocity.Y)/(self.MapParams.TileSize.Y or 1), self.MapParams.OriginCorner.Y, self.MapParams.LeadingCorner.Y))*(self.MapParams.TileSize.Y or 1)
        )
        --print(_target)
        local query = self:QueryPoint(_target.X, _target.Y)
        if not query then continue end
        local Tile = query.Tile
        if Tile then
            local newInterpolantMultipliers = {
                Z = 1
            }

            if InterpolantMultipliers then
                for InterpolantName, InterpolantMultiplier in InterpolantMultipliers do
                    if not newInterpolantMultipliers[InterpolantName] then
                        newInterpolantMultipliers[InterpolantName] = InterpolantMultiplier
                    end
                end
            end
            if target.InterpolantMultipliers then
                for InterpolantName, InterpolantMultiplier in target.InterpolantMultipliers do
                    if not newInterpolantMultipliers[InterpolantName] then
                        newInterpolantMultipliers[InterpolantName] = InterpolantMultiplier
                    end
                end
            end

            if InterpolantMultipliers and target.InterpolantMultipliers then
                for InterpolantName, _ in newInterpolantMultipliers do
                    newInterpolantMultipliers[InterpolantName] = (InterpolantMultipliers[InterpolantName] or 1) * (target.InterpolantMultipliers[InterpolantName] or 1)
                end
            end

            local newFront = {
                Tile = Tile
                ,Position = _target
                ,CameFrom = _target
                ,InterpolantMultipliers = newInterpolantMultipliers -- does not account for cost weightings from a target
                ,CumulativeCost = 0
            } :: Front
            Frontier:Enqueue(newFront)
        end
    end
    if Details then
        for _, detail in Details do
            local _detail = Vector2.new(
                math.round(math.clamp((detail.X)/(self.MapParams.TileSize.X or 1), self.MapParams.OriginCorner.X, self.MapParams.LeadingCorner.X))*(self.MapParams.TileSize.X or 1)
                ,math.round(math.clamp((detail.Y)/(self.MapParams.TileSize.Y or 1), self.MapParams.OriginCorner.Y, self.MapParams.LeadingCorner.Y))*(self.MapParams.TileSize.Y or 1)
            )
            local query = self:QueryPoint(_detail.X, _detail.Y)
            if not query then continue end
            local Tile = query.Tile
            if Tile then
                local newFront = {
                    Tile = Tile
                    ,Position = _detail
                    ,CameFrom = _detail
                    ,InterpolantMultipliers = {} -- does not account for cost weightings from a target
                    ,CumulativeCost = math.huge
                } :: Front
                Frontier:Enqueue(newFront)
            end
        end
    end
    --print(#Frontier.Values)
    local tileCount = self.TileCount
    local desiredTileRate = #StandardAdjacents
    local desiredTime = 0.05
    local generationTimeStart = os.clock()
    local querycount = 0

    while #Frontier.Values > 0 do
        for _ = 1, desiredTileRate, 1 do
            debug.profilebegin("fastpath_ucs")
            local current = Frontier:Dequeue()
            local currentTile : Tile = current.Tile
            local currentPosition

            if not currentTile then continue end

            --if currentTile.MapParams then print("Abstracted Tile!") end

            local parent = currentTile.Parent
            --if parent then print(parent) end

            if (currentTile.MapParams) then currentPosition = currentTile.MapParams.OriginCorner
            else currentPosition = currentTile.Position end



            local currentHeat = current.CumulativeCost
            if ClosedFronts[currentPosition.X] == nil then ClosedFronts[currentPosition.X] = {} end
                if ClosedFronts[currentPosition.X][currentPosition.Y] == nil then ClosedFronts[currentPosition.X][currentPosition.Y] = current end

            for a, adjacent in currentTile.Adjacents do --check each adjacent tile (8 directional)
                --print(adjacent)
                --if not adjacent.Position then --[[warn("Continued! 4")]] print(adjacent) continue end

                local adjacentPosition = adjacent.Position

                local adjacentSearch

                local otherabstraction
                if not currentTile.MapParams then --If we are a tile
                    if parent and parent.Tiles and parent.Tiles[adjacent.Position.X] then
                        adjacentSearch = parent.Tiles[adjacent.Position.X][adjacent.Position.Y]
                        --print("Adjacent Tile")                       
                    else 
                        if parent and parent.Parent and parent.Parent.Abstraction.Children then
                            otherabstraction = parent.Parent.Abstraction
                            --print("Tile to Abstraction", otherabstraction)
                        end
                    end
                else --Else, we are a tilemap
                    if parent and parent.Abstraction.Children then
                        otherabstraction = parent.Abstraction
                        --print("Abstraction to Abstraction")
                    end
                end
                if otherabstraction and otherabstraction.Children and otherabstraction.Size then
                    local roundedPosition = Vector2.new(
                        math.floor(adjacent.Position.X / otherabstraction.Size.X)*otherabstraction.Size.X
                        ,math.floor(adjacent.Position.Y / otherabstraction.Size.Y)*otherabstraction.Size.Y
                    )

                    adjacentSearch = otherabstraction.Children[roundedPosition.X][roundedPosition.Y]
                    --print("Step up!", roundedPosition)
                end

                if not adjacentSearch then
                    continue
                end

                --if adjacentSearch then print(adjacentSearch) end

                local multipliedCosts = {}
                if current.InterpolantMultipliers then
                    for InterpolantName, _ in adjacent.Costs do
                        multipliedCosts[InterpolantName] = adjacent.Costs[InterpolantName] * (current.InterpolantMultipliers[InterpolantName] or 1)
                        --print(multipliedCosts[InterpolantName])
                    end
                end

                --[[
                for InterpolantName, InterpolantMultiplier in current.InterpolantMultipliers do
                    multipliedCosts[InterpolantName] *= InterpolantMultiplier or 1
                end
                ]]

                local adjacentCost : number = mathsummation(multipliedCosts) --[layer] --assign heat values to tiles

                local sizeMagnitude = parent.MapParams.TileSize.Magnitude or 1
                if otherabstraction and otherabstraction.Size then sizeMagnitude = otherabstraction.Size.Magnitude end
                local newCost = currentHeat + adjacentCost * ((adjacentPosition-currentPosition).Magnitude / sizeMagnitude or 1) --magnitude for euclidean distance
                if newCost == nil then warn("Cost has been nil'd!") end

                --do not re-add already witnessed tiles to the frontier
                local adjacentClosed 
                if ClosedFronts[adjacentPosition.X] then
                    if ClosedFronts[adjacentPosition.X][adjacentPosition.Y] then
                        adjacentClosed = ClosedFronts[adjacentPosition.X][adjacentPosition.Y]
                    end 
                end
                if adjacentClosed ~= nil and adjacentClosed.CumulativeCost then
                    --warn("Attempted to backtrack!")
                    --if currentTile.MapParams ~= nil and adjacentClosed.Tile.MapParams == nil then warn("Step down!") continue end
                    if currentTile.MapParams ~= nil and adjacentClosed.Tile.MapParams == nil then continue end

                    if newCost < adjacentClosed.CumulativeCost and newCost ~= nil then
                        adjacentClosed.CumulativeCost = newCost
                        adjacentClosed.CameFrom = currentPosition
                    end
                    
                    --print(adjacentClosed.CumulativeCost)
                    continue
                else
                    --print("Enqueue!")
                    local newFront = {
                        Tile = adjacentSearch
                        ,Position = adjacentPosition
                        ,CameFrom = currentPosition
                        ,InterpolantMultipliers = InterpolantMultipliers -- does not account for cost weightings from a target
                        ,CumulativeCost = newCost
                    }::Front

                    if ClosedFronts[adjacentPosition.X] == nil then ClosedFronts[adjacentPosition.X] = {} end
                    ClosedFronts[adjacentPosition.X][adjacentPosition.Y] = newFront
                    --print(ClosedFronts)

                    Frontier:Enqueue(newFront)
                end
                querycount += 1
            end

            querycount += 1
            debug.profileend()
            if #Frontier.Values == 0 then
                break
            end
        end

        local generationTimeDelta = os.clock() - generationTimeStart

        desiredTileRate = (tileCount * (generationTimeDelta / desiredTime))^2

        --print(#Frontier.Values)
        --generationTimeStart += task.wait()
        task.wait()
    end

    local generationTime = os.clock() - generationTimeStart
    --print("Finished Pathfinding query: " , Name , " in " , generationTime , " seconds after searching " , querycount , " tiles")

    NewNavgrid.Tilegrid = self
    NewNavgrid.Map = ClosedFronts

    if Name then
        AllNavgrids[Name] = NewNavgrid
    end
    --print(NewNavgrid)
    resolve( NewNavgrid )

    end)
end

function Navgrid:KernalConvolute(Position : Vector3)
    local out = Vector3.zero

    local Tilegrid = self.Tilegrid
    local RootSize = Tilegrid.Abstraction.Size or Tilegrid.MapParams.TileSize
    local RootPosition = Vector2.new(
        math.floor(Position.X / RootSize.X) * RootSize.X
        ,math.floor(Position.Z / RootSize.Y) * RootSize.Y
    )
    local query = Tilegrid:QueryPoint(RootPosition.X, RootPosition.Y) --check to see if there is a 'root tile', we're looking for abstraction grids
    if not (query and query.Tile) then return out end

    local SnapSize
    local SnapPosition
    local SnapPath
    local Abstracted = false
    --local AbstractionOffset = Vector2.zero


    local up = query.Tile.Parent
    if up.Tiles then --we initially search through the tile layer to see if we can find the tile in the navgrid
        SnapSize = Tilegrid.MapParams.TileSize
        SnapPosition = Vector2.new(
            math.round(Position.X / SnapSize.X) * SnapSize.X
            ,math.round(Position.Z / SnapSize.Y) * SnapSize.Y
        )
        --print(SnapPosition)
        if self.Map[SnapPosition.X] and self.Map[SnapPosition.X][SnapPosition.Y] then
            up = nil
            SnapPath = self.Map[SnapPosition.X][SnapPosition.Y]
            --print("Found in first try", SnapPosition)
        end
    end
    while up do --if we cannot find the tile in the navgrid, recursively decrease the search resolution by searching abstraction layers
        up = up.Parent
        --print("Upshift")
        if not up then return out end

        if not (up and up.Abstraction and up.Abstraction.Size) then continue end
        SnapSize = up.Abstraction.Size
        SnapPosition = Vector2.new(
            math.floor(Position.X / SnapSize.X) * SnapSize.X
            ,math.floor(Position.Z / SnapSize.Y) * SnapSize.Y
        )
        if self.Map[SnapPosition.X] and self.Map[SnapPosition.X][SnapPosition.Y] then
            up = nil
            SnapPath = self.Map[SnapPosition.X][SnapPosition.Y]
            --print(SnapPath)
            Abstracted = true
            --AbstractionOffset = SnapPath.Tile.MapParams.Midpoint
            --print("Found", SnapPosition)
            break
        end
    end

    local AdjacentSearchArea
    if Abstracted then AdjacentSearchArea = StandardAdjacents
        else AdjacentSearchArea = ConvolutionAdjacents end
    
    local vectors = {}
    for v, vertex : Vector2 in AdjacentSearchArea do
        vertex *= SnapSize
		local adjacentPosition = SnapPosition + vertex

        local path
        if self.Map[adjacentPosition.X] then
            path = self.Map[adjacentPosition.X][adjacentPosition.Y]
        end
		
        local newVector = vertex * 100
		if path then
            --[[
            local truePosition = Vector2.new(Position.X, Position.Z)
            if (SnapPath) then
                if (SnapPath.MapParams and SnapPath.MapParams.Midpoint) then truePosition = SnapPath.MapParams.Midpoint 
                    elseif SnapPath.Position then truePosition = SnapPath.Position
                        else truePosition = SnapPosition end
            end
            print(truePosition)
            ]]

            --Vector2.new(Position.X, Position.Z)
            newVector = (path.Position - path.CameFrom).Unit * path.CumulativeCost

            
            --print(newVector)
		end
        if newVector.Magnitude > 0 then
            table.insert(vectors, newVector)
        end
	end

    table.insert(vectors, (SnapPath.Position - SnapPath.CameFrom).Unit)
    --print(SnapPath.Position - SnapPath.CameFrom)

    --print(#vectors)
    --print(vectors)
	for v, vector in vectors do
		out += Vector3.new(vector.X, 0, vector.Y) or Vector3.zero
        --print(out)
	end
    if out.Magnitude ~= 0 then
        --if Abstracted then out = out.Unit else out = -out.Unit end
        out = -out.Unit
    end
    --print(out)

    return out
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

Module.BuildTilegrid = function(
    Name : string?,
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
            newTile.Parent = NewTilegrid

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
                    if AdjacentTile then
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
        ,Midpoint = (Vector2.new(X1,Y1) + Vector2.new(X2,Y2)) * 0.5
        ,TileSize = Vector2.new(TileSizeX,TileSizeY)
    }::MapParams
    NewTilegrid.Adjacents = {} --contains adjacent Tilegrid on the same abstraction layer
    NewTilegrid.Abstraction = { --leave blank for child abstraction navlayers
        Size = nil
        ,Children = nil
    } 
    
    if Name then
        AllTilegrids[Name] = NewTilegrid
    end
    
    
    return NewTilegrid
end

Module.GetTilegrid = function(Name : string)
    return AllTilegrids[Name]
end


Module.BuildTarget = function(Input : Vector3 | Part)
    local targetType = type(Input)
    local output = {}

    if targetType == type(Vector3.zero) then --all vector3s are accepted
        output.Position = Input
    elseif targetType == "userdata" then --basepart positions are accepted - !!! we cant use parts anymore, refactor later
        output.Position = Input.Position
        output.Velocity = Input:GetVelocityAtPosition(Input.Position)
        output.Part = Input
    else
        return nil
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

--[==[
Module.KernalConvolute = function(Name : string, Position : Vector3)
    --[[
    DO SOMETHING
    Pick a tile, and cycle through all of its adjacents to find the lowest heat
    ]]
    local Navgrid = Module.GetNavgrid(Name)
    local Tilegrid = Navgrid.Tilegrid
    local MapParams = Tilegrid.MapParams

    local SnapSizeX = (MapParams.TileSize.X or 1)
    local SnapSizeY = (MapParams.TileSize.Y or 1)
    local SnapPosition = Vector2.new(
        math.round(math.clamp(Position.X/SnapSizeX,MapParams.OriginCorner.X,MapParams.LeadingCorner.X)) * SnapSizeX
        ,math.round(math.clamp(Position.Z/SnapSizeY,MapParams.OriginCorner.Y,MapParams.LeadingCorner.Y)) * SnapSizeY
    )
    if Tilegrid.Abstraction.Children and Tilegrid.Abstraction.Size then --check for abstracted layer
        SnapSizeX = Tilegrid.Abstraction.Size.X
        SnapSizeY = Tilegrid.Abstraction.Size.Y
        SnapPosition = Vector2.new(
            math.floor(math.clamp(Position.X/SnapSizeX,MapParams.OriginCorner.X,MapParams.LeadingCorner.X)) * SnapSizeX
            ,math.floor(math.clamp(Position.Z/SnapSizeY,MapParams.OriginCorner.Y,MapParams.LeadingCorner.Y)) * SnapSizeY
        )
    end

    local vectors = {}
    for v, vertex : Vector2 in box do
        vertex = Vector2.new(
            vertex.X * SnapSizeX
            ,vertex.Y * SnapSizeY
        )
		local adjacentPosition = SnapPosition + vertex
        --print(adjacentPosition)

        local path
        if Navgrid.Map[adjacentPosition.X] then
            path = Navgrid.Map[adjacentPosition.X][adjacentPosition.Y]
        else
            print("no")
        end
		
		--print(path.heat)
		--vectors[v] = vertex--*100
		if path then
			vectors[v] = vertex * path.CumulativeCost
            --print("1")
		end
	end
    --print(vectors)
    local finalVector = Vector3.zero
	for v, vector in vectors do
		finalVector += Vector3.new(vector.X, 0, vector.Y) or Vector3.zero
        --print(finalVector)
	end
    if finalVector.Magnitude ~= 0 then
        finalVector = -finalVector.Unit
    end
    --print(finalVector)

    return finalVector
end
]==]



--[[
Module.AStarSearch = function(Name : string, Origin : Vector3, Target : Target, InterpolantWeightings : table?)
    local Tilegrid = Module.GetTilegrid(Name)
    
    local Frontier = PriorityQueue.Create()
    Frontier.ComparatorGetFunction = function(Value : any)
        return Frontier.Values[Value].CumulativeCost -- tiles
    end
    if true then
        local _target = Vector2.new(
            math.round(math.clamp((Target.Position.X+Target.Velocity.X)/(Tilegrid.MapParams.TileSize.X or 1), Tilegrid.MapParams.OriginCorner.X, Tilegrid.MapParams.LeadingCorner.X))*(Tilegrid.MapParams.TileSize.X or 1)
            ,math.round(math.clamp((Target.Position.Y+Target.Velocity.Y)/(Tilegrid.MapParams.TileSize.Y or 1), Tilegrid.MapParams.OriginCorner.Y, Tilegrid.MapParams.LeadingCorner.Y))*(Tilegrid.MapParams.TileSize.Y or 1)
        )
        --print(_target)
        local Tile = Tilegrid:QueryPoint(_target.X, _target.Y)
        if (Tile ~= nil) then
            local newFront = {
                Tile = Tile
                ,InterpolantWeightings = InterpolantWeightings -- does not account for cost weightings from a target
                ,CumulativeCost = 0
                ,ClosedFronts = {}
            } :: Front
            Frontier:Enqueue(newFront)
        end
    end

    while #Frontier > 0 do
        local current = Frontier:Dequeue()
        local currentTile = current.Tile
        local currentHeat = current.CumulativeCost
    end
end
]]

return Module