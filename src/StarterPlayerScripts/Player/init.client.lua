local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemModule = require(ReplicatedStorage.Scripts.Items)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local CharacterAnimations = require(ReplicatedStorage.Scripts.Registry.Animations.Character)
local Hotkeys = require(ReplicatedStorage.Scripts.Util.Hotkeys)
local Viewmodel = require(ReplicatedStorage.Scripts.Util.Viewmodel)
local Enums = require(ReplicatedStorage.Scripts.Enums)

local Player = Players.LocalPlayer

local function CreateCharacter(Character)
    local Entity = CharacterStates.World.entity()

    CharacterModule.RegisterCharacter(Entity, Character)

    local IKData = {
        ["LeftHand"] = CharacterAnimations.CreateLeftHandIK(Character)
        ,["RightHand"] = CharacterAnimations.CreateRightHandIK(Character)
    }

    CharacterStates.IKControllers.add(Entity, IKData)
    CharacterStates.LookAtMouse.add(Character)
    CharacterStates.Stamina.add(Character, 5)

    Viewmodel.BindRigToCharacter(Character)

    local GunEntity = ItemModule.CreateEntity(Enums.Item.Shotgun)
    Hotkeys.BindEquipToHotkey(1, GunEntity)
end

if Player.Character then CreateCharacter(Player.Character) end

Player.CharacterAdded:Connect(CreateCharacter)