local MathSmall = 10^-7






local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuadtreeModule = require(ReplicatedStorage.Scripts.Util.Quadtree)

local module = {}

type Gridventory = {
    Id : number
    ;Boundary : Box --The space that items can be stored in; Larger boundary means larger inventory
    ;Items : table | Item
}

type Item = {
    Id : number
    ;Position : Point
    ;Rotation : number
    ;Boundaries : table | Box --The space that an item takes up in an inventory; Table for complex shapes
}

--hey, i learned something from you poopnugget!
local Id = 0
local function NextId()
    Id += 1
    return Id
end
local GridventoryList = {}
local ItemList = {}


module.GetGridventoryFromId = function(Id : number)
    return GridventoryList[Id]
end
module.GetItemFromId = function(Id : number)
    return ItemList[Id]
end




module.Gridventory_CheckBox = function(Gridventory : Gridventory, Box : Box)
    --check if box is within gridventory boundary
    --make a new box to account for excessively large items
    local BoundaryCheck = QuadtreeModule.BoxCheck(
        QuadtreeModule.BuildBox(
            Gridventory.Boundary.X
            ,Gridventory.Boundary.Y
            ,Gridventory.Boundary.w + MathSmall - Box.w --quadtree fails on == cases, add a very small number to boundary check size
            ,Gridventory.Boundary.h + MathSmall - Box.h
        )
        ,QuadtreeModule.newPoint(Box.X,Box.Y)
    )

    if not BoundaryCheck then return false end

    --check if box collides with any other items
    local GridventoryQuad = QuadtreeModule.newQuadtree(
        Gridventory.Boundary.X
        ,Gridventory.Boundary.Y
        ,Gridventory.Boundary.w
        ,Gridventory.Boundary.h
    )
    for _, Item : Item in Gridventory.Items do
        --items can have multiple boundaries, another for loop here
        for _, Boundary : Box in Item.Boundaries do
            GridventoryQuad:Insert(QuadtreeModule.BuildBox(
                Item.Position.X + Boundary.X
                ,Item.Position.Y + Boundary.Y
                ,Boundary.w - MathSmall
                ,Boundary.h - MathSmall
            ))
        end
    end

    local QueryRange = GridventoryQuad:QueryRange(Box)
    print(QueryRange)
    if #QueryRange > 0 then return false end --if the box collides with any items, return false

    --return true if valid
    return true
end

module.Item_PlaceInGridventory = function(Item : Item, Gridventory : Gridventory, Position : Point)
    --check target item position
    for _, Boundary in Item.Boundaries do
        local BoundaryCheck = QuadtreeModule.BuildBox(
            Position.X + Boundary.X --account for individual boundary offsets
            ,Position.Y + Boundary.Y
            ,Boundary.w - MathSmall
            ,Boundary.h - MathSmall
        )
        if not module.Gridventory_CheckBox(Gridventory, BoundaryCheck) then return false end
    end

    --set the position of an item to an XY
    Item.Parent = Gridventory
    Item.Position = Position

    return true
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
        ,Parent = nil
        ,Position = Position
        ,Rotation = 0 --value from 0 -> 3 (pi/2)
        ,Boundaries = Boundaries


        ,Functions = {}
    } :: Item
end


return module