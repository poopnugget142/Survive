local SharedTableRegistry = game:GetService("SharedTableRegistry")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Squash = require(ReplicatedStorage.Packages.Squash)

local AllMovementData = SharedTableRegistry:GetSharedTable("AllMovementData")

local UpdateNPCPosition : RemoteEvent = ReplicatedStorage.Remotes.UpdateNPCPosition

while task.wait(0.05) do
    local PositionDataArray = {}
    for NpcId, MovementData in AllMovementData do
        local Position = MovementData.Position
        table.insert(PositionDataArray, Squash.uint.ser(NpcId, 2))
        table.insert(PositionDataArray, Squash.Vector3.ser(Position))
    end

    if #PositionDataArray == 0 then continue end

    UpdateNPCPosition:FireAllClients(PositionDataArray)
end