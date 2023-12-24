local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedScripts = ReplicatedStorage:WaitForChild("Scripts")
local Enums = require(ReplicatedScripts.Registry.Enums)
local Item = Enums.Item

return {
    [Item.Shotgun] = {4, 2}
}