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
local Assets = ReplicatedStorage.Assets

local ItemStates = require(ReplicatedStorage.Scripts.States.Item)
local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)
local GunModule = require(ReplicatedStorage.Scripts.Class.Gun)
local Enums = require(ReplicatedStorage.Scripts.Enums)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

local GunEnum = Enums.Item.M1911

local Attack : RemoteEvent = Remotes.Custom.Attack
local SetEquipmentModel : RemoteEvent = Remotes.SetEquipmentModel

local Player = Players.LocalPlayer

local Module = {}

Module.Give = function(Entity)
    local Model = Assets.Guns.M1911:Clone()
    ItemStates.LoadingItem.add(Entity, Model)

    local Handle = Model.Handle
    local Grip = Handle.Grip

    local Character = Player.Character

    Character:WaitForChild("HumanoidRootPart")

    Model.Parent = Character
    Grip.Part1 = Character.RightHand

    local CharacterEntity = CharacterModule.GetEntityFromCharacter(Character)
    local CharacterData = CharacterStates.World.get(CharacterEntity)

    local IKControllers = CharacterData.IKControllers

    local IKControlR = IKControllers["RightHand"]
    IKControlR.Enabled = true
    IKControlR.SmoothTime = 0.1

    local IKGoalR = IKControlR.Target
    local PoleR = IKControlR.Pole

    IKGoalR.Position = Vector3.new(0.5, 0.5, -1.5)
    IKGoalR.CFrame *= CFrame.Angles(math.rad(90), 0, 0)

    PoleR.Position = Vector3.new(10, 0, 1)
end

Module.ServerGotItemID = function(Entity, ItemID)
    local shooting = false

    local EquipmentData = ItemStates.World.get(Entity)

    local Model = EquipmentData.Model
    
    KeyBindings.BindAction("Attack", Enum.UserInputState.Begin, function()
        shooting = true
        local deviation = Vector3.zero

        while shooting do
            local Character = Player.Character
            --local HumanoidRootPart = Character.Model.PrimaryPart
            local HumanoidRootPart = Character.PrimaryPart
            local Origin = Model.Muzzle.Position

            local BulletResult = GunModule.BulletShoot(Origin)

            --AlphaPart.Spawn(CastBehaviour, Origin, TerrainResult.Position * Vector3.new(1,0,1) + Origin * Vector3.yAxis, 200)

            if not BulletResult.TerrainResult then continue end

            GunModule.CreateTracer(Origin, BulletResult.TerrainResult.Position*Vector3.new(1,0,1) + Origin*Vector3.yAxis, GunEnum, Enums.Bullet["9mmTracer"])

            local NpcId
            if BulletResult.HitCharacter then
                NpcId = tonumber(BulletResult.HitCharacter.Name)
            end

            Attack:FireServer(ItemID, BulletResult.TerrainResult.Position, NpcId)
            task.wait(60/600)
        end
    end)

    KeyBindings.BindAction("Attack", Enum.UserInputState.End, function()
        shooting = false
    end)
end

Module.Equip = function(Entity)
    print("Equipped Pistol")
    --SetEquipmentModel:FireServer(ItemID)
end

Module.ServerLoadModel = function(Entity, ItemModel : Model)
    
end

return Module