local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.Scripts

local Enums = require(ReplicatedScripts.Registry.Enums)

local NpcType = {
	Parse = function (value)
		return Enums.NPC[value]
	end
}

local NpcEnums = {}

for EnumName, EnumNumber in Enums.NPC do
    table.insert(NpcEnums, EnumName)
end

return function (registry)
	registry:RegisterType("npc", registry.Cmdr.Util.MakeEnumType("Npc", NpcEnums))
end