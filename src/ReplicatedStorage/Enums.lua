local Id = 0

local function NextId()
    Id += 1
    return Id
end

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