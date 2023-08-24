local RunService = game:GetService("RunService")

local Player : Player = game.Players.LocalPlayer

local HUD : ScreenGui = Player.PlayerGui:WaitForChild("HUD")
local ViewportFrame : ViewportFrame = HUD.CharacterAppearance
local WorldModel : WorldModel = ViewportFrame.WorldModel

local Camera : Camera = Instance.new("Camera")
ViewportFrame.CurrentCamera = Camera
Camera.Parent = ViewportFrame

local Character : Model
local Animator : Animator

local LoadedAnimation : AnimationTrack

local function AddCharacter()
    repeat task.wait() until Player:HasAppearanceLoaded()

    --Turn archivable to true so we can clone
    Player.Character.Archivable = true
    Character = Player.Character:Clone()
    Animator = Character.Humanoid.Animator

    Character:PivotTo(CFrame.new(0, 0, 0))

    Camera.CFrame = CFrame.new(Vector3.new(2, 2, -4), Character.PrimaryPart.Position)

    Character.Parent = WorldModel
end

local function UpdateAnimations(RealCharacter : Model)
    local RealAnimator : Animator = RealCharacter.Humanoid.Animator

    --With the system as is we can't have overlapping animations which is very bad
    --This also doesn't copy over animation weight or... animation fade time
    RealAnimator.AnimationPlayed:Connect(function(AnimationTrack : AnimationTrack)
        if LoadedAnimation then
            LoadedAnimation:Stop()
        end

        LoadedAnimation = Animator:LoadAnimation(AnimationTrack.Animation)
        LoadedAnimation:Play()
    end)
end

if Player.Character then
    AddCharacter()
    UpdateAnimations(Player.Character)
end

Player.CharacterAdded:Connect(function(RealCharacter : Model)
    if not Character then
        AddCharacter()
    end
    UpdateAnimations(RealCharacter)
end)