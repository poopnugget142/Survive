local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JunkFolder = workspace:WaitForChild("JunkFolder")
local CharactersFolder = workspace:WaitForChild("Characters")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local PlayerModule = require(ReplicatedStorage.Scripts.Class.Player)

local RunService = game:GetService("RunService")

--It appears I use terrain params a lot lets store it in a database somewhere
local TerrainParams = RaycastParams.new()
TerrainParams.IgnoreWater = true
TerrainParams.FilterType = Enum.RaycastFilterType.Exclude
TerrainParams.FilterDescendantsInstances = {JunkFolder, CharactersFolder}

RunService.RenderStepped:Connect(function()
    for Character in CharacterStates.World.query{CharacterStates.LookAtMouse} do
        local Root = Character.PrimaryPart
        local MouseResult = PlayerModule.MouseCast(TerrainParams, 10000)

        if not MouseResult then continue end

	    Root.CFrame = CFrame.new(Root.Position, Vector3.new(MouseResult.Position.X, Root.Position.Y, MouseResult.Position.Z))
    end
end)