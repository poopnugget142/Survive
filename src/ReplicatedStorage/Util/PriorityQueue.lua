local Queue = {}

function Queue:Comparator(a, b)
    local _a = self.ComparatorGetFunction(a)
    local _b = self.ComparatorGetFunction(b)
    if (_a == nil or _b == nil) then
        return 0
    end

    return(_a - _b)
end

function Queue:HeapSort()
    local out = {}
    for e = 1, self.Length do
        table.insert(out, self:Dequeue())
    end

    return out
end

function Queue:Parent(NodeIndex : number) --called for a child to get the node in the tree level above it
    if (NodeIndex == 1) then return nil end
    return math.floor(NodeIndex/2)
end

function Queue:LeftChild(NodeIndex : number) --called for a parent to get the left childs
    local child = (NodeIndex*2)
    if (child >= self.Length) then return nil end
    return child
end

function Queue:RightChild(NodeIndex : number) --called for a parent to get the right child
    local child = (NodeIndex*2)+1
    if (child >= self.Length) then return nil end
    return child
end

function Queue:ShiftUp() --move smaller frontier up the binary tree
    local index = self.Length

    while (true) do
        local parentIndex = self:Parent(index)

        if (parentIndex ~= nil and (self:Comparator( index, parentIndex ) < 0) ) then
            local temp = self.Values[index]
            self.Values[index] = self.Values[parentIndex]
            self.Values[parentIndex] = temp
            continue
        end

        return
    end
end

function Queue:ShiftDown() --move bigger frontier down the binary tree
    local index = 1

    while true do
        local left = self:LeftChild(index)
        local right = self:RightChild(index)
        
        local swapCandidiate = index
        if (left ~= nil and (self:Comparator( swapCandidiate, left ) > 0) ) then
            swapCandidiate = left
        end
        if (right ~= nil and (self:Comparator( swapCandidiate, right ) > 0) ) then
            swapCandidiate = right
        end
        if (swapCandidiate ~= index) then --check to see if swap candidate was altered by the two previous ifs
            local temp = self.Values[index]
            self.Values[index] = self.Values[swapCandidiate]
            self.Values[swapCandidiate] = temp
            index = swapCandidiate
            continue
        end

        return --otherwise break the operation
    end
end

function Queue:Enqueue(Value)
    if (self.Length2 ~= nil) then
        if (self.Length2 <= self.Length) then --increase array length exponentially depending on value count
            self.Length2 = math.max(1, self.Length2 * 2)
        end
    else
        self.Length2 = 1
    end
    self.Values[self.Length+1] = Value --add
    self.Length+=1 --add
    self:ShiftUp()

    print(self.Values)

    return true
end

function Queue:Dequeue()
    if (self.Length == 0) then return nil end --skip if theres nothing to remove

    local node = self.Values[1] --look at our first value

    if (self.Length == 1) then --if theres only one value, we require no further computations
        self.Length = 0 
        self.Values[1] = nil
        return node
    end

    self.Values[1] = self.Values[self.Length] --move the topmost value to the bottom of the binary tree, to do some swapping
    self.Values[self.Length] = nil
    self.Length-=1
    self:ShiftDown() --swapping function
    
    return node
end

local Module = {}

Module.Create = function(ComparatorGetFunction : any)
    local NewQueue = setmetatable(Queue, {})
    NewQueue.Length = 0
    NewQueue.Length2 = 0
    NewQueue.ComparatorGetFunction = ComparatorGetFunction or function (Value) return Value
    end
    NewQueue.Values = {}

    return NewQueue
end

return Module