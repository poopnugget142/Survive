export type ComparatorFn<T> = (a : T, b : T) -> number

export type Null = any
export type PriorityQueue = {
    ComparatorFn : ComparatorFn<T>
    ,IsEmpty : (nil) -> boolean
    ,Enqueue : (Value : any) -> Null
    ,Dequeue : (nil) -> any
    ,HeapSort : (nil) -> table
}

local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

function PriorityQueue:IsEmpty()
    if PriorityQueue.RealLength == 0 then return true end
    return
end

local function Parent(NodeIndex : number) --called for a child to get the node in the tree level above it
    if (NodeIndex == 1) then return end
    return math.floor(NodeIndex/2)
end

local function LeftChild(Queue : PriorityQueue, NodeIndex : number) --called for a parent to get the left child
    local Child = NodeIndex*2
    if Child >= Queue.RealLength then return end
    return Child
end

local function RightChild(Queue : PriorityQueue, NodeIndex : number) --called for a parent to get the right child
    local Child = NodeIndex*2 +1
    if Child >= Queue.RealLength then return end
    return Child
end

local function ShiftUp(Queue: PriorityQueue)
    local Index = Queue.RealLength

    while true do
        local Parent = Parent(Index)

        if (Parent ~= nil and Queue.ComparatorFn(Queue.Values[Index], Queue.Values[Parent]) < 0) then
            local Temp = Queue.Values[Index]
            Queue.Values[Index] = Queue.Values[Parent]
            Queue.Values[Parent] = Temp
            Index = Parent
            continue
        end

        return
    end
end

local function ShiftDown(Queue: PriorityQueue)
    local Index = 1

    while true do
        local Left = LeftChild(Queue, Index)
        local Right = RightChild(Queue, Index)

        local SwapCandidate = Index
        if Left ~= nil and Queue.ComparatorFn(Queue.Values[SwapCandidate], Queue.Values[Left]) > 0 then
            SwapCandidate = Left
        end
        if Right ~= nil and Queue.ComparatorFn(Queue.Values[SwapCandidate], Queue.Values[Right]) > 0 then
            SwapCandidate = Right
        end

        if SwapCandidate ~= Index then
            local Temp = Queue.Values[Index]
            Queue.Values[Index] = Queue.Values[SwapCandidate]
            Queue.Values[SwapCandidate] = Temp
            Index = SwapCandidate
            continue
        end

        return
    end
end

function PriorityQueue:Enqueue(Value : any)
    if (self.VirtualLength <= self.RealLength) then
        self.VirtualLength = math.max(1, self.RealLength * 2)
    end
    self.Values[self.RealLength+1] = Value
    self.RealLength+=1
    ShiftUp(self)
end

function PriorityQueue:Dequeue()
    if self:IsEmpty() then return end

    local Node = self.Values[1]

    if self.RealLength == 1 then
        self.RealLength = 0
        self.Values = {}
        return Node
    end

    self.Values[1] = self.Values[self.RealLength]
    self.Values[self.RealLength] = nil
    self.RealLength -= 1

    ShiftDown(self)

    return Node
end

function PriorityQueue:HeapSort()
    local out
    while not PriorityQueue:IsEmpty() do
        self:Dequeue()
    end
end

local Module = {}
Module.BuildPriorityQueue = function(ComparatorFn : ComparatorFn<T>) : PriorityQueue
    local NewPriorityQueue = setmetatable({}, PriorityQueue)
    NewPriorityQueue.Values = {}
    NewPriorityQueue.ComparatorFn = ComparatorFn or function(a, b) return a - b end
    NewPriorityQueue.VirtualLength = 0
    NewPriorityQueue.RealLength = 0

    return NewPriorityQueue :: PriorityQueue
end
return Module
