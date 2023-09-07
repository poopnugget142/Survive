local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Squash = require(ReplicatedStorage.Packages.Squash)

local UpdateNPCPosition : RemoteEvent = ReplicatedStorage.Remotes.UpdateNPCPosition

--for raycastparams
local CharactersFolder = workspace:WaitForChild("Characters")
local JunkFolder = workspace:WaitForChild("JunkFolder")

local Actor : Actor = script.Parent

local FRAMERATE = 1 / 240
local STIFFNESS = 300
local DAMPING = 30
local PRECISION = 0.001
local STEPHEIGHT = 1

local AllMovementData = {}

Actor:BindToMessage("CreateMovementData", function(NpcId : number, Character : Model, StartingPosition : Vector3, WalkSpeed : number)
    AllMovementData[NpcId] = {
        MoveDirection =  Vector3.new()
        ;LookDirection = Vector3.new()
        ;Velocity = Vector3.new()
        ;AccumulatedTime = 0
        ;Position = StartingPosition or Vector3.zero
        ;WalkSpeed = WalkSpeed or 16
        ;Character = Character
    }
end)

Actor:BindToMessage("UpdateMoveDirection", function(NpcId : number, MoveDirection : Vector3)
    assert(AllMovementData[NpcId], "Movement data hasn't been created yet")

    AllMovementData[NpcId].MoveDirection = MoveDirection
end)

Actor:BindToMessage("UpdateWalkSpeed", function(NpcId : number, WalkSpeed : number)
    assert(AllMovementData[NpcId], "Movement data hasn't been created yet")

    AllMovementData[NpcId].WalkSpeed = WalkSpeed
end)

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

RunService.Heartbeat:ConnectParallel(function(DeltaTime)
    for NpcId, MovementData in AllMovementData do
        local Position = MovementData.Position

        local Velocity = MovementData.Velocity or Vector3.zero
        local CurrentVelocityX = Velocity.X
        local CurrentVelocityZ = Velocity.Z


        local TargetVelocity = Vector3.new()

        local MoveDirection = MovementData.MoveDirection -- Would explode if Y wasn't 0

        if MoveDirection.Magnitude > 0 then
            --If MoveDirection magnititude is 0 then we get nan
            TargetVelocity = (MoveDirection*Vector3.new(1,0,1)).Unit * MovementData.WalkSpeed

            --If autorotate is on and were moving then make character face towards move direction
            if MovementData.AutoRotate then
                MovementData.LookDirection = MoveDirection
            end
        end

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
            Position+Velocity*DeltaTime+Vector3.yAxis*100
            ,-Vector3.yAxis*(100+STEPHEIGHT+0.001)
            ,TerrainParams
        )
        local step = 0
        if (wallCheck) then
            step = 100-wallCheck.Distance
            if (math.abs(step) > STEPHEIGHT) then
                Velocity *= Velocity.Magnitude/MovementData.WalkSpeed -2
                step=0
                --Velocity -= MoveDirection / Velocity.Magnitude * 10
            end
        end

        MovementData.Velocity = Velocity

        local newPosition = Position + Vector3.yAxis*step + MovementData.Velocity*DeltaTime
        MovementData.Position = newPosition
    end

    task.synchronize()
    
    local PositionDataArray = {}
    for NpcId, MovementData in AllMovementData do
        local Position = MovementData.Position
        MovementData.Character:MoveTo(Position)
        table.insert(PositionDataArray, Squash.uint.ser(NpcId, 2))
        table.insert(PositionDataArray, Squash.Vector3.ser(Position))
    end

    if #PositionDataArray == 0 then return end
    UpdateNPCPosition:FireAllClients(PositionDataArray)
end)

return Module