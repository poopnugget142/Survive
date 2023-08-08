local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemsFolder = ReplicatedStorage.Scripts.Items

local Remotes = ReplicatedStorage.Remotes

local GiveRemote : RemoteEvent = Remotes.Give

GiveRemote.OnClientEvent:Connect(function(ItemName : string)
    local ItemModule = ItemsFolder:FindFirstChild(ItemName)

    if not ItemModule then
        error(ItemName.." is not a valid weapon module")
    end
    
    require(ItemModule).Give()
end)