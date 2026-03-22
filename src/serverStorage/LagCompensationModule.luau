local LagCompensationModule = {}

local HistoryModule = require(game.ServerStorage:WaitForChild("HistoryModule"))
local GameConfig = require(game.ReplicatedStorage:WaitForChild("GameConfig"))


-- HELPERS ----------------------------------------------------------------------

local function findClosestCFrameDict(enemyCFrames, rewindTimeStamp)
	local closestCFrameDict = nil
	local minTimeDifference = math.huge
	for timeVal, cFrameDict in pairs(enemyCFrames) do
		local timeDiff = math.abs(rewindTimeStamp - timeVal)
		if timeDiff < minTimeDifference then
			closestCFrameDict = cFrameDict
			minTimeDifference = timeDiff
		end
	end
	return closestCFrameDict, minTimeDifference
end

-- places part for visualization AND for raycast to hit it
local function cloneAndPositionHitbox(hitboxPart, cframe, partType)
	local clone = hitboxPart:Clone()
	local weld = clone:FindFirstChildOfClass("WeldConstraint")
	if weld then weld:Destroy() end
	clone.Anchored = true
	clone.CanCollide = false
	clone.Material = Enum.Material.Neon
	clone.Color = Color3.new(1, 0, 0)
	if partType == "head" then
		clone.Color = Color3.new(0.458824, 0, 0)
	end
	clone.Transparency = 0.7
	clone.CFrame = cframe
	clone.Parent = workspace
	game.Debris:AddItem(clone, 2.5)
	return clone
end






function LagCompensationModule.processShot(player, rayDir, clientTime, clientPos)
	print("\n\n------------------------------------LAG COMPENSATION REPORT-------------------------------------------------------")
	print(player.Name .. " SENT SHOT AT TIME --> " .. clientTime)
	
	local ping = player:GetNetworkPing()
	print(`CLIENT'S PING: {ping}`)
	
	-- sanity check client position
	local serverPosition = player.Character.HumanoidRootPart.Position
	local distance = (clientPos - serverPosition).Magnitude

	if distance > 10 then -- threshold to account for lag
		print("REJECTED: position too far from server position")
		return
	end

	local rewindTimeStamp = clientTime - GameConfig.INTERP_DELAY -- what the client saw at clientTime (synchronized time) was the server state at rewindTimeStamp

	local rewindHitboxes = {} -- {[clonedHitbox]: enemyPlayer}
	local hitboxArray = {}
	
	print("--------------------ENEMY CFRAME SEARCH-------------------------")
	for _, enemyPlayer in pairs(game.Players:GetPlayers()) do

		if enemyPlayer == player then continue end

		print(`ENEMY {enemyPlayer.Name} `)
		local enemyCFrames = HistoryModule.getHistory(enemyPlayer)
		if not enemyCFrames then continue end

		local closestCFrameDict, minTimeDifference = findClosestCFrameDict(enemyCFrames, rewindTimeStamp)
		
		print(string.format("FOUND STORED SERVER STATE, REWIND TIMESTAMP VS STORED TIMESTAMP DIFFERENCE: %.5f", minTimeDifference))
		print("")
		print("     -------------------------     ")
		print("")
		local enemyBodyHitbox = enemyPlayer.Character:FindFirstChild("Hitbox")
		local enemyHeadHitbox = enemyPlayer.Character:FindFirstChild("HeadHitbox")
		
		if not enemyBodyHitbox or not enemyHeadHitbox then 
			warn(`NO HITBOXES FOUND... FOR ENEMY: {enemyPlayer.Name}`)
			continue
		end

		-- rewound hitbox
		local bodyClone = cloneAndPositionHitbox(enemyBodyHitbox, closestCFrameDict["body"], "body")
		local headClone = cloneAndPositionHitbox(enemyHeadHitbox, closestCFrameDict["head"], "head")
		
		-- add to list of hitboxes to check
		rewindHitboxes[bodyClone] = { player = enemyPlayer, hitType = "body" }
		rewindHitboxes[headClone] = { player = enemyPlayer, hitType = "head" }
		
		table.insert(hitboxArray, bodyClone)
		table.insert(hitboxArray, headClone)

		
	end
	print("------------------------------------------------------------------------------------------------------------------")
	

	-- 3. CREATE RAYCAST PARAMS AND PERFORM RAYCAST
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = hitboxArray
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local result = workspace:Raycast(clientPos, rayDir * 1000, raycastParams)

	

	-- CREATE RAYCAST PART FOR VISUALIZING
	local rayPart = Instance.new("Part")
	rayPart.Anchored = true
	rayPart.CanCollide = false
	rayPart.Material = Enum.Material.Neon
	rayPart.Transparency = 0.5

	-- 5. check result
	if result and rewindHitboxes[result.Instance]["player"].Character:FindFirstChild("Humanoid") then
		local enemyHit = rewindHitboxes[result.Instance]["player"]
		local hitType = rewindHitboxes[result.Instance]["hitType"]
		print("RESULTS: " .. player.Name .. " HIT " .. enemyHit.Name .. " ON THE " .. hitType)

		-- visualize raycast hit, color it green
		rayPart.Color = Color3.new(0, 1, 0)
		local distance = (result.Position - clientPos).Magnitude
		rayPart.Size = Vector3.new(0.1, 0.1, distance)
		rayPart.CFrame = CFrame.lookAt(clientPos, result.Position) * CFrame.new(0, -0.1, -distance / 2 - 0.25)
		
		
		
		-- 6. damage enemy
		local enemyHumanoid = enemyHit.Character:FindFirstChild("Humanoid")
		
		if hitType == "head" then
			enemyHumanoid:TakeDamage(20)
		else
			enemyHumanoid:TakeDamage(10)
		end
	
	else
		print("RESULTS: " .. player.Name .. " DIDN'T HIT ANY ENEMY PLAYERS" )

		-- visualize ray hit nothing, color it red and go full length
		rayPart.Color = Color3.new(1, 0, 0)
		rayPart.Size = Vector3.new(0.1, 0.1, 1000)
		rayPart.CFrame = CFrame.lookAt(clientPos, clientPos + rayDir) * CFrame.new(0, -0.1, -500 - 0.25)

	end

	rayPart.Parent = workspace

	-- auto cleanup after 1 second
	game.Debris:AddItem(rayPart, 2.5)

	print("------------------------------------------------------------------------------------------------------------------")

end




return LagCompensationModule
