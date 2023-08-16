local CollectionService = game:GetService("CollectionService")

local Module = {}

--Returns the first ancestor Model of Object that has an "Baddie" tag, nil if none are found
Module.FindFirstCharacter = function(Object : Instance)
    if CollectionService:HasTag(Object, "Character") then return Object end

    local Ancestor = Object:FindFirstAncestorWhichIsA("Model")
    if not Ancestor then return end

    return Module.FindFirstCharacter(Ancestor)
end

return Module