local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CharacterDataModule = require(ReplicatedStorage.Scripts.CharacterData)
local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

local FRAMERATE = 1 / 240
local STIFFNESS = 300
local DAMPING = 30
local PRECISION = 0.001

local Module = {}

--Establish default values
Module.New = function(Character : Model)
    CharacterDataModule.CreateCharacterData(Character)

    CharacterStates.AutoRotate.add(Character)
end

local function StepSpring(framerate, position, velocity, destination, stiffness, damping, precision)
	local displacement = position - destination
	local springForce = -stiffness * displacement
	local dampForce = -damping * velocity

	local acceleration = springForce + dampForce
	local newVelocity = velocity + acceleration * framerate
	local newPosition = position + velocity * framerate

	if math.abs(newVelocity) < precision and math.abs(destination - newPosition) < precision then
		return destination, 0
	end

	return newPosition, newVelocity
end

RunService:BindToRenderStep("PlayerMovement", Enum.RenderPriority.Character.Value, function(DeltaTime : number)
    for Character : Model in CharacterStates.World.query{CharacterStates.Moving} do
        local CharacterData = CharacterDataModule.GetCharacterData(Character)

        local Primary : BasePart = Character.PrimaryPart

        if not Primary then continue end

        local Mover : VectorForce = Primary.Mover
        local Aligner : AlignOrientation = Primary.Aligner

        local AutoRotate = CharacterStates.World.get(Character).AutoRotate

        local Velocity = Primary.AssemblyLinearVelocity
        local CurrentVelocityX = Velocity.X
        local CurrentVelocityZ = Velocity.Z

        local TargetVelocity = Vector3.new()

        local MoveDirection = CharacterData.MoveDirection -- Would explode if Y wasn't 0

        if MoveDirection.Magnitude > 0 then
            --If MoveDirection magnititude is 0 then we get nan
            TargetVelocity = Vector3.new(MoveDirection.X, 0, MoveDirection.Z).Unit * CharacterData.WalkSpeed

            --If autorotate is on and were moving then make character face towards move direction
            if AutoRotate then
                CharacterData.LookDirection = MoveDirection
            end
        end

        local LookDirection = Vector3.new(-CharacterData.LookDirection.X, 0, CharacterData.LookDirection.Z)

        if LookDirection.Magnitude > 0 then
            Aligner.Attachment0.CFrame = CFrame.lookAt(Vector3.new(), LookDirection)
        end

        --Incremeants time
        CharacterData.AccumulatedTime = (CharacterData.AccumulatedTime or 0) + DeltaTime

        while CharacterData.AccumulatedTime >= FRAMERATE do
            CharacterData.AccumulatedTime -= FRAMERATE

            CurrentVelocityX, CharacterData.CurrentAccelerationX = StepSpring(
                FRAMERATE,
                CurrentVelocityX,
                CharacterData.CurrentAccelerationX or 0,
                TargetVelocity.X,
                STIFFNESS,
                DAMPING,
                PRECISION
            )

            CurrentVelocityZ, CharacterData.CurrentAccelerationZ = StepSpring(
                FRAMERATE,
                CurrentVelocityZ,
                CharacterData.CurrentAccelerationZ or 0,
                TargetVelocity.Z,
                STIFFNESS,
                DAMPING,
                PRECISION
            )
        end

        Mover.Enabled = true

        --Applies forces
        Mover.Force = Vector3.new(CharacterData.CurrentAccelerationX, 0, CharacterData.CurrentAccelerationZ)*Primary.AssemblyMass
    end
end)

return Module