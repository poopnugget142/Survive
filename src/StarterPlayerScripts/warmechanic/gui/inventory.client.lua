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
local cellPosition = Vector2.new(10,10)
local component = nil
local clicking = false
local clickPos = UDim2.fromScale(0,0)
local startPos = UDim2.fromScale(0,0)



local hoverEvents = {}
local ActivateButtons = function ()
    for _, template in templates do    
        table.insert(hoverEvents,template.MouseEnter:Connect(function() hovering = template end))
        table.insert(hoverEvents,template.MouseLeave:Connect(function() hovering = nil end))
    end
end
local DeactivateButtons = function ()
    for _, template in templates do    
        hoverEvents[1]:Disconnect()
        hoverEvents[2]:Disconnect()
        table.remove(hoverEvents, 2)
        table.remove(hoverEvents, 1)
    end
end
ActivateButtons()



Pickup = function()
    clicking = true	

    startPos = hovering.Position
	clickPos = userInputService:GetMouseLocation()

    DeactivateButtons()
    local hold = runService.RenderStepped:Connect(function()
        --templates[1].Position = UDim2.fromOffset(mouse.X, mouse.Y) 
        
        if clickPos and startPos then
            --local delta = userInputService:GetMouseLocation() - clickPos
            --hovering.Position = UDim2.new(
            --    startPos.X.Scale, startPos.X.Offset + delta.X--math.round(delta.X/50)*50
            --    , startPos.Y.Scale, startPos.Y.Offset + delta.Y--math.round(delta.Y/50)*50
            --)
            hovering.Position = UDim2.fromOffset(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y)
        end
    end)
    repeat task.wait() until clicking == false
    hold:Disconnect()
    ActivateButtons()

    return Putdown()
end

Putdown = function()
    component = world.Component.Get( itemCells[cellPosition.X-5][cellPosition.Y-5], "inventory_itemCell")
    if (component ~= nil) then
        print(component)
        component.frame.BackgroundColor3 = Color3.fromRGB(129,129,129)
    end

    local testScale = Vector2.new(1,1)
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
        component.frame.BackgroundColor3 = Color3.fromHSV(0,1,1)
    end

    return
end





local delta
userInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and hovering then
		Pickup()
	end
end)

userInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if clicking then clicking = false end
	end
end)