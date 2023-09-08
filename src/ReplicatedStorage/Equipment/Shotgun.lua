--initialise dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Remotes = ReplicatedStorage.Remotes
local Assets = ReplicatedStorage.Assets

local EquipmentStates = require(ReplicatedStorage.Scripts.States.Equipment)
local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)
local PlayerModule = require(ReplicatedStorage.Scripts.Class.Player)
local GunModule = require(ReplicatedStorage.Scripts.Class.Gun)
local Enums = require(ReplicatedStorage.Scripts.Enums)

local CharactersFolder = workspace:WaitForChild("Characters")
local JunkFolder = workspace:WaitForChild("JunkFolder")
local TerrainParams = RaycastParams.new()
TerrainParams.IgnoreWater = true
TerrainParams.FilterType = Enum.RaycastFilterType.Exclude
TerrainParams.FilterDescendantsInstances = {JunkFolder, CharactersFolder}

local GunEnum = Enums.Gun.Shotgun

local Attack : RemoteEvent = Remotes.Custom.Attack
local SetEquipmentModel : RemoteEvent = Remotes.SetEquipmentModel

local Player = Players.LocalPlayer

local Module = {}

Module.Give = function(Entity)
    local Model = Assets.Guns.Shotgun:Clone()
    EquipmentStates.LoadingItem.add(Entity, Model)

    local Handle = Model.Handle
    local Grip = Handle.Grip

    local Character = Player.Character

    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

    Model.Parent = Character
    Grip.Part1 = Character.RightHand

    --IK WILL MOVE SOMEWEHRE ELSE LATER TRUST ME THIS IS TOO LONG
    --IK Attachments
    local IKGoalR = Instance.new("Attachment")
    IKGoalR.Name = "IKGoalR"
    --[[
    IKGoalR.Parent = HumanoidRootPart
    IKGoalR.Position = Vector3.new(0.7, 0, -0.7)
    IKGoalR.CFrame *= CFrame.Angles(math.rad(90), math.rad(0), math.rad(0))
    ]]
    IKGoalR.Parent = Character.UpperTorso
    IKGoalR.Position = Vector3.new(0.7, 0, 0.5)
    IKGoalR.CFrame *= CFrame.Angles(math.rad(90), math.rad(0), math.rad(0))

    local PoleR = Instance.new("Attachment")
    PoleR.Parent = HumanoidRootPart
    PoleR.Position = Vector3.new(10, 0, 10)
    PoleR.Name = "PoleR"

    
    local IKGoalL = Instance.new("Attachment")
    IKGoalL.Name = "IKGoalL"
    --[[
    IKGoalL.Parent = HumanoidRootPart
    IKGoalL.Position = Vector3.new(0, 0.5, -2.5)
    IKGoalL.CFrame *= CFrame.Angles(math.rad(0), math.rad(0), math.rad(90))
    ]]
    IKGoalL.Parent = Character.RightHand
    IKGoalL.Position = Vector3.new(0, -2, 0)
    IKGoalL.CFrame *= CFrame.Angles(math.rad(-90), math.rad(0), math.rad(90))

    local PoleL = Instance.new("Attachment")
    PoleL.Parent = HumanoidRootPart
    PoleL.Position = Vector3.new(-10, 0, -10)
    PoleL.Name = "PoleL"

    local HeadBase = Character.Head.Neck.C0
    RunService.RenderStepped:Connect(function(deltaTime)
        local MouseCast = PlayerModule.MouseCast(TerrainParams, 10000)
        local Aimpoint = MouseCast.Position - IKGoalR.WorldCFrame.Position + Vector3.new(0,4,0)
        local gunCFrame = CFrame.lookAt(Vector3.zero, Aimpoint) * CFrame.Angles(math.rad(90), math.rad(0), math.rad(0))
        local lookUpFactor = (IKGoalR.WorldCFrame.Rotation.ZVector.Y+1) -- -1 to 1 based on whether aiming up or down
        IKGoalR.WorldCFrame = gunCFrame
        IKGoalR.Position = Vector3.new(0.7, -0.5, -0.3) + Vector3.new(0,0,-1)*lookUpFactor
        --print(IKGoalR.WorldCFrame.Rotation.XVector)
        --print(IKGoalR.WorldCFrame.Rotation.YVector)
        --print(IKGoalR.WorldCFrame.Rotation.ZVector)
        --Character.Head.Neck.C0 = HeadBase * CFrame.lookAt(Vector3.zero, Aimpoint) * CFrame.Angles(math.rad(0), math.rad(90) + math.atan2(Aimpoint.Z, Aimpoint.X), math.rad(0))
    end)


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

    --Elbow Constraint
    local LeftElbowConstraint = Instance.new("HingeConstraint")
    LeftElbowConstraint.Visible = true
    LeftElbowConstraint.Parent = Character.LeftLowerArm
    LeftElbowConstraint.Name = "LeftElbowConstraint"

    local LeftElbowConstraintAttachment0 = Instance.new("Attachment")
    LeftElbowConstraintAttachment0.Parent = Character.LeftUpperArm.LeftElbowRigAttachment

    local LeftElbowConstraintAttachment1 = Instance.new("Attachment")
    LeftElbowConstraintAttachment1.Parent = Character.LeftUpperArm.LeftElbowRigAttachment

    LeftElbowConstraintAttachment1.CFrame = LeftElbowConstraintAttachment0.CFrame

    LeftElbowConstraint.Attachment0 = LeftElbowConstraintAttachment0
    LeftElbowConstraint.Attachment1 = LeftElbowConstraintAttachment1

    --Wrist Constraint
    local LeftWristConstraint = Instance.new("BallSocketConstraint")
    LeftWristConstraint.Parent = Character.LeftHand
    LeftWristConstraint.Name = "LeftWristConstraint"

    local LeftWristConstraintAttachment0 = Instance.new("Attachment")
    LeftWristConstraintAttachment0.CFrame *= CFrame.Angles(0, math.rad(-180), math.rad(-90))
    LeftWristConstraintAttachment0.Parent = Character.LeftLowerArm.LeftWristRigAttachment

    local LeftWristConstraintAttachment1 = Instance.new("Attachment")
    LeftWristConstraintAttachment1.Parent = Character.LeftHand.LeftWristRigAttachment

    LeftWristConstraintAttachment1.CFrame = LeftWristConstraintAttachment0.CFrame

    LeftWristConstraint.Attachment0 = LeftWristConstraintAttachment0
    LeftWristConstraint.Attachment1 = LeftWristConstraintAttachment1

    LeftWristConstraint.LimitsEnabled = true
    LeftWristConstraint.UpperAngle = 80

    --IK Control Set up
    local IKControlR = Instance.new("IKControl")
    IKControlR.Name = "RightArmControl"
    IKControlR.SmoothTime = 0.2
    IKControlR.Pole = PoleR

    IKControlR.ChainRoot = Character.RightUpperArm
    IKControlR.EndEffector = Character.RightHand

    IKControlR.Type = Enum.IKControlType.Transform
    IKControlR.Target = IKGoalR
    IKControlR.Parent = Character.Humanoid


    local IKControlL = Instance.new("IKControl")
    IKControlL.Name = "LeftArmControl"
    IKControlL.SmoothTime = 0.01
    IKControlL.Pole = PoleL

    IKControlL.ChainRoot = Character.LeftUpperArm
    IKControlL.EndEffector = Character.LeftHand

    IKControlL.Type = Enum.IKControlType.Transform
    IKControlL.Target = IKGoalL
    IKControlL.Parent = Character.Humanoid
end

Module.ServerGotItemID = function(Entity, ItemID)
    local shooting = false
    local deviation = Vector2.zero
    local cooldown = 0
    local firerate = 60/100

    local DeviationRecovery = function(deviationRecovery)
        local deltaTime = task.wait()
        if (deviation.Magnitude > 0) then deviation -= (deviation.Unit*math.min(deviationRecovery, deviation.Magnitude)) * (deltaTime/(1/60)) end
        --print (deviation)
        cooldown -= deltaTime
    end

    local EquipmentData = EquipmentStates.World.get(Entity)

    local Model = EquipmentData.Model
    
    KeyBindings.BindAction("Attack", Enum.UserInputState.Begin, function()
        shooting = true
        while shooting do
            if cooldown <= 0 then
                local Origin = Model.Muzzle.Position
                local MouseCast = PlayerModule.MouseCast(TerrainParams, 10000)
                --print(MouseCast.Position)
                local Displacement = MouseCast.Position - Origin
                local DisplacementRight = Vector3.new(-Displacement.Z, 0, Displacement.X)

                
                local AimDeviation = (Displacement.Unit*deviation.Y + DisplacementRight.Unit*deviation.X)*Displacement.Magnitude*Vector3.new(1,0,1) or Vector3.zero
                --print((Displacement.Unit*deviation.Y + DisplacementRight.Unit*deviation.X))
                local DeviatedAim = MouseCast.Position + AimDeviation
                if (DeviatedAim.Magnitude == nil) then DeviatedAim = MouseCast.Position end
                --print(DeviatedAim)

                --distance values to modify shotgun speed
                local MinDist = math.huge 
                local MaxDist = 1 --never divide by 0
                local TracerTargets = {}
                for i = 1, 10, 1 do
                    local BulletResult = GunModule.BulletShoot(Origin, DeviatedAim)

                    if not BulletResult.TerrainResult then continue end

                    local Distance = BulletResult.TerrainResult.Distance
                    if (Distance < MinDist) then
                        MinDist = Distance
                    elseif (Distance > MaxDist) then
                        MaxDist = Distance
                    end

                    table.insert(TracerTargets, BulletResult.TerrainResult)

                    local NpcId
                    if BulletResult.HitCharacter then
                        NpcId = tonumber(BulletResult.HitCharacter.Name)
                    end

                    Attack:FireServer(ItemID, BulletResult.TerrainResult.Position, NpcId)
                end
                for _, Target in TracerTargets do
                    GunModule.CreateTracer(Origin, Target.Position*Vector3.new(1,0,1) + Origin*Vector3.yAxis, GunEnum, Enums.Bullet["9mmTracer"], Target.Distance/((MaxDist+MinDist)/2)*100+math.random(-100,100)/10 or 100)
                end

                local SpreadPermutations = 10^3
                deviation += Vector2.new( --RECOIL!!!
                    math.random(
                        -0.75*SpreadPermutations
                        ,0.75*SpreadPermutations
                    )/SpreadPermutations
                    ,math.random(
                        0.5*SpreadPermutations
                        ,2*SpreadPermutations
                    )/SpreadPermutations
                ) / math.clamp(deviation.Magnitude+1, 1, math.huge) --reduce recoil impulse with magnitude
                --print(deviation)
                cooldown = firerate
            end
            
            if true then
                DeviationRecovery(.1)
            end
        end
    end)

    KeyBindings.BindAction("Attack", Enum.UserInputState.End, function()
        shooting = false
        repeat 
            if true then
                DeviationRecovery(.1)
            end
        until (--[[cooldown <= 0 or]] shooting)
    end)
end

Module.Equip = function(Entity)
    print("Equipped Shotgun")
    --SetEquipmentModel:FireServer(ItemID)
end

Module.ServerLoadModel = function(Entity, ItemModel : Model)
    
end

return Module