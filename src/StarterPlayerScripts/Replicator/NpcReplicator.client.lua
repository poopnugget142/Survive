--[[
    Notes need way to remove npcs on death
]]
if script:GetActor() == nil then
    print("returning")
    return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local NpcRegistry = require(ReplicatedStorage.Scripts.Registry.NPC)
local Promise = require(ReplicatedStorage.Packages.Promise)

local Actor : Actor = script.Parent

local SharedNpcData = SharedTableRegistry:GetSharedTable("NpcData")

local RenderedGuys = {}
local DeletePromise = {}

Actor:BindToMessageParallel("AddNpc", function(NpcId : number)
    RenderedGuys[NpcId] = true
end)

Actor:BindToMessage("RemoveNpc", function(NpcId : number)
    RenderedGuys[NpcId] = nil
    local Model : Model = workspace.Characters.NPCs:FindFirstChild(tostring(NpcId))
    if Model then
        Model:Destroy()
    end
end)

RunService.RenderStepped:ConnectParallel(function(DeltaTime)
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
                task.synchronize()
                Model:Destroy()
                task.desynchronize()
            end)

            continue
        end

        if NpcData.Hidden then
            NpcData.Hidden = false
            if DeletePromise[NpcId] then
                DeletePromise[NpcId]:cancel()
            end
        end

        if not Model then
            task.synchronize()
            Model = NpcRegistry.GetBaddieModel(NpcData.Enum):Clone()
            Model.Name = tostring(NpcId)
            Model.Parent = workspace.Characters.NPCs
            Model:MoveTo(LastPosition)
            task.desynchronize()
        end

        local CurrentPosition = Model.PrimaryPart.Position

        --Calculates a alpha between 0 and 1 that represents the position between the last and new position
        local Alpha = math.clamp((tick()-NpcData.LastTick)/(NpcData.NewTick-NpcData.LastTick), 0, 1)

        local Position : Vector3 = LastPosition:Lerp(NewPosition, Alpha)

        if (CurrentPosition-Position).Magnitude == 0  then
            --Only move if there is a change in position
            continue
        end

        local Angle = CFrame.lookAt(CurrentPosition, Position)
        local NewCFrame = CFrame.new(Position)*(Angle-Angle.Position)

        task.synchronize()
        Model:PivotTo(NewCFrame)
        task.desynchronize()
    end
end)