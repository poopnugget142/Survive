--[[
Notetaking
    Start off with temp pick / place controls
    Then move controls to be item specific (implement bullet belt linkage)

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local GridventoryCore = require(ReplicatedStorage.Scripts.Util.GridventoryCore)
local KeyBindings = require(ReplicatedStorage.Scripts.Util.KeyBindings)


local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local PlayerGui = Player:WaitForChild("PlayerGui")
local ScreenGui : ScreenGui = PlayerGui:WaitForChild("ScreenGui")


