local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

local Remotes = ReplicatedStorage.Remotes

local Promise = require(ReplicatedStorage.Packages.Promise)

local HealthUpdate : RemoteEvent = Remotes.UpdateHealth

local Player = game:GetService("Players").LocalPlayer

local HUD : ScreenGui = Player.PlayerGui:WaitForChild("HUD")
local HealthBar : Frame = HUD.HealthBar
HealthBar.Visible = true

local HealthFill : Frame = HealthBar.GreenFill
local RedFill : Frame = HealthBar.RedFill
local HealthPercent : TextLabel = HealthBar.Percent

local CurrentPromise

--Make this into a promise so it can be cancelled
--Also make it so that it doesn't show red if the health is going up
HealthUpdate.OnClientEvent:Connect(function(CurrentHealth, DamageType)
    if CurrentPromise and Promise.is(Promise) then
        CurrentPromise:Cancel()
    end

    CurrentPromise = Promise.new(function(Resolve, Reject, onCancel)
        local HealthNumber = math.max(CurrentHealth, 0)

        HealthPercent.Text = tostring(math.floor(HealthNumber*100)) .. "%"

        local HealthSize = UDim2.new(HealthNumber, 0, 1, 0)

        local HealthMove = TS:Create(HealthFill, TweenInfo.new(0.4), {Size = HealthSize})
        local RedMove = TS:Create(RedFill, TweenInfo.new(0.2), {Size = HealthSize})

        onCancel(function()
            HealthMove:Cancel()
            RedMove:Cancel()
            HealthFill.Size = HealthSize
            RedFill.Size = HealthSize
        end)

        HealthMove:Play()
        HealthMove.Completed:Wait()
        task.wait(1)
        RedMove:Play()
    end)
end)