local RunService = game:GetService("RunService")

local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

Camera.CameraType = Enum.CameraType.Scriptable

local TopDownOffset = Vector3.new(0, 30, -20)
local RootOffset = Vector3.new(0, 0, -2)

local function UpdateCameraPosition()
    local Character : Model = Player.Character
    local Primary : BasePart = Character.PrimaryPart

    if not Primary then return end

    local RootOrgin = Primary.Position + RootOffset

    Camera.CFrame = CFrame.new(RootOrgin + TopDownOffset, RootOrgin)
end

Player.CharacterAdded:Wait()

RunService:BindToRenderStep("FollowCharacter", Enum.RenderPriority.Camera.Value, UpdateCameraPosition)