local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedScripts = ReplicatedStorage:WaitForChild("Scripts")
local Enums = require(ReplicatedScripts.Registry.Enums)
local Item = Enums.Item

--Tags that define interactions it can have
return {
    [Item.Shotgun] = {"Gun"}
    ;[Item.M1911] = {"Gun"}
}