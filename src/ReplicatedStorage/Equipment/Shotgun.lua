--initialise dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage.Assets

local EquipmentModule = require(script.Parent)
local EquipmentStates = require(ReplicatedStorage.Scripts.States.Equipment)
local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)
local PlayerModule = require(ReplicatedStorage.Scripts.Class.Player)
local GunModule = require(ReplicatedStorage.Scripts.Class.Gun)
local Enums = require(ReplicatedStorage.Scripts.Enums)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local Viewmodel = require(ReplicatedStorage.Scripts.Util.Viewmodel)

local CharactersFolder = workspace:WaitForChild("Characters")
local JunkFolder = workspace:WaitForChild("JunkFolder")
local TerrainParams = RaycastParams.new()
TerrainParams.IgnoreWater = true
TerrainParams.FilterType = Enum.RaycastFilterType.Exclude
TerrainParams.FilterDescendantsInstances = {JunkFolder, CharactersFolder}

local GunEnum = Enums.Gun.Shotgun

local Player = Players.LocalPlayer

local Module = {}

Module.Give = function(Entity)
    EquipmentStates[GunEnum].add(Entity)
    EquipmentStates.Cooldown.add(Entity, 0)
    EquipmentStates.Firerate.add(Entity, 60/100)
    EquipmentStates.Deviation.add(Entity, Vector2.zero)
end

Module.ServerGotItemID = function(Entity, ItemID)

end

Module.Equip = function(Entity)
    local Model = Assets.Guns.Shotgun:Clone()
    EquipmentStates.Model.add(Entity, Model)

    local Handle = Model.Handle
    local Grip = Handle.Grip

    local Character = Player.Character

    Character:WaitForChild("HumanoidRootPart")

    Model.Parent = Character
    Grip.Part1 = Character.RightHand

    Viewmodel.BindRigToCharacter(Character)

    local CharacterEntity = CharacterModule.GetEntityFromCharacter(Character)
    local CharacterData = CharacterStates.World.get(CharacterEntity)

    local IKControllers = CharacterData[CharacterStates.IKControllers]

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

    EquipmentModule.WaitUntilItemID(Entity)

    local EntityData = EquipmentStates.World.get(Entity)

    local ItemID = EntityData[EquipmentStates.ItemID]

    --EquipmentModule.RequestModel(Entity, ItemID)

    KeyBindings.BindAction("Attack", Enum.UserInputState.Begin, function()
        EquipmentStates.Shooting.add(Entity)
    end)

    KeyBindings.BindAction("Attack", Enum.UserInputState.End, function()
        EquipmentStates.Shooting.remove(Entity)
        repeat 
            if true then
                GunModule.DeviationRecovery(Entity, .1)
            end
        until (--[[cooldown <= 0 or]] EquipmentStates.World.get(Entity)[EquipmentStates.Shooting])
    end)
end

Module.Unequip = function(Entity)
    KeyBindings.UnbindAction("Attack", Enum.UserInputState.Begin)
    KeyBindings.UnbindAction("Attack", Enum.UserInputState.End)

    EquipmentStates.Model.remove(Entity)
    EquipmentStates.Shooting.remove(Entity)

    local Character = Player.Character

    Viewmodel.BindRigToCharacter(Character)

    local CharacterEntity = CharacterModule.GetEntityFromCharacter(Character)
    local CharacterData = CharacterStates.World.get(CharacterEntity)

    local IKControllers = CharacterData[CharacterStates.IKControllers]

    local IKControlR, IKControlL = IKControllers["RightHand"], IKControllers["LeftHand"]
    IKControlR.Enabled, IKControlL.Enabled = false, false
end

Module.ServerLoadModel = function(Entity, ItemModel : Model)
    
end

--Shooting
RunService.RenderStepped:Connect(function(deltaTime)
    for Entity in EquipmentStates.World.query{EquipmentStates[GunEnum], EquipmentStates.Shooting} do
        local EntityData = EquipmentStates.World.get(Entity)

        if not EntityData[EquipmentStates.Shooting] then continue end

        local Model = EntityData[EquipmentStates.Model]

        if EntityData[EquipmentStates.Cooldown] > 0 then
            continue
        end

        local Origin = Model.Muzzle.Position
        local MouseCast = PlayerModule.MouseCast(TerrainParams, 10000)
        local Displacement = MouseCast.Position - Origin
        local DisplacementRight = Vector3.new(-Displacement.Z, 0, Displacement.X)
        local Deviation = EntityData[EquipmentStates.Deviation]


        local AimDeviation = (Displacement.Unit*Deviation.Y + DisplacementRight.Unit*Deviation.X)*Displacement.Magnitude*Vector3.new(1,0,1) or Vector3.zero
        local DeviatedAim = MouseCast.Position + AimDeviation
        if (DeviatedAim.Magnitude == nil) then DeviatedAim = MouseCast.Position end


        EquipmentModule.FireCustomAction(Entity, "Attack", DeviatedAim)
        
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
        EntityData[EquipmentStates.Deviation] += Vector2.new( --RECOIL!!!
            math.random(
                -0.75*SpreadPermutations
                ,0.75*SpreadPermutations
            )/SpreadPermutations
            ,math.random(
                0.5*SpreadPermutations
                ,2*SpreadPermutations
            )/SpreadPermutations
        ) / math.clamp(Deviation.Magnitude+1, 1, math.huge) --reduce recoil impulse with magnitude
        EntityData[EquipmentStates.Cooldown] = EntityData[EquipmentStates.Firerate]

        GunModule.DeviationRecovery(Entity, .1)
    end
end)

return Module