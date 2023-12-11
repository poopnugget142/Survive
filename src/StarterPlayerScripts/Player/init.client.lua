local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.Scripts

local ItemModule = require(ReplicatedScripts.Lib.Items)
local CharacterModule = require(ReplicatedScripts.Class.Character)
local CharacterStates = require(ReplicatedScripts.States.Character)
local CharacterAnimations = require(ReplicatedScripts.Registry.Animations.Character)
local Hotkeys = require(ReplicatedScripts.Lib.Player.Hotkeys)
local Viewmodel = require(ReplicatedScripts.Lib.Player.GUI.Viewmodel)
local Enums = require(ReplicatedScripts.Registry.Enums)

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