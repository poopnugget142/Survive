local PlayerService = game:GetService("Players")
local TS = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataFolder = ReplicatedStorage.Data

local Player = PlayerService.LocalPlayer

local HUD = Player.PlayerGui:WaitForChild("HUD")

local WaveBar = HUD:WaitForChild("WaveBar")
local Arrow = WaveBar:WaitForChild("Arrow")

local WaveNumber : IntValue = DataFolder.Wave

local ArrowBounce = TS:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, -1, true), {Position = UDim2.new(-1.5, 0, 0, 0)})
local ArrowFadeIn = TS:Create(Arrow, TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {ImageTransparency = 0})
local ArrowFadeOut = TS:Create(Arrow, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {ImageTransparency = 1})



WaveNumber:GetPropertyChangedSignal("Value"):Connect(function()
    WaveBar.WaveNumber.Text = WaveNumber.Value
    ArrowBounce:Play()
    ArrowFadeIn:Play()
    task.wait(2)
    ArrowFadeOut:Play()
    task.wait(1)
    ArrowBounce:Cancel()
end)