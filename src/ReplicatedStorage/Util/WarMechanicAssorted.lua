local ReplicatedStorage = game:GetService("ReplicatedStorage")

local module = {}


local Cam = workspace.CurrentCamera
local YDelta = Cam.CFrame.Position.Y
local CacheScreenPosition
local CacheOut
module.CameraExtrapolate = function(ScreenPosition: Vector2)
    if not (Cam or YDelta) then --if we dont have dependencies, cache dependencies
        Cam = workspace.CurrentCamera
        YDelta = Cam.CFrame.Position.Y
    end
    if ScreenPosition ~= CacheScreenPosition then --only compute if the mouse moves
        CacheScreenPosition = ScreenPosition

        local Direction = Cam:ScreenPointToRay(CacheScreenPosition.X, CacheScreenPosition.Y, 1).Direction
        CacheOut = Cam.CFrame.Position - Direction/Direction.Y*YDelta
    end
    
    return CacheOut
end


return module