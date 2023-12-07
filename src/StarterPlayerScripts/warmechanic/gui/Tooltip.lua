local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer


local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui : ScreenGui = PlayerGui:WaitForChild("HUD")
local Tooltip : Frame = ScreenGui.Tooltip

local CurrentCamera = workspace.CurrentCamera
local ViewportSize = CurrentCamera.ViewportSize


local Module = {}

Module.Position = function(AbsolutePosition : Vector2)
    Tooltip.Position = UDim2.fromOffset(AbsolutePosition.X, AbsolutePosition.Y)

    local TooltipCorner = UDim2.fromScale(
        math.round((AbsolutePosition.X-1) / ViewportSize.X) -- minus 1 offsets to bias bottom right corner
        ,math.round((AbsolutePosition.Y-1) / ViewportSize.Y)
    )

    Tooltip.Background.Position = UDim2.fromScale(0.5, 0.5) - TooltipCorner
end

Module.Label = function(Text : string)
    Tooltip.Background.Text = Text
end

return Module