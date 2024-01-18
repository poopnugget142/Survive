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
    ,Interpolants : (table) -> number
}

export type Abstraction = Node --Abstractions are similar to Tiles, but contain aggregated data instead
export type AbstractionLayer = {
    AbstractionGrid : Abstraction
    ,AbstractionSize : Vector2
}
export type TileGrid = {
    --stuff
    Tiles : (table) -> Tile
    ,TileCount : number
    ,TileSize : Vector2
    ,AbstractionLayers : (table) -> AbstractionLayer
    ,OriginCorner : Vector2
    ,LeadingCorner : Vector2
    ,NavGrids : (table) -> NavGrid
}

export type Front = {
    Node : Node
    ,Boundary : Point | Box
    ,PreviousFront : Front
    ,Force : Vector2
    ,Target : Target
    ,CumulativeInterpolants : (table) -> number
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

local ManhattanAdjacents : (table) -> Vector2 = {
    Vector2.new(0,1),   -- 12 o'clock
    Vector2.new(1,0),   -- 3  o'clock
    Vector2.new(0,-1),  -- 6  o'clock
    Vector2.new(-1,0),  -- 9  o'clock
}
local EuclideanAdjacents : (table) -> Vector2 = {
    Vector2.new(0,1),   -- 12 o'clock
    Vector2.new(1,1),   --
    Vector2.new(1,0),   -- 3  o'clock
    Vector2.new(1,-1),  --
    Vector2.new(0,-1),  -- 6  o'clock
    Vector2.new(-1,-1), --
    Vector2.new(-1,0),  -- 9  o'clock
    Vector2.new(-1,1)   --
}

--[==[local GetEdgeChildrenInDirection = function(Tile : Tile, Direction : Vector2) --first, get Adjacent Abstraction in a direction, then get Children Tiles in opposite direction to step down
    local Side = Vector2.new(
        0.5 + math.sign(Direction.X) * 0.5
        ,0.5 + math.sign(Direction.Y) * 0.5
    )
    --output a row/column of Tiles/Abstractions for single Vector2 s


    --if both axes have entries, then output a Corner Tile

end]==]


--get Adjacent Nodes on a TileGrid / Abstraction Layer
function TileGrid:GetAdjacents(Node : Node) : (table) -> Adjacent
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

    local SearchAdjacents = EuclideanAdjacents
    --if Layer == 0 then SearchAdjacents = EuclideanAdjacents else SearchAdjacents = EuclideanAdjacents end --Abstractions use manhattan Adjacents (there are no edges between Corners dummy!)

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
                return Vector2.new(AdjacentNode.PrimaryChild.Boundary.X - Front.Boundary.X, AdjacentNode.PrimaryChild.Boundary.Y - Front.Boundary.Y).Magnitude*2
                --return math.abs(NodeChild.Boundary.X - Node.Boundary.X) + math.abs(NodeChild.Boundary.Y - NodeChild.Boundary.Y) --this method assumes that a child will be in the center, fix later
            end
            local Query = self:AStarQuery(Node.PrimaryChild, AdjacentNode.PrimaryChild, HeuristicFn)
            if not Query then continue end
            AdjacentInterpolants = Query.Interpolants
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
    local newTile = {
        TileGrid = self
        ,Layer = 0
        ,Boundary = QuadtreeModule.newPoint(U,V)
        ,Parent = nil
        ,Adjacents = {}
        ,Interpolants = {}
    } :: Tile

    --populate Adjacents for this Tile
    newTile.Adjacents = self:GetAdjacents(newTile)
        --add this Tile to Adjacents
        for _, Adjacent : Adjacent in newTile.Adjacents do
            local newAdjacent = {
                Node = newTile
                ,Interpolants = newTile.Interpolants
            } :: Adjacent

            table.insert(
                Adjacent.Node.Adjacents
                ,newAdjacent
            )
        end
    --

    --add new Tile to TileGrid
    if not self.Tiles[U] then self.Tiles[U] = {} end
    self.Tiles[U][V] = newTile

    --check for mins and max
    self:CornerCheck(U,V)

    return newTile
end

--TileGrid Abstraction creates multiple Layers of less refined TileGrid s that cache navigation data to be read faster
function TileGrid:Abstract(Layer : number?)
    --create multiple Abstractions of the TileGrid based on a parsed size
    --  has support for obtuse sizes
    if not Layer then Layer = 0 end

    local AbstractionLayer : AbstractionLayer = self.AbstractionLayers[Layer+1]

    if not AbstractionLayer then warn("NoAbstractionLayer: ", Layer) return end

    local ChildLayer : AbstractionLayer = self.AbstractionLayers[Layer]

    if not ChildLayer then warn("NoChildLayer: ", Layer) return end
    print("Abstracting Layer: ", Layer, " -> ", Layer+1)

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
    for i = TileGridOriginCornerU + math.sign(Layer)*AbstractionSizeU/2, TileGridLeadingCornerU, AbstractionSizeU do --!!!!!!!!!!!!!!!!!!!!!!! math.sign(Layer)*AbstractionSizeU/2 written in consideration of Abstractions having boundaries, and Tiles not... May be cause for issues later
        for j = TileGridOriginCornerV + math.sign(Layer)*AbstractionSizeV/2, TileGridLeadingCornerV, AbstractionSizeV do      
            local Children = {}
            local newAbstract
            --populate Abstract with Children
            for U = i, i+AbstractionSizeU-ChildSize.X, ChildSize.X do
                for V = j, j+AbstractionSizeV-ChildSize.Y, ChildSize.Y do
                    if not ChildGrid[U] then continue end
                    if not Children[U] then Children[U] = {} end
                    Children[U][V] = ChildGrid[U][V]
                end
            end

            if not Children then warn("NoChildrenNodes") continue end --if the Abstract doesnt have Children, no need for it to exist

            --the actual Abstract Node
            newAbstract = {
                TileGrid = self
                ,Layer = Layer+1
                ,Boundary = QuadtreeModule.BuildBoxFromCorners(i,j,i+AbstractionSizeU,j+AbstractionSizeV) --start Abstract at Origin Corner
                ,Parent = nil
                ,Children = Children
                ,PrimaryChild = nil
                ,Adjacents = {}
                ,Interpolants = {}
            }

            --identify Children's Parent as this Abstraction, and discover a PrimaryChild
            local ChildrenDistanceFilter = PriorityQueueModule.BuildPriorityQueue(
                function(a, b)
                    local A = Vector2.new(newAbstract.Boundary.X - a.Boundary.X, newAbstract.Boundary.Y - a.Boundary.Y).Magnitude
                    local B = Vector2.new(newAbstract.Boundary.X - b.Boundary.X, newAbstract.Boundary.Y - b.Boundary.Y).Magnitude
                    return A - B
                end
            )
            --
            for U = i, i+AbstractionSizeU-ChildSize.X, ChildSize.X do
                if not Children[U] then continue end
                for V = j, j+AbstractionSizeV-ChildSize.Y, ChildSize.Y do
                    if not Children[U][V] then continue end
                    Children[U][V].Parent = newAbstract
                    ChildrenDistanceFilter:Enqueue(Children[U][V])
                end
                newAbstract.PrimaryChild = ChildrenDistanceFilter:Dequeue()
            end

            --populate Abstraction Adjacents
            newAbstract.Adjacents = self:GetAdjacents(newAbstract)
                --add this Tile to Adjacents
                for _, Adjacent : Adjacent in newAbstract.Adjacents do
                    --use pathfinding cost for abstraction interpolants
                    local HeuristicFn = function(Front : Front)
                        return Vector2.new(Adjacent.Node.PrimaryChild.Boundary.X - Front.Boundary.X, Adjacent.Node.PrimaryChild.Boundary.Y - Front.Boundary.Y).Magnitude*2
                        --return math.abs(newAbstract.Boundary.X - NodeChild.Boundary.X) + math.abs(newAbstract.Boundary.Y - NodeChild.Boundary.Y) --this method assumes that a child will be in the center, fix later
                    end
                    local Query = self:AStarQuery(Adjacent.Node.PrimaryChild, newAbstract.PrimaryChild, HeuristicFn)
                    local newAdjacent = {
                        Node = newAbstract
                        ,Interpolants = Query.Interpolants
                    } :: Adjacent

                    table.insert(
                        Adjacent.Node.Adjacents
                        ,newAdjacent
                    )
                end
            --
            --add Abstract to Layer
            if not AbstractionGrid[newAbstract.Boundary.X] then AbstractionGrid[newAbstract.Boundary.X] = {} end
            AbstractionGrid[newAbstract.Boundary.X][newAbstract.Boundary.Y] = newAbstract
        end
    end

    --recursively Abstract until all Abstraction Layers have been parsed
    self:Abstract(Layer+1)
end

function TileGrid:BuildNavGrid(
    Name : string
    ,HeuristicFn : (Front : Front) -> number? --the Heuristic is passed to NavGrid fronts
) : NavGrid
    local newNavGrid = setmetatable({}, NavGrid) :: NavGrid

    newNavGrid.Name = Name
    newNavGrid.TileGrid = self
    newNavGrid.Targets = {}
    newNavGrid.InterpolantMultipliers = {}
    newNavGrid.AbstractionMap = {}

    newNavGrid.HeuristicFn = HeuristicFn or function() return 0 end

    if Name then
        self.NavGrids[Name] = newNavGrid
    end

    return newNavGrid
end

local function Backstep(Front : Front)
    local out
    local PreviousFront = Front.PreviousFront
    if PreviousFront then
        PreviousFront.Force = Vector2.new(
            Front.Boundary.X - PreviousFront.Boundary.X
            ,Front.Boundary.Y - PreviousFront.Boundary.Y
        )

        out = Backstep(PreviousFront)
    else
        out = Front.Force
    end

    return out
end
function TileGrid:AStarQuery(
    Origin : Target | Node
    ,Target : Target | Node
    ,HeuristicFn : (Front : Front) -> number
    ,Abstraction : boolean?
)
    local out = {
        Interpolants = {}
        ,Direction = Vector2.zero
    }
    if not (Origin or Target) then return end
    --build Origin and Target Nodes
    local OriginNode
    if Origin.Position then
        local _Origin = Module.BuildTarget(Vector2.new(
            math.round(Origin.Position.X/self.TileSize.X)*self.TileSize.X
            ,math.round(Origin.Position.Y/self.TileSize.Y)*self.TileSize.Y
        ))
        if not self.Tiles[_Origin.Position.X] then return end
        OriginNode = self.Tiles[_Origin.Position.X][_Origin.Position.Y]
        if not OriginNode then return end
    else 
        OriginNode = Origin
    end
    local TargetNode
    if Target.Position then
        local _Target = Module.BuildTarget(Vector2.new(
            math.round(Target.Position.X/self.TileSize.X)*self.TileSize.X
            ,math.round(Target.Position.Y/self.TileSize.Y)*self.TileSize.Y
        ))
        if not self.Tiles[_Target.Position.X] then return end
        TargetNode = self.Tiles[_Target.Position.X][_Target.Position.Y]
        if not TargetNode then return end
    else
        TargetNode = Target
    end

    if not Abstraction then Abstraction = false end
    if not OriginNode.Layer then warn("No Origin") return end

    --build our first Front
    local newFront = {
        Node = OriginNode
        ,Boundary = OriginNode.Boundary
        ,PreviousFront = nil
        ,Force = Vector2.zero
        ,Target = Target
        ,CumulativeInterpolants = {}
        ,Priorty = 0
    } :: Front
    newFront.Priority = HeuristicFn(newFront)
    local OriginFront = newFront

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
        [newFront.Boundary.X] = {
            [newFront.Boundary.Y] = newFront
        }
    }
    local generationStart = os:clock()
    local generationSteps = 0
    while not Frontier:IsEmpty() do
        generationSteps += 1

        local CurrentFront : Front = Frontier:Dequeue()
        if not CurrentFront then continue end

        local CurrentNode = CurrentFront.Node
        local CurrentBoundary = CurrentFront.Boundary
        local CurrentInterpolants = CurrentFront.CumulativeInterpolants


        --print(Util.MathSummation(CurrentInterpolants), Vector2.new(CurrentBoundary.X, CurrentBoundary.Y))
        if CurrentNode == TargetNode or (Abstraction == true and QuadtreeModule.BoxCheck(CurrentNode.Boundary, TargetNode.Boundary)) then
            out.Interpolants = CurrentInterpolants
            out.Direction = Backstep(CurrentFront) --recursively step back through all previous fronts to determine their forces
            --[==[
            print ("Done!")
            print({
                Direction = out.Direction
                ,Layer = CurrentNode.Layer
                ,Steps = generationSteps
            })
            ]==]
            break
        end

        for _, Adjacent in CurrentNode.Adjacents do
            local AdjacentNode = Adjacent.Node
            if not AdjacentNode then continue end
            local newInterpolants = {}

            --'Step Up' Abstractions when leaving our parent tile
            if Abstraction == true then
                if CurrentNode.Parent and not QuadtreeModule.BoxCheck(CurrentNode.Parent.Boundary, AdjacentNode.Boundary) then
                    AdjacentNode = Adjacent.Node.Parent
                    if not AdjacentNode then continue end
                end
            end

            --apply Costs to each Interpolant on the Front
            for Index, Cost in Adjacent.Interpolants do
                if not CurrentInterpolants[Index] then newInterpolants[Index] = Cost else
                    newInterpolants[Index] = CurrentInterpolants[Index] + Cost end
            end

            if not (
                ClosedNodes[AdjacentNode.Boundary.X] and
                ClosedNodes[AdjacentNode.Boundary.X][AdjacentNode.Boundary.Y]
            ) or (
                ClosedNodes[AdjacentNode.Boundary.X] and
                Util.MathSummation(newInterpolants) < Util.MathSummation(ClosedNodes[AdjacentNode.Boundary.X][AdjacentNode.Boundary.Y].CumulativeInterpolants)
            )
            then
                local newFront = {
                    Node = AdjacentNode
                    ,Boundary = AdjacentNode.Boundary
                    ,PreviousFront = CurrentFront
                    ,Force = Vector2.zero
                    ,Target = Target
                    ,CumulativeInterpolants = newInterpolants
                    ,Priorty = math.huge
                } :: Front

                if not ClosedNodes[AdjacentNode.Boundary.X] then ClosedNodes[AdjacentNode.Boundary.X] = {} end
                ClosedNodes[AdjacentNode.Boundary.X][AdjacentNode.Boundary.Y] = newFront

                newFront.Priority = Util.MathSummation(newInterpolants) + HeuristicFn(newFront)
                Frontier:Enqueue(newFront)
            end
        end
        --task.wait()
    end
    local generationDelta = os:clock() - generationStart
    --print(generationDelta, generationSteps)
    print(1/generationDelta)

    return out
end

--[==[
function TileGrid:UniformCostSearch(
    NavGrid : NavGrid
    ,Targets : (table) -> Target | Node
)
return Promise.new(function(resolve, reject, onCancel)
    --red blob games ucs



end) end

--NavGrid class
function NavGrid:MapAbstractions(
    Origins : (table) -> Target | Node
)
    local out

    local TileGrid = self.TileGrid

    local OriginNodes = {}
    --expand out from zombie positions to determine an abstraction map
    for _, Origin : Target in Origins do        
        if Origin.Position then
            local _Origin = Module.BuildTarget(Vector2.new(
                math.round(Origin.Position.X/TileGrid.TileSize.X)*TileGrid.TileSize.X
                ,math.round(Origin.Position.Y/TileGrid.TileSize.Y)*TileGrid.TileSize.Y
            ))
            if not TileGrid.Tiles[_Origin.Position.X] then continue end
            table.insert(OriginNodes, TileGrid.Tiles[_Origin.Position.X][_Origin.Position.Y])
            if not OriginNodes then continue end
        elseif Origin.Boundary then
            table.insert(OriginNodes, Origin)
        end
    end

    if not OriginNodes then return end

    local Frontier = PriorityQueueModule.BuildPriorityQueue(
        function(a, b)
            return a.Priority -
            b.Priority
        end
    )
    local newAbstractionMap = {}

    for _, Node : Node in OriginNodes do
        local newFront = {
            Node = Node
            ,Boundary = Node.Boundary
            ,PreviousFront = nil
            ,Force = Vector2.zero
            ,Target = nil
            ,CumulativeInterpolants = nil
            ,Priorty = 0
        } :: Front
        Frontier:Enqueue(newFront)

        if not newAbstractionMap[Node.Boundary.X] then newAbstractionMap[Node.Boundary.X] = {} end
        newAbstractionMap[Node.Boundary.X][Node.Boundary.Y] = 0 
    end
    local generationStart = os:clock()
    local generationSteps = 0
    while not Frontier:IsEmpty() do
        generationSteps += 1

        local CurrentFront : Front = Frontier:Dequeue()
        print(CurrentFront)
        if not CurrentFront then break end

        local CurrentNode = CurrentFront.Node
        local CurrentParent = CurrentNode.Parent

        --assign a layer to all children within the same abstraction
        for i, _ in CurrentParent.Children do
            for j, _ in CurrentParent.Children[i] do
                local Child = CurrentParent.Children[i][j]
                --print(Child)
                if not Child then continue end
                if not newAbstractionMap[Child.Boundary.X] then newAbstractionMap[Child.Boundary.X] = {} end
                if newAbstractionMap[Child.Boundary.X][Child.Boundary.Y] then continue end
                newAbstractionMap[Child.Boundary.X][Child.Boundary.Y] = CurrentFront.Priority
            end
        end
        print(CurrentParent.Children)

        --query nodes adjacent to the parent abstraction
    end

    out = newAbstractionMap
    return out
end

function NavGrid:KernalConvolute() : Vector2 | Vector3

end
]==]



Module.BuildTileGrid = function(Name : string, TileSize : Vector2?) : TileGrid
    local newTileGrid = setmetatable({}, TileGrid) :: TileGrid

    newTileGrid.Tiles = {} --contains Tiles (duh)
    newTileGrid.TileCount = 0
    newTileGrid.TileSize = TileSize or Vector2.new(1,1)
    newTileGrid.AbstractionLayers = {
        [0] = {
            AbstractionGrid = newTileGrid.Tiles
            ,AbstractionSize = newTileGrid.TileSize
        } :: AbstractionLayer
    }
    newTileGrid.OriginCorner = Vector2.new(10000,10000) --Origin Corner is the minimum Corner, automatically assigned at Tile creation
    newTileGrid.LeadingCorner = Vector2.new(-10000,-10000) --Leading Corner is the maximum Corner, automatically assigned at Tile creation
    newTileGrid.NavGrids = {}

    if Name then
        AllTileGrids[Name] = newTileGrid
    end

    return newTileGrid
end
Module.GetTileGrid = function(Name : string) : TileGrid
    return AllTileGrids[Name]
end

Module.BuildTarget = function(Position : Vector3 | Vector2, Velocity : Vector3 | Vector2?) : Target
    --check if Position is a Vector3

    local Vector3Type = typeof(Vector3.new())
    if Position then 
        if typeof(Position) == Vector3Type then
            Position = Vector2.new(Position.X or 0, Position.Z or Position.Y or 0)
        else
            Position = Vector2.new(Position.X or 0, Position.Y or 0)
        end
    end
    if Velocity then 
        if typeof(Velocity) == Vector3Type then
            Velocity = Vector2.new(Velocity.X or 0, Velocity.Z or Velocity.Y or 0)
        else
            Velocity = Vector2.new(Velocity.X or 0, Velocity.Y or 0)
        end
    end

    return {
        Position = Position
        ,Velocity = Velocity
        ,Time = tick()
    } :: Target
end

return Module