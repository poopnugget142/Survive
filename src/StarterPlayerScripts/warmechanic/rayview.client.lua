--[[
	note: i want to concat frames horizontally later on
	all unrevealed frames along a length will be combined into a long length

    add support for multiple LoS cones

    do some trig (cos) math to fix parallax error at tight angles

    texels and raycasts independent, allow for double the frame count + bilinear filtering
	
	rewrite the entire system to use stew (its better)
]]

-- initialise dependencies
local players : Players = game:GetService("Players")
local runService : RunService = game:GetService("RunService")
local userInputService: UserInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local module = require(replicatedStorage.Scripts.warmechanic.rayview)

local player : Player = players.LocalPlayer
local screenGui : ScreenGui = player.PlayerGui:WaitForChild("ScreenGui")

local cam : Camera = workspace.CurrentCamera
while (player.Character == nil) do task.wait() end
    local character : Model = player.Character
local root : Part = character:WaitForChild("HumanoidRootPart")

local windowFocused = true
--local remoteEvent = replicatedStorage:FindFirstChildOfClass("RemoteEvent")

--print(cam)


--generate a 'lightmap' ui which reflects custom lighting information from the server
local pixelMatrix = {}
local pixelSizeIMax = 80
local pixelSizeJMax = 80

local pixelSizeI = pixelSizeIMax
local pixelSizeJ = pixelSizeJMax

--field of view
local theta = math.rad(70)
theta /= 2

--sure
module.clientGenerateLightingMap()

--define the pixels along the screen
for i = 0, pixelSizeIMax do
	for j = 0, pixelSizeJMax do
		local dude = Instance.new("Frame")
		dude.Parent = screenGui:WaitForChild("losFrame")
		dude.Name = tostring(i) .. "," .. tostring(j)
		dude.BorderSizePixel = 0
		dude.Transparency = 0.8

		dude.Position = UDim2.new(
			i/pixelSizeIMax, 
			0, 
			j/pixelSizeJMax, 
			0
		)
		dude.Size = UDim2.new(1/pixelSizeIMax, 0, 1/pixelSizeJMax, 0)

		if not pixelMatrix[i] then
			pixelMatrix[i] = {}
		end
		--the lighting grid is defined as a grid of (i,j) coordinates
		--variables can be accessed at these coordinates
		pixelMatrix[i][j] = {
			frame = dude
		}
	end
	task.wait(0.01)
end

--get the hypotenuse of the screen
local screenHypo = math.sqrt(cam.ViewportSize.X^2 + cam.ViewportSize.Y^2)
--generate 3 triangles which coexist with the players FoV
local thetaInverse = 2*math.pi - theta*2
local thetaInverseI = thetaInverse/3
--local thetaInverseMul = thetaInverseI/(math.pi/2)

--reused function to set a pixel as transparent
local function TransparentPixel(i,j)
	pixelMatrix[i][j].frame.BackgroundColor3 = Color3.new(.1, .1, .1)
	pixelMatrix[i][j].frame.Transparency = 0.1
end


local debugger = {}

--dynamic resolution adjustments
local dynamicResolution = true
local desiredFps = 60
local desiredCount = 1800
--ignore
local historicalFps = {}
local dynamoHistory = {}

--line of sight adjustments
local lineOfSight = true
--raycasts spread across field of view
local distRays = 32

--iterate every physics step to see lighting, as well as determine line of sight
runService.RenderStepped:Connect(function(deltaTime)
	local maxCount = desiredCount
	local count = 0

	if (windowFocused == false) then
		return
	end

	--dynamic resolution
	if (dynamicResolution) then
		--compares the client's current fps to their average fps
		local currentFps = 1/deltaTime
		historicalFps[#historicalFps+1] = currentFps
		if (#historicalFps > 100) then
			table.remove(historicalFps, 1)
		end

		local averageFps = 0
		for c, anFps in ipairs(historicalFps) do
			averageFps += anFps
		end
		averageFps /= #historicalFps

		--use the average fps to create a dynamic resolution multipliers
		local dynamoMultiplier = math.clamp(
			(averageFps/desiredFps) --[[* (1/math.exp(player:GetNetworkPing()*0))]], 
			0, 
			1
		)
		--collect average multipliers to make the multiplier look nicer
		dynamoHistory[#dynamoHistory+1] = dynamoMultiplier
		if (#dynamoHistory > 100) then
			table.remove(dynamoHistory, 1)
		end
		local averageDynamo = 0
		for c, aDynamo in ipairs(dynamoHistory) do
			averageDynamo += aDynamo
		end
		averageDynamo /= #dynamoHistory
		--scale the resolution down
		pixelSizeI = math.floor( (pixelSizeIMax * averageDynamo) )
		pixelSizeJ = math.floor( (pixelSizeJMax * averageDynamo) )

		--this for loop still uses maxSize to hide excess frames
		for i = 0, pixelSizeIMax do
			for j = 0, pixelSizeJMax do
				local dude = pixelMatrix[i][j].frame
				dude.Position = UDim2.new(
					i/pixelSizeI, 
					0, 
					j/pixelSizeJ, 
					0
				)
				dude.Size = UDim2.new(1/pixelSizeI, 0, 1/pixelSizeJ, 0)

				if (i > pixelSizeI or j > pixelSizeJ) then
					dude.BackgroundColor3 = Color3.new(0, 0, 0)
					dude.Transparency = 0
				end
			end
		end
	else
		--if dynamic resolution is disabled, default to max resolution
		pixelSizeI = pixelSizeIMax
		pixelSizeJ = pixelSizeJMax
	end

	--mouse position relative to screen center
	local mousePosition = (userInputService:GetMouseLocation() - cam.ViewportSize/2)
	local mouseBearing = mousePosition.Unit

	--line of sight 
	--distance values spread across arc for LoS checks
	local distData = {}
	if (lineOfSight) then
		--filters
		local raycastParams = RaycastParams.new()
		--raycastParams.FilterDescendantsInstances = player.Character:GetChildren()
		raycastParams.FilterDescendantsInstances = {workspace.Characters, workspace.JunkFolder}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.IgnoreWater = true

		--loop for desired number of rays
		for r = 0, distRays do
			local camAngX, camAngY, camAngZ = cam.CFrame:ToEulerAnglesYXZ()
			local curAng = -(2*(r/distRays)-1)*theta - camAngY  --math.pi/2
			--later add cos relationship for camera pitch

			--rotates the mouse position along an arc using matrix math
			local rayBearing = Vector2.new(
				(mousePosition.X * math.cos(curAng)) - (mousePosition.Y * math.sin(curAng)),
				(mousePosition.X * math.sin(curAng)) + (mousePosition.Y * math.cos(curAng))
			)
			local rayOrigin = root.Position
			local rayDirection = Vector3.new(rayBearing.X, 0, rayBearing.Y).Unit
			--print (rayDirection)

			local rayResult = workspace:Raycast(rayOrigin, rayDirection * 1000, raycastParams)

			if (rayResult) then
				distData[r] = rayResult.Position
			else
				distData[r] = nil
			end
		end
		--print(distData)
	end

	for i = 0, pixelSizeI do
		for j = 0, pixelSizeJ do
			--pixel position relative to screen center
			local pixelPosition = cam.ViewportSize * (Vector2.new(i/pixelSizeI,j/pixelSizeJ) - Vector2.new(0.5,0.5))

			--rotates the pixel position 90 degrees using matrix math
			local pixelRight = Vector2.new(
				pixelPosition.X * math.cos(math.pi/2) - pixelPosition.Y * math.sin(math.pi/2),
				pixelPosition.X * math.sin(math.pi/2) + pixelPosition.Y * math.cos(math.pi/2)
			)

			--create a vector from two dot products, and compare it to the mouse angle
			local pixelDotForward = mouseBearing:Dot(pixelPosition.Unit)
			local pixelDotRight = mouseBearing:Dot(pixelRight.Unit)

			local relativeAngle = math.atan2(pixelDotRight,pixelDotForward)

			--check to see whether the pixel can be rendered
			if ( 
				math.abs(relativeAngle) <= theta and 
					count < maxCount
				) 
			then
				--raycast from camera at pixel coordinates (i,j)
				local unitRay = cam:ViewportPointToRay(
					(i/pixelSizeI)*cam.ViewportSize.X, 
					(j/pixelSizeJ)*cam.ViewportSize.Y
				)
				local rayResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 10000)


				--send data to server to return lighting information
				if (rayResult) then
					--LoS check
					--converts relative angle to dist data
					local distFinder = (relativeAngle/theta/2+0.5)*(distRays)
					--finds the floor and the modulo from the data for interpolation
					local distIndex, distModulo = math.modf(distFinder)
					--distance threshold to display pixel on screen
					local distPosition : Vector3 = root.Position
					local distThreshold = 0
					--interpolate between two distance points
					if ( not (distData[distIndex] == nil or distData[distIndex+1] == nil)) then
						distPosition = distData[distIndex]*(1-distModulo) + distData[distIndex+1]*distModulo
						distThreshold = (distPosition - root.Position).Magnitude + 2
					else
						distThreshold = 1000
					end
					local distCheck = (rayResult.Position - root.Position).Magnitude

					--check to see if LoS is enabled and distance threshold is not overflowing
					if ( 
						((lineOfSight == true and distCheck < distThreshold) 
							or lineOfSight == false) 
							and count < maxCount
						) 
					then
						--colour
						count += 1
						--remoteEvent:FireServer(i, j, rayResult.Position)
						
						
						--temp
						local _, _, color, alpha = module.computeTileData(i,j,rayResult.Position)
						
						pixelMatrix[i][j].frame.BackgroundColor3 = Color3.new(color.X, color.Y, color.Z)
						pixelMatrix[i][j].frame.Transparency = alpha
					else
						TransparentPixel(i,j)
					end
				else 
					TransparentPixel(i,j)
				end

				--print if there are too many light probes
				if (count >= maxCount) then
					print("Excessive light probes!")
				end
			else
				TransparentPixel(i,j)
			end

			--for dynamic resolution
			local previousCount = desiredCount
		end
	end

	--print(debugger)
end)

userInputService.WindowFocused:Connect(function()
	windowFocused = true
end)

userInputService.WindowFocusReleased:Connect(function()
	windowFocused = false
end)

--receive pixel information from the server
--[[
remoteEvent.OnClientEvent:Connect(function(i, j, color : Color3, alpha)
	pixelMatrix[i][j].frame.BackgroundColor3 = Color3.new(color.X, color.Y, color.Z)
	pixelMatrix[i][j].frame.Transparency = alpha
end)
]]


