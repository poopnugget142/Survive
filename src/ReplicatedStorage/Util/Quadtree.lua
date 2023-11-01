local Quadtree = {}
Quadtree.__index = Quadtree

local Module = {}
local AllQuadTrees = {}

export type Box = {
    X : number, -- X and y define a center point, not a corner point
    Y : number,
    w : number, -- the width and height are half dimensions constrained to the center point
    h : number,
    Data : table
}
export type Circle = {
    X : number,
    Y : number,
    r : number,
    Data : table
}
export type Point = {
    X : number,
    Y : number,
    Data : table
}

function Quadtree:Insert(Point : Point | Circle)
    if not Module.BoxCheck(self.Box, Point) then return end -- if the point is outside the quadtree, ignore

    if (#self.Points < self.Capacity and #self.Children == 0) then --if there is enough space in the quadtree, accept the point and leave
        table.insert(self.Points, Point)
        --print("Insert Quad")
        return true

    else --otherwise, we subdivide and test for children
        if (#self.Children == 0) then self:Subdivide() end
        --add a point to whichever child will accept it
        for _, Child in self.Children do
            if Child:Insert(Point) then 
                --print ("Insert Subdivide")
                return true 
            end
        end
    end

    -- if we cannot add a point for whatever reason, return failure
    return false
end

function Quadtree:Subdivide()
    local Box : Box = self.Box
    --print ("Subdivide")

    self.Children = {}
    table.insert(self.Children, Module.newQuadtree(Box.X - Box.w/2, Box.Y + Box.h/2, Box.w/2, Box.h/2))
    table.insert(self.Children, Module.newQuadtree(Box.X + Box.w/2, Box.Y + Box.h/2, Box.w/2, Box.h/2))
    table.insert(self.Children, Module.newQuadtree(Box.X - Box.w/2, Box.Y - Box.h/2, Box.w/2, Box.h/2))
    table.insert(self.Children, Module.newQuadtree(Box.X + Box.w/2, Box.Y - Box.h/2, Box.w/2, Box.h/2))

    for _, Child in self.Children do
        Child.Capacity = self.Capacity * 2
    end
    for _, Point in self.Points do --transcribe points on this quad tree to child quadtrees
        for _, Child in self.Children do
            if Child:Insert(Point) then break end
        end
    end
    self.Points = {}
end

function Quadtree:QueryRange(range : Box | Circle)
    local out = {}

    --abort if not within range
    if not Module.BoxCheck(self.Box, range) then return out end
    
    --check and add points to output
    for _, Point in self.Points do
        if (range.r and Module.CircleCheck(range, Point)) or --if we are a circle and pass a circle check
        ((not range.r) and Module.BoxCheck(range,Point)) --if we are not a circle and pass a box check
        then table.insert(out, Point) end
    end

    --if there are no child quadtrees, terminate
    if (#self.Children == 0) then return out end

    --otherwise recursively fetch children points
    for _, Child in self.Children do
        local ChildPoints = Child:QueryRange(range)
        for _, Point in ChildPoints do
            table.insert(out, Point)
        end
    end

    --nothing else for us to do, return
    return out
end

Module.BuildBox = function(X,Y,w,h)
    --print(X, y, w, h)
    return {
        X = X
        ;Y = Y
        ;w = w
        ;h = h
        ;Data = {}
    } :: Box
end
Module.BuildCircle = function(X,Y,r)
    return {
        X = X
        ;Y = Y
        ;r = r
        ;Data = {}
    } :: Circle
end
Module.newPoint = function(X,Y)
    return {
        X = X
        ;Y = Y
        ;Data = {}
    } :: Point
end

Module.BoxCheck = function(Box : Box, Other : Box | Circle | Point)
    return not (
        Box.X - Box.w >= Other.X + (Other.w or Other.r or 0) or
        Box.X + Box.w < Other.X - (Other.w or Other.r or 0) or
        Box.Y - Box.h >= Other.Y + (Other.h or Other.r or 0) or
        Box.Y + Box.h < Other.Y - (Other.h or Other.r or 0)
    )
end
Module.CircleCheck = function(Circle : Circle, Other : Circle | Point)
    return (
        (
            (Other.X-(Circle.X or 0))^2 + 
            (Other.Y-(Circle.Y or 0))^2
        ) <= 
        ((Circle.r or 0)^2 + (Other.r or 0)^2)
    )
end

Module.newQuadtree = function(X,Y,w,h, QuadName : string?)
    local NewQuadtree = setmetatable({}, Quadtree)
    NewQuadtree.Capacity = 4
    NewQuadtree.Box = Module.BuildBox(X,Y,w,h)

    NewQuadtree.Points = {} --contains points, will be nil'd when subdivided
    NewQuadtree.Children = {} --leave blank for leaf nodes

    if (QuadName) then
        AllQuadTrees[QuadName] = NewQuadtree
    end
    
    return NewQuadtree
end
Module.GetQuadtree = function(QuadName : string)
    return AllQuadTrees[QuadName]
end

return Module