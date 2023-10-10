local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local BoundEvents = {}

local Module = {}

Module.CreateEvent = function(Entity : any, Name : any) : Signal.Signal
    if not BoundEvents[Entity] then
        BoundEvents[Entity] = {}
    end

    local NewSignal = Signal.new()

    BoundEvents[Entity][Name] = NewSignal

    return NewSignal
end

Module.GetEvent = function(Entity : any, Name : string) : Signal.Signal
    if not BoundEvents[Entity] or not BoundEvents[Entity][Name] then return end

    return BoundEvents[Entity][Name]
end

Module.FireEvent = function(Entity : any, Name : string, ...)
    local NewSignal = Module.GetEvent(Entity, Name)

    if not NewSignal then return end

    NewSignal:Fire(Entity, ...)
end

return Module