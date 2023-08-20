--[[
    notetaking

    seperate spread into mechanical spread and deviation (recoil) later on
        im thinking deviation has a velocity / acceleration that changes as the player fires the gun
        if you were to equip a laser pointer, youd be able to see where the next bullet will go and account for spread
]]


--initialise dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage.Remotes
local JunkFolder = workspace:WaitForChild("JunkFolder")
local CharactersFolder = workspace:WaitForChild("Characters")

local Equipment = require(script.Parent)
local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)
local ballistics = require(ReplicatedStorage.Scripts.Util.Ballistics)
local ballistics2 = require(ReplicatedStorage.Scripts.Util.ballistics2)
local PlayerModule = require(ReplicatedStorage.Scripts.Class.Player)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)

local Attack : RemoteEvent = Remotes.Custom.Attack
local SetEquipmentModel : RemoteEvent = Remotes.SetEquipmentModel

local Player = Players.LocalPlayer

local TerrainParams = RaycastParams.new()
TerrainParams.IgnoreWater = true
TerrainParams.FilterType = Enum.RaycastFilterType.Exclude
TerrainParams.FilterDescendantsInstances = {JunkFolder, CharactersFolder}

local CharacterParams = RaycastParams.new()
CharacterParams.IgnoreWater = true
CharacterParams.FilterType = Enum.RaycastFilterType.Include
CharacterParams.FilterDescendantsInstances = {CharactersFolder.Baddies}

local caster = ballistics.CreateCaster()
local bullet = Instance.new("Part")
    bullet.Anchored = true 
    bullet.CanCollide = false

local castBehaviour = ballistics.CreateCastBehavior()
    castBehaviour.CosmeticBulletTemplate = bullet
    castBehaviour.Acceleration = Vector3.zero
    castBehaviour.Container = JunkFolder

local castBehaviour2 = ballistics2.CreateCastBehavior()
    castBehaviour2.CosmeticBulletTemplate = bullet
    castBehaviour2.Container = JunkFolder
    castBehaviour2.MoveFunction = function(origin : Vector3, target : Vector3, alpha : number)
        local alphaMax = math.min(alpha, 1)
        local position : Vector3 = origin:Lerp(target, alpha) --+ Vector3.yAxis*math.sin(alphaMax*math.pi)*(target-origin).Magnitude*0.5
        return position
    end


local Module = {}

Module.Give = function(Entity, ItemModel)

    --[[
    KeyBindings.BindAction("Attack", Enum.UserInputState.Begin, function()
        
    end)
    ]]
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

            local MouseCast = PlayerModule.MouseCast(TerrainParams, 10000)
            if not MouseCast then continue end

            local AimPosition = MouseCast.Position
            
            local DistanceToAim = (AimPosition-Origin).Magnitude

            local spreadPermutations = 10^5 --number of subdivisions of 1 that can occur due to math.random

            --deviation += Vector3.xAxis--(AimPosition-Origin)
            
            local Circularity = math.sin(math.rad( math.random(0, 180))) --defines the hit position of a bullet in a circular spread
            local AimTarget = AimPosition + (
                Vector3.new(
                    math.random(-spreadPermutations, spreadPermutations)/spreadPermutations * Circularity
                    , 0
                    , math.random(-spreadPermutations, spreadPermutations)/spreadPermutations * (1-Circularity)
                ).Unit * (DistanceToAim*math.tan(math.rad(25)/2)) --offset 
                * math.random(-spreadPermutations, spreadPermutations)/spreadPermutations
            ) --+ deviation
            --print(deviation)

            local TerrainDirection = CFrame.new(Origin, AimTarget).LookVector
            local TerrainResult = workspace:Raycast(Origin, TerrainDirection*200, TerrainParams)
            if not TerrainResult then continue end

            local Part = Instance.new("Part")
            Part.Anchored = true
            Part.CanCollide = false
            Part.Position = TerrainResult.Position
            Part.Size = Vector3.new(0.5, 0.5, 0.5)
            Part.Parent = JunkFolder
            Debris:AddItem(Part, 1)

            --ballistics.SpawnBullet(caster, castBehaviour, Origin, (TerrainResult.Position - Origin).Unit*Vector3.new(1,0,1)*100)
            ballistics2.SpawnBullet(castBehaviour2, Origin, TerrainResult.Position * Vector3.new(1,0,1) + Origin * Vector3.yAxis, 200)
            

            local CharacterDirection = CFrame.new(TerrainResult.Position, Origin).LookVector
            local CharacterResult = workspace:Raycast(TerrainResult.Position, CharacterDirection*200, CharacterParams)

            if not CharacterResult then continue end

            local HitPart = CharacterResult.Instance
            local HitCharacter = CharacterModule.FindFirstCharacter(HitPart)

            Attack:FireServer(ItemID, HitCharacter)
        end
    end)

    KeyBindings.BindAction("Attack", Enum.UserInputState.End, function()
        shooting = false
        --print(shooting)
    end)
    --SetEquipmentModel:FireServer(ItemID)
end



Module.ServerLoadModel = function(Entity, ItemModel : Model)
    
end

return Module