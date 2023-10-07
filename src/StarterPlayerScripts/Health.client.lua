local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

local Remotes = ReplicatedStorage.Remotes

local HealthUpdate : RemoteEvent = Remotes.UpdateHealth

local Player = game:GetService("Players").LocalPlayer

local HUD : ScreenGui = Player.PlayerGui:WaitForChild("HUD")
local HealthBar : Frame = HUD.HealthBar
HealthBar.Visible = true

local HealthFill : Frame = HealthBar.GreenFill
local RedFill : Frame = HealthBar.RedFill

--Make this into a promise so it can be cancelled
HealthUpdate.OnClientEvent:Connect(function(CurrentHealth, DamageType)
    local HealthNumber = math.max(CurrentHealth/1, 0)

    local HealthMove = TS:Create(HealthFill, TweenInfo.new(0.4), {Size = UDim2.new(HealthNumber, 0, 1, 0)})
    HealthMove:Play()
    HealthMove.Completed:Wait()
    task.wait(1)
    TS:Create(RedFill, TweenInfo.new(0.2), {Size = UDim2.new(HealthMove, 0, 1, 0)}):Play()
end)