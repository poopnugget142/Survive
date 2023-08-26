-- Variables Prep --

local Players = game:GetService("Players")
local http = game:GetService("HttpService")
local Webhook = "https://discord.com/api/webhooks/1143296988893434038/f7vj4zUdQwOk3zhbkU_aX1SUr5ANOOZnl1DTxT6GDSM37gJIVjURC6xP0cUaSxX26AxW"
local RunService = game:GetService("RunService")

-- Actual Code --

Players.PlayerAdded:Connect(function(plr)
	if not RunService:IsStudio() then
		local data = 
			{
			["contents"] = "",
			["embeds"] = {{
				["title"]= plr.name.." has joined the game!",
				["description"] = "[Profile](https://www.roblox.com/users/"..plr.UserId.."/profile)",
				["type"]= "rich",
				["color"]= tonumber(0x36393e),
			}}}	
		http:PostAsync(Webhook,http:JSONEncode(data))
	end
end)