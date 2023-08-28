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


inventory_cellFlag = world.factory("inventory_cellFlag", {
    add = function(_, Entity : any, GuiObject : GuiButton)
        return 
        {
            cell = Entity
            ,_ = nil --no names
            ,itemIndex = nil
            ,GuiObject = GuiObject
        }
    end
})


--what other information does this item contain? talk with poop later
inventory_item = world.factory("inventory_item", { 
    add = function(_, Entity : any, positions : table, GuiObject : GuiObject)
        return
        {
            item = Entity
            ,_ = nil --no names
            ,GuiObject = GuiObject
        }
    end
})

local frameStartPosition = screenGui.mainFrame.inventoryFrame.cellStorage.AbsolutePosition - screenGui.mainFrame.inventoryFrame.cellStorage.AbsoluteSize/2


--generate 10x10 inventory cells
local itemCells = {}
for i = 1, 10 do
    for j = 1, 10 do
        if not itemCells[i] then
			itemCells[i] = {}
		end

        local instance : GuiObject = screenGui.mainFrame.inventoryFrame.prefabs.itemCell:Clone()
        instance.Parent = screenGui.mainFrame.inventoryFrame.cellStorage
        --instance.Position = UDim2.fromScale(0.25+i/20,0.25+j/20) --rewrite later to use start + end positions
        instance.Position = UDim2.fromScale((i-0.5)/10,(j-0.5)/10) --rewrite later to use start + end positions
        instance.Size = UDim2.fromScale(1/10,1/10)
        instance.BackgroundTransparency = 0
        
        instance.MouseEnter:Connect(function() 
            print(i .. ", " .. j) 
            instance.BackgroundColor3 = Color3.fromHSV(0,0,.5)
        end)
        instance.MouseLeave:Connect(function() 
            instance.BackgroundColor3 = Color3.fromHSV(0,0,1)
        end)

        local entity = world.entity(Vector2.new(i,j))--world.Entity.Register( tostring(Vector2.new(i,j)) )
        --print(entity)
        if (entity ~= nil) then
            --local component = inventory_cellFlag.add(entity, instance)
            --print(component)

            itemCells[i][j] = entity
        end

        --print("iterate")
    end
end
print(itemCells)

local itemItems = {}

--local testItemScale = Vector2.new(1,1)

if true then
    local instance : GuiObject = screenGui.mainFrame.inventoryFrame.prefabs.itemButton:Clone()
    instance.Parent = screenGui.mainFrame.inventoryFrame.itemStorage
    instance.Position = UDim2.fromScale((1-0.5)/10,(1-0.5)/10)
    instance.Size = UDim2.fromScale(1/10,1/10)
    instance.BackgroundTransparency = 0

    local entity = world.entity()
    if (entity ~= nil) then
        local component = inventory_item.add(entity, {Vector2.new(1,1)}, instance)
        --print(component)

        itemItems[1] = entity
    end
    --print(itemItems)
end
local templates : GuiObject = screenGui.mainFrame.inventoryFrame.itemStorage:GetChildren()













