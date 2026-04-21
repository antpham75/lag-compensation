local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LagCompensationModule = {}

local HistoryModule = require(game.ServerStorage:WaitForChild("HistoryModule"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local HitboxConfig = require(ReplicatedStorage:WaitForChild("HitboxConfig"))
local GunConfig = require(ReplicatedStorage:WaitForChild("GunConfig"))

local DEBUG_MODE = false

local CLIENT_SERVER_POS_THRESHOLD_STUDS = 10


-- HELPERS ----------------------------------------------------------------------

local function findClosestCFrame(enemyCFrames, rewindTimeStamp)
	local closestCFrame = nil
	local minTimeDifference = math.huge

	for timeVal, cFrame in pairs(enemyCFrames) do

		local timeDiff = math.abs(rewindTimeStamp - timeVal)

		if timeDiff < minTimeDifference then
			closestCFrame = cFrame
			minTimeDifference = timeDiff
		end

	end

	return closestCFrame, minTimeDifference
end

-- places part to see if raycast will hit it. 
-- change transparency of the part for visualization. 
local function spawnClonedHitbox(cFrame, partType)
	local hitboxClone = Instance.new("Part")

    hitboxClone.Name = "rewindHitbox"
	hitboxClone.Anchored = true
	hitboxClone.CanCollide = false
	hitboxClone.Material = Enum.Material.Neon
    hitboxClone.Transparency = 1

	if partType == "head" then
		hitboxClone.Color = Color3.new(0.231372, 0, 0)
        hitboxClone.CFrame = cFrame * HitboxConfig.head.offset
        hitboxClone.Size = HitboxConfig.head.size
    elseif partType == "body" then
        hitboxClone.Color = Color3.new(1, 0, 0)
        hitboxClone.CFrame = cFrame * HitboxConfig.body.offset
        hitboxClone.Size = HitboxConfig.body.size
	else
		warn("invalid partType passed into spawnClonedHitbox")
    end
	
	if DEBUG_MODE then
		hitboxClone.Transparency = 0.7
	end
	
	
	hitboxClone.Parent = workspace
	game.Debris:AddItem(hitboxClone, 2.5)
	return hitboxClone
end

local function printEnemyCFrameReport(enemyPlayerName, rewindVsServerTimeDiff )
	print("--------------------ENEMY CFRAME SEARCH-------------------------")
	print(`ENEMY {enemyPlayerName} `)
	print(string.format("Found closest server state, rewindTimestamp - storedTimestamp = %.5f", rewindVsServerTimeDiff))
	print("")
	print("     -------------------------     ")
	print("")
end

local function createVisualRaycastPart(startPos, endPos, rayDir)
	local rayPart = Instance.new("Part")
	rayPart.Anchored = true
	rayPart.CanCollide = false
	rayPart.Material = Enum.Material.Neon
	rayPart.Transparency = 0.5

	if endPos then
		local distance = (endPos - startPos).Magnitude
		rayPart.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, -0.1, -distance / 2 - 0.25)
		rayPart.Color = Color3.new(0, 1, 0)
		rayPart.Size = Vector3.new(0.1, 0.1, distance)
	else
		-- visualize ray hit nothing, color it red and go full length
		rayPart.Color = Color3.new(1, 0, 0)
		rayPart.Size = Vector3.new(0.1, 0.1, 1000)
		rayPart.CFrame = CFrame.lookAt(startPos, startPos + rayDir) * CFrame.new(0, -0.1, -500 - 0.25)
	end
	rayPart.Parent = workspace
	game.Debris:AddItem(rayPart, 2.5)
end

local function sanityCheckClientPos(clientPos, serverPos) 
	if (clientPos - serverPos).Magnitude > CLIENT_SERVER_POS_THRESHOLD_STUDS then -- threshold to account for lag
		warn("REJECTED: shot origin too far from server position")
		return false
	end

	return true
end


local function raycastOntoParts(raycastOrigin, rayDir, partList)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = partList
	raycastParams.FilterType = Enum.RaycastFilterType.Include

	local result = workspace:Raycast(raycastOrigin, rayDir * 1000, raycastParams)

	if not result then return nil end

	return result.Instance, result.Position
end

local function debugProcessShot(player, clientTime, hitboxHit, hitPosition, clientPos, rayDir, rewindHitboxes, enemyReports)
	print("\n\n------------------------------------LAG COMPENSATION REPORT-------------------------------------------------------")
	print(player.Name .. " SENT SHOT AT TIME --> " .. clientTime)
	print(`CLIENT'S PING: {player:GetNetworkPing()}`)

	for _, report in ipairs(enemyReports) do
		printEnemyCFrameReport(report.enemyName, report.timeDiff)
	end

	if hitboxHit then
		print("RESULTS: " .. player.Name .. " HIT " .. rewindHitboxes[hitboxHit].player.Name .. " ON THE " .. rewindHitboxes[hitboxHit].hitType)
		createVisualRaycastPart(clientPos, hitPosition, rayDir)
	else
		print("RESULTS: " .. player.Name .. " DIDN'T HIT ANY ENEMY PLAYERS")
		createVisualRaycastPart(clientPos, nil, rayDir)
	end

	print("------------------------------------------------------------------------------------------------------------------")
end





-- determine if client hit the shot on their screen
function LagCompensationModule.processShot(player, rayDir, clientTime, clientPos)

	if not sanityCheckClientPos(clientPos, player.Character.HumanoidRootPart.Position) then return end

	local rewindTimeStamp = clientTime - GameConfig.INTERP_DELAY -- what the client saw at clientTime (synchronized time) was the server state at rewindTimeStamp

	local rewindHitboxes = {} -- {[clonedHitbox]: enemyPlayer}
	local hitboxArray = {} -- list of every single cloned hitbox

	local enemyCFrameReports = {}
	for _, enemyPlayer in pairs(game.Players:GetPlayers()) do

		if enemyPlayer == player then continue end
		
	
		
		local enemyCFrames = HistoryModule.getHistory(enemyPlayer)
		if not enemyCFrames then continue end

		local closestCFrame, minTimeDifference = findClosestCFrame(enemyCFrames, rewindTimeStamp)
		
		if not closestCFrame then
			warn(`COULD NOT FIND CFRAMES FOR ENEMY: {enemyPlayer.Name}`)
			continue
		end
		
		-- spawn rewinded hitboxes
		local bodyClone = spawnClonedHitbox(closestCFrame, "body")
		local headClone = spawnClonedHitbox(closestCFrame, "head")
		
		-- store clone assigned to player for whenever we test to see if attack hit the rewind hitbox
		rewindHitboxes[bodyClone] = { player = enemyPlayer, hitType = "body" }
		rewindHitboxes[headClone] = { player = enemyPlayer, hitType = "head" }
		
		table.insert(hitboxArray, bodyClone)
		table.insert(hitboxArray, headClone)

		if DEBUG_MODE then
			table.insert(enemyCFrameReports, {
				enemyName = enemyPlayer.Name,
				timeDiff = minTimeDifference
			})
		end
		
	end



	local hitboxHit, hitPosition = raycastOntoParts(clientPos, rayDir, hitboxArray)

	-- apply damage
	if hitboxHit and rewindHitboxes[hitboxHit]["player"].Character:FindFirstChild("Humanoid") then
		local enemyHit = rewindHitboxes[hitboxHit]["player"]
		local hitType = rewindHitboxes[hitboxHit]["hitType"]

		local enemyHumanoid = enemyHit.Character:FindFirstChild("Humanoid")
		
		if hitType == "head" then
			enemyHumanoid:TakeDamage(GunConfig.HEAD_DAMAGE)
		else
			enemyHumanoid:TakeDamage(GunConfig.BODY_DAMAGE)
		end

	end

	if DEBUG_MODE then
		debugProcessShot(player, clientTime, hitboxHit, hitPosition, clientPos, rayDir, rewindHitboxes, enemyCFrameReports)
	end

end




return LagCompensationModule
