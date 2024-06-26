local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.Scripts

local KeyBindings = require(ReplicatedScripts.Lib.Player.KeyBindings)

local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

local isometer = (2^1.5) --try 2^6.1293 for fun, or 2^0 to turn off

Camera.CameraType = Enum.CameraType.Scriptable
Camera.FieldOfView = 70/isometer

local TopDownOffset = Vector3.new(-27, 40, -27)  * isometer
local RootOffset = Vector3.new(-2, 0, -2)

local Zoom = 1

KeyBindings.BindAction("Camera_ZoomIn", Enum.UserInputState.Begin, function()
    Zoom -= 0.25
    Zoom = math.clamp(Zoom, 0.1, 1)
end)

KeyBindings.BindAction("Camera_ZoomOut", Enum.UserInputState.Begin, function()
    Zoom += 0.25
    Zoom = math.clamp(Zoom, 0.1, 1)
end)

local function UpdateCameraPosition()
    local Character : Model = Player.Character
    local Primary : BasePart = Character.PrimaryPart

    if not Primary then return end

    local RootOrgin = Primary.Position + RootOffset

    Camera.CFrame = CFrame.new(RootOrgin + (TopDownOffset*Zoom), RootOrgin) 
end

Player.CharacterAdded:Wait()

RunService:BindToRenderStep("FollowCharacter", Enum.RenderPriority.Camera.Value, UpdateCameraPosition)