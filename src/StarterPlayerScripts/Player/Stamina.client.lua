local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage.Assets.GUI

local CharacterStates = require(ReplicatedStorage.Scripts.States.Character)
local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)

local Player = game.Players.LocalPlayer

--We need some sort of cooldown so the player doesn't just spam sprint

CharacterStates.Stamina = CharacterStates.World.factory("Stamina", {
    add = function(Factory, Entity : Model, Stamina : number)
        local StaminaBar = Assets.Stamina:Clone()
        StaminaBar.Parent = Entity:WaitForChild("HumanoidRootPart")
        StaminaBar.Enabled = false

        return {
            Current = Stamina;
            Max = Stamina;
            Bar = StaminaBar;
        }
    end;
})

CharacterStates.Sprinting = CharacterStates.World.factory("Sprinting", {
    add = function(Factory, Entity : Model)

        --Entity.Humanoid.WalkSpeed = 24

        return true
    end;

    remove = function(Factory, Entity : Model)
        Entity.Humanoid.WalkSpeed = 16
    end;
})

KeyBindings.BindAction("Sprint", Enum.UserInputState.Begin, function()
    CharacterStates.Sprinting.add(Player.Character)
end)

KeyBindings.BindAction("Sprint", Enum.UserInputState.End, function()
    CharacterStates.Sprinting.remove(Player.Character)
end)

RunService.RenderStepped:Connect(function(DeltaTime)
    for Character in CharacterStates.World.query{CharacterStates.Stamina} do
        local CharacterData = CharacterStates.World.get(Character)
        local Stamina = CharacterData.Stamina

        if not Stamina then
            continue
        end

        local alpha = Stamina.Current/Stamina.Max

        if CharacterData.Sprinting then
            Stamina.Current -= DeltaTime
            Stamina.Bar.Enabled = true
            
            --it's not good to have speed that makes you move at inconsisten speeds
            --(IT'S ALSO CONFUSING TO THE PLAYER)
            Character.Humanoid.WalkSpeed = 16*(1-alpha) + 24*alpha --warmechanic code
        elseif Stamina.Current < Stamina.Max then
            Stamina.Current = math.min(
                Stamina.Current + DeltaTime/2
                ,Stamina.Max
            )
            --Stamina.Current += DeltaTime
            Stamina.Bar.Enabled = true

            if Stamina.Current >= Stamina.Max then
                --Stamina.Current = Stamina.Max
                Stamina.Bar.Enabled = false
            end
            Character.Humanoid.WalkSpeed = 16
        end

        local Fill : Frame = Stamina.Bar.Back.Fill
        Fill.Size = UDim2.new(Stamina.Current/Stamina.Max, 0, 1, 0)
        local fillgradient = Fill.UIGradient.Offset
        Fill.UIGradient.Offset = fillgradient - Vector2.new(
            1/60 * 3 --delta
            - (math.sign(fillgradient.X-1)+1) --if fillgradient.x > 1
            + (math.sign(fillgradient.X+1)-1) --if fillgradient.x < 1
        ,0)

        if Stamina.Current <= 0 then
            CharacterStates.Sprinting.remove(Character)
        end
    end
end)