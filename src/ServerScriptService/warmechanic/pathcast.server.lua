local runService : RunService = game:GetService("RunService")

local replicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local djikstra2 = require(ServerScriptService.warmechanic.DjikstraPathfinding)
--local priorityQueue = require(replicatedStorage.Scripts.warmechanic.priorityqueue)
local priorityQueue2 = require(replicatedStorage.Scripts.Util.PriorityQueue)


local Players = game:GetService("Players")

--[[
repeat task.wait() until djikstra.pathfind(Vector2.new(0,0), Vector2.new(100,100))

local printPath = djikstra.world.Component.Get(djikstra.tileUV(0,0), "pathData")
print(printPath.heat)
printPath = djikstra.world.Component.Get(djikstra.tileUV(25,25), "pathData")
print(printPath.heat)
printPath = djikstra.world.Component.Get(djikstra.tileUV(50,50), "pathData")
print(printPath.heat)
printPath = djikstra.world.Component.Get(djikstra.tileUV(75,75), "pathData")
print(printPath.heat)
printPath = djikstra.world.Component.Get(djikstra.tileUV(100,100), "pathData")
print(printPath.heat)
]]

--[[
runService.Heartbeat:Connect(function(deltaTime)
    
end)
]]

local temp = {4,5,2,3,1}
--[[
for _, number in temp do
    priorityQueue.enqueue(number)
end
print(priorityQueue.heapSort())
local out = priorityQueue.heapSort()
print(out)
]]
--[[
local queue = priorityQueue2.Create()
for _, number in temp do
    queue:Enqueue(number)
end
print(queue:HeapSort())
]]

while true do
    --debug.profilebegin("Pathcast Begin")
    --local target = workspace.Characters:WaitForChild("poopnugget142")
    --local target = workspace.Characters:WaitForChild("WarMechanist")
    local targets = workspace.Characters.Players:GetChildren()
    local parts = {}
    for _, target in targets do
        table.insert(parts, target.PrimaryPart)
    end

    --local part : BasePart = target.PrimaryPart

    if not parts then return end
    --print(type(target))
    --local velocity = part:GetVelocityAtPosition(part.position)*0.5
    --local position = (part.position + velocity) * Vector3.new(1,0,1)
    
    local flowfield = djikstra2.pathfind(table.unpack(parts)--[[position--[[, Vector3.new(5,0,5)]])

    repeat task.wait(0.25) until flowfield

    --debug.profileend()
end
