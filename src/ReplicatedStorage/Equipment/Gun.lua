local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Remotes = ReplicatedStorage.Remotes
local JunkFolder = workspace:WaitForChild("JunkFolder")
local CharactersFolder = workspace:WaitForChild("Characters")

local Equipment = require(script.Parent)
local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)
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

local Module = {}

Module.Give = function(Entity, ItemModel)

    KeyBindings.BindAction("Attack", Enum.UserInputState.Begin, function()
        
    end)
end

Module.ServerGotItemID = function(Entity, ItemID)
    KeyBindings.BindAction("Attack", Enum.UserInputState.Begin, function()
        local Character = Player.Character
        local HumanoidRootPart = Character.Model.PrimaryPart
        local Orgin = HumanoidRootPart.Position

        local MouseCast = PlayerModule.MouseCast(TerrainParams, 10000)
        if not MouseCast then return end

        local AimPosition = MouseCast.Position
        
        local DistanceToAim = (Orgin-AimPosition).Magnitude
        local Circularity = math.rad( math.random(0, 180) )

        local SpreadAim = AimPosition +
        ( Vector3.new(math.random(-100, 100)*0.01*math.sin(Circularity), 0, math.random(-100, 100)*0.01*math.cos(Circularity))
        *(DistanceToAim*math.tan(math.rad(25)/2)) )

        local TerrainDirection = CFrame.new(Orgin, SpreadAim).LookVector
        local TerrainResult = workspace:Raycast(Orgin, TerrainDirection*200, TerrainParams)
        
        local Part = Instance.new("Part")
        Part.Anchored = true
        Part.CanCollide = false
        Part.Position = TerrainResult.Position
        Part.Size = Vector3.new(0.5, 0.5, 0.5)
        Part.Parent = JunkFolder
        Debris:AddItem(Part, 1)

        if not TerrainResult then return end

        local CharacterDirection = CFrame.new(TerrainResult.Position, Orgin).LookVector
        local CharacterResult = workspace:Raycast(TerrainResult.Position, CharacterDirection*200, CharacterParams)

        if not CharacterResult then return end

        local HitPart = CharacterResult.Instance
        local HitCharacter = CharacterModule.FindFirstCharacter(HitPart)

        Attack:FireServer(ItemID, HitCharacter)
    end)
    --SetEquipmentModel:FireServer(ItemID)
end

Module.ServerLoadModel = function(Entity, ItemModel : Model)
    
end

return Module