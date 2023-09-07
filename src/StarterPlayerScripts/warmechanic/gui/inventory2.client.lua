--[[
    notetaking

    add support for multiple inventories / subinventories in inventories (ammo case in player backpack)
]]
--initialise dependencies
--local StarterPlayer = game:GetService("StarterPlayer")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cam = workspace.CurrentCamera

local players = game:GetService("Players")
local player = players.LocalPlayer

local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)

local playerGui = player:WaitForChild("PlayerGui")
local screenGui : ScreenGui = playerGui:WaitForChild("ScreenGui")

local stew = require(ReplicatedStorage.Packages.Stew)
local world = stew.world()


type InventoryCell = {
    Dummy : GuiObject --frame
    ;CellItemIndex : number --index that leads to item
    ;
}
type InventoryItem = {
    Dummy : GuiObject --frame
    ;ItemIndex : number
    ;ItemShape : table --table of vector2 offsets that define shape
    ;ItemPosition : Vector2 --position relative to inventory origin (0,0 = top left)
    ;ItemRotation : number
    ;DummyOffset : Vector2
    ;
}


local frameStartPosition = screenGui.mainFrame.inventoryFrame.cellStorage.AbsolutePosition * screenGui.mainFrame.inventoryFrame.cellStorage.AbsoluteSize

local BuildCell = function(Position : Vector2) -- silly function for creating a new cell
    return {
        Dummy = nil
        ;CellPosition = Position
        ;CellItemIndex = nil
        ;
    }
end :: InventoryCell
local BuildItem = function(Index : number) -- silly function for creating a new item
    return {
        Dummy = nil
        ;ItemIndex = Index
        ;ItemShape = {}
        ;ItemPosition = nil
        ;ItemRotation = 0 --0 <= r <= 3 (90 degree rotations)
        ;DummyOffset = Vector2.zero
        ;
    }
end :: InventoryItem


local ItemCells = {}
local itemItems = {}
local CellHovering : InventoryCell
local ItemHovering : InventoryItem--item the player is hovering (directly) over
local ItemPicking : InventoryItem--item the player has picked with their mouse
    local ItemPickOffset : Vector2--when picing up a multicelled item, the item will appear at an offset

    --generate 10x10 inventory cells
local inventorySize = Vector2.new(10,10)
for i = 0, inventorySize.X-1 do
    for j = 0, inventorySize.Y-1 do
        if not ItemCells[i] then
			ItemCells[i] = {}
		end

        local instance : GuiObject = screenGui.mainFrame.inventoryFrame.prefabs.itemCell:Clone()
        instance.Parent = screenGui.mainFrame.inventoryFrame.cellStorage
        --instance.Position = UDim2.fromScale(0.25+i/20,0.25+j/20) --rewrite later to use start + end positions
        instance.Position = UDim2.fromScale((i+0.5)/inventorySize.X,(j+0.5)/inventorySize.Y) --rewrite later to use start + end positions
        instance.Size = UDim2.fromScale(1/inventorySize.X,1/inventorySize.Y)
        instance.BackgroundTransparency = 0
        
        local NewCell : InventoryCell = BuildCell(Vector2.new(i,j))
        NewCell.Dummy = instance
        NewCell.CellPosition = Vector2.new(i,j)
        NewCell.CellItemIndex = nil

        instance.MouseLeave:Connect(function() 
            if ItemHovering  then
                instance.BackgroundColor3 = Color3.fromHSV(0.5,.25,1)
            else 
                instance.BackgroundColor3 = Color3.fromHSV(0,0,1)
            end
            CellHovering = nil
            ItemHovering = nil
        end)
        instance.MouseEnter:Connect(function() 
            --print(NewCell) 
            task.wait()
            CellHovering = NewCell
            --print(CellHovering)
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

local InventoryItemBuild = function(Position : Vector2, RectSize : Vector2)
    local newItem : InventoryItem = BuildItem(#itemItems+1)
    newItem.ItemPosition = Position
    --[[newItem.ItemShape = {
        Vector2.new(0,0), Vector2.new(1,0), Vector2.new(2,0), Vector2.new(3,0), Vector2.new(4,0), 
        Vector2.new(0,1), Vector2.new(1,1), Vector2.new(2,1), Vector2.new(3,1), Vector2.new(4,1),
        Vector2.new(0,2), Vector2.new(1,2), Vector2.new(2,2), Vector2.new(3,2), Vector2.new(4,2)
    }]]
    for u = 1, RectSize.X, 1 do
        for v = 1, RectSize.Y, 1 do
            table.insert(newItem.ItemShape, Vector2.new(u-1,v-1))
        end
    end

    local newDummy : GuiObject = screenGui.mainFrame.inventoryFrame.prefabs.itemButton:Clone()
    newDummy.Parent = screenGui.mainFrame.inventoryFrame.itemStorage
    newItem.DummyOffset = Vector2.new()--((RectSize.X-1)/2, (RectSize.Y-1)/2)
    newDummy.Position = UDim2.fromScale(
        (Position.X--[[+newItem.DummyOffset.X]])/inventorySize.X
        ,(Position.Y--[[+newItem.DummyOffset.Y]])/inventorySize.Y
    )
    newDummy.ben.Position = UDim2.fromScale((RectSize.X)/2, (RectSize.Y)/2)
    newDummy.Size = UDim2.fromScale(1/inventorySize.X,1/inventorySize.Y)
    newDummy.ben.Size = UDim2.fromScale((RectSize.X),(RectSize.Y))
    --newDummy.BackgroundTransparency = 0

    newItem.Dummy = newDummy
    
    table.insert(itemItems, newItem)

    ItemCells[Position.X][Position.Y].CellItemIndex = #itemItems
end
InventoryItemBuild(Vector2.new(0,0), Vector2.new(2,1))
InventoryItemBuild(Vector2.new(0,1), Vector2.new(2,1))
--local templates : GuiObject = screenGui.mainFrame.inventoryFrame.itemStorage:GetChildren()

local ItemPick = function()
    if ItemHovering and not ItemPicking then
        ItemPicking = ItemHovering
        ItemPickOffset = CellHovering.CellPosition - ItemPicking.ItemPosition
        for _, ItemOffset in ItemPicking.ItemShape do --delete previous item reference
            local newCell = ItemCells
                [ItemPicking.ItemPosition.X + (ItemOffset.X*math.cos(ItemPicking.ItemRotation*math.pi*0.5) - (ItemOffset.Y*math.sin(ItemPicking.ItemRotation*math.pi*0.5))) ]
                [ItemPicking.ItemPosition.Y + (ItemOffset.X*math.sin(ItemPicking.ItemRotation*math.pi*0.5) + (ItemOffset.Y*math.cos(ItemPicking.ItemRotation*math.pi*0.5))) ]

            print(newCell)
            newCell.CellItemIndex = nil
        end
        print(ItemPickOffset)
        ItemHovering = nil
    else
        if ItemPicking then
            --dummy stuff
            ItemPicking.Dummy.Parent = screenGui.mainFrame.inventoryFrame.itemStorage
            ItemPicking.Dummy.Position = UDim2.fromScale(
                (CellHovering.CellPosition.X--[[+ItemPicking.DummyOffset.X]]-ItemPickOffset.X+0.5)/inventorySize.X
                ,(CellHovering.CellPosition.Y--[[+ItemPicking.DummyOffset.Y]]-ItemPickOffset.Y+0.5)/inventorySize.Y
            )
            
            --local itemIndex = table.find(itemItems, ItemPicking)
            local newPosition = CellHovering.CellPosition - ItemPickOffset
            local newCells = {}
            local detectedItems = {}
            for _, ItemOffset in ItemPicking.ItemShape do --add new item reference
                local newCell = (ItemCells
                    [newPosition.X + (ItemOffset.X*math.cos(ItemPicking.ItemRotation*math.pi*0.5) - (ItemOffset.Y*math.sin(ItemPicking.ItemRotation*math.pi*0.5))) ]
                    [newPosition.Y + (ItemOffset.X*math.sin(ItemPicking.ItemRotation*math.pi*0.5) + (ItemOffset.Y*math.cos(ItemPicking.ItemRotation*math.pi*0.5))) ]
                )
                if (newCell == nil) then
                    print("Oops!")
                    return
                else
                    print(newCell)
                    table.insert(newCells, newCell) --failsafe
                    if (newCell.CellItemIndex) then --item check
                        if (not table.find(detectedItems, newCell.CellItemIndex)) then
                            table.insert(detectedItems, itemItems[newCell.CellItemIndex])
                            if (#detectedItems > 1) then --cancel item transaction if >2 items
                                print("> 2 Items!!!")
                                return
                            end
                        end
                    end
                end
            end
            for _, newCell in newCells do
                print(newCell)
                newCell.CellItemIndex = ItemPicking.ItemIndex
            end
            ItemPicking.ItemPosition = newPosition

            --CellHovering.MouseEnter()
            --print("Bing Chilling!")
            ItemHovering = ItemPicking --allows the player to pick up the item directly after placing it
            ItemPicking = nil
            if (#detectedItems == 1) then
                ItemPicking = detectedItems[1]
            end
        end
        
    end
end

local ItemRotate = function(amount : number)
    if ItemPicking then
        print("Bing Chilling!")
        ItemPicking.ItemRotation += amount
        ItemPicking.Dummy.Rotation = ItemPicking.ItemRotation * 90
            if (math.abs(ItemPicking.ItemRotation) > 3) then ItemPicking.ItemRotation = 0 end --return to center
    end
end

KeyBindings.BindAction("Inventory_Open", Enum.UserInputState.Begin, function()
    --print("Bing Chilling!")
    screenGui.mainFrame.Visible = not screenGui.mainFrame.Visible
    if (screenGui.mainFrame.Visible) then
        KeyBindings.BindAction("Inventory_Interact1", Enum.UserInputState.Begin, function()
            ItemPick()
        end, 2)
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

--left click handler, pick up and put down items
runService.RenderStepped:Connect(function(deltaTime)
    if ItemPicking then
        ItemPicking.Dummy.Parent = screenGui
        ItemPicking.Dummy.Position = UDim2.fromOffset(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y) 
            + UDim2.fromScale((--[[ItemPicking.DummyOffset.X]]-ItemPickOffset.X)/inventorySize.X, (--[[ItemPicking.DummyOffset.Y]]-ItemPickOffset.Y)/inventorySize.Y)
            
    end
end)