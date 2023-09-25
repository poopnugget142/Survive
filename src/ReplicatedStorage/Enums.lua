local Id = 0

local function NextId()
    Id += 1
    return Id
end

return {
    NPC = {
        Guy = NextId();
        Gargoyle = NextId();
    },
    Action = {
        Die = NextId();
    };
    Gun = {
        M1911 = NextId();
        Shotgun = NextId();
    },
    Bullet = {
        ["9mmTracer"] = NextId()
    };
}