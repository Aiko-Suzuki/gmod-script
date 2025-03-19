-- Configuration variables
local triggerDistance = 500000 -- Using the original high value
local triggerDistanceSqr = triggerDistance * triggerDistance -- Pre-calculate for DistToSqr comparison
local maxSlow = 0.35
local slowDecrease = 0.05
local onlyTowards = true -- only slow down players moving towards the entity
local updateFrequency = 0.1 -- How often to update player positions (seconds)
-- Cache for optimization
local playerPositions = {}
local nextUpdate = 0
-- Check if the player is moving towards the entity
local function isPlayerMovingTowards(playerPosition, entityPosition, forwardDirection, sideDirection)
	local directionDifference = (entityPosition - playerPosition):GetNormalized()
	local dotProduct = forwardDirection:Dot(directionDifference) + sideDirection:Dot(directionDifference)
	return dotProduct >= 0
end

-- Calculate the slow down factor based on distance (using squared distance)
local function calculateSlowDown(distanceSqr)
	-- Convert squared distance back to approximate linear distance for calculation
	local distance = math.sqrt(distanceSqr)
	return math.max(slowDecrease + (distance / triggerDistance), maxSlow)
end

-- Hook to modify player movement
hook.Add("SetupMove", "PlayerSlowdownNearby", function(player, moveData, userCommand)
	if not player:IsValid() or not player:Alive() then return end
	local currentTime = CurTime()
	local playerPosition = moveData:GetOrigin()
	-- Update cached player positions periodically instead of every frame
	if currentTime > nextUpdate then
		playerPositions = {}
		-- Use FindInSphere instead of GetAll for much better performance
		local nearbyEntities = ents.FindInSphere(playerPosition, triggerDistance)
		for _, entity in ipairs(nearbyEntities) do
			if entity:IsPlayer() and entity:IsValid() and entity:Alive() and entity ~= player then playerPositions[entity] = entity:GetPos() end
		end

		nextUpdate = currentTime + updateFrequency
	end

	-- Skip if no other players to check
	if table.IsEmpty(playerPositions) then return end
	-- Get movement directions
	local moveAngles = moveData:GetMoveAngles()
	local forwardDirection = userCommand:GetForwardMove() > 0 and moveAngles:Forward() or -moveAngles:Forward()
	local sideDirection = userCommand:GetSideMove() > 0 and moveAngles:Right() or -moveAngles:Right()
	-- Track nearest player
	local nearestDistance = triggerDistanceSqr
	local foundNearbyPlayer = false
	-- Find the nearest player within the trigger distance
	for _, entityPosition in pairs(playerPositions) do
		local distanceSqr = playerPosition:DistToSqr(entityPosition)
		-- Skip if too far away (shouldn't happen with FindInSphere but keeping as safeguard)
		if distanceSqr >= triggerDistanceSqr then continue end
		-- Skip if only checking players we're moving towards and we're not moving towards this one
		if onlyTowards and not isPlayerMovingTowards(playerPosition, entityPosition, forwardDirection, sideDirection) then continue end
		-- Update if this is the closest player so far
		if distanceSqr < nearestDistance then
			nearestDistance = distanceSqr
			foundNearbyPlayer = true
		end
	end

	-- Apply slowdown if we found a nearby player
	if foundNearbyPlayer then
		local slowDown = calculateSlowDown(nearestDistance)
		moveData:SetForwardSpeed(slowDown * moveData:GetForwardSpeed())
		moveData:SetSideSpeed(slowDown * moveData:GetSideSpeed())
		moveData:SetMaxSpeed(slowDown * moveData:GetMaxSpeed())
		moveData:SetMaxClientSpeed(slowDown * moveData:GetMaxClientSpeed())
	end
end)