local RunService = game:GetService("RunService")
local CFrameUpdate = game.ReplicatedStorage:WaitForChild("CFrameUpdate")
local Workspace = game.Workspace
local player = game.Players.LocalPlayer
local Players = game:GetService("Players")

local GameConfig = require(game.ReplicatedStorage:WaitForChild("GameConfig"))

local SEND_RATE = 1/60

local MAX_INTERP_BUFFER_SIZE = 20

local DEBUG_MODE = false



local RS = game:GetService("ReplicatedStorage")
local localPlayer = game.Players.LocalPlayer
local CFrameBroadcast = RS:WaitForChild("CFrameBroadcast")
local ShotConfirm = RS:WaitForChild("ShotConfirm")



local function snapPlayer(player, cFrame)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	hrp.CFrame = cFrame
end

local function debugInterpolation(renderTime, buffer, prevSnapshot, nextSnapshot, nextSnapshotIndex)
	print("latest snapshot time - renderTime = " .. string.format("%.5f", buffer[#buffer].time - renderTime))
	print("# of extra buffer snapshots ahead of nextSnapshot: " .. #buffer - (nextSnapshotIndex or #buffer))

	if prevSnapshot and not nextSnapshot then
		print("CAN'T LERP. SNAPPING CFRAME...")
	end
end






local elapsed = 0
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



local interpolationBuffer = {} -- { [player] = { {time, cframe}, {time, cframe}, ... } }

CFrameBroadcast.OnClientEvent:Connect(function(latestCFrames, serverTimestamp)

	for userId, newCFrame in pairs(latestCFrames) do
		local player = Players:GetPlayerByUserId(userId)
		if not player or player == localPlayer then continue end

		if not interpolationBuffer[player] then
			interpolationBuffer[player] = {}
		end

		-- just insert to end, already in order since server sends consistently
		table.insert(interpolationBuffer[player], {
			time = serverTimestamp,
			cframe = newCFrame
		})

		-- trim old entries beyond what we need
		while #interpolationBuffer[player] > MAX_INTERP_BUFFER_SIZE do 
			table.remove(interpolationBuffer[player], 1)
		end
	end

end)


local INTERP_DELAY = GameConfig.INTERP_DELAY 

-- interpolate CFrames of players and show the CFrame
RunService.Heartbeat:Connect(function()
	local renderTime = workspace:GetServerTimeNow() - INTERP_DELAY
	
	for player, buffer in pairs(interpolationBuffer) do

		local prevSnapshot, nextSnapshot = nil, nil
		local nextSnapshotIndex = nil

		for i, snapshot in ipairs(buffer) do
			
			if snapshot.time <= renderTime then
				prevSnapshot = snapshot
				
			elseif snapshot.time > renderTime then
				nextSnapshot = snapshot
				nextSnapshotIndex = i
				break
				
			end
		end
		
	
		-- 2. if there is a prevSnapshot and nextSnapshot, get CFrame between them
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
			-- should probably do extrapolation later
			if prevSnapshot then
				snapPlayer(player, prevSnapshot.cframe)
			end
			
		end

		if DEBUG_MODE then
			debugInterpolation(renderTime, buffer, prevSnapshot, nextSnapshot, nextSnapshotIndex)
		end


		
	end
end)



