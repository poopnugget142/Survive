local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local ReplicatedScripts = ReplicatedStorage.Scripts

local Quadtree = require(ReplicatedScripts.Lib.Quadtree)
local CharacterClass = require(ReplicatedScripts.Class.Character)
local CharacterStates = require(ReplicatedScripts.States.Character)
local Enums = require(ReplicatedScripts.Registry.Enums)
local NPCRegistry = require(ReplicatedScripts.Registry.NPC)


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

        local CollisionRadius = NPCRegistry.GetCollisionRadius(EntityData[CharacterStates.NPCType])
        local NewPoint = Quadtree.BuildCircle(MovementData.Position.X, MovementData.Position.Z, CollisionRadius)
        NewPoint.Data.Entity = Entity

        --if (EntityData.NPCType ~= Enums.NPC.Gargoyle) then
            Quad:Insert(NewPoint)
        --end
    end

    for _, Player in game:GetService("Players"):GetPlayers() do
        local Character = Player.Character

        if not Character then continue end

        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

        if not HumanoidRootPart then continue end

        local Position = HumanoidRootPart.Position

        local Entity = CharacterClass.GetEntityFromCharacter(Character)

        local CollisionRadius = NPCRegistry.GetCollisionRadius(Enums.NPC.Player)
        local NewPoint = Quadtree.BuildCircle(Position.X, Position.Z, CollisionRadius)
        NewPoint.Data.Entity = Entity

        Quad:Insert(NewPoint)
    end
end)