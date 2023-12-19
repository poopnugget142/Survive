if script:GetActor() == nil then
    return
end

local RunService = game:GetService("RunService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")

--for raycastparams
local CharactersFolder = workspace:WaitForChild("Characters")
local JunkFolder = workspace:WaitForChild("JunkFolder")

local FRAMERATE = 1 / 240
local STIFFNESS = 300
local DAMPING = 30
local PRECISION = 0.001
local STEPHEIGHT = 1

local AllMovementData = SharedTableRegistry:GetSharedTable("AllMovementData")
local RenderedGuys = {}

local Actor = script:GetActor()

Actor:BindToMessageParallel("AddNpc", function(NpcId : number)
    RenderedGuys[NpcId] = true
end)

Actor:BindToMessageParallel("RemoveNpc", function(NpcId : number)
    RenderedGuys[NpcId] = nil
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

RunService.Heartbeat:ConnectParallel(function(deltaTime)
    for NpcId, Value in RenderedGuys do
        local MovementData = AllMovementData[NpcId]

        local Position = MovementData.Position

        local Velocity = MovementData.Velocity or Vector3.zero
        local CurrentVelocityX = Velocity.X
        local CurrentVelocityZ = Velocity.Z


        local TargetVelocity = Vector3.new()

        local MoveDirection = MovementData.MoveDirection -- Would explode if Y wasn't 0

        if MoveDirection.Magnitude > 0 then
            --If MoveDirection magnititude is 0 then we get nan
            
            --TargetVelocity = (MoveDirection*Vector3.new(1,0,1)).Unit * CharacterData.WalkSpeed.Current
            TargetVelocity = (MoveDirection*Vector3.new(1,0,1)).Unit * MovementData.WalkSpeed

            --If autorotate is on and were moving then make character face towards move direction
            if MovementData.AutoRotate then
                MovementData.LookDirection = MoveDirection
            end
        end

        --Incremeants time
        MovementData.AccumulatedTime = (MovementData.AccumulatedTime or 0) + deltaTime

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

        local stepCheck : RaycastResult = workspace:Raycast(
            Position+Velocity*deltaTime+Vector3.yAxis*100
            ,-Vector3.yAxis*(100+STEPHEIGHT+0.001)
            ,TerrainParams
        )
        local step = 0
        if (stepCheck) then
            step = 100-stepCheck.Distance
            if (math.abs(step) > STEPHEIGHT) then
                --Velocity *= Velocity.Magnitude/MovementData.WalkSpeed -2
                --[[
                
                Velocity = Velocity * SpeedAlpha + MoveRight * math.sign(Velocity:Dot(MoveRight)) * MovementData.WalkSpeed * (1-SpeedAlpha)]]
                
                --Velocity -= MoveDirection / Velocity.Magnitude * 10

                local SpeedAlpha = (Velocity.Magnitude/MovementData.WalkSpeed -1)
                local MoveRight = Vector3.new(-MoveDirection.Z, 0, MoveDirection.X)
                local wallCheck : RaycastResult = workspace:Raycast(
                    Position
                    ,Velocity*deltaTime
                    ,TerrainParams
                )
                if wallCheck then
                    Velocity = (
                        Velocity * SpeedAlpha 
                        + wallCheck.Normal * MovementData.WalkSpeed * (1-SpeedAlpha) * (2/3)
                        + MoveRight * math.sign(MoveRight:Dot(wallCheck.Normal)) * MovementData.WalkSpeed * (1-SpeedAlpha) * (1/3)
                    )
                else
                    Velocity = Velocity * SpeedAlpha
                end
                step=0
            end
        end

        MovementData.Velocity = Velocity

        local newPosition = Position + Vector3.yAxis*step + MovementData.Velocity*deltaTime
        MovementData.Position = newPosition
    end
end)

return Module