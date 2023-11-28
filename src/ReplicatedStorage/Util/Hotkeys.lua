local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Equipment = require(ReplicatedStorage.Scripts.Equipment)
local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)

local Module = {}

local CurrentEquip

Module.BindEquipToHotkey = function(Hotkey, GunEntity)
    KeyBindings.BindAction(tostring(Hotkey), Enum.UserInputState.Begin, function()
        if CurrentEquip then
            Equipment.Unequip(CurrentEquip)

            if CurrentEquip == GunEntity then
                CurrentEquip = nil
                return
            end
        end

        CurrentEquip = GunEntity

        Equipment.Equip(GunEntity)
    end)
end

Module.UnbindFromHotkey = function(Hotkey)
    KeyBindings.UnbindAction(tostring(Hotkey), Enum.UserInputState.Begin)
end

return Module