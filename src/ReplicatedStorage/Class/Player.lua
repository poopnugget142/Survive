local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Module = {}

Module.MouseCast = function(RaycastParams : RaycastParams, RayLength) : RaycastResult
    local Mouse = Player:GetMouse()
    local UnitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local RaycastResult = workspace:Raycast(UnitRay.Origin, UnitRay.Direction * RayLength, RaycastParams)
    return RaycastResult
end

return Module