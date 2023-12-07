local Id = 0

local function NextId()
    Id += 1
    return Id
end

local Children = script:GetChildren()
local Module = {}
table.sort(Children, function(a, b) return a.Name < b.Name end) 
for _, Script : ModuleScript in Children do
    local Child = require(Script)
    Module[Script.Name] = {}
    for i, Value in Child do
        Module[Script.Name][Value] = NextId()
    end
end

return Module

--[[
return {
    NPC = {
        Player = NextId();
        Guy = NextId();
        Gargoyle = NextId();
        Big = NextId();
    },
    Action = {
        Die = NextId();
        Attack = NextId();
        Walk = NextId();
    };
    States = {
        Walking = NextId();
        Attacking = NextId();
    };
    Gun = {
        M1911 = NextId();
        Shotgun = NextId();
    },
    Bullet = {
        ["9mmTracer"] = NextId()
    };
    DamageType = {
        Bullet = NextId();
        Explosion = NextId();
        Physical = NextId();
    };
}
--]]