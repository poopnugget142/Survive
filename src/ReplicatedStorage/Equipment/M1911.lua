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
local Workspace = game:GetService("Workspace")

local Remotes = ReplicatedStorage.Remotes
local Assets = ReplicatedStorage.Assets

local EquipmentStates = require(ReplicatedStorage.Scripts.States.Equipment)
local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)
local GunModule = require(ReplicatedStorage.Scripts.Class.Gun)
local Enums = require(ReplicatedStorage.Scripts.Enums)

local GunEnum = Enums.Gun.M1911

local Attack : RemoteEvent = Remotes.Custom.Attack
local SetEquipmentModel : RemoteEvent = Remotes.SetEquipmentModel

local Player = Players.LocalPlayer

local Module = {}

Module.Give = function(Entity)
    local Model = Assets.Guns.M1911:Clone()
    EquipmentStates.LoadingItem.add(Entity, Model)

    local Handle = Model.Handle
    local Grip = Handle.Grip

    local Character = Player.Character

    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

    Model.Parent = Character
    Grip.Part1 = Character.RightHand

    --IK WILL MOVE SOMEWEHRE ELSE LATER TRUST ME THIS IS TOO LONG
    --IK Attachments
    local IKGoal = Instance.new("Attachment")
    IKGoal.Parent = HumanoidRootPart
    IKGoal.Position = Vector3.new(0.5, 0.5, -1.5)
    IKGoal.CFrame *= CFrame.Angles(math.rad(90), 0, 0)
    IKGoal.Name = "IKGoal"

    local Pole = Instance.new("Attachment")
    Pole.Parent = HumanoidRootPart
    Pole.Position = Vector3.new(10, 0, 1)
    Pole.Name = "Pole"

    --[[
        note from yours truly
        i commented out your constraints because they dont really seem to be doing much
            (the arm and the elbow dont connect very well?)
        
        i advise hard coding some rotation adjustments instead
    ]]

    --Elbow Constraint

    local RightElbowConstraint = Instance.new("HingeConstraint")
    RightElbowConstraint.Visible = true
    RightElbowConstraint.Parent = Character.RightLowerArm
    RightElbowConstraint.Name = "RightElbowConstraint"

    local RightElbowConstraintAttachment0 = Instance.new("Attachment")
    RightElbowConstraintAttachment0.Parent = Character.RightUpperArm.RightElbowRigAttachment

    local RightElbowConstraintAttachment1 = Instance.new("Attachment")
    RightElbowConstraintAttachment1.Parent = Character.RightLowerArm.RightElbowRigAttachment

    RightElbowConstraintAttachment1.CFrame = RightElbowConstraintAttachment0.CFrame

    RightElbowConstraint.Attachment0 = RightElbowConstraintAttachment0
    RightElbowConstraint.Attachment1 = RightElbowConstraintAttachment1

    --Wrist Constraint
    
    local RightWristConstraint = Instance.new("BallSocketConstraint")
    RightWristConstraint.Parent = Character.RightHand
    RightWristConstraint.Name = "LeftWristConstraint"

    local RightWristConstraintAttachment0 = Instance.new("Attachment")
    RightWristConstraintAttachment0.CFrame *= CFrame.Angles(0, math.rad(-180), math.rad(-90))
    RightWristConstraintAttachment0.Parent = Character.RightLowerArm.RightWristRigAttachment

    local RightWristConstraintAttachment1 = Instance.new("Attachment")
    RightWristConstraintAttachment1.Parent = Character.RightHand.RightWristRigAttachment

    RightWristConstraintAttachment1.CFrame = RightWristConstraintAttachment0.CFrame

    RightWristConstraint.Attachment0 = RightWristConstraintAttachment0
    RightWristConstraint.Attachment1 = RightWristConstraintAttachment1

    RightWristConstraint.LimitsEnabled = true
    RightWristConstraint.UpperAngle = 80
    
    --IK Control Set up
    local IKControl = Instance.new("IKControl")
    IKControl.Name = "RightArmControl"
    IKControl.SmoothTime = 0.1
    IKControl.Pole = Pole

    IKControl.ChainRoot = Character.RightUpperArm
    IKControl.EndEffector = Character.RightHand

    IKControl.Type = Enum.IKControlType.Transform
    IKControl.Target = IKGoal
    IKControl.Parent = Character.Humanoid
end

Module.ServerGotItemID = function(Entity, ItemID)
    local shooting = false

    local EquipmentData = EquipmentStates.World.get(Entity)

    local Model = EquipmentData.Model
    
    KeyBindings.BindAction("Attack", Enum.UserInputState.Begin, function()
        shooting = true
        local deviation = Vector3.zero

        while shooting do
            task.wait(60/600)
            local Character = Player.Character
            --local HumanoidRootPart = Character.Model.PrimaryPart
            local HumanoidRootPart = Character.PrimaryPart
            local Origin = Model.Muzzle.Position

            local BulletResult = GunModule.BulletShoot(Origin)

            --AlphaPart.Spawn(CastBehaviour, Origin, TerrainResult.Position * Vector3.new(1,0,1) + Origin * Vector3.yAxis, 200)

            if not BulletResult.TerrainResult then continue end

            GunModule.CreateTracer(Origin, BulletResult.TerrainResult.Position*Vector3.new(1,0,1) + Origin*Vector3.yAxis, GunEnum, Enums.Bullet["9mmTracer"])

            Attack:FireServer(ItemID, BulletResult.TerrainResult.Position, BulletResult.HitCharacter)
        end
    end)

    KeyBindings.BindAction("Attack", Enum.UserInputState.End, function()
        shooting = false
    end)
end

Module.Equip = function(Entity)
    print("Equiped Pistol")
    --SetEquipmentModel:FireServer(ItemID)
end

Module.ServerLoadModel = function(Entity, ItemModel : Model)
    
end

return Module