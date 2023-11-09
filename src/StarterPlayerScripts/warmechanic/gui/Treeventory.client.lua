--[[
Notetaking
    Start off with temp pick / place controls
    Then move controls to be item specific (implement bullet belt linkage)

    Picking up an item 
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

local TreeventoryCore = require(ReplicatedStorage.Scripts.Class.TreeventoryCore)
local QuadtreeModule = require(ReplicatedStorage.Scripts.Util.Quadtree)
local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui : ScreenGui = PlayerGui:WaitForChild("ScreenGui")




local ItemHeld
local ItemHeldOffset

--Create inventory
local TEMPSIZE = Vector2.new(10,10)--TEMP SIZE, REFERENCE LATER !!!!!!!!!!!!!

local LocalTreeventory = TreeventoryCore.BuildTreeventory(
    QuadtreeModule.BuildBox( 
        TEMPSIZE.X/2,
        TEMPSIZE.Y/2,
        TEMPSIZE.X,
        TEMPSIZE.Y
    )
)

--I should make a function for adding items to an inventory, huh
--local TEMPITEM1 = TreeventoryCore.BuildItem(QuadtreeModule.newPoint(1,1), {QuadtreeModule.BuildBox(2/4, 0/4, 2/2, 1/2), QuadtreeModule.BuildBox(-2/4, 0/4, 2/2, 1/2)}) --remember that qtree width extends to each side, divide by 2
--TEMPITEM1.Rotation = 1
local TEMPITEM1 = TreeventoryCore.BuildItem({QuadtreeModule.BuildBox(0/4, 0/4, 1/2, 1/2)})
local TEMPITEM2 = TreeventoryCore.BuildItem({QuadtreeModule.BuildBox(0/4, 0/4, 1/2, 1/2)})

TreeventoryCore.Item_PlaceInTreeventory(TEMPITEM1, LocalTreeventory, QuadtreeModule.newPoint(1,1))
TreeventoryCore.Item_PlaceInTreeventory(TEMPITEM2, LocalTreeventory, QuadtreeModule.newPoint(2,2))

print(LocalTreeventory)
print(TreeventoryCore.Item_PlaceInTreeventory(TEMPITEM1, LocalTreeventory, QuadtreeModule.newPoint(2,3)))
print(LocalTreeventory)




local ItemPick = function()
    --Pick up an item
end

local ItemPlace = function()
    local intersect = 0
    if intersect == 0 then
        --if the item doesn't intersect with anything, place the item
    elseif intersect == 1 then
        --otherwise if the item only intersects with 1 other item, swap held items
    else
        --if the item intersects with more than 1 other item, impossible to swap
        return
    end
end