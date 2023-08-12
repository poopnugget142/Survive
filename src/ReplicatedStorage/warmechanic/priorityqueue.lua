--special thanks https://youtu.be/M6OW0KNkhhs

local module = {}

local values = {}
local length : number = 0

comparator = function(a, b)
    return(a - b)
end

module.enqueue = function(value)
    if (values.length ~= nil) then
        if (values.length <= length) then --increase array length exponentially depending on value count
            values.length = math.max(1, values.length * 2)
        end
    else
        values.length = 1
    end
    values[length+1] = value --add
    length+=1 --add
end

module.dequeue = function()
    if (length == 0) then return nil end --skip if theres nothing to remove

    local node = values[1] --look at our first value

    if (length == 1) then --if theres only one value, we require no further computations
        length = 0 
        values[1] = nil
        return node
    end

    values[1] = values[length] --move the topmost value to the bottom of the binary tree, to do some swapping
    values[length] = nil
    length-=1

    shiftDown() --swapping function

    return node
end

module.heapSort = function()
    local out = {}
    for e = 1, length do
        table.insert(out, module.dequeue())
    end

    return out
end


parent = function(nodeIndex : number) --called for a child to get the node in the tree level above it
    if (nodeIndex == 1) then return nil end
    return math.floor(nodeIndex/2)
end
leftChild = function(nodeIndex : number) --called for a parent to get the left child
    local child = (nodeIndex*2)
    if (child >= length) then return nil end
    return child
end
rightChild = function(nodeIndex : number) --called for a parent to get the right child
    local child = (nodeIndex*2)+1
    if (child >= length) then return nil end
    return child
end

shiftUp = function() --move smaller values up the binary tree
    local index = length

    while (true) do
        local parentIndex = parent(index)

        if (parentIndex ~= nil and (comparator( values[index], values[parentIndex] ) < 0) ) then
            local temp = values[index]
            values[index] = values[parentIndex]
            values[parentIndex] = temp
            continue
        end

        return
    end
end

shiftDown = function() --move bigger values down the binary tree
    local index = 1

    while true do
        local left = leftChild(index)
        local right = rightChild(index)
        
        local swapCandidiate = index
        if (left ~= nil and (comparator( values[swapCandidiate], values[left] ) > 0) ) then
            swapCandidiate = left
        end
        if (right ~= nil and (comparator( values[swapCandidiate], values[right]) > 0) ) then
            swapCandidiate = right
        end
        if (swapCandidiate ~= index) then --check to see if swap candidate was altered by the two previous ifs
            local temp = values[index]
            values[index] = values[swapCandidiate]
            values[swapCandidiate] = temp
            index = swapCandidiate
            continue
        end

        return --otherwise break the operation
    end
end

return module