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

local GridventoryCore = require(ReplicatedStorage.Scripts.Class.GridventoryCore)
local QuadtreeModule = require(ReplicatedStorage.Scripts.Util.Quadtree)
local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui : ScreenGui = PlayerGui:WaitForChild("ScreenGui")




local ItemHeld
local ItemHeldOffset

--Create inventory
local TEMPSIZE = Vector2.new(10,10)--TEMP SIZE, REFERENCE LATER !!!!!!!!!!!!!

local LocalGridventory = GridventoryCore.BuildGridventory(
    QuadtreeModule.BuildBox( 
        TEMPSIZE.X/2,
        TEMPSIZE.Y/2,
        TEMPSIZE.X,
        TEMPSIZE.Y
    )
)

local TEMPITEM1 = GridventoryCore.BuildItem(QuadtreeModule.newPoint(1,1), {QuadtreeModule.BuildBox(0,0,1/2,1/2)}) --remember that qtree width extends to each side, divide by 2
local TEMPITEM2 = GridventoryCore.BuildItem(QuadtreeModule.newPoint(2,2), {QuadtreeModule.BuildBox(0,0,1/2,1/2)})

table.insert(LocalGridventory.Items, TEMPITEM1)
table.insert(LocalGridventory.Items, TEMPITEM2)

print(LocalGridventory)
print(GridventoryCore.Item_PlaceInGridventory(TEMPITEM1, LocalGridventory, QuadtreeModule.newPoint(2,3)))
print(LocalGridventory)

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