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
local ScreenGui : ScreenGui = PlayerGui:WaitForChild("HUD")




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
--TEMPITEM1.Rotation = 1
--local TEMPITEM1 = TreeventoryCore.BuildItem({QuadtreeModule.BuildBox(0/4, 0/4, 1/2, 1/2)})
local TEMPITEM2 = TreeventoryCore.BuildItem({QuadtreeModule.BuildBox(0/4, 0/4, 1/2, 1/2)})

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

--Inventory Cell Rendering
local ItemCells = {}
for i = 0, TEMPSIZE.X do
    for j = 0, TEMPSIZE.Y do
        if not ItemCells[i] then
			ItemCells[i] = {}
		end

        local instance : GuiObject = ReplicatedStorage.Assets.GUI.ItemCell:Clone()
        instance.Parent = ScreenGui.InventoryMenu.Background.Tileinset.Tilespace
        --instance.Position = UDim2.fromScale(0.25+i/20,0.25+j/20) --rewrite later to use start + end positions
        instance.Position = UDim2.fromScale(i/TEMPSIZE.X,j/TEMPSIZE.Y) --rewrite later to use start + end positions
        instance.Size = UDim2.fromScale(1/TEMPSIZE.X,1/TEMPSIZE.Y)
        instance.BackgroundTransparency = 0

        
        instance.MouseLeave:Connect(function() 
            --if ItemHovering  then
            --    instance.BackgroundColor3 = Color3.fromHSV(0.5,.25,1)
            --else 
                instance.BackgroundColor3 = Color3.fromHSV(0,0,1)
            --end
            --CellHovering = nil
            --ItemHovering = nil
        end)
        instance.MouseEnter:Connect(function() 
            --print(NewCell) 
            task.wait()
            --CellHovering = NewCell
            --print(CellHovering)
            --if (NewCell.CellItemIndex ~= nil) then --check to see if cell has item
            --    ItemHovering = itemItems[NewCell.CellItemIndex]
            --    print(ItemHovering)
            --end
            instance.BackgroundColor3 = Color3.fromHSV(0,0,.5)
        end)
        

        ItemCells[i][j] = instance

        --print("iterate")
    end
end



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
        --TEMPDUMMY1.ben.Rotation += amount*90
        --cosmetic item rotation
            if (math.abs(ItemHeld.Rotation or 0) > 3) then ItemHeld.Rotation = 0 end --return to center
    end
end


KeyBindings.BindAction("Inventory_Open", Enum.UserInputState.Begin, function()
    --print("Bing Chilling!")
    ScreenGui.InventoryMenu.Visible = not ScreenGui.InventoryMenu.Visible
    if (ScreenGui.InventoryMenu.Visible) then
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
    if ItemHeld and ScreenGui.InventoryMenu.Visible then
            --[==[
            ItemPicking.Dummy.Parent = screenGui
            ItemPicking.Dummy.Position = UDim2.fromOffset(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y) 
                + UDim2.fromScale((--[[ItemPicking.DummyOffset.X]]-ItemPickOffset.X)/TEMPSIZE.X, (--[[ItemPicking.DummyOffset.Y]]-ItemPickOffset.Y)/TEMPSIZE.Y)
            ]==]
        local LocalMouse = LocalPlayer:GetMouse()

        local NewPoint = QuadtreeModule.newPoint(LocalMouse.X / LocalMouse.ViewSizeX * 10, LocalMouse.Y / LocalMouse.ViewSizeY * 10) --debug 10x10 inventory
        --TEMPDUMMY1.Position = UDim2.fromScale(NewPoint.X / 10, NewPoint.Y / 10)
        print(NewPoint)
        local Move = TreeventoryCore.Item_PlaceInTreeventory(
            ItemHeld
            , LocalTreeventory
            , NewPoint
        )
        if Move.Value == false then warn("Item Collision!") end
    end
end)
