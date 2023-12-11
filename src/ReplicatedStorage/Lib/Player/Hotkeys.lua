local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.Scripts

local ItemModule = require(ReplicatedScripts.Lib.Items)
local KeyBindings = require(ReplicatedScripts.Lib.Player.KeyBindings)

local Module = {}

local CurrentEquip

Module.BindEquipToHotkey = function(Hotkey, GunEntity)
    KeyBindings.BindAction(tostring(Hotkey), Enum.UserInputState.Begin, function()
        if CurrentEquip then
            ItemModule.Unequip(CurrentEquip)

            if CurrentEquip == GunEntity then
                CurrentEquip = nil
                return
            end
        end

        CurrentEquip = GunEntity

        ItemModule.Equip(GunEntity)
    end)
end

Module.UnbindFromHotkey = function(Hotkey)
    KeyBindings.UnbindAction(tostring(Hotkey), Enum.UserInputState.Begin)
end

return Module