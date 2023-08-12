-- initialise dependencies
local replicatedStorage = game:GetService("ReplicatedStorage")

local remoteEvent = replicatedStorage:FindFirstChildOfClass("RemoteEvent")

-- instantiate a pathfinding grid
local tileMatrix = {}
local tileSizeI = 100
local tileSizeJ = 100
local tileScale = Vector3.new(5, 0, 5)
for i = 0, tileSizeI do
	for j = 0, tileSizeJ do
		if not tileMatrix[i] then
			tileMatrix[i] = {}
		end
		--the lighting grid is defined as a grid of (i,j) coordinates
		--variables can be accessed at these coordinates
		local preColor = Color3.fromHSV(
			math.random(0,100)/100,
			0.5,
			1
		)
		tileMatrix[i][j] = {
			identifier = tostring(i) .. ", " .. tostring(j),
			cost = 1,
			heat = 0
		}
	end
end

local adjacents : Vector2 = {
	Vector2.new(1,0),
	Vector2.new(0,1),
	Vector2.new(0,-1),
	Vector2.new(-1,0),
}

function Pathfind(startPosition : Vector2)
	print("Pathfinding Go!")
	local frontier = {}
	frontier[1] = {
		position = startPosition,
		heat = 1
	}
	local explored = {}
	
	while (#frontier > 0 or frontier[1].position.X >= 50) do
		local current = frontier[1] 
		
		for _, adjacent in ipairs(adjacents) do
			local adjacentPosition = current.position + adjacent
			if (table.find(explored, adjacentPosition)) then --skip instances that have already been witnessed
				continue
			end
			--print (adjacentPosition)
			local adjacentTile = tileMatrix[math.round(adjacentPosition.X)][math.round(adjacentPosition.Y)]
			--print(adjacentTile)
			
			local currentCost : number = current.heat
			local adjacentCost : number = 0
				if (not (adjacentTile[1] == nil) ) then adjacentCost = adjacentTile.cost end
			
			local newcost = currentCost + adjacentCost
			if newcost < current.heat then
				current.heat += newcost
			end
			frontier[#frontier+1] = adjacentTile
		end
		
		explored[#explored+1] = current
		--frontier[1] = nil -- does not work
		--table.move(frontier, 2, #frontier, 1, frontier) -- does not work
		print (frontier)
		--print (explored)
	end
	task.wait(0.001)
end

Pathfind(Vector2.new(50,50))