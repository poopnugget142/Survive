--TODO!
--Move this to playerscripts with a new PlayerStates

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stew = require(ReplicatedStorage.Packages.Stew)
local KeyBindings = require(ReplicatedStorage.Scripts.KeyBindings)
local CharacterDataModule = require(ReplicatedStorage.Scripts.CharacterData)

local World = Stew.World.Create()

local MoveDirections = {
	["Move Forward"] = Vector3.new(0, 0, 1).Unit;
	["Move Left"] = Vector3.new(1, 0, 0).Unit;
	["Move Backward"] = Vector3.new(0, 0, -1).Unit;
	["Move Right"] = Vector3.new(-1, 0, 0).Unit;
}

local MoveDirection = Vector3.new(0,0,0)

local CurrentMoveDirections = {}

World.Component.Build("PlayerMovement", {
    Constructor = function(Entity : Stew.Entity<any>, Name : Stew.Name)
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

	Destructor = function(Entity : Stew.Entity<any>, Name : Stew.Name)
		for ActionName, Direction in MoveDirections do
			KeyBindings.UnbindAction(ActionName, Enum.UserInputState.Begin)
			KeyBindings.UnbindAction(ActionName, Enum.UserInputState.End)
		end

		CurrentMoveDirections = {}
	end
})

local PlayerMovingCharacters : Stew.Collection = World.Collection.Get{"PlayerMovement"}

RunService:BindToRenderStep("PlayerMovement", Enum.RenderPriority.Character.Value, function()
    for Player : Player in PlayerMovingCharacters do
        MoveDirection = Vector3.new(0,0,0)

        for _, Direction in pairs(CurrentMoveDirections) do --only does things when keys are being held down
            MoveDirection += Direction
        end

        local CharacterData = CharacterDataModule.GetCharacterData(Player.Character)

        CharacterData.MoveDirection = MoveDirection
    end
end)

return World