export type CharacterData = {
    MoveDirection : Vector3;
    WalkSpeed : number;
    AccumulatedTime : number;
    CurrentAccelerationX : number;
    CurrentAccelerationZ : number;
}

local CharacterDataContainer = {} :: {[Model] : CharacterData}

local Module = {}

Module.CreateCharacterData = function(Character : Model)

    CharacterDataContainer[Character] = {
        MoveDirection =  Vector3.new();
        LookDirection = Vector3.new();
        WalkSpeed = 16;
        AccumulatedTime = 0;
    }

end

Module.GetCharacterData = function(Character : Model) : CharacterData
    return CharacterDataContainer[Character]
end

return Module