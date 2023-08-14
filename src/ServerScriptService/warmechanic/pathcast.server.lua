local runService : RunService = game:GetService("RunService")

local replicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
--local djikstra = require(ServerScriptService.warmechanic.djikstrapathfind)
local djikstra2 = require(ServerScriptService.warmechanic.djikstrapathfind2)
local priorityQueue = require(replicatedStorage.Scripts.warmechanic.priorityqueue)


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

local temp = {1,4,5,2,3}
for _, number in temp do
    priorityQueue.enqueue(number)
end
print(priorityQueue.heapSort())
local out = priorityQueue.heapSort()
print(out)



while true do
    local target = workspace:WaitForChild("WarMechanist")
    local part : BasePart = target:WaitForChild("HumanoidRootPart")
    local position = Vector3.new(
        math.round(part.Position.X),
        0, 
        math.round(part.Position.Z)
    )
    --local flowfield = djikstra.pathfind(Vector2.new(position.X,position.Z))
    local flowfield = djikstra2.pathfind(position--[[, Vector3.new(5,0,5)]])

    repeat task.wait(0.5) until flowfield
    --local printPath = djikstra.world.Component.Get(djikstra.tileUV(0,0), "pathData")
    --print(printPath.heat)
end
