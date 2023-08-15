--[[
    notetaking

    store item indices in stew components at positions, makes it easy to check item overlap

]]
--initialise dependencies
local StarterPlayer = game:GetService("StarterPlayer")
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

--[[
screenGui.mainFrame.inventoryFrame.TextButton.MouseButton1Down:Connect(function()
    print("Hello!")
    local object : Frame = screenGui.mainFrame.inventoryFrame.TextButton

    while true do
        local mouse = userInputService:GetMouseLocation()
        object.Position = UDim2.new(
            UDim.new(mouse/cam.ViewportSize.X,0),
            UDim.new(mouse/cam.ViewportSize.Y,0)
        )
        task.wait()
    end
end)
]]

local templates : GuiObject = screenGui.mainFrame.inventoryFrame.holder:GetChildren()


local mouse = player:GetMouse()
local hovering = false
local clicking = false
local clickPos = UDim2.fromScale(0,0)
local startPos = UDim2.fromScale(0,0)

--mouse enter and mouse leave
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

local delta
userInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if hovering then	
			clicking = true				
			
			startPos = hovering.Position
			clickPos =	userInputService:GetMouseLocation()
			
			local hold = runService.RenderStepped:Connect(function()
				--templates[1].Position = UDim2.fromOffset(mouse.X, mouse.Y) 
				
				if clickPos and startPos then
					local delta = userInputService:GetMouseLocation() - clickPos
					hovering.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + math.round(delta.X/50)*50
                        , startPos.Y.Scale, startPos.Y.Offset + math.round(delta.Y/50)*50
                    )
				end

			end)	
            DeactivateButtons()

            ----
			repeat task.wait() until clicking == false
            ----

            local tempCheck = UDim2.new(
                startPos.X.Scale, startPos.X.Offset-- + math.round(-100/50)*50
                , startPos.Y.Scale, startPos.Y.Offset-- + math.round(0/50)*50
            )
            if hovering.Position ~= tempCheck then --condition for denying an inventory transaction
                hovering.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset
                    , startPos.Y.Scale, startPos.Y.Offset
                )   
            end

			hold:Disconnect()
            ActivateButtons()

		end
		
	end
end)

userInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if clicking then clicking = false end
	end
end)