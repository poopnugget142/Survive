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
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

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

    Character:WaitForChild("HumanoidRootPart")

    Model.Parent = Character
    Grip.Part1 = Character.RightHand

    local CharacterEntity = CharacterModule.GetEntityFromCharacter(Character)
    local CharacterData = CharacterStates.World.get(CharacterEntity)

    local IKControllers = CharacterData.IKControllers

    local IKControlR, IKControlL = IKControllers["RightHand"], IKControllers["LeftHand"]
    IKControlR.Enabled, IKControlL.Enabled = true, true
    local IKGoalR, IKGoalL = IKControlR.Target, IKControlL.Target
    local PoleR, PoleL = IKControlR.Pole, IKControlL.Pole

    IKControlL.SmoothTime = 0.001
    IKControlR.SmoothTime = 0.05

    IKGoalR.Position = Vector3.new(0.7, 0, 0.5)
    IKGoalR.CFrame *= CFrame.Angles(math.rad(90), math.rad(0), math.rad(0))

    PoleR.Position = Vector3.new(10, 0, 10)

    IKGoalL.Position = Vector3.new(0, -2, 0)
    IKGoalL.CFrame *= CFrame.Angles(math.rad(-90), math.rad(0), math.rad(90))

    PoleL.Position = Vector3.new(-10, 0, -10)

    local Waist : Motor6D = Character.UpperTorso.Waist
    Waist.C0 *= CFrame.fromOrientation(0,math.rad(-10),math.rad(3))
    local Neck : Motor6D = Character.Head.Neck
    Neck.C0 *= CFrame.fromOrientation(0,math.rad(10),0)

    local HeadBase = Character.Head.Neck.C0
    RunService.RenderStepped:Connect(function(deltaTime)
        local MouseCast = PlayerModule.MouseCast(TerrainParams, 10000)
        local Aimpoint = MouseCast.Position - IKGoalR.WorldCFrame.Position + Vector3.new(0,4,0)
        local gunCFrame = CFrame.lookAt(Vector3.zero, Aimpoint) * CFrame.Angles(math.rad(90), math.rad(0), math.rad(0))
        local lookUpFactor = (IKGoalR.WorldCFrame.Rotation.ZVector.Y+1) -- -1 to 1 based on whether aiming up or down
        IKGoalR.WorldCFrame = gunCFrame
        IKGoalR.Position = Vector3.new(0.7, -0.5, -0.3) + Vector3.new(0,0,-1)*lookUpFactor
        --Character.Head.Neck.C0 = HeadBase * CFrame.lookAt(Vector3.zero, Aimpoint) * CFrame.Angles(math.rad(0), math.rad(90) + math.atan2(Aimpoint.Z, Aimpoint.X), math.rad(0))
    end)
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

                Attack:FireServer(ItemID, DeviatedAim)

                --[[
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
                ]]

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