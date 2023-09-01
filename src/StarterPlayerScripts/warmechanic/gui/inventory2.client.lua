--[[
    notetaking

    store item indices in stew components at positions, makes it easy to check item overlap

    rehash modulo math later to be in terms of inventory frame size rather than screen size,
        so conversions dont need to be done between them

    add support for multiple inventories / subinventories in inventories (ammo case in player backpack)
]]
--initialise dependencies
--local StarterPlayer = game:GetService("StarterPlayer")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local cam = workspace.CurrentCamera

local players = game:GetService("Players")
local player = players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")
local screenGui : ScreenGui = playerGui:WaitForChild("ScreenGui")

local stew = require(replicatedStorage.Packages.Stew)
local world = stew.world()


type InventoryCell = {
    Dummy : GuiObject; --frame
    CellItemIndex : number; --index that leads to item
}
type InventoryItem = {
    Dummy : GuiObject; --frame
    ItemShape : table; --table of vector2 offsets that define shape
    ItemPosition : Vector2; --position relative to inventory origin (0,0 = top left)
}


local frameStartPosition = screenGui.mainFrame.inventoryFrame.cellStorage.AbsolutePosition * screenGui.mainFrame.inventoryFrame.cellStorage.AbsoluteSize

local BuildCell = function(Position : Vector2) -- silly function for creating a new cell
    return {
        Dummy = nil;
        CellPosition = Position;
        CellItemIndex = nil;
    }
end :: InventoryCell
local BuildItem = function() -- silly function for creating a new item
    return {
        Dummy = nil;
        ItemShape = nil;
        ItemPosition = nil;
    }
end :: InventoryItem


local ItemCells = {}
local itemItems = {}
local CellHovering : InventoryCell
local ItemHovering : InventoryItem--item the player is hovering (directly) over
local ItemPicking : InventoryItem--item the player has picked with their mouse

--generate 10x10 inventory cells
for i = 1, 10 do
    for j = 1, 10 do
        if not ItemCells[i] then
			ItemCells[i] = {}
		end

        local instance : GuiObject = screenGui.mainFrame.inventoryFrame.prefabs.itemCell:Clone()
        instance.Parent = screenGui.mainFrame.inventoryFrame.cellStorage
        --instance.Position = UDim2.fromScale(0.25+i/20,0.25+j/20) --rewrite later to use start + end positions
        instance.Position = UDim2.fromScale((i-0.5)/10,(j-0.5)/10) --rewrite later to use start + end positions
        instance.Size = UDim2.fromScale(1/10,1/10)
        instance.BackgroundTransparency = 0
        
        local NewCell : InventoryCell = BuildCell(Vector2.new(i,j))
        NewCell.Dummy = instance
        NewCell.CellPosition = Vector2.new(i,j)
        NewCell.CellItemIndex = nil

        instance.MouseLeave:Connect(function() 
            CellHovering = nil
            ItemHovering = nil
            instance.BackgroundColor3 = Color3.fromHSV(0,0,1)
        end)
        instance.MouseEnter:Connect(function() 
            --print(NewCell) 
            task.wait()
            CellHovering = NewCell
            print(CellHovering)
            if (NewCell.CellItemIndex ~= nil) then --check to see if cell has item
                ItemHovering = itemItems[NewCell.CellItemIndex]
                print(ItemHovering)
            end
            instance.BackgroundColor3 = Color3.fromHSV(0,0,.5)
        end)

        ItemCells[i][j] = NewCell

        --print("iterate")
    end
end
--print(ItemCells)

if true then --debug test item
    local newDummy : GuiObject = screenGui.mainFrame.inventoryFrame.prefabs.itemButton:Clone()
    newDummy.Parent = screenGui.mainFrame.inventoryFrame.itemStorage
    newDummy.Position = UDim2.fromScale((1-0.5)/10,(1-0.5)/10)
    newDummy.Size = UDim2.fromScale(1/10,1/10)
    newDummy.BackgroundTransparency = 0

    local newItem : InventoryItem = BuildItem()
    newItem.Dummy = newDummy
    newItem.ItemShape = {Vector2.new(0,0)}
    newItem.ItemPosition = Vector2.new(1,1)
    table.insert(itemItems, newItem)

    ItemCells[1][1].CellItemIndex = 1
end
--local templates : GuiObject = screenGui.mainFrame.inventoryFrame.itemStorage:GetChildren()

--left click handler, pick up and put down items
userInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if ItemHovering and not ItemPicking then
            ItemPicking = ItemHovering
            ItemHovering = nil
        else
            if ItemPicking then
                --dummy stuff
                ItemPicking.Dummy.Parent = screenGui.mainFrame.inventoryFrame.itemStorage
                ItemPicking.Dummy.Position = UDim2.fromScale((CellHovering.CellPosition.X-0.5)/10,(CellHovering.CellPosition.Y-0.5)/10)
                
                for _, ItemOffset in ItemPicking.ItemShape do --delete previous item reference
                    ItemCells[ItemPicking.ItemPosition.X + ItemOffset.X][ItemPicking.ItemPosition.Y + ItemOffset.Y-1].CellItemIndex = nil
                end
                --local itemIndex = table.find(itemItems, ItemPicking)
                for _, ItemOffset in ItemPicking.ItemShape do --add new item reference
                    ItemCells[CellHovering.CellPosition.X + ItemOffset.X][CellHovering.CellPosition.Y + ItemOffset.Y-1].CellItemIndex = 1--itemIndex
                end
                ItemPicking.ItemPosition = CellHovering.CellPosition
                --CellHovering.MouseEnter()
                print("Bing Chilling!")
                ItemHovering = ItemPicking --allows the player to pick up the item directly after placing it
                ItemPicking = nil
            end
            
        end
    end
end)






runService.RenderStepped:Connect(function(deltaTime)
    if ItemPicking then
        ItemPicking.Dummy.Parent = screenGui
        ItemPicking.Dummy.Position = UDim2.fromOffset(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y)
    end
end)