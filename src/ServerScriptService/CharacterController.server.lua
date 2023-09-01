local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

local FRAMERATE = 1 / 240
local STIFFNESS = 300
local DAMPING = 30
local PRECISION = 0.001

local Module = {}


local function StepSpring(framerate, position, velocity, destination, stiffness, damping, precision)
	local displacement = position - destination             --s
	local springForce = -stiffness * displacement           --stretch the acceleration depending on target distance
	local dampForce = -damping * velocity                   --constrain acceleration from going too high

	local acceleration = springForce + dampForce
	local newVelocity = velocity + acceleration * framerate --v = u + at
	local newPosition = position + velocity * framerate     --s = ut

	if math.abs(newVelocity) < precision and math.abs(destination - newPosition) < precision then
		return destination, 0
	end

	return newPosition, newVelocity
end


RunService.Heartbeat:Connect(function(DeltaTime)
    for Character : Model in CharacterStates.World.query{CharacterStates.Moving} do
        local CharacterData = CharacterStates.World.get(Character)
        local MovementData = CharacterData.MovementData

        local Primary : BasePart = Character.PrimaryPart

        if not Primary then continue end

        --[[ --no mover / aligner
        local Mover : VectorForce = Primary.Mover
        local Aligner : AlignOrientation = Primary.Aligner
        ]]

        local AutoRotate = CharacterStates.World.get(Character).AutoRotate

        local Velocity = MovementData.Velocity or Vector3.zero
        local CurrentVelocityX = Velocity.X
        local CurrentVelocityZ = Velocity.Z


        local TargetVelocity = Vector3.new()

        local MoveDirection = MovementData.MoveDirection -- Would explode if Y wasn't 0

        if MoveDirection.Magnitude > 0 then
            --If MoveDirection magnititude is 0 then we get nan
            TargetVelocity = Vector3.new(MoveDirection.X, 0, MoveDirection.Z).Unit * CharacterData.WalkSpeed

            --If autorotate is on and were moving then make character face towards move direction
            if AutoRotate then
                MovementData.LookDirection = MoveDirection
            end
        end

        local LookDirection = Vector3.new(-MovementData.LookDirection.X, 0, MovementData.LookDirection.Z)

        --[[ --no mover / aligner
        if LookDirection.Magnitude > 0 then
            Aligner.Attachment0.CFrame = CFrame.lookAt(Vector3.new(), LookDirection)
        end
        ]]

        --Incremeants time
        MovementData.AccumulatedTime = (MovementData.AccumulatedTime or 0) + DeltaTime

        while MovementData.AccumulatedTime >= FRAMERATE do
            MovementData.AccumulatedTime -= FRAMERATE

            CurrentVelocityX, MovementData.CurrentAccelerationX = StepSpring(
                FRAMERATE,
                CurrentVelocityX,
                MovementData.CurrentAccelerationX or 0,
                TargetVelocity.X,
                STIFFNESS,
                DAMPING,
                PRECISION
            )

            CurrentVelocityZ, MovementData.CurrentAccelerationZ = StepSpring(
                FRAMERATE,
                CurrentVelocityZ,
                MovementData.CurrentAccelerationZ or 0,
                TargetVelocity.Z,
                STIFFNESS,
                DAMPING,
                PRECISION
            )
        end

        Velocity = Vector3.new(CurrentVelocityX, 0, CurrentVelocityZ)
        MovementData.Velocity = Velocity

        Character:PivotTo(CFrame.new(Primary.Position + MovementData.Velocity * DeltaTime))

        --Mover.Enabled = true

        --Applies forces
        --Mover.Force = Vector3.new(MovementData.CurrentAccelerationX, 0, MovementData.CurrentAccelerationZ)*Primary.AssemblyMass
    end
end)

return Module