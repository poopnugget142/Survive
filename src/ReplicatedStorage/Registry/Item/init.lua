local Module = {}

for _, ModuleScript in script:GetChildren() do
    local PropertyName = ModuleScript.Name

    local PropertyModule = require(ModuleScript)

    Module["Get" .. PropertyName] = function(Enum)
        return PropertyModule[Enum]
    end
end

return Module