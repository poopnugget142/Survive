local module = {}

module.server = function()
	
end

local tileMatrix = {}
local tileSizeI = 100
local tileSizeJ = 100
local tileScale = Vector3.new(5, 0, 5)
module.clientGenerateLightingMap = function()
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
				identifier = "(" .. tostring(i) .. "+" .. tostring(j) .. ")",
				color = Vector3.new(
					math.random(0.5,1),
					math.random(0.5,1),
					math.random(0.5,1)
				)
				--[[color = Vector3.new(
					math.sqrt((tileSizeI - i)^2 + (tileSizeJ - j)^2) / math.sqrt((tileSizeI)^2 + (tileSizeJ)^2),
					math.sqrt(i^2 + j^2) / math.sqrt(tileSizeI^2 + tileSizeJ^2),
					0
				)]]
				--color = Vector3.new(preColor.R, preColor.G, preColor.B)
				,--alpha = math.random(0.5,1)
				alpha = 0.75
			}		
		end
	end	
end

local adjacents : Vector3 = {
	Vector3.new(0,0,0),
	Vector3.new(1,0,0),
	Vector3.new(0,0,1),
	Vector3.new(1,0,1)
}
module.computeTileData = function(i, j, rayPosition : Vector3)
	--snaps the poisition of the ray to the lightmap
	local originPosition : Vector3 = Vector3.new(
		math.floor(rayPosition.X),
		0,
		math.floor(rayPosition.Z)
	)
	--start at color black for averages
	local finalColor = Vector3.new(0,0,0)
	local finalAlpha = 1

	--compute the color of the pixel 4 times to get the interpolated color
	--bilinear filtering
	for k, adjacent in ipairs(adjacents) do
		if (math.min(originPosition.X + adjacent.X, originPosition.Z + adjacent.Z) >= 0) then
			local n : IntValue = math.clamp(
				math.ceil( (originPosition.X + adjacent.X) / tileScale.X ), 
				0, 
				tileSizeI
			)

			local m : IntValue = math.clamp( 
				math.ceil( (originPosition.Z + adjacent.Z) / tileScale.Z ),
				0, 
				tileSizeJ
			)			
			local point = tileMatrix[n][m]
			--if a point exists, get the color
			if (point) then
				--sqrt(2)/2 = 1.414... the maximum distance of a square
				finalColor += point.color * (math.sqrt(2)/2)
				finalAlpha += point.alpha * (math.sqrt(2)/2)
			end
		end
	end
	--averages
	finalColor /= 4
	finalAlpha /= 4
	
	return i, j, finalColor, finalAlpha
end

return module