--[[
    notetaking
    all unrevealed frames along a length will be combined into a long length

    add support for multiple LoS cones

    do some trig (cos) math to fix parallax error at tight angles

    texels and raycasts independent, allow for double the frame count + bilinear filtering

    screen space lighting

]]

-- initialise dependencies
local players : Players = game:GetService("Players")
local runService : RunService = game:GetService("RunService")
local userInputService: UserInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local stew = require(replicatedStorage.Packages.Stew)
local world = stew.world()

local player : Player = players.LocalPlayer
local screenGui : ScreenGui = player.PlayerGui:WaitForChild("ScreenGui")

local cam : Camera = workspace.CurrentCamera
repeat task.wait() until player.Character ~= nil
    local character : Model = player.Character
local root : Part = character:WaitForChild("HumanoidRootPart")
local windowFocused = true


local texelComponent = world.factory("texelComponent", { -- add stuff later
    add = function(_, entity : any, frame : Frame)
        return {
            entity = entity
            ,frame = frame
        }
    end
})

local texelUMax = 120 --maximum number of texels (raycasts) along X axis
local texelVMax = 120 --maximum number of texels (raycasts) along Y axis
local texelU = texelUMax
local texelV = texelVMax

local pixelSize = Vector2.new(3,3) --number of pixels occupying texel
local pixelUMax = 1*texelUMax
local pixelVMax = 1*texelVMax

local pixelMap = {}

if true then
    local i = 1
    for u = 0, pixelUMax do
        for v = 0, pixelVMax do
            local dude = Instance.new("Frame")
            dude.Parent = screenGui:WaitForChild("losFrame")
            dude.Name = tostring(i)
            dude.BorderSizePixel = cam.ViewportSize.Y/pixelVMax
            dude.Transparency = 0.8
    
            --dude.Position = UDim2.new(2,2)
            dude.Position = UDim2.new(
			u/pixelUMax, 
			0, 
			v/pixelVMax, 
			0
		    )
            dude.Size = UDim2.new(
                0--1/pixelUMax
                , 0
                , 0--1/pixelVMax
                , 0
            )
            dude.Interactable = false
            dude.Selectable = false

            dude.MouseEnter:Connect(function()
                print("Bad Dog!")
            end)

            table.insert(pixelMap, texelComponent.add(dude, dude))

            i+=1
        end
        task.wait()
    end
end
print(pixelMap)

while true do
    for _, pixel in pixelMap do
        local frame : Frame = pixel.frame
        frame.BackgroundColor3 = Color3.fromHSV(math.random(0,100)/100,1,1)
    end
    --print("bing!")
    task.wait()
end