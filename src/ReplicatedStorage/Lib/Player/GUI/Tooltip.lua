local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local LocalMouse = LocalPlayer:GetMouse()


local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui : ScreenGui = PlayerGui:WaitForChild("HUD")
local Tooltip : Frame = ScreenGui.Tooltip

local CurrentCamera = workspace.CurrentCamera
local ViewportSize = CurrentCamera.ViewportSize


local Module = {}

Module.Position = function(AbsolutePosition : Vector2?)

    if not AbsolutePosition then
        AbsolutePosition = UserInputService:GetMouseLocation()
    end

    Tooltip.Position = UDim2.fromOffset(AbsolutePosition.X, AbsolutePosition.Y)

    local TooltipCorner = UDim2.fromScale(
        math.round((AbsolutePosition.X-2) / ViewportSize.X) -- minus 2 offsets to bias bottom right corner
        ,math.round((AbsolutePosition.Y-2) / ViewportSize.Y)
    )

    Tooltip.Background.Position = UDim2.fromScale(0.5, 0.5) - TooltipCorner
end

Module.Label = function(Text : string)
    Tooltip.Background.Text = Text
end

Module.Visible = function(Bool : boolean)
    Tooltip.Visible = Bool
end

return Module