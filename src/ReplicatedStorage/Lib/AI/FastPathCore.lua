--[[
    NOTETAKING

    store way more data, make the system more robust
        dont use step up/down logic, index every position with a Tile for Abstraction
    --

--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ReplicatedScripts = ReplicatedStorage.Scripts
--

local Util = require(ReplicatedScripts.Lib.Util)
local PriorityQueueModule = require(ReplicatedScripts.Lib.PriorityQueue)
local QuadtreeModule = require(ReplicatedScripts.Lib.Quadtree)
local Promise = require(ReplicatedStorage.Packages.Promise)

local TileGrid = {}
TileGrid.__index = TileGrid
local AllTileGrids = {}

local NavGrid = {}
NavGrid.__index = NavGrid

local Module = {}

export type Function = any

export type Point = QuadtreeModule.Point
export type Box = QuadtreeModule.Box

export type Node = {
    TileGrid : TileGrid
    ,Layer : number
    ,Boundary : Box | Point
    ,Parent : Abstraction --Abstraction Layers, helpful for 'stepping up' Layers
    ,Children : table | Node --used exclusively by Abstraction Layers
    ,PrimaryChild : Node
    ,Adjacents : table | Node
    ,Interpolants : table | number
}

export type Tile = Node --Tiles are primary containers for navigation information
export type Adjacent = {
    Node : Tile | Abstraction
    ,Interpolants : table | number
}

export type Abstraction = Node --Abstractions are similar to Tiles, but contain aggregated data instead
export type AbstractionLayer = {
    AbstractionGrid : Abstraction
    ,AbstractionSize : Vector2
}
export type TileGrid = {
    --stuff
    Tiles : table | Tile
    ,TileCount : number
    ,TileSize : Vector2
    ,AbstractionLayers : table | AbstractionLayer
    ,OriginCorner : Vector2
    ,LeadingCorner : Vector2
    ,NavGrids : table | NavGrid
}

export type Front = {
    CurrentTile : Tile
    ,CurrentBoundary : Point | Box
    ,PreviousFronts : table | Front
    ,Target : Target
    ,CumulativeCost : number
    ,Priority : number
}
export type NavGrid = {
    --stuff
}

export type Target = {
    Position : Vector2 
    ,Velocity : Vector2
    ,Time : number --position + velocity
}

local ManhattanAdjacents : table | Vector2 = {
    Vector2.new(0,1),   -- 12 o'clock
    Vector2.new(1,0),   -- 3  o'clock
    Vector2.new(0,-1),  -- 6  o'clock
    Vector2.new(-1,0),  -- 9  o'clock
}
local EuclideanAdjacents : table | Vector2 = {
    Vector2.new(0,1),   -- 12 o'clock
    Vector2.new(1,1),   --
    Vector2.new(1,0),   -- 3  o'clock
    Vector2.new(1,-1),  --
    Vector2.new(0,-1),  -- 6  o'clock
    Vector2.new(-1,-1), --
    Vector2.new(-1,0),  -- 9  o'clock
    Vector2.new(-1,1)   --
}

local GetEdgeChildrenInDirection = function(Tile : Tile, Direction : Vector2) --first, get Adjacent Abstraction in a direction, then get Children Tiles in opposite direction to step down
    local Side = Vector2.new(
        0.5 + math.sign(Direction.X) * 0.5
        ,0.5 + math.sign(Direction.Y) * 0.5
    )
    --output a row/column of Tiles/Abstractions for single vectors


    --if both axes have entries, then output a Corner Tile

end

--get Adjacent Nodes on a TileGrid / Abstraction Layer
function TileGrid:GetAdjacents(Node : Tile | Abstraction | Node) : table | Adjacent
    local out = {}
    local U = Node.Boundary.X
    local V = Node.Boundary.Y
    local Layer = Node.Layer

    local AbstractionLayer : AbstractionLayer = self.AbstractionLayers[Layer]
    local AbstractionGrid = AbstractionLayer.AbstractionGrid
    local AbstractionSize = AbstractionLayer.AbstractionSize

    local ChildLayer : AbstractionLayer = self.AbstractionLayers[Layer-1]
    local ChildGrid
    local ChildSize
    if ChildLayer then
        ChildGrid = ChildLayer.AbstractionGrid
        ChildSize = ChildLayer.AbstractionSize
    end

    local SearchAdjacents
    if Layer == 0 then SearchAdjacents = EuclideanAdjacents else SearchAdjacents = ManhattanAdjacents end --Abstractions use manhattan Adjacents (there are no edges between Corners dummy!)

    --cycle through table of standard Adjacents and store Adjacent Tiles in each Tile
    for _, Adjacent : Vector2 in SearchAdjacents do
        local AdjacentNode : Node

        if not AbstractionGrid[U+Adjacent.X*AbstractionSize.X] then
            continue 
        end --check to see if X exists to avoid error

        AdjacentNode = AbstractionGrid[U+Adjacent.X*AbstractionSize.X][V+Adjacent.Y*AbstractionSize.Y]
        if not AdjacentNode then 
            continue 
        end

        local AdjacentInterpolants
        --query the cost of the Node
        if AdjacentNode.Layer == 0 then
            AdjacentInterpolants = AdjacentNode.Interpolants
        else
            --store pathfinding cost for abstraction interpolants
            local HeuristicFn = function(Front : Front)
                return Vector2.new(AdjacentNode.PrimaryChild.Boundary.X - Front.CurrentBoundary.X, AdjacentNode.PrimaryChild.Boundary.Y - Front.CurrentBoundary.Y).Magnitude*2
                --return math.abs(NodeChild.Boundary.X - Node.Boundary.X) + math.abs(NodeChild.Boundary.Y - NodeChild.Boundary.Y) --this method assumes that a child will be in the center, fix later
            end
            AdjacentInterpolants = self:AStarQuery(Node.PrimaryChild, AdjacentNode.PrimaryChild, HeuristicFn)
        end

        --add Adjacent to list of Adjacents
        table.insert(
            out
            ,{
                Node = AdjacentNode
                ,Interpolants = AdjacentInterpolants
            } :: Adjacent
        )
    end

    return out
end

function TileGrid:CornerCheck(U,V)
    if U < self.OriginCorner.X then self.OriginCorner = Vector2.new(U,self.OriginCorner.Y) 
        elseif U > self.LeadingCorner.X then self.LeadingCorner = Vector2.new(U,self.LeadingCorner.Y) 
            end
    if V < self.OriginCorner.Y then self.OriginCorner = Vector2.new(self.OriginCorner.X, V) 
        elseif V > self.LeadingCorner.Y then self.LeadingCorner = Vector2.new(self.LeadingCorner.X, V) 
            end
end

function TileGrid:BuildTile(U,V)
    -- define a Tile at a position
    local NewTile = {
        TileGrid = self
        ,Layer = 0
        ,Boundary = QuadtreeModule.newPoint(U,V)
        ,Parent = nil
        ,Adjacents = {}
        ,Interpolants = {}
    } :: Tile

    --populate Adjacents for this Tile
    NewTile.Adjacents = self:GetAdjacents(NewTile)
        --add this Tile to Adjacents
        for _, Adjacent : Adjacent in NewTile.Adjacents do
            local NewAdjacent = {
                Node = NewTile
                ,Interpolants = NewTile.Interpolants
            } :: Adjacent

            table.insert(
                Adjacent.Node.Adjacents
                ,NewAdjacent
            )
        end
    --

    --add new Tile to TileGrid
    if not self.Tiles[U] then self.Tiles[U] = {} end
    self.Tiles[U][V] = NewTile

    --check for mins and max
    self:CornerCheck(U,V)

    return NewTile
end

--TileGrid Abstraction creates multiple Layers of less refined TileGrid s that cache navigation data to be read faster
function TileGrid:Abstract(Layer : number?)
    --create multiple Abstractions of the TileGrid based on a parsed size
    --  has support for obtuse sizes
    if not Layer then Layer = 0 end

    local AbstractionLayer : AbstractionLayer = self.AbstractionLayers[Layer+1]

    if not AbstractionLayer then return end

    local ChildLayer : AbstractionLayer = self.AbstractionLayers[Layer]

    --remove generic variables later?
    local AbstractionGrid = AbstractionLayer.AbstractionGrid
    local AbstractionSizeU = AbstractionLayer.AbstractionSize.X
    local AbstractionSizeV = AbstractionLayer.AbstractionSize.Y

    local ChildGrid = ChildLayer.AbstractionGrid
    local ChildSize = ChildLayer.AbstractionSize

    local TileSizeU = self.TileSize.X
    local TileSizeV = self.TileSize.Y
    local TileGridOriginCornerU = self.OriginCorner.X
    local TileGridOriginCornerV = self.OriginCorner.Y
    local TileGridLeadingCornerU = self.LeadingCorner.X
    local TileGridLeadingCornerV = self.LeadingCorner.Y
    --

    --iterate through the ChildGrid based on a given size for our Abstractions
    for i = TileGridOriginCornerU, TileGridLeadingCornerU, AbstractionSizeU do
        for j = TileGridOriginCornerV, TileGridLeadingCornerV, AbstractionSizeV do      
            local Children = {}
            local NewAbstract
            --populate Abstract with Children
            for U = i, i+AbstractionSizeU-ChildSize.X, ChildSize.X do
                for V = j, j+AbstractionSizeV-ChildSize.Y, ChildSize.Y do
                    if not ChildGrid[U] then continue end
                    if not Children[U] then Children[U] = {} end
                    Children[U][V] = ChildGrid[U][V]
                    --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Filter children by distance to center, and set the closest as a 'child node'
                
                end
            end

            if not Children then continue end --if the Abstract doesnt have Children, no need for it to exist

            --the actual Abstract Node
            NewAbstract = {
                TileGrid = self
                ,Layer = Layer+1
                ,Boundary = QuadtreeModule.BuildBoxFromCorners(i,j,i+AbstractionSizeU,j+AbstractionSizeV) --start Abstract at Origin Corner
                ,Parent = nil
                ,Children = Children
                ,PrimaryChild = nil
                ,Adjacents = {}
                ,Interpolants = {}
            }

            --identify Children's parent as this Abstraction, and discover a PrimaryChild
            local ChildrenDistanceFilter = PriorityQueueModule.BuildPriorityQueue(
                function(a, b)
                    local A = Vector2.new(NewAbstract.Boundary.X - a.Boundary.X, NewAbstract.Boundary.Y - a.Boundary.Y).Magnitude
                    local B = Vector2.new(NewAbstract.Boundary.X - b.Boundary.X, NewAbstract.Boundary.Y - b.Boundary.Y).Magnitude

                    return A - B
                end
            )
            --
            for U = i, i+AbstractionSizeU-ChildSize.X, ChildSize.X do
                if not Children[U] then continue end
                for V = j, j+AbstractionSizeV-ChildSize.Y, ChildSize.Y do
                    Children[U][V].Parent = NewAbstract
                    ChildrenDistanceFilter:Enqueue(Children[U][V])
                end
                NewAbstract.PrimaryChild = ChildrenDistanceFilter:Dequeue()
            end

            --populate Abstraction Adjacents
            NewAbstract.Adjacents = self:GetAdjacents(NewAbstract)
                --add this Tile to Adjacents
                for _, Adjacent : Adjacent in NewAbstract.Adjacents do
                    --use pathfinding cost for abstraction interpolants
                    local HeuristicFn = function(Front : Front)
                        return Vector2.new(Adjacent.Node.PrimaryChild.Boundary.X - Front.CurrentBoundary.X, Adjacent.Node.PrimaryChild.Boundary.Y - Front.CurrentBoundary.Y).Magnitude*2
                        --return math.abs(NewAbstract.Boundary.X - NodeChild.Boundary.X) + math.abs(NewAbstract.Boundary.Y - NodeChild.Boundary.Y) --this method assumes that a child will be in the center, fix later
                    end
                    local NewAdjacent = {
                        Node = NewAbstract
                        ,Interpolants = self:AStarQuery(NewAbstract.PrimaryChild, Adjacent.Node.PrimaryChild, HeuristicFn)
                    } :: Adjacent

                    table.insert(
                        Adjacent.Node.Adjacents
                        ,NewAdjacent
                    )
                end
            --
            --add Abstract to Layer
            if not AbstractionGrid[NewAbstract.Boundary.X] then AbstractionGrid[NewAbstract.Boundary.X] = {} end
            AbstractionGrid[NewAbstract.Boundary.X][NewAbstract.Boundary.Y] = NewAbstract
        end
    end

    --recursively Abstract until all Abstraction Layers have been parsed
    self:Abstract(Layer+1)
end

function TileGrid:BuildNavGrid(Name : string)
    local NewNavGrid = setmetatable({}, NavGrid) :: NavGrid

    NewNavGrid.Name = Name
    NewNavGrid.Targets = {}
    NewNavGrid.InterpolantMultipliers = {}

    NewNavGrid.HeuristicFn = function() return 0 end

    if Name then
        self.NavGrids[Name] = NewNavGrid
    end

    return NewNavGrid
end

function TileGrid:AStarQuery(
    Origin : Target | Node
    ,Target : Target | Node
    ,HeuristicFn : (Front : Front) -> number
)
    local out
    if not (Origin or Target) then return end
    --build Origin and Target Nodes
    local OriginNode
    if Origin.X and Origin.Y then
        local _Origin = Vector2.new(
            math.round(Origin.X/self.TileSize.X)*self.TileSize.X
            ,math.round(Origin.Y/self.TileSize.Y)*self.TileSize.Y
        )
        if not self.Tiles[_Origin.X] then return end
        OriginNode = self.Tiles[_Origin.X][_Origin.Y]
        if not OriginNode then return end
    else 
        OriginNode = Origin
    end
    local TargetNode
    if Target.X and Target.Y then
        local _Target = Vector2.new(
            math.round(Target.X/self.TileSize.X)*self.TileSize.X
            ,math.round(Target.Y/self.TileSize.Y)*self.TileSize.Y
        )
        if not self.Tiles[_Target.X] then return end
        TargetNode = self.Tiles[_Target.X][_Target.Y]
        if not TargetNode then return end
    else
        TargetNode = Target
    end

    if OriginNode.Layer ~= TargetNode.Layer then warn("A* across different Abstractions is not implemented yet!") return end

    --build our first Front
    local newFront = {
        CurrentNode = OriginNode
        ,CurrentBoundary = OriginNode.Boundary
        ,PreviousFronts = {}
        ,Target = Target
        ,CumulativeCost = {}
        ,Priorty = 0
    } :: Front
    newFront.Priority = HeuristicFn(newFront)

    --initialise Priority Queue
    local Frontier = PriorityQueueModule.BuildPriorityQueue(
        function(a,b) return
            a.Priority -
            b.Priority
        end
    )
    Frontier:Enqueue(newFront)

    --Pathfind
    local ClosedNodes = {
        [newFront.CurrentBoundary.X] = {
            [newFront.CurrentBoundary.Y] = newFront
        }
    }

    local generationStart = os:clock()
    local generationSteps = 0
    while not Frontier:IsEmpty() do
        generationSteps += 1

        local CurrentFront : Front = Frontier:Dequeue()
        local CurrentNode = CurrentFront.CurrentNode
        local CurrentBoundary = CurrentFront.CurrentBoundary
        local CurrentCost = CurrentFront.CumulativeCost
        local PreviousFronts = CurrentFront.PreviousFronts

        --print(Util.MathSummation(CurrentCost), Vector2.new(CurrentBoundary.X, CurrentBoundary.Y))
        if CurrentNode == TargetNode then
            --print ("Done!", CurrentCost)
            out = CurrentCost
            break
        end

        for _, Adjacent in CurrentNode.Adjacents do
            local AdjacentNode = Adjacent.Node
            if not AdjacentNode then continue end
            local NewCost = {}
            --apply Costs to each Interpolant on the Front
            for Index, Cost in Adjacent.Interpolants do
                if not CurrentCost[Index] then NewCost[Index] = Cost else
                    NewCost[Index] = CurrentCost[Index] + Cost end
            end

            if not (
                ClosedNodes[AdjacentNode.Boundary.X] and
                ClosedNodes[AdjacentNode.Boundary.X][AdjacentNode.Boundary.Y]
            ) or (
                ClosedNodes[AdjacentNode.Boundary.X] and
                Util.MathSummation(NewCost) < Util.MathSummation(ClosedNodes[AdjacentNode.Boundary.X][AdjacentNode.Boundary.Y].CumulativeCost)
            )
            then
                --[[
                local newPreviousFronts = PreviousFronts
                if not newPreviousFronts[CurrentBoundary.X] then newPreviousFronts[CurrentBoundary.X] = {} end
                newPreviousFronts[CurrentBoundary.X][CurrentBoundary.Y] = CurrentFront
                ]]

                local newFront = {
                    CurrentNode = AdjacentNode
                    ,CurrentBoundary = AdjacentNode.Boundary
                    --,PreviousFronts = newPreviousFronts
                    ,Target = Target
                    ,CumulativeCost = NewCost
                    ,Priorty = math.huge
                } :: Front

                if not ClosedNodes[AdjacentNode.Boundary.X] then ClosedNodes[AdjacentNode.Boundary.X] = {} end
                ClosedNodes[AdjacentNode.Boundary.X][AdjacentNode.Boundary.Y] = newFront

                newFront.Priority = Util.MathSummation(NewCost) + HeuristicFn(newFront)
                Frontier:Enqueue(newFront)
            end
        end
        --task.wait()
    end
    local generationDelta = os:clock() - generationStart
    --print(generationDelta, generationSteps)

    return out
end

function TileGrid:UniformCostSearch(
    NavGrid : NavGrid
    ,Targets : table
    ,HeuristicFn : Function | number --the Heuristic is passed to NavGrid fronts
)
return Promise.new(function(resolve, reject, onCancel)
    --red blob games ucs



end) end


--NavGrid class




Module.BuildTileGrid = function(Name : string, TileSize : Vector2?)
    local NewTileGrid = setmetatable({}, TileGrid) :: TileGrid

    NewTileGrid.Tiles = {} --contains Tiles (duh)
    NewTileGrid.TileCount = 0
    NewTileGrid.TileSize = TileSize or Vector2.new(1,1)
    NewTileGrid.AbstractionLayers = {
        [0] = {
            AbstractionGrid = NewTileGrid.Tiles
            ,AbstractionSize = NewTileGrid.TileSize
        } :: AbstractionLayer
    }
    NewTileGrid.OriginCorner = Vector2.new(10000,10000) --Origin Corner is the minimum Corner, automatically assigned at Tile creation
    NewTileGrid.LeadingCorner = Vector2.new(-10000,-10000) --Leading Corner is the maximum Corner, automatically assigned at Tile creation
    NewTileGrid.NavGrids = {}

    if Name then
        AllTileGrids[Name] = NewTileGrid
    end

    return NewTileGrid
end
Module.GetTileGrid = function(Name : string)
    return AllTileGrids[Name]
end

Module.BuildTarget = function(Position : Vector2 | Vector3, Velocity : Vector2 | Vector3?)
    --check if Position is a Vector3
    if Position.Z then
        Position = Vector2.new(Position.X, Position.Y)
        if Velocity.Z then
            Velocity = Vector2.new(Position.X, Position.Z)
    
        end
    end

    return {
        Position = Position
        ,Velocity = Velocity
        ,Time = tick()
    } :: Target
end

return Module