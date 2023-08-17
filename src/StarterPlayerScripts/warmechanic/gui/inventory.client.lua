--[[
    notetaking

    store item indices in stew components at positions, makes it easy to check item overlap

    rehash modulo math later to be in terms of inventory frame size rather than screen size,
        so conversions dont need to be done between them
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
local world = stew.World.Create()

local assets = {
     "mainFrame"
    --,"inventoryFrame"
}

for a, asset in assets do
    screenGui:WaitForChild(asset)
end

world.Component.Build("inventory_itemCell", {
    Constructor = function(Entity : any, name : string, frame : Frame)
        return 
        {
            cellPosition = Entity
            ,_ = nil --no names
            ,itemIndex = nil
            ,frame = frame
        }
    end
})

local itemCells = {}
for i = 0, 10 do
    for j = 0, 10 do
        if not itemCells[i] then
			itemCells[i] = {}
		end

        local instance : GuiObject = screenGui.mainFrame.inventoryFrame.prefabs.itemCell:Clone()
        instance.Parent = screenGui.mainFrame.inventoryFrame.cellStorage
        instance.Position = UDim2.fromScale(0.25+i/20,0.25+j/20)
        instance.BackgroundTransparency = 0

        local entity = world.Entity.Create()--world.Entity.Register( tostring(Vector2.new(i,j)) )
        --print(entity)
        if (entity ~= nil) then
            local component = world.Component.Create(entity, "inventory_itemCell", instance)
            print(component)

            itemCells[i][j] = entity
        end

        --[[
        local instance : GuiObject = screenGui.mainFrame.inventoryFrame.prefabs.itemCell:Clone()
        instance.Parent = screenGui.mainFrame.inventoryFrame.cellStorage
        instance.Position = UDim2.fromScale(0.25+i/20,0.25+j/20)
        instance.BackgroundTransparency = 0
        ]]

        --table.insert(templates, instance)
        print("iterate")
    end
end
print(itemCells)














































--inventory manipulation
--mouse enter and mouse leave
local templates : GuiObject = screenGui.mainFrame.inventoryFrame.itemStorage:GetChildren()
--screenGui.mainFrame.inventoryFrame.Position = UDim2.fromOffset(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)

local mouse = player:GetMouse()
local hovering = nil
local itemScale = Vector2.new(2,2)
local cellPosition = Vector2.new(10,10)
local component = nil
local picking = nil
local clickPos = UDim2.fromScale(0,0)
local startPos = UDim2.fromScale(0,0)
local startCells = {}



local hoverEvents = {}
local ActivateButtons = function () --enable modification of the hovering variable
    for _, template in templates do    
        table.insert(hoverEvents,template.MouseEnter:Connect(function() hovering = template end))
        table.insert(hoverEvents,template.MouseLeave:Connect(function() hovering = nil end))
    end
end
local DeactivateButtons = function () --disable modification of the hovering variable (the player picks an item)
    for _, template in templates do    
        hoverEvents[1]:Disconnect()
        hoverEvents[2]:Disconnect()
        table.remove(hoverEvents, 2)
        table.remove(hoverEvents, 1)
    end
end
ActivateButtons()


--[==[
ItemPick = function(item)
    picking = item

    startPos = picking.Position
	clickPos = userInputService:GetMouseLocation()

    --DeactivateButtons()
    --[[
    local hold = runService.RenderStepped:Connect(function()
        --templates[1].Position = UDim2.fromOffset(mouse.X, mouse.Y) 
        if (picking == nil) then
            return
        end
        
        if clickPos and startPos then
            picking.Position = UDim2.fromOffset(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y)
        end
    end)
    ]]
    while picking do
        if clickPos and startPos then
            picking.Position = UDim2.fromOffset(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y)
        end
        task.wait()
    end


    --repeat task.wait() until picking == nil
    --hold:Disconnect()
    --ActivateButtons()

    return ItemPut()
end

ItemPut = function()
    component = world.Component.Get( itemCells[cellPosition.X-5][cellPosition.Y-5], "inventory_itemCell")
    if (component ~= nil) then
        print(component)
        
    end

    

    local testScale = Vector2.new(2,2)
    cellPosition = Vector2.new(
            (math.round(hovering.AbsolutePosition.X/cam.ViewportSize.X*20+0.5) -- +0.5 added due to roblox weirdness, check later in case of bugs
                + select(2, math.modf((testScale.X+1)/2)) --use modulo to determine whether an item should exist on or in between cells
            )
            ,(math.round(hovering.AbsolutePosition.Y/cam.ViewportSize.Y*20+2)
                + select(2, math.modf((testScale.X+1)/2))
            )
        )

    hovering.Position = UDim2.fromScale(cellPosition.X/20, cellPosition.Y/20)
    print(Vector2.new(cellPosition.X, cellPosition.Y))

    component = world.Component.Get( itemCells[cellPosition.X-5][cellPosition.Y-5], "inventory_itemCell")
    if (component ~= nil) then
        print(component)
        component.frame.BackgroundColor3 = Color3.fromHSV(0,0,1)
    end

    return
end
]==]

roundItemPosition = function()
    return Vector2.new(
        math.round( --X
            (hovering.AbsolutePosition.X/cam.ViewportSize.X+0.025)*20
        ) + select(2, math.modf((itemScale.X-1)/2))
        ,math.round( --Y
        (hovering.AbsolutePosition.Y/cam.ViewportSize.Y+0.05)*20 + 1
        ) + select(2, math.modf((itemScale.Y-1)/2))
    )
end
itemCellsCheck = function(roundedPosition)
    local output = {}

    for i = 1, itemScale.X, 1 do
        local shiftX = i - ((itemScale.X-1)/2) - 1
        for j = 1, itemScale.Y, 1 do
            

            local shiftY = j - ((itemScale.Y-1)/2) - 1
            local newCellPosition = Vector2.new(
                    roundedPosition.X + shiftX -5
                    ,roundedPosition.Y + shiftY -5
            )
            print(newCellPosition)


            table.insert(output, newCellPosition)
        end
    end

    return output
end

ItemPick = function(item)
    picking = item

    startPos = picking.Position
	clickPos = userInputService:GetMouseLocation()

    local roundedPosition = roundItemPosition()

    startCells = itemCellsCheck(roundedPosition)

    while picking do
        if clickPos and startPos then
            picking.Position = UDim2.fromOffset(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y)
        end
        task.wait()
    end

    return ItemPut()
end

ItemPut = function()
    local startComponents = {}
    for c, cell in startCells do
        local component = world.Component.Get(itemCells[cell.X][cell.Y], "inventory_itemCell")
        if (component == nil) then
            break
        end
        print(component)
        table.insert(startComponents, component)
        --component.frame.BackgroundColor3 = Color3.fromHSV(0,0,0.505)
    end

    local roundedPosition = roundItemPosition()
    hovering.Position = UDim2.fromScale(roundedPosition.X/20, roundedPosition.Y/20)
    local cells = itemCellsCheck(roundedPosition)

    for c, cell in cells do
        local component = world.Component.Get(itemCells[cell.X][cell.Y], "inventory_itemCell")
        if (component ~= nil) then
            print(component)
            component.frame.BackgroundColor3 = Color3.fromHSV(0,0,1)
        end
    end
end



userInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if hovering and not picking then
            ItemPick(hovering)
        else
            picking = nil
        end
    end
end)

--[[
userInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if picking then picking = false end
	end
end)
]]