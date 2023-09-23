local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local Quadtree = require(ReplicatedStorage.Scripts.Util.Quadtree)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)


local AllMovementData = SharedTableRegistry:GetSharedTable("AllMovementData")




--[[
for i = 1, 8, 1 do
    local NewPoint = Quadtree.newPoint(math.random(0,100), math.random(0,100))
    NewPoint.Data.Deez = true
    Quad:Insert(NewPoint)
    --print(Quad)
end

print(Quad)
print(Quad:QueryRange(Quadtree.BuildBox(50,50,50,50)))
]]

RunService.Heartbeat:Connect(function(deltaTime)
    local Quad = Quadtree.newQuadtree(175,175,175,175, "GroundUnits")
    
    for NpcId, MovementData in AllMovementData do
        local NewPoint = Quadtree.newPoint(MovementData.Position.X, MovementData.Position.Z)
        NewPoint.Data.NpcId = NpcId
        Quad:Insert(NewPoint)
    end
end)