local Id = 0

local function NextId()
    Id += 1
    return Id
end

return {
    Baddies = {
        Guy = NextId()
    }
}