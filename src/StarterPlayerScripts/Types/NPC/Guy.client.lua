local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local CharacterModule = require(ReplicatedStorage.Scripts.Class.Character)
local Enums = require(ReplicatedStorage.Scripts.Enums)
local EventHandler = require(ReplicatedStorage.Scripts.Util.EventHandler)
local NpcRegistry = require(ReplicatedStorage.Scripts.Registry.NPC)

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
        EventHandler.FireEvent("Npc", "DeleteNpc", EntityData[CharacterStates.NPCId])
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

        local CreateModelSignal = EventHandler.CreateEvent(Entity, "CreateModel")
        CreateModelSignal:Connect(CreateModel)

        local RemoveModelSignal = EventHandler.CreateEvent(Entity, "RemoveModel")
        RemoveModelSignal:Connect(RemoveModel)

        local SetStateSignal = EventHandler.CreateEvent(Entity, "SetState")
        SetStateSignal:Connect(SetState)

        local ActionSignal = EventHandler.CreateEvent(Entity, "Action")
        ActionSignal:Connect(Action)

        return true
    end;
})