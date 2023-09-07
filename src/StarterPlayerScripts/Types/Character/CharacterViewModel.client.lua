local RunService = game:GetService("RunService")

local Player : Player = game.Players.LocalPlayer

local HUD : ScreenGui = Player.PlayerGui:WaitForChild("HUD")
local ViewportFrame : ViewportFrame = HUD.Frame.CharacterAppearance
local WorldModel : WorldModel = ViewportFrame.WorldModel

local Camera : Camera = Instance.new("Camera")
ViewportFrame.CurrentCamera = Camera
Camera.Parent = ViewportFrame

local Character : Model

local RealCharacter : Model
local RealParts = {}

local Isometer = (2^1)

--Cloning character to put into viewmodel
local function BindRigToCharacter(AddedCharacter : Model)
    repeat task.wait() until Player:HasAppearanceLoaded()

    if Character then
        Character:Destroy()
    end

    RealCharacter = AddedCharacter

    --Turn archivable to true so we can clone
    Player.Character.Archivable = true
    Character = Player.Character:Clone()

    Character.HumanoidRootPart.Anchored = true

    for _, Instance in Character:GetDescendants() do
        if Instance:IsA("Script") or Instance:IsA("Motor6D")  then
            --Instance:Destroy()
            continue
        end
    end

    for _, Part in AddedCharacter:GetChildren() do
        if not Part:IsA("BasePart") or Part.Name == "HumanoidRootPart" then continue end
        table.insert(RealParts, Part)
    end

    Character:PivotTo(CFrame.new(0, 0, 0))

    Camera.FieldOfView = 70/Isometer
    Camera.CFrame = CFrame.new(Vector3.new(2.25, 2.25, -4.5)*Isometer, Character.PrimaryPart.Position)

    Character.Parent = WorldModel
end

--Able to 100% accurately represent animations at the subtle cost of smoothness
local function UpdateAnimations()
    for _, Part : BasePart in RealParts do
        local RootOffset = RealCharacter.HumanoidRootPart.CFrame:ToObjectSpace(Part.CFrame)

        Character[Part.Name].Anchored = true
        Character[Part.Name].CFrame = Character.HumanoidRootPart.CFrame*RootOffset
    end
end

if Player.Character then
    BindRigToCharacter(Player.Character)
end

Player.CharacterAdded:Connect(function(AddedCharacter : Model)
    BindRigToCharacter(AddedCharacter)
end)

RunService:BindToRenderStep("UpdateAnimations", Enum.RenderPriority.Last.Value, UpdateAnimations)