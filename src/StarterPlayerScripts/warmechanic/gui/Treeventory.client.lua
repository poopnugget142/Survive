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
local TEMPITEM1 = TreeventoryCore.BuildItem({QuadtreeModule.BuildBox(2/4, 0/4, 2/2, 1/2), QuadtreeModule.BuildBox(-2/4, 0/4, 2/2, 1/2)}) --remember that qtree width extends to each side, divide by 2
local TEMPDUMMY1 : GuiObject = ScreenGui.mainFrame.inventoryFrame.prefabs.itemButton:Clone()
TEMPDUMMY1.Parent = ScreenGui.mainFrame.inventoryFrame.itemStorage
TEMPDUMMY1.ben.Position = UDim2.fromScale(0,0)
TEMPDUMMY1.Size = UDim2.fromScale(1/TEMPSIZE.X,1/TEMPSIZE.Y)
TEMPDUMMY1.ben.Size = UDim2.fromScale(3,1)
--TEMPITEM1.Rotation = 1
--local TEMPITEM1 = TreeventoryCore.BuildItem({QuadtreeModule.BuildBox(0/4, 0/4, 1/2, 1/2)})
local TEMPITEM2 = TreeventoryCore.BuildItem({QuadtreeModule.BuildBox(0/4, 0/4, 1/2, 1/2)})
local TEMPDUMMY2 : GuiObject = ScreenGui.mainFrame.inventoryFrame.prefabs.itemButton:Clone()
TEMPDUMMY2.Parent = ScreenGui.mainFrame.inventoryFrame.itemStorage
TEMPDUMMY2.Position = UDim2.fromScale(1/10*2,1/10*2)
TEMPDUMMY2.ben.Position = UDim2.fromScale(0,0)
TEMPDUMMY2.Size = UDim2.fromScale(1/TEMPSIZE.X,1/TEMPSIZE.Y)
TEMPDUMMY2.ben.Size = UDim2.fromScale(1,1)

ItemHeld = TEMPITEM1

TreeventoryCore.Item_PlaceInTreeventory(TEMPITEM1, LocalTreeventory, QuadtreeModule.newPoint(1,1))
TreeventoryCore.Item_PlaceInTreeventory(TEMPITEM2, LocalTreeventory, QuadtreeModule.newPoint(2,2))

--[[
print(LocalTreeventory)
local Move = TreeventoryCore.Item_PlaceInTreeventory(TEMPITEM1, LocalTreeventory, QuadtreeModule.newPoint(2,2))
print(Move)
if Move.Value == false then warn("Item Collision!") end
print(LocalTreeventory)
]]



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




local ItemRotate = function(amount : number)
    if ItemHeld then
        print("Rotated item by ", amount*90, " degrees")
        ItemHeld.Rotation += amount
        TEMPDUMMY1.ben.Rotation += amount*90
        --cosmetic item rotation
            if (math.abs(ItemHeld.Rotation or 0) > 3) then ItemHeld.Rotation = 0 end --return to center
    end
end


KeyBindings.BindAction("Inventory_Open", Enum.UserInputState.Begin, function()
    --print("Bing Chilling!")
    ScreenGui.mainFrame.Visible = not ScreenGui.mainFrame.Visible
    if (ScreenGui.mainFrame.Visible) then
        --[[KeyBindings.BindAction("Inventory_Interact1", Enum.UserInputState.Begin, function()
            ItemPick()
        end, 2)]]
        KeyBindings.BindAction("Inventory_RotateLeft", Enum.UserInputState.Begin, function()
            ItemRotate(-1)
        end)
        KeyBindings.BindAction("Inventory_RotateRight", Enum.UserInputState.Begin, function()
            ItemRotate(1)
        end)
    else
        KeyBindings.UnbindAction("Inventory_Interact1")
        KeyBindings.UnbindAction("Inventory_RotateLeft")
        KeyBindings.UnbindAction("Inventory_RotateRight")
    end
end)


RunService.RenderStepped:Connect(function(deltaTime)
    if ItemHeld and ScreenGui.mainFrame.Visible then
        --[==[
            ItemPicking.Dummy.Parent = screenGui
            ItemPicking.Dummy.Position = UDim2.fromOffset(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y) 
                + UDim2.fromScale((--[[ItemPicking.DummyOffset.X]]-ItemPickOffset.X)/inventorySize.X, (--[[ItemPicking.DummyOffset.Y]]-ItemPickOffset.Y)/inventorySize.Y)
        ]==]

        local LocalMouse = LocalPlayer:GetMouse()

        local NewPoint = QuadtreeModule.newPoint(LocalMouse.X / LocalMouse.ViewSizeX * 10, LocalMouse.Y / LocalMouse.ViewSizeY * 10) --debug 10x10 inventory
        TEMPDUMMY1.Position = UDim2.fromScale(NewPoint.X / 10, NewPoint.Y / 10)
        print(NewPoint)
        local Move = TreeventoryCore.Item_PlaceInTreeventory(
            ItemHeld
            , LocalTreeventory
            , NewPoint
        )
        if Move.Value == false then warn("Item Collision!") end
    end
end)