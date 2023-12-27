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

local Tilegrid = {}
Tilegrid.__index = Tilegrid
local AllTilegrids = {}

local Navgrid = {}
Navgrid.__index = Navgrid
local AllNavgrids = {}

local Module = {}

export type Point = QuadtreeModule.Point

export type Tile = {
    Parent : Tile
    ,Children : Tile
    ,Point : Point
    ,Adjacents : table | Tile
    ,Interpolants : table | number
}
export type TileGrid = {
    --stuff
}

export type Front = {
    CurrentTile : Tile
    ,CurrentPosition : Point
    ,PreviousTile : Tile
    ,PreviousPosition : Point
    ,CumulativeCost : number
    ,Target : Target
}


export type Target = {
    Position : Vector2 
    ,Velocity : Vector2
    ,Tile : Tile
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


local TileGrid = {}
TileGrid.__index = TileGrid
local AllTileGrids = {}

function TileGrid:GetTileAdjacents(U,V)
    local out = {}
    local TileGrid = self.Tiles
    local TileSize = self.TileSize

    --cycle through table of standard adjacents and store adjacent tiles in each tile
    for _, Adjacent : Vector2 in StandardAdjacents do
        local AdjacentTile
        if TileGrid[U+Adjacent.X*TileSize.X] then --check to see if X exists to avoid error
            AdjacentTile = TileGrid[U+Adjacent.X*TileSize.X][V+Adjacent.Y*TileSize.Y]
            if AdjacentTile then
                table.insert(
                    out
                    ,AdjacentTile
                )
            end
        end
    end

    return out
end

function TileGrid:BuildTile(U,V)
    -- define a tile at a position
    local NewTile = {
        TileGrid = self
        ,Parent = nil
        ,Children = {}
        ,Point = QuadtreeModule.newPoint(U,V)
        ,Adjacents = {}
        ,Interpolants = {}
    } :: Tile

    --populate adjacents
    NewTile.Adjacents = self:GetTileAdjacents(U,V)
    for _, Adjacent : Tile in NewTile.Adjacents do
        table.insert(Adjacent.Adjacents, NewTile)
    end

    --add new Tile to TileGrid
    if not self.Tiles[U] then self.Tiles[U] = {} end
    self.Tiles[U][V] = NewTile

    return NewTile
end



Module.BuildTileGrid = function(Name : string, TileSize : Vector2?)
    local NewTilegrid = setmetatable({}, TileGrid)

    NewTilegrid.Tiles = {} --contains tiles (duh)
    NewTilegrid.TileCount = 0
    NewTilegrid.TileSize = TileSize or Vector2.new(1,1)

    if Name then
        AllTilegrids[Name] = NewTilegrid
    end

    return NewTilegrid
end

Module.GetTileGrid = function(Name : string)
    return AllTilegrids[Name]
end

Module.BuildTargetFromVector3 = function()
    
end

return Module