local HistoryModule = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CFrameUpdate = ReplicatedStorage:WaitForChild("CFrameUpdate")
local CFrameBroadcast = ReplicatedStorage:WaitForChild("CFrameBroadcast")

local HitboxConfig = require(game.ReplicatedStorage:WaitForChild("HitboxConfig"))


local hitboxCFrames = {}  -- holds history 

local clientReportedCFrame = {}   
--[[ 
holds the last CFrame sent by the client  {
	[player1] = CFrame
	[player2] = CFrame
}

*is updated irregularly, but is polled at a constant rate
]]


local MAX_HISTORY_SECS = 1.1


-- THIS IS HOW hitboxCFrames looks:
--[[
	{
		[Player1] = {
						[serverTick1] = {hrp = CFrame1
								body = CFrame1
								head = CFrame1
						
						},
						[serverTick2] = CFrame2
						[serverTick3] = CFrame3
						...
					},
					
		[Player2] = {
						[serverTick1] = CFrame1
						[serverTick2] = CFrame2
						[serverTick3] = CFrame3
						...
					},
		...			
	}

]]


-- helper function for debugging
local function countDictionary(t)
	local count = 0
	for _ in pairs(t) do 
		count = count + 1
	end
	return count
end




function HistoryModule.initPlayer(player)
	hitboxCFrames[player] = {}
end

function HistoryModule.removePlayer(player)
	hitboxCFrames[player] = nil
end

function HistoryModule.getHistory(player)
	return hitboxCFrames[player]
end


-- runs automatically when module is required
CFrameUpdate.OnServerEvent:Connect(function(player, hrpCFrame, clientTime)
	if not hitboxCFrames[player] then return end
	local character = player.Character
	if not character then return end

	local serverTime = workspace:GetServerTimeNow()
	if math.abs(serverTime - clientTime) > 1 then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp and (hrpCFrame.Position - hrp.Position).Magnitude > 10 then return end

	clientReportedCFrame[player] = hrpCFrame
	
end)

-- send position update to all clients
local BROADCAST_RATE = 1/60
local elapsed = 0

-- STORES ALL PLAYERS' CFRAMES WITH THE SAME SERVER TICK AND THEN BROADCASTS THESE CFRAMES TO ALL CLIENTS
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < BROADCAST_RATE then return end
	elapsed = 0

	local serverTime = workspace:GetServerTimeNow()
	local latestCFrames = {}
	
	for _, player in pairs(Players:GetPlayers()) do
		if not hitboxCFrames[player] then continue end
		local hrpCFrame = clientReportedCFrame[player]
		if not hrpCFrame then continue end
		
		-- all players stored with same server time
		hitboxCFrames[player][serverTime] = {
			hrp = hrpCFrame,
			body = hrpCFrame * HitboxConfig.body.offset,
			head = hrpCFrame * HitboxConfig.head.offset
		}
		
		latestCFrames[player.UserId] = hrpCFrame
	end
	
	
	
	CFrameBroadcast:FireAllClients(latestCFrames, serverTime)
end)




-- constantly discard old stored positions
RunService.Heartbeat:Connect(function()
	-- remove old CFrames
	local serverTime = workspace:GetServerTimeNow()
	for _, player in pairs(Players:GetPlayers()) do
		
		if not hitboxCFrames[player] then continue end
		
		for time, _ in pairs(hitboxCFrames[player]) do
			if serverTime - time > MAX_HISTORY_SECS then
				hitboxCFrames[player][time] = nil
			end
		end
		
	end
end)



return HistoryModule
