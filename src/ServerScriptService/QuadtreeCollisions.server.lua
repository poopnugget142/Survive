local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


local Quadtree = require(ReplicatedStorage.Scripts.Util.Quadtree)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)


local Quad = Quadtree.newQuadtree(50,50,50,50)

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

--[[
RunService.Heartbeat:Connect(function(deltaTime)
    Quad = Quadtree.newQuadtree(175,175,175,175)
    --[[
    for NpcId, MovementData in AllMovementData do
        local NewPoint = Quadtree.newPoint(MovementData.Position.X, MovementData.Position.Y)
        NewPoint.Data.NpcId = NpcId
        Module.Quad:Insert(NewPoint)
    end
    ]
    local Characters = CharacterStates.World.query(CharacterStates.Character)
    for Entity in Characters do
        local EntityData = CharacterStates.World.get(Entity)

        CharacterStates.
    end
end)
]]