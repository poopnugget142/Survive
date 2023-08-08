local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes

local GiveRemote : RemoteEvent = Remotes.Give

local ItemsFolder = ServerStorage.Scripts.Items

local Module = {}

Module.Give = function(Player : Player, ItemName : string)
    local ItemModule = ItemsFolder:FindFirstChild(ItemName)

    if not ItemModule then
        error(ItemName.." is not a valid weapon module")
    end

    GiveRemote:FireClient(Player, "Gun")
    print("Server gave!")
    
    require(ItemModule).Give()
end

return Module