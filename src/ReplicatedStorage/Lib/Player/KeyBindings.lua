local InputActions = {
    ["Move Forward"] =          {Enum.KeyCode.W}
    ;["Move Backward"] =        {Enum.KeyCode.S}
    ;["Move Left"] =            {Enum.KeyCode.A}
    ;["Move Right"] =           {Enum.KeyCode.D}
    ;["Attack"] =               {Enum.UserInputType.MouseButton1}
    ;["Sprint"] =               {Enum.KeyCode.LeftShift}
    ;["Reload"] =               {Enum.KeyCode.R}

    --camera controls
    ;["Camera_ZoomIn"] =        {Enum.KeyCode.Equals}
    ;["Camera_ZoomOut"] =       {Enum.KeyCode.Minus}

    --inventory controls
    ;["Inventory_Open"] =       {Enum.KeyCode.Tab}
    ;["Inventory_Interact1"] =  {Enum.UserInputType.MouseButton1} --mouse1, typically item pick
    ;["Inventory_Interact2"] =  {Enum.UserInputType.MouseButton2} --mouse2, typically item place
    ;["Inventory_RotateLeft"] =     {Enum.KeyCode.Q}
    ;["Inventory_RotateRight"] =     {Enum.KeyCode.E}
    
    --Numberkeys
    ;["1"] = {Enum.KeyCode.One, Enum.KeyCode.KeypadOne}
    ;["2"] = {Enum.KeyCode.Two, Enum.KeyCode.KeypadTwo}
    ;["3"] = {Enum.KeyCode.Three, Enum.KeyCode.KeypadThree}
    ;["4"] = {Enum.KeyCode.Four, Enum.KeyCode.KeypadFour}
    ;["5"] = {Enum.KeyCode.Five, Enum.KeyCode.KeypadFive}
    ;["6"] = {Enum.KeyCode.Six, Enum.KeyCode.KeypadSix}
    ;["7"] = {Enum.KeyCode.Seven, Enum.KeyCode.KeypadSeven}
    ;["8"] = {Enum.KeyCode.Eight, Enum.KeyCode.KeypadEight}
    ;["9"] = {Enum.KeyCode.Nine, Enum.KeyCode.KeypadNine}
    ;["0"] = {Enum.KeyCode.Zero, Enum.KeyCode.KeypadZero}
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

Module.SetKeys = function(ActionName : string, Inputs : Enum.UserInputType | Enum.KeyCode)
    InputActions[ActionName] = Inputs
end

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

Module.GetKeys = function(ActionName : string)
    return InputActions[ActionName]
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