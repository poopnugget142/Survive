local Module = {}
Module.DecimalPlaces = 2

--Parses a bullet and returns the bare minimum necessary to reconstruct it on the server / other clients
function Module.ParseVector3(Vector3In : Vector3)
	local Scale = 10 ^ Module.DecimalPlaces
	local Vector3Out16 = Vector3int16.new(Vector3In.X, Vector3In.Y, Vector3In.Z)

	return Vector3Out16
end

--Recieves the parsed bullet information and fires a reconstructed bullet
function Module.ReceiveVector3(Vector3In16 : Vector3int16)
	local Scale = 10 ^ -Module.DecimalPlaces
	local Vector3Out = Vector3.new(Vector3In16.X, Vector3In16.Y, Vector3In16.Z)

	return Vector3Out
end

return Module