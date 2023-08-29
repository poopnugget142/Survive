local PlayerService = game:GetService("Players")

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

return Module