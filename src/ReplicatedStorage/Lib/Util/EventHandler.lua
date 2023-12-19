local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local BoundEntityEvents = {}
local BoundEvents = {}

local Module = {}

Module.CreateEvent = function(Name : string) : Signal.Signal
    local NewSignal = Signal.new()

    BoundEvents[Name] = NewSignal

    return NewSignal
end

Module.GetEvent = function(Name : string) : Signal.Signal
    return BoundEvents[Name]
end

Module.FireEvent = function(Name : string, ...)
    local NewSignal = Module.GetEvent(Name)

    if not NewSignal then return end

    NewSignal:Fire(...)
end

Module.CreateEntityEvent = function(Entity : any, Name : any) : Signal.Signal
    if not BoundEntityEvents[Entity] then
        BoundEntityEvents[Entity] = {}
    end

    local NewSignal = Signal.new()

    BoundEntityEvents[Entity][Name] = NewSignal

    return NewSignal
end

Module.GetEntityEvent = function(Entity : any, Name : string) : Signal.Signal
    if not BoundEntityEvents[Entity] or not BoundEntityEvents[Entity][Name] then return end

    return BoundEntityEvents[Entity][Name]
end

Module.FireEntityEvent = function(Entity : any, Name : string, ...)
    local NewSignal = Module.GetEntityEvent(Entity, Name)

    if not NewSignal then return end

    NewSignal:Fire(Entity, ...)
end

return Module