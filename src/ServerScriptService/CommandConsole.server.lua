-- This is a script you would create in ServerScriptService, for example.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Cmdr = require(ReplicatedStorage.Packages.Cmdr)

Cmdr:RegisterDefaultCommands() -- This loads the default set of commands that Cmdr comes with. (Optional)
Cmdr:RegisterCommandsIn(ServerStorage.Scripts.Commands.Admin) -- Register commands from your own folder. (Optional
Cmdr:RegisterHooksIn(ServerStorage.Scripts.Commands.Hooks)