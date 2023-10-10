if script:GetActor() == nil then
    return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local Promise = require(ReplicatedStorage.Packages.Promise)

local Actor : Actor = script.Parent

local SharedNpcData = SharedTableRegistry:GetSharedTable("NpcData")
local QueryNpcModels = SharedTableRegistry:GetSharedTable("QueryNpcModels")

local RenderedGuys = {}
local DeletePromise = {}

Actor:BindToMessageParallel("AddNpc", function(NpcId : number)
    RenderedGuys[NpcId] = true
end)

Actor:BindToMessageParallel("RemoveNpc", function(NpcId : number)
    RenderedGuys[NpcId] = nil
    QueryNpcModels[NpcId] = false
end)

RunService.RenderStepped:ConnectParallel(function(DeltaTime)
    local MovedNpcs = {}

    for NpcId, Value in RenderedGuys do

        local NpcData = SharedNpcData[tostring(NpcId)]

        local LastPosition : Vector3 = NpcData.LastPosition
        local NewPosition : Vector3 = NpcData.NewPosition

        --Lerp so that things off screen will appear before they enter the screen
        local _, OnScreen = workspace.CurrentCamera:WorldToScreenPoint(SharedNpcData.CenterPosition:Lerp(NewPosition, 0.9))

        local Model : Model = workspace.Characters.NPCs:FindFirstChild(tostring(NpcId))

        if not OnScreen then
            --Only move if the character is on screen
            if NpcData.Hidden then continue end

            NpcData.Hidden = true

            DeletePromise[NpcId] = Promise.try(function(resolve, reject, onCancel)
                task.wait(5)
                QueryNpcModels[NpcId] = false
            end)

            continue
        end

        if NpcData.Hidden then
            NpcData.Hidden = false
            if DeletePromise[NpcId] then
                DeletePromise[NpcId]:cancel()
            end
        end

        if not Model and not QueryNpcModels[NpcId] then
            QueryNpcModels[NpcId] = LastPosition
        end

        if not Model then continue end

        local CurrentPosition = Model.PrimaryPart.Position

        --Calculates a alpha between 0 and 1 that represents the position between the last and new position
        local NpcDeltaTime = (tick()-NpcData.LastTick)

        local DeltaTime = tick() - NpcData.NewTick

        NpcData.Alpha += DeltaTime
        local Alpha = NpcData.Alpha/NpcDeltaTime

        --local blend = Alpha / ((Alpha^2 + (1/NpcDeltaTime)^0.5 )^0.5)
        local blend = (
            (1-math.exp(-2*NpcDeltaTime*Alpha))
            /(1+math.exp(-2*NpcDeltaTime*Alpha))
        )
        --print(blend)

        local Position : Vector3 = LastPosition:Lerp(NewPosition, blend)

        if (CurrentPosition-Position).Magnitude == 0  then
            --Only move if there is a change in position
            continue
        end

        local Angle = CFrame.lookAt(CurrentPosition, Position)
        local NewCFrame = CFrame.new(Position)*(Angle-Angle.Position)
        
        MovedNpcs[NpcId] = NewCFrame
    end

    task.synchronize()
    for NpcId, NewCFrame in MovedNpcs do
        local Model : Model = workspace.Characters.NPCs:FindFirstChild(tostring(NpcId))
        if Model then
            Model:PivotTo(NewCFrame)
        end
    end
    task.desynchronize()
end)