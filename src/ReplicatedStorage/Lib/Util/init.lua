local PlayerService = game:GetService("Players")

local Camera = workspace.CurrentCamera

local Module = {}

Module.EasyStewReturn = function (Factory, Entity : any, Item : any)
    return Item
end

Module.GetAllPlayersExcept = function(ThesePlayers : {Player})
    local GoodPlayers = {}

    for i, Player in PlayerService:GetPlayers() do
        if table.find(ThesePlayers, Player) then continue end

        table.insert(GoodPlayers, Player)
    end

    return GoodPlayers
end :: {Player}

local CacheScreenPosition
local CacheOut

Module.CameraExtrapolate = function(ScreenPosition: Vector2)
    if ScreenPosition == CacheScreenPosition then return CacheOut end --only compute if the mouse moves

    local YDelta = Camera.CFrame.Position.Y
    CacheScreenPosition = ScreenPosition

    local Direction = Camera:ScreenPointToRay(CacheScreenPosition.X, CacheScreenPosition.Y, 1).Direction
    CacheOut = Camera.CFrame.Position - Direction/Direction.Y*YDelta
    
    return CacheOut
end

Module.MathSummation = function(Values : table | number)
    local out = 0
    if not Values then return out end
    for _, Value : number in Values do
        out += Value
    end
    return out
end

return Module