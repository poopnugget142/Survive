--[[
    notetaking

    seperate spread into mechanical spread and deviation (recoil) later on
        im thinking deviation has a velocity / acceleration that changes as the player fires the gun
        if you were to equip a laser pointer, youd be able to see where the next bullet will go and account for spread

    update backward raycasting to consider circle size
]]


--initialise dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage.Remotes

local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)
local GunModule = require(ReplicatedStorage.Scripts.Class.Gun)
local Enums = require(ReplicatedStorage.Scripts.Enums)

local GunEnum = Enums.Gun.M1911

local Attack : RemoteEvent = Remotes.Custom.Attack
local SetEquipmentModel : RemoteEvent = Remotes.SetEquipmentModel

local Player = Players.LocalPlayer

local Module = {}

Module.Give = function(Entity, ItemModel)

end

Module.ServerGotItemID = function(Entity, ItemID)
    local shooting = false


    KeyBindings.BindAction("Attack", Enum.UserInputState.Begin, function()
        shooting = true
        local deviation = Vector3.zero

        while shooting do
            --print(shooting)
            task.wait(60/600)
            local Character = Player.Character
            --local HumanoidRootPart = Character.Model.PrimaryPart
            local HumanoidRootPart = Character.PrimaryPart
            local Origin = HumanoidRootPart.Position

            local BulletResult = GunModule.BulletShoot(Origin)

            --AlphaPart.Spawn(CastBehaviour, Origin, TerrainResult.Position * Vector3.new(1,0,1) + Origin * Vector3.yAxis, 200)

            GunModule.CreateTracer(Origin, BulletResult.TerrainResult.Position, GunEnum, Enums.Bullet["9mmTracer"])

            Attack:FireServer(ItemID, BulletResult.TerrainResult.Position, BulletResult.HitCharacter)
        end
    end)

    KeyBindings.BindAction("Attack", Enum.UserInputState.End, function()
        shooting = false
        --print(shooting)
    end)
end

Module.Equip = function(Entity)
    print("Equiped Pistol")
    --SetEquipmentModel:FireServer(ItemID)
end

Module.ServerLoadModel = function(Entity, ItemModel : Model)
    
end

return Module