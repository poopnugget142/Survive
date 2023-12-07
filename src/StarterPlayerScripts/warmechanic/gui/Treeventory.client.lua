--[[
Notetaking
    Start off with temp pick / place controls
    Then move controls to be item specific (implement bullet belt linkage)

    Picking up an item 
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

local TreeventoryCore = require(ReplicatedStorage.Scripts.Class.TreeventoryCore)
local QuadtreeModule = require(ReplicatedStorage.Scripts.Util.Quadtree)
local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)
local Tooltip = require(StarterPlayerScripts.warmechanic.gui.Tooltip)

local Assorted = require(ReplicatedStorage.Scripts.Util.WarMechanicAssorted)

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui : ScreenGui = PlayerGui:WaitForChild("HUD")
local InventoryTilespace = ScreenGui.InventoryMenu.Background.Tileinset.Tilespace


local ItemHeld
local ItemHeldVisualOffset
local ItemHeldCursorOffset
local ItemHeldRotationDelta = 0 -- a separate rotation counter for visual item offsets

--Create inventory
local TEMPSIZE = Vector2.new(13,7)--TEMP SIZE, REFERENCE LATER !!!!!!!!!!!!!
local CellMax = math.max(TEMPSIZE.X, TEMPSIZE.Y)
local LocalTreeventory = TreeventoryCore.BuildTreeventory(
    QuadtreeModule.BuildBox(
        TEMPSIZE.X/2,
        TEMPSIZE.Y/2,
        TEMPSIZE.X/2,
        TEMPSIZE.Y/2
    )
)

--Inventory Cell Rendering
local ItemCells = {}
for i = 0, TEMPSIZE.X-1 do
    for j = 0, TEMPSIZE.Y-1 do
        if not ItemCells[i] then
			ItemCells[i] = {}
		end

        local instance : GuiObject = ReplicatedStorage.Assets.GUI.ItemCell:Clone()
        instance.Parent = ScreenGui.InventoryMenu.Background.Tileinset.Tilespace
        instance.Name = "cell_(" .. tostring(i) .. "," .. tostring(j) .. ")"
        local CellSize = CellMax
        instance.Position = UDim2.fromScale(
            (i+0.5)/CellSize
            ,(j+0.5)/CellSize
        )
        instance.Size = UDim2.fromScale(
            1/CellSize +0.001
            ,1/CellSize +0.001
        )
        instance.BackgroundTransparency = 0

        
        instance.MouseLeave:Connect(function() 
            instance.BackgroundColor3 = Color3.fromHSV(0,0,1)
        end)
        instance.MouseEnter:Connect(function()  
            task.wait()
            instance.BackgroundColor3 = Color3.fromHSV(0,0,.5)
            Tooltip.Position(instance.AbsolutePosition + instance.AbsoluteSize/2)
        end)
        

        ItemCells[i][j] = instance
    end
end

local GetMouseRelativeToInventory = function()
    local LocalMouse = LocalPlayer:GetMouse()
    
    local MouseRelativeX = LocalMouse.X - InventoryTilespace.AbsolutePosition.X
    local MouseRelativeY = LocalMouse.Y - InventoryTilespace.AbsolutePosition.Y

    return Vector2.new(
        MouseRelativeX/InventoryTilespace.AbsoluteSize.X
        ,MouseRelativeY/InventoryTilespace.AbsoluteSize.Y
    )
end

local GetAbsolutePositionFromInventory = function(Position : Vector2)
    return Vector2.new(
        InventoryTilespace.AbsolutePosition.X + InventoryTilespace.AbsoluteSize.X * (Position.X/TEMPSIZE.X)
        ,InventoryTilespace.AbsolutePosition.Y + InventoryTilespace.AbsoluteSize.Y * (Position.Y/TEMPSIZE.Y)
    )
end

local RotateVector2 = function(Target : Vector2, Amount : number)
    local Theta = math.round(Amount or 0) * math.pi * 0.5
    return Vector2.new(
        Target.X * math.cos(Theta) - Target.Y * math.sin(Theta) --boundary offset
        ,Target.X * math.sin(Theta) + Target.Y * math.cos(Theta)
    )
end

local CreateItemDummy = function(Item)
    local NewDummy : GuiObject = ReplicatedStorage.Assets.GUI.ItemFrame:Clone()
    NewDummy.Parent = ScreenGui.InventoryMenu.Background.Tileinset.Tilespace
    NewDummy.Position = UDim2.fromScale(
        (Item.Position.X-1--[[+newItem.DummyOffset.X]])/CellMax
        ,(Item.Position.Y-1--[[+newItem.DummyOffset.Y]])/CellMax
    )
    NewDummy.Size = UDim2.fromScale(1/CellMax,1/CellMax)
    --tidy this up later
    NewDummy.AnchorParent.Frame.Position = UDim2.fromScale(Item.Boundaries[1].X/2,Item.Boundaries[1].Y/2)
    NewDummy.AnchorParent.Frame.Size = UDim2.fromScale(Item.Boundaries[1].w,Item.Boundaries[1].h)
    for i = 2, #Item.Boundaries, 1 do 
        local NewFrame = NewDummy.AnchorParent.Frame:Clone()
        NewFrame.Parent = NewDummy.AnchorParent
        NewFrame.Position = UDim2.fromScale(Item.Boundaries[i].X/2,Item.Boundaries[i].Y/2)
        NewFrame.Size = UDim2.fromScale(Item.Boundaries[i].w,Item.Boundaries[i].h)
    end
    
    Item.Dummy = NewDummy
    return true
end


--Temp Items
local TEMPITEM1 = TreeventoryCore.BuildItem({QuadtreeModule.BuildBox(2/4, 0/4, 2/2, 1/2), QuadtreeModule.BuildBox(-2/4, 0/4, 2/2, 1/2)})
TreeventoryCore.Item_PlaceInTreeventory(TEMPITEM1, LocalTreeventory, QuadtreeModule.newPoint(4,4))
CreateItemDummy(TEMPITEM1)

local TEMPITEM2 = TreeventoryCore.BuildItem({QuadtreeModule.BuildBox(0/4, 0/4, 1/2, 1/2)})
TreeventoryCore.Item_PlaceInTreeventory(TEMPITEM2, LocalTreeventory, QuadtreeModule.newPoint(2,2))
CreateItemDummy(TEMPITEM2)

local TEMPITEM3 = TreeventoryCore.BuildItem({QuadtreeModule.BuildBox(0/4, 0/4, 1/2, 1/2)})
TreeventoryCore.Item_PlaceInTreeventory(TEMPITEM3, LocalTreeventory, QuadtreeModule.newPoint(3,2))
CreateItemDummy(TEMPITEM3)


--Item Functions
local ItemPick = function()
    --Pick up an item
    local MousePosition = GetMouseRelativeToInventory()

    local CursorPosition = Vector2.new(
        math.ceil(MousePosition.X*CellMax)
        ,math.ceil(MousePosition.Y*CellMax)
    )
    local ItemCheck = TreeventoryCore.Treeventory_CheckBox(LocalTreeventory, QuadtreeModule.BuildBox(math.ceil(CursorPosition.X), math.ceil(CursorPosition.Y), 0.5, 0.5))

    if (ItemCheck.Error and #ItemCheck.Error) then
        --check if there are multiple items among boundaries
        local DesiredItem = ItemCheck.Error[1].Data.Item
        for _, Boundary in ItemCheck.Error do
            if Boundary.Data.Item ~= DesiredItem then return ItemCheck end
        end

        ItemHeld = DesiredItem --table.unpack(ItemCheck.Error).Data.Item
        ItemHeld.Parent.Items[ItemHeld.Id] = nil
        ItemHeld.Parent = nil


        local ItemScreenPosition = Vector2.new(ItemHeld.Position.X-0.5, ItemHeld.Position.Y-0.5)

        --offset item from cursor
        ItemHeldVisualOffset = -( MousePosition*CellMax - ItemScreenPosition) / CellMax
        ItemHeldCursorOffset = Vector2.new(math.round(ItemHeldVisualOffset.X*CellMax), math.round(ItemHeldVisualOffset.Y*CellMax))
    end
end


local ItemPlace = function()
    print("Attempted to Place Item")
    local MousePosition = GetMouseRelativeToInventory()
    local CursorPosition = Vector2.new(
        math.ceil(MousePosition.X*CellMax)
        ,math.ceil(MousePosition.Y*CellMax)
    )
    local CursorOffset = RotateVector2(ItemHeldCursorOffset, ItemHeldRotationDelta)

    local NewPoint = QuadtreeModule.newPoint(
        CursorPosition.X + CursorOffset.X
        ,CursorPosition.Y + CursorOffset.Y
    )
    local Move = TreeventoryCore.Item_PlaceInTreeventory(
        ItemHeld
        ,LocalTreeventory
        ,NewPoint
    )
    if Move.Value == true then --if the item doesn't intersect with anything, move dummy stuff
        ItemHeld.Dummy.Position = UDim2.fromScale(
            (ItemHeld.Position.X-1--[[+newItem.DummyOffset.X]])/CellMax
            ,(ItemHeld.Position.Y-1--[[+newItem.DummyOffset.Y]])/CellMax
        )

        ItemHeld = nil
        ItemHeldRotationDelta = 0
    elseif Move.Error and #Move.Error and Move.Error[1].Error then --otherwise attempt to swap held items
        --check if there are multiple items among boundaries
        local DesiredItem = Move.Error[1].Error[1].Data.Item
        for _, Check in Move.Error do
            for _, Boundary in Check.Error do
                if Boundary.Data.Item ~= DesiredItem then return Move end
            end
        end

        -- remove item from inventory in temporary storage
        local ItemSwap = DesiredItem
        ItemSwap.Parent.Items[ItemSwap.Id] = nil
        ItemSwap.Parent = nil
        
        --reattempt item placement
        Move = TreeventoryCore.Item_PlaceInTreeventory( 
            ItemHeld
            ,LocalTreeventory
            ,NewPoint
        )
        if Move.Value == false then return end

        ItemHeld.Dummy.Position = UDim2.fromScale(
            (ItemHeld.Position.X-1--[[+newItem.DummyOffset.X]])/CellMax
            ,(ItemHeld.Position.Y-1--[[+newItem.DummyOffset.Y]])/CellMax
        )
        ItemHeld = ItemSwap

        --offset item from cursor
        local ItemScreenPosition = Vector2.new(ItemHeld.Position.X-0.5, ItemHeld.Position.Y-0.5)
        ItemHeldVisualOffset = -( MousePosition*CellMax - ItemScreenPosition) / CellMax
        ItemHeldCursorOffset = Vector2.new(math.round(ItemHeldVisualOffset.X*CellMax), math.round(ItemHeldVisualOffset.Y*CellMax))
        
        ItemHeldRotationDelta = 0
    else --check if the item touches the inventory >>at all<<, if not then we can consider it a drop action
        local TouchesInventory = true
        for _, Boundary in ItemHeld.Boundaries do
            local CollisionCheck = QuadtreeModule.BoxCheck(LocalTreeventory.Boundary, TreeventoryCore.PositionPlusBoundary(CursorPosition, Boundary, ItemHeld.Rotation))
            if CollisionCheck == false then --return if we touch something
                TouchesInventory = CollisionCheck
                break
            end
        end

        if not TouchesInventory then --temp item drop (delete)
            ItemHeld.Dummy:Destroy()
            ItemHeld = nil
            ItemHeldVisualOffset = Vector2.zero
            ItemHeldCursorOffset = Vector2.zero
            ItemHeldRotationDelta = 0
        end
    end
end


local ItemRotate = function(amount : number)
    if ItemHeld then
        print("Rotated item by ", amount*90, " degrees")
        ItemHeld.Rotation += amount
        ItemHeldRotationDelta += amount
        ItemHeld.Dummy.Rotation += amount*90
        --cosmetic item rotation
            if (math.abs(ItemHeld.Rotation or 0) > 3) then ItemHeld.Rotation = 0 end --return to center
    end
end


KeyBindings.BindAction("Inventory_Open", Enum.UserInputState.Begin, function()
    ScreenGui.InventoryMenu.Visible = not ScreenGui.InventoryMenu.Visible
    if (ScreenGui.InventoryMenu.Visible) then
        KeyBindings.BindAction("Inventory_Interact1", Enum.UserInputState.Begin, function()
            if not ItemHeld then ItemPick()
                else ItemPlace() end
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


RunService.RenderStepped:Connect(function(deltaTime)
    local LocalMouse = LocalPlayer:GetMouse()
    if ItemHeld and ScreenGui.InventoryMenu.Visible then
        --item display handling, absolute mouse position
        --local LocalMouse = LocalPlayer:GetMouse()
        local VisualOffset = RotateVector2(
            ItemHeldVisualOffset
            ,ItemHeldRotationDelta
        )

        ItemHeld.Dummy.Parent = InventoryTilespace
        ItemHeld.Dummy.Position = UDim2.fromOffset(
            LocalMouse.X - InventoryTilespace.AbsolutePosition.X
            ,LocalMouse.Y - InventoryTilespace.AbsolutePosition.Y
        )
        + UDim2.fromScale(
            -0.5/CellMax
            ,-0.5/CellMax
        )
        + UDim2.fromScale(
            VisualOffset.X
            ,VisualOffset.Y
        )

        --internal item position, relative mouse position
        local MousePosition = GetMouseRelativeToInventory()
        local CursorPosition = Vector2.new(
            math.ceil(MousePosition.X*CellMax)
            ,math.ceil(MousePosition.Y*CellMax)
        )
        local CursorOffset = RotateVector2(
            ItemHeldCursorOffset
            ,ItemHeldRotationDelta
        )

        --collision printing, not actually important
        for _, Boundary in ItemHeld.Boundaries do
            local Move = TreeventoryCore.Treeventory_CheckBox(
                LocalTreeventory
                ,TreeventoryCore.PositionPlusBoundary(CursorPosition + CursorOffset, Boundary, ItemHeld.Rotation)
            )
            if Move.Value == false and not (Move.Error ~= false and #Move.Error == 1 and table.unpack(Move.Error).Data.Item == ItemHeld) then warn("Potential Collision!") end
        end
    end
end)

