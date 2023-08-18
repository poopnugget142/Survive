local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)
local CharacterDataModule = require(ReplicatedStorage.Scripts.CharacterData)
local PlayerStates = require(ReplicatedStorage.Scripts.States.Player)

local MoveDirections = {
	["Move Forward"] = Vector3.new(0, 0, 1).Unit;
	["Move Left"] = Vector3.new(1, 0, 0).Unit;
	["Move Backward"] = Vector3.new(0, 0, -1).Unit;
	["Move Right"] = Vector3.new(-1, 0, 0).Unit;
}

local MoveDirection = Vector3.new(0,0,0)

local CurrentMoveDirections = {}

PlayerStates["ControllMovement"] = PlayerStates.World.factory("ControllMovement", ({
	add = function(Factory, Entity : Player)
		--Binds all input to their keys
		for ActionName, Direction in MoveDirections do
			KeyBindings.BindAction(ActionName, Enum.UserInputState.Begin, function()
				CurrentMoveDirections[ActionName] = Direction
			end)
		
			KeyBindings.BindAction(ActionName, Enum.UserInputState.End, function()
				--Remove input from list of directions
				CurrentMoveDirections[ActionName] = nil
			end)
		end

        return true
    end;

	remove = function(Factory, Entity : Player)
		--Removes key bindings
		for ActionName, Direction in MoveDirections do
			KeyBindings.UnbindAction(ActionName, Enum.UserInputState.Begin)
			KeyBindings.UnbindAction(ActionName, Enum.UserInputState.End)
		end

		CurrentMoveDirections = {}
	end;
}))

RunService:BindToRenderStep("ControllMovement", Enum.RenderPriority.Character.Value, function()
    for Player : Player in PlayerStates.World.query{PlayerStates.ControllMovement} do
        MoveDirection = Vector3.new(0,0,0)

        for _, Direction in pairs(CurrentMoveDirections) do --only does things when keys are being held down
            MoveDirection += Direction
        end

        local CharacterData = CharacterDataModule.GetCharacterData(Player.Character)
		CharacterData.WalkSpeed = 30

        CharacterData.MoveDirection = MoveDirection
    end
end)