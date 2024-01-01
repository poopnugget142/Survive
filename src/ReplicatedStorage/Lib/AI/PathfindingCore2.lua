--[[
    NOTETAKING

    store way more data, make the system more robust
        dont use step up/down logic, index every position with a tile for abstraction

    
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
local AllNavGrids = {}

local Module = {}

export type Point = QuadtreeModule.Point
export type Box = QuadtreeModule.Box

export type Node = {
    TileGrid : TileGrid
    ,Layer : number
    ,Boundary : Box
    ,Parent : Abstraction --abstraction layers, helpful for 'stepping up' layers
    ,Children : table | Node --used exclusively by abstraction layers
    ,Adjacents : table | Node
    ,Interpolants : table | number
}

export type Tile = Node --tiles are primary containers for navigation information
export type Adjacent = {
    Node : Tile | Abstraction
    ,Interpolants : table | number
}

export type Abstraction = Node --abstractions are similar to tiles, but contain aggregated data instead
export type AbstractionLayer = {
    Abstractions : Abstraction
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
    ,CurrentBoundary : Box
    ,PreviousFront : Front
    ,ClosedTiles : table | Tile
    ,CumulativeCost : number
    ,Target : Target
}
export type NavGrid = {
    --stuff
}

export type Target = {
    Position : Vector2 
    ,Velocity : Vector2
    ,Time : number --position + velocity
}


local StandardAdjacents : table | Vector2 = {
    Vector2.new(0,1),   -- 12 o'clock
    Vector2.new(1,1),   --
    Vector2.new(1,0),   -- 3  o'clock
    Vector2.new(1,-1),  --
    Vector2.new(0,-1),  -- 6  o'clock
    Vector2.new(-1,-1), --
    Vector2.new(-1,0),  -- 9  o'clock
    Vector2.new(-1,1)   --
}

local GetEdgeChildrenInDirection = function(Tile : Tile, Direction : Vector2) --first, get adjacent abstraction in a direction, then get children tiles in opposite direction to step down
    local Side = Vector2.new(
        0.5 + math.sign(Direction.X) * 0.5
        ,0.5 + math.sign(Direction.Y) * 0.5
    )
    --output a row/column of tiles/abstractions for single vectors


    --if both axes have entries, then output a corner tile

end

function TileGrid:GetAdjacents(Node : Tile | Abstraction | Node)
    local out = {}
    local U = Node.Boundary.X
    local V = Node.Boundary.Y
    local Layer = Node.Layer

    local AbstractionLayer : AbstractionLayer = self.AbstractionLayers[Layer]
    local TileGrid = AbstractionLayer.Abstractions
    local TileSize = AbstractionLayer.AbstractionSize

    --cycle through table of standard adjacents and store adjacent tiles in each tile
    for _, Adjacent : Vector2 in StandardAdjacents do
        local AdjacentNode : Node
        
        if TileGrid[U+Adjacent.X*TileSize.X] then --check to see if X exists to avoid error
            AdjacentNode = TileGrid[U+Adjacent.X*TileSize.X][V+Adjacent.Y*TileSize.Y]
            if not AdjacentNode then continue end
            local AdjacentInterpolants
            --query the cost of the node
            if AdjacentNode.Layer == 0 then
                AdjacentInterpolants = AdjacentNode.Interpolants
            else
                --A* pathfind through an abstraction to return an approximate cost
            end

            --add adjacent to list of adjacents
            table.insert(
                out
                ,{
                    Node = AdjacentNode
                    ,Interpolants = AdjacentInterpolants
                } :: Adjacent
            )
            
        end
    end

    return out
end

function TileGrid:CornerCheck(U,V)
    if U < self.OriginCorner.X then self.OriginCorner = Vector2.new(U,self.OriginCorner.Y) 
        elseif U > self.LeadingCorner.X then self.LeadingCorner = Vector2.new(U,self.LeadingCorner.Y) end
    if V < self.OriginCorner.Y then self.OriginCorner = Vector2.new(self.OriginCorner.X, V) 
        elseif V > self.LeadingCorner.Y then self.LeadingCorner = Vector2.new(self.LeadingCorner.X, V) end
end

function TileGrid:BuildTile(U,V)
    -- define a tile at a position
    local NewTile = {
        TileGrid = self
        ,Layer = 0
        ,Boundary = QuadtreeModule.newPoint(U,V)
        ,Parent = nil
        ,Adjacents = {}
        ,Interpolants = {}
    } :: Tile

    --populate adjacents for this tile
    NewTile.Adjacents = self:GetAdjacents(NewTile)
        --add this tile to adjacents
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

    --add new Tile to TileGrid
    if not self.Tiles[U] then self.Tiles[U] = {} end
    self.Tiles[U][V] = NewTile

    --check for mins and max
    self:CornerCheck(U,V)

    return NewTile
end

function TileGrid:Abstract(Layer : number?)
    --create multiple abstractions of the tilegrid based on a parsed size
    --  has support for obtuse sizes
    if not Layer then Layer = 0 end

    local AbstractionLayer : AbstractionLayer = self.AbstractionLayers[Layer+1]
    
    if not AbstractionLayer then return end

    local ChildLayer : AbstractionLayer = self.AbstractionLayers[Layer]

    --remove generic variables later?
    local AbstractionGrid = AbstractionLayer.Abstractions
    local AbstractionSizeU = AbstractionLayer.AbstractionSize.X
    local AbstractionSizeV = AbstractionLayer.AbstractionSize.Y

    local ChildGrid = ChildLayer.Abstractions
    local ChildSizeU = ChildLayer.AbstractionSize.X
    local ChildSizeV = ChildLayer.AbstractionSize.Y

    local TileSizeU = self.TileSize.X
    local TileSizeV = self.TileSize.Y
    local TileGridOriginCornerU = self.OriginCorner.X
    local TileGridOriginCornerV = self.OriginCorner.Y
    local TileGridLeadingCornerU = self.LeadingCorner.X
    local TileGridLeadingCornerV = self.LeadingCorner.Y
    --

    --iterate through the child grid based on a given size for our abstractions
    for i = TileGridOriginCornerU, TileGridLeadingCornerU, AbstractionSizeU do
        for j = TileGridOriginCornerV, TileGridLeadingCornerV, AbstractionSizeV do      
            local Children = {}
            local NewAbstract
            --populate abstract with children
            for U = i, i+AbstractionSizeU-ChildSizeU, ChildSizeU do
                for V = j, j+AbstractionSizeV-ChildSizeV, ChildSizeV do
                    if not ChildGrid[U] then continue end
                    if not Children[U] then Children[U] = {} end
                    Children[U][V] = ChildGrid[U][V]
                end
            end

            if not Children then continue end --if the abstract doesnt have children, no need for it to exist

            --the actual abstract node
            NewAbstract = {
                TileGrid = self
                ,Layer = Layer+1
                ,Boundary = QuadtreeModule.BuildBoxFromCorners(i,j,i+ChildSizeU,i+ChildSizeV) --start abstract at origin corner
                ,Parent = nil
                ,Children = Children
                ,Adjacents = {}
                ,Interpolants = {}
            }

            --identify children's parent as this abstraction
            for U = i, i+AbstractionSizeU-ChildSizeU, ChildSizeU do
                for V = j, j+AbstractionSizeV-ChildSizeV, ChildSizeV do
                    Children[U][V].Parent = NewAbstract
                end
            end

            --populate abstraction adjacents
            self:GetAdjacents(NewAbstract)

            --add abstract to layer
            if not AbstractionGrid[i] then AbstractionGrid[i] = {} end
            AbstractionGrid[i][j] = NewAbstract
            --print(NewAbstract)
        end
    end

    --recursively abstract until all abstraction layers have been parsed
    self:Abstract(Layer+1)
end

function TileGrid:UniformCostSearch(
    NavGrid : NavGrid 
    ,Targets : table
    ,HeuristicFunction : Function
)
return Promise.new(function(resolve, reject, onCancel)
    --red blob games ucs



end) end


Module.BuildTileGrid = function(Name : string, TileSize : Vector2?)
    local NewTileGrid = setmetatable({}, TileGrid) :: TileGrid

    NewTileGrid.Tiles = {} --contains tiles (duh)
    NewTileGrid.TileCount = 0
    NewTileGrid.TileSize = TileSize or Vector2.new(1,1)
    NewTileGrid.AbstractionLayers = {
        [0] = {
            Abstractions = NewTileGrid.Tiles
            ,AbstractionSize = NewTileGrid.TileSize
        } :: AbstractionLayer
    }
    NewTileGrid.OriginCorner = Vector2.new(10000,10000) --origin corner is the minimum corner, automatically assigned at tile creation
    NewTileGrid.LeadingCorner = Vector2.new(-10000,-10000) --leading corner is the maximum corner, automatically assigned at tile creation
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