local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local JunkFolder = workspace:WaitForChild("JunkFolder")

local CharacterStates = require(ReplicatedStorage.Scripts.CharacterStates)
local KeyBindings = require(ReplicatedStorage.Scripts.KeyBindings)
local Ballistics = require(ReplicatedStorage.Scripts.Ballistics)

local Player = Players.LocalPlayer

local Mouse = Player:GetMouse()

local ZeroY = Vector3.new(1, 0, 1)

local Module = {}

Module.Give = function()
    print("Huhrah")
    local Character : Model = Player.Character

    local Caster : Ballistics.Caster = Ballistics.CreateCaster()

    local Round = Instance.new("Part")
    Round.CanCollide = false
    Round.CastShadow = false

    Instance.new("Attachment")

    local CasterParams = RaycastParams.new()
    CasterParams.FilterType = Enum.RaycastFilterType.Blacklist
    CasterParams.IgnoreWater = true
    CasterParams.FilterDescendantsInstances = {Character, JunkFolder}

    local CastBehavior = Ballistics.CreateCastBehavior()
    CastBehavior.RaycastParams = CasterParams
    CastBehavior.Container = JunkFolder
    CastBehavior.CosmeticBulletTemplate = Round
    CastBehavior.Acceleration = Vector3.new(0,0,0)

    KeyBindings.BindAction("Attack", Enum.UserInputState.Begin, function()
        --Check if character is valid
    
        local Character = Player.Character
    
        local IsAttacking = CharacterStates.Component.Get(Character, "Attacking")
    
        if IsAttacking then return end

        local HumanoidRootPart = Character.Model.PrimaryPart

        local Orgin = HumanoidRootPart.Position

        local Direction = CFrame.new(Orgin, Mouse.Hit.Position).LookVector*ZeroY

        local Bullet = Ballistics.SpawnBullet(Caster, CastBehavior, Orgin, Direction*20)

    end)
end

return Module