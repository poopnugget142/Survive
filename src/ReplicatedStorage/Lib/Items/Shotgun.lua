--initialise dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage.Assets
local ReplicatedScripts = ReplicatedStorage.Scripts

local ItemModule = require(script.Parent)
local ItemStates = require(ReplicatedScripts.States.Item)
local KeyBindings = require(ReplicatedScripts.Lib.Player.KeyBindings)
local PlayerModule = require(ReplicatedScripts.Class.Player)
local GunModule = require(ReplicatedScripts.Class.Gun)
local Enums = require(ReplicatedScripts.Registry.Enums)
local CharacterModule = require(ReplicatedScripts.Class.Character)
local CharacterStates = require(ReplicatedScripts.States.Character)
local Viewmodel = require(ReplicatedScripts.Lib.Player.GUI.Viewmodel)

local CharactersFolder = workspace:WaitForChild("Characters")
local JunkFolder = workspace:WaitForChild("JunkFolder")
local TerrainParams = RaycastParams.new()
TerrainParams.IgnoreWater = true
TerrainParams.FilterType = Enum.RaycastFilterType.Exclude
TerrainParams.FilterDescendantsInstances = {JunkFolder, CharactersFolder}

local GunEnum = Enums.Item.Shotgun

local Player = Players.LocalPlayer

local Module = {}

Module.Give = function(Entity)
    ItemStates[GunEnum].add(Entity)
    ItemStates.Cooldown.add(Entity, 0)
    ItemStates.Firerate.add(Entity, 60/100)
    ItemStates.Deviation.add(Entity, Vector2.zero)
end

Module.ServerGotItemID = function(Entity, ItemID)

end

Module.Equip = function(Entity)
    local Model = Assets.Guns.Shotgun:Clone()
    ItemStates.Model.add(Entity, Model)

    local Handle = Model.Handle
    local Grip = Handle.Grip

    local Character = Player.Character

    Character:WaitForChild("HumanoidRootPart")

    Model.Parent = Character
    Grip.Part1 = Character.RightHand

    --Model.Mesh.Transparency = 0.5

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

    ItemModule.WaitUntilItemID(Entity)

    ItemModule.FireCustomAction(Entity, "SetEquipmentModel")
end

Module.Unequip = function(Entity)
    ItemModule.FireCustomAction(Entity, "SetEquipmentModel")

    KeyBindings.UnbindAction("Attack", Enum.UserInputState.Begin)
    KeyBindings.UnbindAction("Attack", Enum.UserInputState.End)

    ItemStates.Shooting.remove(Entity)
    ItemStates.Model.remove(Entity)

    local Character = Player.Character

    Viewmodel.BindRigToCharacter(Character)

    local CharacterEntity = CharacterModule.GetEntityFromCharacter(Character)
    local CharacterData = CharacterStates.World.get(CharacterEntity)

    local IKControllers = CharacterData[CharacterStates.IKControllers]

    local IKControlR, IKControlL = IKControllers["RightHand"], IKControllers["LeftHand"]
    IKControlR.Enabled, IKControlL.Enabled = false, false
end

Module.SetEquipmentModel = function(Entity, ItemModel : Model)
    ItemStates.Model.remove(Entity)
    ItemStates.Model.add(Entity, ItemModel)

    KeyBindings.BindAction("Attack", Enum.UserInputState.Begin, function()
        ItemStates.Shooting.add(Entity)
    end)

    KeyBindings.BindAction("Attack", Enum.UserInputState.End, function()
        ItemStates.Shooting.remove(Entity)
        repeat
            if true then
                GunModule.DeviationRecovery(Entity, .1)
            end
        until (--[[cooldown <= 0 or]] ItemStates.World.get(Entity)[ItemStates.Shooting])
    end)
end

--Shooting
RunService.Heartbeat:Connect(function(deltaTime)
    for Entity in ItemStates.World.query{ItemStates[GunEnum], ItemStates.Shooting} do
        local EntityData = ItemStates.World.get(Entity)

        if not EntityData[ItemStates.Shooting] then continue end

        local Model = EntityData[ItemStates.Model]

        if EntityData[ItemStates.Cooldown] > 0 then
            continue
        end

        local Origin = Model.Muzzle.Position
        local MouseCast = PlayerModule.MouseCast(TerrainParams, 10000)
        local Displacement = MouseCast.Position - Origin
        local DisplacementRight = Vector3.new(-Displacement.Z, 0, Displacement.X)
        local Deviation = EntityData[ItemStates.Deviation]


        local AimDeviation = (Displacement.Unit*Deviation.Y + DisplacementRight.Unit*Deviation.X)*Displacement.Magnitude*Vector3.new(1,0,1) or Vector3.zero
        local DeviatedAim = MouseCast.Position + AimDeviation
        if (DeviatedAim.Magnitude == nil) then DeviatedAim = MouseCast.Position end


        ItemModule.FireCustomAction(Entity, "Attack", DeviatedAim)
        
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
        end
        for _, Target in TracerTargets do
            GunModule.CreateTracer(Origin, Target.Position*Vector3.new(1,0,1) + Origin*Vector3.yAxis, GunEnum, Enums.Bullet["9mmTracer"], Target.Distance/((MaxDist+MinDist)/2)*100+math.random(-100,100)/10 or 100)
        end

        local SpreadPermutations = 10^3
        EntityData[ItemStates.Deviation] += Vector2.new( --RECOIL!!!
            math.random(
                -0.75*SpreadPermutations
                ,0.75*SpreadPermutations
            )/SpreadPermutations
            ,math.random(
                0.5*SpreadPermutations
                ,2*SpreadPermutations
            )/SpreadPermutations
        ) / math.clamp(Deviation.Magnitude+1, 1, math.huge) --reduce recoil impulse with magnitude
        EntityData[ItemStates.Cooldown] = EntityData[ItemStates.Firerate]

        GunModule.DeviationRecovery(Entity, .1)
    end
end)

return Module