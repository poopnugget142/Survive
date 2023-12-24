local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedScripts = ReplicatedStorage:WaitForChild("Scripts")
local Enums = require(ReplicatedScripts.Registry.Enums)
local Item = Enums.Item

--Item Combinables

--Any allows any item with the tag to be combined with the item
--Both only allows items with both tags for it to work
--Exclude is all the items/tags you don't want to be combined with the item

return {
    [Item.Shotgun] = {
        Any = {"Shell"}
    }
    ;[Item["S&W Model 10"]] = {
        Any = {".38"}
    }
    ;[Item["Colt Python"]] = {
        Any = {".357", ".38"}
    }
    ;[Item["Colt Anaconda"]] = {
        Any = {".357", ".38"}
    }
}