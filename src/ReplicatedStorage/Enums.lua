local Id = 0

local function NextId()
    Id += 1
    return Id
end

return {
    Baddies = {
        Guy = NextId();
    },
    Gun = {
        M1911 = NextId();
        Shotgun = NextId();
    },
    Bullet = {
        ["9mmTracer"] = NextId()
    };
}