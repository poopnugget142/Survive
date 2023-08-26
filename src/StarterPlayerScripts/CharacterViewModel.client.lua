local RunService = game:GetService("RunService")

local Player : Player = game.Players.LocalPlayer

local HUD : ScreenGui = Player.PlayerGui:WaitForChild("HUD")
local ViewportFrame : ViewportFrame = HUD.Frame.CharacterAppearance
local WorldModel : WorldModel = ViewportFrame.WorldModel

local Camera : Camera = Instance.new("Camera")
ViewportFrame.CurrentCamera = Camera
Camera.Parent = ViewportFrame

local Character : Model
local Animator : Animator

local RealCharacter : Model
local RealAnimator : Animator

local PlayingAnimations = {}

--Cloning character to put into viewmodel
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

--This checks what animations are playing and applies them to the viewmodel
--We don't have the animation fade time which will cause some visual errors
local function UpdateAnimations()
    if not RealCharacter then return end

    --Create a list of animations that need to be cancelled
    local StoppedAnimations = table.clone(PlayingAnimations)

    for _, AnimationTrack : AnimationTrack in RealAnimator:GetPlayingAnimationTracks() do
        local AnimationName = AnimationTrack.Animation.Name

        if StoppedAnimations[AnimationName] then
            StoppedAnimations[AnimationName] = nil
        end

        --Play new animations here
        local ViewmodelAnimationTrack = PlayingAnimations[AnimationName]
        if not ViewmodelAnimationTrack then
            ViewmodelAnimationTrack = Animator:LoadAnimation(AnimationTrack.Animation)
            ViewmodelAnimationTrack:Play(nil, AnimationTrack.WeightTarget, AnimationTrack.Speed)
            PlayingAnimations[AnimationName] = ViewmodelAnimationTrack
        end

        ViewmodelAnimationTrack:AdjustSpeed(AnimationTrack.Speed)
        ViewmodelAnimationTrack:AdjustWeight(AnimationTrack.WeightCurrent)
    end

    --Stopping old animations
    for AnimationName, AnimationTrack : AnimationTrack in StoppedAnimations do
        AnimationTrack:Stop()
        PlayingAnimations[AnimationName] = nil
    end
end

--Used to have the viewmodel mimic the animations of the bound character
local function BindRigToCharacter(AddedCharacter : Model)
    RealCharacter = AddedCharacter
    RealAnimator = RealCharacter.Humanoid.Animator
    PlayingAnimations = {}
end

if Player.Character then
    AddCharacter()
    BindRigToCharacter(Player.Character)
end

Player.CharacterAdded:Connect(function(AddedCharacter : Model)
    if not Character then
        AddCharacter()
    end
    BindRigToCharacter(AddedCharacter)
end)

RunService:BindToRenderStep("UpdateAnimations", Enum.RenderPriority.Last.Value, UpdateAnimations)