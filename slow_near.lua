-- Configuration variables
local triggerDistance = 500000
local maxSlow = 0.35
local slowDecrease = 0.05
local onlyTowards = true -- only slow down players moving towards the entity
-- Check if the player is moving towards the entity
local function isPlayerMovingTowards(playerPosition, entityPosition, forwardDirection, sideDirection)
	local directionDifference = (entityPosition - playerPosition):GetNormalized()
	local dotProduct = forwardDirection:Dot(directionDifference) + sideDirection:Dot(directionDifference)
	return dotProduct >= 0
end

-- Calculate the slow down factor based on distance
local function calculateSlowDown(distance)
	return math.max(slowDecrease + (distance / triggerDistance), maxSlow)
end

-- Hook to modify player movement
hook.Add("SetupMove", "Test", function(player, moveData, userCommand)
	-- Create a filter for players in the same PVS
	local pFilter = RecipientFilter()
	pFilter:AddPVS(player:GetPos())
	if pFilter:GetCount() <= 1 then return end
	-- Get movement directions
	local moveAngles = moveData:GetMoveAngles()
	local forwardDirection = userCommand:GetForwardMove() > 0 and moveAngles:Forward() or -moveAngles:Forward()
	local sideDirection = userCommand:GetSideMove() > 0 and moveAngles:Right() or -moveAngles:Right()
	local playerPosition = moveData:GetOrigin()
	local nearestPlayer = nil
	-- Find the nearest player within the trigger distance
	for _, entity in pairs(pFilter:GetPlayers()) do
		if entity == player then continue end
		local entityPosition = entity:GetPos()
		local distance = playerPosition:DistToSqr(entityPosition)
		if distance >= triggerDistance then continue end
		if onlyTowards and not isPlayerMovingTowards(playerPosition, entityPosition, forwardDirection, sideDirection) then continue end
		if not nearestPlayer or distance < nearestPlayer.distance then
			nearestPlayer = {
				distance = distance
			}
		end
	end

	if not nearestPlayer then return end
	-- Apply the slow down factor to the player's movement
	local slowDown = calculateSlowDown(nearestPlayer.distance)
	moveData:SetForwardSpeed(slowDown * moveData:GetForwardSpeed())
	moveData:SetSideSpeed(slowDown * moveData:GetSideSpeed())
	moveData:SetMaxSpeed(slowDown * moveData:GetMaxSpeed())
	moveData:SetMaxClientSpeed(slowDown * moveData:GetMaxClientSpeed())
end)