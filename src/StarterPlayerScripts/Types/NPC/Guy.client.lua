local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.Scripts

local CharacterStates = require(ReplicatedScripts.States.Character)
local CharacterModule = require(ReplicatedScripts.Class.Character)
local Enums = require(ReplicatedScripts.Registry.Enums)
local EventHandler = require(ReplicatedScripts.Lib.Util.EventHandler)
local NpcRegistry = require(ReplicatedScripts.Registry.NPC)

local NpcEnum = Enums.NPC.Guy

local function CreateModel(Entity : any, Position : Vector3)
    local EntityData = CharacterStates.World.get(Entity)

    local Model = NpcRegistry.GetBaddieModel(NpcEnum):Clone()
    Model.Name = tostring(EntityData[CharacterStates.NPCId])
    Model.Parent = workspace.Characters.NPCs
    Model:MoveTo(Position)

    CharacterModule.RegisterCharacter(Entity, Model)

    local AnimationController : AnimationController = Model.Model.AnimationController

    local LoadedAnimations = {
        [Enums.States.Walking] = AnimationController:LoadAnimation(AnimationController.Walk);
        [Enums.States.Attacking] = AnimationController:LoadAnimation(AnimationController.Attack);
    }

    CharacterStates.LoadedAnimations.add(Entity, LoadedAnimations)

    CharacterModule.PlayAnimation(Entity, EntityData[CharacterStates.State])
end

local function RemoveModel(Entity : any)
    CharacterStates.Model.remove(Entity)
    CharacterStates.LoadedAnimations.remove(Entity)
end

local function Action(Entity : any, ActionEnum : number)
    local EntityData = CharacterStates.World.get(Entity)

    if ActionEnum == Enums.Action.Die then
        EventHandler.FireEvent("DeleteNpc", EntityData[CharacterStates.NPCId])
        CharacterStates.World.kill(Entity)
    elseif ActionEnum == Enums.Action.Attack then
        CharacterModule.SetState(Entity, Enums.States.Attacking)
    elseif ActionEnum == Enums.Action.Walk then
        CharacterModule.SetState(Entity, Enums.States.Walking)
    end
end

local function SetState(Entity : any, State : number)
    local EntityData = CharacterStates.World.get(Entity)

    if EntityData[CharacterStates.Model] then
        CharacterModule.PlayAnimation(Entity, State)
    end
end

CharacterStates[NpcEnum] = CharacterStates.World.factory({
    add = function(Factory, Entity : any, SpawnPosition : Vector3)
        CharacterStates.NPCType.add(Entity, NpcEnum)

        CharacterModule.SetState(Entity, Enums.States.Walking)

        local CreateModelSignal = EventHandler.CreateEntityEvent(Entity, "CreateModel")
        CreateModelSignal:Connect(CreateModel)

        local RemoveModelSignal = EventHandler.CreateEntityEvent(Entity, "RemoveModel")
        RemoveModelSignal:Connect(RemoveModel)

        local SetStateSignal = EventHandler.CreateEntityEvent(Entity, "SetState")
        SetStateSignal:Connect(SetState)

        local ActionSignal = EventHandler.CreateEntityEvent(Entity, "Action")
        ActionSignal:Connect(Action)

        return true
    end;
})