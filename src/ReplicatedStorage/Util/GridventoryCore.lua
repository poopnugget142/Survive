local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Quadtree = require(ReplicatedStorage.Scripts.Util.Quadtree)

local module = {}

type Gridventory = {
    Boundary : Box --The space that items can be stored in; Larger boundary means larger inventory
    ;Items : Item | table
}

type Item = {
    Boundaries : Box | table --The space that an item takes up in an inventory; Table for complex shapes

}

local Gridventory = {}
    Gridventory.__index = Gridventory


function Gridventory:Check()
    --check all items in the Gridventory to see if it intersects with another
end

module.BuildGridventory = function(Boundary : Box)
    return {
        Id = -1
        ,Boundary = Boundary
        ,Items = {}
    } :: Gridventory
end
module.BuildItem = function(Position : Point, Boundaries : Box | Table)
    return {
        Id = -1
        ,Position = Position
        ,Boundaries = Boundaries


        ,Functions = {}
    }
end


return module