local MathSmall = 10^-5






local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuadtreeModule = require(ReplicatedStorage.Scripts.Util.Quadtree)

local module = {}

type Treeventory = {
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
local TreeventoryList = {}
local ItemList = {}


module.GetTreeventoryFromId = function(Id : number)
    return TreeventoryList[Id]
end
module.GetItemFromId = function(Id : number)
    return ItemList[Id]
end


--recurring format for adding a position and a boundary
module.PositionPlusBoundary = function(Position : Point, Boundary : Box, Rotation : number?)
    local Theta = math.round(Rotation or 0) * math.pi * 0.5
    --print(Theta)

    return QuadtreeModule.BuildBox(
        Position.X + (Boundary.X * math.cos(Theta) - Boundary.Y * math.sin(Theta)) --boundary offset
        ,Position.Y + (Boundary.X * math.sin(Theta) + Boundary.Y * math.cos(Theta))
        ,math.abs(Boundary.w * math.cos(Theta) - Boundary.h * math.sin(Theta)) - MathSmall --boundary box
        ,math.abs(Boundary.w * math.sin(Theta) + Boundary.h * math.cos(Theta)) - MathSmall
    )
end


module.Treeventory_CheckBox = function(Treeventory : Treeventory, Box : Box | Point)
    --check if box is within Treeventory boundary
    --make a new box to account for excessively large items
    local BoundaryCheck = QuadtreeModule.BoxCheck(
        QuadtreeModule.BuildBox(
            Treeventory.Boundary.X + 1/2 --spaghetti math, further investigation encouraged
            ,Treeventory.Boundary.Y + 1/2
            ,(Treeventory.Boundary.w/2 - ((Box.w) or 0)) + MathSmall  --quadtree fails on == cases, add a very small number to boundary check size
            ,(Treeventory.Boundary.h/2 - ((Box.h) or 0)) + MathSmall 
        )
        ,QuadtreeModule.newPoint(Box.X,Box.Y)
    )

    if not BoundaryCheck then return {Value = false, Error = false} end

    --check if box collides with any other items
    local TreeventoryQuad = QuadtreeModule.newQuadtree(
        Treeventory.Boundary.X
        ,Treeventory.Boundary.Y
        ,Treeventory.Boundary.w
        ,Treeventory.Boundary.h
    )
    for _, Item : Item in Treeventory.Items do
        --items can have multiple boundaries, another for loop here
        for _, Boundary : Box in Item.Boundaries do
            local NewBoundary = module.PositionPlusBoundary(Item.Position, Boundary, Item.Rotation)
            NewBoundary.Data.Item = Item
            TreeventoryQuad:Insert(NewBoundary)
        end
    end

    local QueryRange = TreeventoryQuad:QueryRange(Box)
    --print(QueryRange)
    if #QueryRange > 0 then return {Value = false, Error = QueryRange} end --if the box collides with any items, return false

    --return true if valid
    return {Value = true}
end

module.Item_PlaceInTreeventory = function(Item : Item, Treeventory : Treeventory, Position : Point)
    if Item.Parent and Item.Parent.Items then Item.Parent.Items[Item.Id] = nil end
    --check target item position
    --if Item.Boundaries then
        for _, Boundary in Item.Boundaries do
            local CollisionCheck = module.Treeventory_CheckBox(Treeventory, module.PositionPlusBoundary(Position, Boundary, Item.Rotation))
            --print(CollisionCheck)
            if CollisionCheck.Value == false then --return if we touch something
                if Item.Parent and Item.Parent.Items then Item.Parent.Items[Item.Id] = Item end
                return CollisionCheck 
            end
        end
    --end

    --set the position of an item to an XY
    
    Item.Parent = Treeventory
    Item.Position = Position
    Treeventory.Items[Item.Id] = Item

    return {Value = true}
end
















module.BuildTreeventory = function(Boundary : Box)
    return {
        Id = -1
        ,Boundary = Boundary
        ,Items = {}
    } :: Treeventory
end
module.BuildItem = function(Boundaries : Box | Table)
    return {
        Id = NextId()
        ,Parent = nil
        ,Position = QuadtreeModule.newPoint(-1,-1)
        ,Rotation = 0 --value from 0 -> 3 (pi/2)
        ,Boundaries = Boundaries
        ,Dummy = nil


        ,Functions = {}
    } :: Item
end


return module