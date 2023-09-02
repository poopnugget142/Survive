local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--for raycastparams
local CharactersFolder = workspace:WaitForChild("Characters")
local JunkFolder = workspace:WaitForChild("JunkFolder")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)

local FRAMERATE = 1 / 240
local STIFFNESS = 300
local DAMPING = 30
local PRECISION = 0.001
local STEPHEIGHT = 1

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

local TerrainParams = RaycastParams.new()
TerrainParams.IgnoreWater = true
TerrainParams.FilterType = Enum.RaycastFilterType.Exclude
TerrainParams.FilterDescendantsInstances = {JunkFolder, CharactersFolder}

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
            TargetVelocity = (MoveDirection*Vector3.new(1,0,1)).Unit * CharacterData.WalkSpeed

            --If autorotate is on and were moving then make character face towards move direction
            if AutoRotate then
                MovementData.LookDirection = MoveDirection
            end
        end

        --local LookDirection = Vector3.new(-MovementData.LookDirection.X, 0, MovementData.LookDirection.Z)

        --[[ --no mover / aligner
        if LookDirection.Magnitude > 0 then
            Aligner.Attachment0.CFrame = CFrame.lookAt(Vector3.new(), LookDirection)
        end
        ]]
        --Primary.CFrame = Primary.CFrame * CFrame.lookAt(Vector3.new(), LookDirection)

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

        --raycasting
        Velocity = Vector3.new(CurrentVelocityX, 0, CurrentVelocityZ)



        local wallCheck : RaycastResult = workspace:Raycast(
            Primary.Position+Velocity*DeltaTime+Vector3.yAxis*100
            ,-Vector3.yAxis*(100+STEPHEIGHT+0.001)
            ,TerrainParams
        )
        local step = 0
        if (wallCheck) then
            step = 100-wallCheck.Distance
            if (math.abs(step) > STEPHEIGHT) then
                Velocity *= Velocity.Magnitude/CharacterData.WalkSpeed -2
                step=0
                --Velocity -= MoveDirection / Velocity.Magnitude * 10
            end
        end

        MovementData.Velocity = Velocity

        local newPosition = Primary.Position + Vector3.yAxis*step + MovementData.Velocity*DeltaTime
        local lookDirection = (Velocity.Unit*0.85 + MovementData.travel.Unit*0.15).Unit
        --if (lookDirection == Vector3.zero or lookDirection == nil) then
        --    lookDirection = Vector3.zAxis
        --end

        local LookDirection = Vector3.new(-MovementData.LookDirection.X, 0, MovementData.LookDirection.Z)

        local Angle = CFrame.identity
        if Velocity.Magnitude > 0 then
            Angle = CFrame.lookAt(Vector3.zero, Velocity.Unit)
        end

        local newCFrame : CFrame = CFrame.new(newPosition)*Angle
        --newCFrame += newPosition
        --print(MovementData.travel)
        if (MovementData.travel ~= nil) then
        --    newCFrame *= CFrame.fromAxisAngle(-Vector3.yAxis, math.rad(90) + math.atan2(lookDirection.Z, lookDirection.X) or 0)
        end
        --newCFrame = CFrame.lookAt(newPosition, newCFrame:PointToWorldSpace(lookDirection))
        
        
        
        --[[if (newCFrame.Position.Y <= -1000) then
            newCFrame = CFrame.identity
            Velocity = 0
        end
        newCFrame += newPosition]]
        --[[
        if (newCFrame.Position.Magnitude >= 10000) then
            newCFrame = CFrame.new(newPosition)
        end
        ]]

        Character:PivotTo(
            newCFrame
        )
        --Character.Model:PivotTo(CFrame:new(Vector3.zero, lookDirection))

        --Mover.Enabled = true

        --Applies forces
        --Mover.Force = Vector3.new(MovementData.CurrentAccelerationX, 0, MovementData.CurrentAccelerationZ)*Primary.AssemblyMass
    end
end)

return Module