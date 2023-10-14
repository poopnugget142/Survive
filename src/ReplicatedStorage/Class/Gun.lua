local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local CharactersFolder = workspace:WaitForChild("Characters")
local JunkFolder = workspace:WaitForChild("JunkFolder")

local PlayerModule = require(ReplicatedStorage.Scripts.Class.Player)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local AlphaPart = require(ReplicatedStorage.Scripts.Util.AlphaPart)
local GunRegistry = require(ReplicatedStorage.Scripts.Registry.Gun)
local EquipmentStates = require(ReplicatedStorage.Scripts.States.Equipment)

local TerrainParams = RaycastParams.new()
TerrainParams.IgnoreWater = true
TerrainParams.FilterType = Enum.RaycastFilterType.Exclude
TerrainParams.FilterDescendantsInstances = {JunkFolder, CharactersFolder}

local CharacterParams = RaycastParams.new()
CharacterParams.IgnoreWater = true
CharacterParams.FilterType = Enum.RaycastFilterType.Include
CharacterParams.FilterDescendantsInstances = {CharactersFolder.NPCs}

local Module = {}

--In future pass gun id and bullet id
Module.BulletShoot = function(Origin : Vector3, Target : Vector3?)
    local ShootData = {}

    local AimPosition = Target or PlayerModule.MouseCast(TerrainParams, 10000).Position
    
    if not AimPosition then return ShootData end

    local DistanceToAim = (AimPosition-Origin).Magnitude

    local spreadPermutations = 10^2 --number of subdivisions of 1 that can occur due to math.random

    --deviation += Vector3.xAxis--(AimPosition-Origin)
    
    --local Circularity = math.sin(math.rad( math.random(0, 180))) --defines the hit position of a bullet in a circular spread
    local AimTarget = AimPosition + (
        Vector3.new(
            math.random(-spreadPermutations, spreadPermutations)/spreadPermutations-- * Circularity
            , 0
            , math.random(-spreadPermutations, spreadPermutations)/spreadPermutations-- * (Circularity)
        ).Unit 
        * (DistanceToAim*math.tan(math.rad(45)/2)) --offset 
        * math.random(-spreadPermutations, spreadPermutations)/spreadPermutations
    ) --+ deviation
    --print(deviation)

    local TerrainDirection = CFrame.new(Origin, AimTarget).LookVector
    local TerrainResult = workspace:Raycast(Origin, TerrainDirection*200, TerrainParams)
    if not TerrainResult then return ShootData end

    ShootData.TerrainResult = TerrainResult

    local Part = Instance.new("Part")
    Part.Color = Color3.new(1, 0, 0)
    Part.Anchored = true
    Part.CanCollide = false
    Part.Position = TerrainResult.Position
    Part.Size = Vector3.new(0.5, 0.5, 0.5)
    Part.Parent = JunkFolder
    Debris:AddItem(Part, 1)
    

    local CharacterDirection = CFrame.new(Origin, TerrainResult.Position).LookVector
    local DistanceToTerrain = (TerrainResult.Position - Origin).Magnitude
    
    --We set the ray length to the distance to character so you don't shoot people behind you
    local CharacterResult = workspace:Spherecast(TerrainResult.Position-CharacterDirection*3, 3, CharacterDirection*6--[[*DistanceToTerrain]], CharacterParams)

    if not CharacterResult then return ShootData end

    local HitPart = CharacterResult.Instance
    local HitCharacter = CharacterModule.FindFirstCharacter(HitPart)

    if not HitCharacter then return ShootData end

    ShootData.HitCharacter = HitCharacter

    local OldHighlight = HitCharacter:FindFirstChildWhichIsA("Highlight")
    if OldHighlight then
        OldHighlight:Destroy()
    end

    local Highlight = Instance.new("Highlight")
    Highlight.Parent = HitCharacter
    Highlight.FillColor = Color3.fromRGB(255, 0, 0)
    Highlight.FillTransparency = 0
    TweenService:Create(Highlight, TweenInfo.new(0.5), {["FillTransparency"] = 1}):Play()
    TweenService:Create(Highlight, TweenInfo.new(0.5), {["OutlineTransparency"] = 1}):Play()
    Debris:AddItem(Highlight, 0.5)

    return ShootData
end

Module.CreateTracer = function(Origin : Vector3, Target : Vector3, GunEnum : number, BulletEnum : number, Speed : number?)
    local TracerData = GunRegistry.GetTracerData(GunEnum, BulletEnum)

    AlphaPart.Spawn(TracerData.Behavior, Origin, Target, Speed or TracerData.Speed)
end

Module.DeviationRecovery = function(Entity, deviationRecovery)
    local EntityData = EquipmentStates.World.get(Entity)
    local Deviation = EntityData.Deviation

    local deltaTime = task.wait()

    if (Deviation.Magnitude > 0) then
        EntityData.Deviation -= (Deviation.Unit*math.min(deviationRecovery, Deviation.Magnitude)) * (deltaTime/(1/60))
    end

    EntityData.Cooldown -= deltaTime
end

return Module