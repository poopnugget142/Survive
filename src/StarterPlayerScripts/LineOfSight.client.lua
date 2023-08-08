local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Player = game.Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = Player.PlayerGui

local FrameMatrix = {}

local ScreenSize = 1000
local PixelSize = 1/ScreenSize

--Draws pixels horizontally given an x and y starting point and a X end point
local function DrawXLine(StartX, StartY, EndX)
    StartX = math.floor(StartX)
    EndX = math.floor(EndX)

    local FrameLength = EndX-StartX

    local Frame = Instance.new("Frame")
    Frame.BorderSizePixel = 0
    Frame.BackgroundTransparency = 0
    Frame.Visible = true
    Frame.BackgroundColor3 = Color3.new(0, 0, 0)
    Frame.Size = UDim2.new(FrameLength/ScreenSize, 0, PixelSize, 0)
    Frame.Position = UDim2.new(StartX/ScreenSize, 0, StartY/ScreenSize, 0)
    Frame.Parent = ScreenGui

    --[[
    for X = StartX, EndX do
        
        local Frame = FrameMatrix[X][StartY]
        Frame.Visible = true
    end
    ]]
end

local function fillBottomFlatTriangle(v1 : Vector2, v2 : Vector2, v3 : Vector2)
    --Calculate slope from top of triangle leading down to bottom left
    local invslope1 = (v2.X - v1.X) / (v2.Y - v1.Y)
    --Do the same for the bottom right
    local invslope2 = (v3.X - v1.X) / (v3.Y - v1.Y)
    
    --Track the left and right edges of the triangle as we move down
    local curx1 = v1.X
    local curx2 = v1.X

    --Start at top of triangle and move down it drawing lines until we reach the bottom
    local scanlineY = v1.Y
    while scanlineY <= v2.Y do
        task.wait()

        DrawXLine(curx1, scanlineY, curx2)

        curx1 += invslope1
        curx2 += invslope2

        scanlineY += 1
    end
end

 	

local function fillTopFlatTriangle(v1 : Vector2, v2 : Vector2, v3 : Vector2)
     --Calculate slope from bottom to the top left
     local invslope1 = (v3.X - v1.X) / (v3.Y - v1.Y);
     --Do the same for the top right
     local invslope2 = (v3.X - v2.X) / (v3.Y - v2.Y)
     
     --Track the left and right edges of the triangle as we move up
     local curx1 = v3.X
     local curx2 = v3.X
 
     --Start at bottom of triangle and move up it drawing lines until we reach the top
     local scanlineY = v3.Y
     while scanlineY > v1.Y do
         DrawXLine(curx1, scanlineY, curx2)
 
         curx1 -= invslope1
         curx2 -= invslope2
 
         scanlineY -= 1
     end
end



local Character = workspace:WaitForChild("Knight")
local RootPart = Character.PrimaryPart

v1 = Vector2.new(ScreenSize/4, 0)
v2 = Vector2.new(ScreenSize*0.75, 0)
v3 = Vector3.new(ScreenSize/2, ScreenSize/2)

fillTopFlatTriangle(v1, v2, v3)


