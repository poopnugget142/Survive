local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local Quadtree = require(ReplicatedStorage.Scripts.Util.Quadtree)
local CharacterClass = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)
local NPCRegistry = require(ReplicatedStorage.Scripts.Registry.NPC)


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
        local Entity = CharacterClass.GetEntityFromNpcId(NpcId)
        local EntityData = CharacterStates.World.get(Entity)

        local CollisionRadius = NPCRegistry.GetNearbyNpcDistance(EntityData.NPCType)
        local NewPoint = Quadtree.BuildCircle(MovementData.Position.X, MovementData.Position.Z, CollisionRadius)
        NewPoint.Data.NpcId = NpcId

        --if (EntityData.NPCType ~= Enums.NPC.Gargoyle) then
            Quad:Insert(NewPoint)
        --end
    end
end)