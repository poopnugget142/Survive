-- init widget
local Toolbar = plugin:CreateToolbar("FastPath")
local PluginButton = Toolbar:CreateButton(
    "Editor" --Text that will appear below button
    ,"Create and configure navmeshes for maps" --Text that will appear if you hover your mouse on button
    ,"rbxassetid://8740888472" --Button icon
)
local Info = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right --From what side gui appears
	,false --Widget will be initially enabled
	,false --Don't overdrive previouse enabled state
	,200 --default weight
	,300 --default height
)
local Widget = plugin:CreateDockWidgetPluginGui(
    "TestPlugin" --A unique and consistent identifier used to storing the Widget’s dock state and other internal details
    ,Info --dock Widget Info
)

PluginButton.Click:Connect(function()
    Widget.Enabled = not Widget.Enabled
end)


local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ReplicatedScripts = ReplicatedStorage.Scripts
--
local QuadtreeModule = require(ReplicatedScripts.Lib.Quadtree)
local PathfindingCore = require(ReplicatedStorage.Lib.AI.PathfindingCore2)
