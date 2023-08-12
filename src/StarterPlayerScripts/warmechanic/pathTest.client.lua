local players : Players = game:GetService("Players")
local runService : RunService = game:GetService("RunService")
local userInputService: UserInputService = game:GetService("UserInputService")

local replicatedStorage = game:GetService("ReplicatedStorage")
local djikstra = require(replicatedStorage.Scripts.warmechanic.djikstrapathfind)

local player = players.LocalPlayer

local cam = workspace.CurrentCamera

local mouse = player:GetMouse()

local adjacents = {
    Vector2.new(0, 1),
    Vector2.new(1, 1),
    Vector2.new(1, 0),
    Vector2.new(1, -1),
    Vector2.new(0, -1),
    Vector2.new(-1, -1),
    Vector2.new(-1, 0),
    Vector2.new(-1, 1),
}


runService.RenderStepped:Connect(function(deltaTime)
    local mousePosition = mouse.Hit.Position
    local tilePosition : Vector2 = Vector2.new( 
        math.round(mousePosition.X), 
        math.round(mousePosition.Z)
    )

    local vectors = { }
    for a, adjacent in adjacents do
        local adjacentPosition = tilePosition + adjacent
        
        local path = djikstra.world.Component.Get(djikstra.tileUV(0,0), "pathData")
        vectors[a] = adjacent[a]*100
        if (path) then
            vectors[a] = adjacent * (1 / path.heat)            
        end
    end
    local finalVector = Vector2.zero
    for v, vector in vectors do
        finalVector += vector
    end
    finalVector = -finalVector.Unit
    --print(vectors)
    --print(finalVector)
end)