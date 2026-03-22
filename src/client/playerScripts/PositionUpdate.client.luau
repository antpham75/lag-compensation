local RunService = game:GetService("RunService")
local CFrameUpdate = game.ReplicatedStorage:WaitForChild("CFrameUpdate")
local Workspace = game.Workspace
local player = game.Players.LocalPlayer
local Players = game:GetService("Players")

local GameConfig = require(game.ReplicatedStorage:WaitForChild("GameConfig"))

local SEND_RATE = 1/60
local elapsed = 0
local MAX_INTERP_BUFFER_SIZE = 20




local RS = game:GetService("ReplicatedStorage")
local localPlayer = game.Players.LocalPlayer
local CFrameBroadcast = RS:WaitForChild("CFrameBroadcast")
local RunService = game:GetService("RunService")
local ShotConfirm = RS:WaitForChild("ShotConfirm")

local receivedPositions = {} -- { [player] = {cframe, timestamp} }




-- RECEIVE position updates from server
CFrameBroadcast.OnClientEvent:Connect(function(latestCFrames, serverTimestamp)

	
	for userId, updateCFrame in pairs(latestCFrames) do
		local player = game.Players:GetPlayerByUserId(userId)
		if not player then continue end
		if player == localPlayer then continue end
		
		-- make sure that CFrame update is not an old one
		local existing = receivedPositions[player]
		if existing and serverTimestamp < existing.timestamp then return end
		
		receivedPositions[player] = {cframe = updateCFrame, timestamp = serverTimestamp}
		
	end
end)

-- SEND position update to server
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed >= SEND_RATE then
		elapsed = 0
		-- send position update to server

		local character = player.Character
		if not character then return end
		if not character:FindFirstChild("HumanoidRootPart") then return end


		CFrameUpdate:FireServer(
			player.Character.HumanoidRootPart.CFrame,
			Workspace:GetServerTimeNow()
		)

	end
end)


-- going to have to subtract by interpolation delay in lagcompensation
local interpolationBuffer = {} -- { [player] = { {time, cframe}, {time, cframe}, ... } }

CFrameBroadcast.OnClientEvent:Connect(function(latestCFrames, serverTimestamp)

	for userId, updateCFrame in pairs(latestCFrames) do
		local player = Players:GetPlayerByUserId(userId)
		if not player or player == localPlayer then continue end

		if not interpolationBuffer[player] then
			interpolationBuffer[player] = {}
		end

		-- just insert to end, already in order since server sends consistently
		table.insert(interpolationBuffer[player], {
			time = serverTimestamp,
			cframe = updateCFrame
		})

		-- trim old entries beyond what we need
		while #interpolationBuffer[player] > MAX_INTERP_BUFFER_SIZE do 
			table.remove(interpolationBuffer[player], 1)
		end
	end

end)


local INTERP_DELAY = GameConfig.INTERP_DELAY -- 100ms behind

RunService.Heartbeat:Connect(function()
	local renderTime = workspace:GetServerTimeNow() - GameConfig.INTERP_DELAY
	
	
	for player, buffer in pairs(interpolationBuffer) do
		
		print("latest snapshot time - renderTime = " .. buffer[#buffer].time - renderTime)
		
		-- 1. find prevSnapshot and nextSnapshot that surround renderTime
		local prevSnapshot, nextSnapshot = nil, nil
		
		for i, snapshot in ipairs(buffer) do
			
			if snapshot.time <= renderTime then
				prevSnapshot = snapshot
				
			elseif snapshot.time > renderTime then
				nextSnapshot = snapshot
				break
				
			end
		end
		
		--print(prevSnapshot)
		--print(nextSnapshot)
		-- 2. if we found both, lerp between them
		if prevSnapshot and nextSnapshot then
			
			local alpha = (renderTime - prevSnapshot.time) / (nextSnapshot.time - prevSnapshot.time)
			local interpolatedCFrame = prevSnapshot.cframe:Lerp(nextSnapshot.cframe, alpha)
			
			-- 3. set hrp.CFrame to the interpolated result
			local character = player.Character
			if not character then continue end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end
			player.Character.HumanoidRootPart.CFrame = interpolatedCFrame
		else

			-- can't lerp between, screw the lerp and just snap players to their latest found CFrame in interpolation buffer
			if prevSnapshot then
				print("CAN'T LERP. SNAPPING CFRAME...")
				local character = player.Character
				if not character then continue end
				local hrp = character:FindFirstChild("HumanoidRootPart")
				hrp.CFrame = prevSnapshot.cframe
			end
			
		end
		
	end
end)



