local InputActions = {
    ["Move Forward"] = {Enum.KeyCode.W};
    ["Move Backward"] = {Enum.KeyCode.S};
    ["Move Left"] = {Enum.KeyCode.A};
    ["Move Right"] = {Enum.KeyCode.D};
    ["Attack"] = {Enum.UserInputType.MouseButton1};
}

local InputFunctions = {}

local ContextActionService = game:GetService("ContextActionService")

local function UpdateInput(ActionName, InputState, InputObject)
    if not InputActions[ActionName] then return end

    if not InputFunctions[InputState] or not InputFunctions[InputState][ActionName] then return end

    local Action = InputFunctions[InputState][ActionName]

    Action(ActionName, InputState, InputObject)
end

local Module = {}

--this needs to be updated to reload CAS as well
Module.SetKey = function(ActionName : string, Input : Enum.UserInputType | Enum.KeyCode)
    if not InputActions[ActionName] then
        InputActions[ActionName] = {}
    end

    table.insert(InputActions[ActionName], Input)
end

--Removes given input from triggers for action
--this needs to be updated to reload CAS as well
Module.RemoveKey = function(ActionName : string, Input : Enum.UserInputType | Enum.KeyCode)
    local CurrentInput = table.find(InputActions[ActionName], Input)
    table.remove(InputActions[ActionName], CurrentInput)
end

Module.BindAction = function(ActionName : string, InputState : Enum.UserInputState, Action, Priority : number?)
    ContextActionService:BindActionAtPriority(ActionName, UpdateInput, false, Priority or 0, unpack(InputActions[ActionName]))

    if not InputFunctions[InputState] then
        InputFunctions[InputState] = {}
    end

    InputFunctions[InputState][ActionName] = Action
end

Module.UnbindAction = function(ActionName : string, InputState : Enum.UserInputState)
    ContextActionService:UnbindAction(ActionName)

    if not InputFunctions[InputState] then return end

    if not InputFunctions[InputState][ActionName] then return end

    InputFunctions[InputState][ActionName] = nil
end

return Module