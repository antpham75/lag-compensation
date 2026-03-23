local HistoryModule = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CFrameUpdate = ReplicatedStorage:WaitForChild("CFrameUpdate")
local CFrameBroadcast = ReplicatedStorage:WaitForChild("CFrameBroadcast")

local BROADCAST_RATE = 1/60 -- rate at which server sends position info to all other clients


local cFrameHistory = {}  
--[[
	{
		[Player1] = {
						[serverTick1] = CFrame1,
						[serverTick2] = CFrame2,
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


local clientReportedCFrame = {} -- holds the last single CFrame sent by each client
-- is updated irregularly, but is polled at a rate of BROADCAST_RATE
--[[
    {
        [player1] = CFrame,
        [player2] = CFrame
    }

    
]]


local MAX_HISTORY_SECS = 1.1




-- helper function for debugging
local function countDictionary(t)
	local count = 0
	for _ in pairs(t) do 
		count = count + 1
	end
	return count
end




function HistoryModule.initPlayer(player)
	cFrameHistory[player] = {}
end

function HistoryModule.removePlayer(player)
	cFrameHistory[player] = nil
end

function HistoryModule.getHistory(player)
	return cFrameHistory[player]
end


-- runs automatically when module is required
CFrameUpdate.OnServerEvent:Connect(function(player, hrpCFrame, clientTime)
	if not cFrameHistory[player] then return end
	local character = player.Character
	if not character then return end

	local serverTime = workspace:GetServerTimeNow()
	if math.abs(serverTime - clientTime) > 1 then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp and (hrpCFrame.Position - hrp.Position).Magnitude > 10 then return end

	clientReportedCFrame[player] = hrpCFrame
	
end)


local elapsed = 0

-- STORES ALL PLAYERS' CFRAMES IN THE HISTORY WITH THE SAME SERVER TICK AND THEN BROADCASTS THESE CFRAMES TO ALL CLIENTS
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < BROADCAST_RATE then return end
	elapsed = 0

	local serverTime = workspace:GetServerTimeNow()
	local latestCFrames = {}
	
    -- record latest CFrame of every player, all CFrames are stored with the same server time value.
	for _, player in pairs(Players:GetPlayers()) do
		if not cFrameHistory[player] then continue end
		local hrpCFrame = clientReportedCFrame[player]
		if not hrpCFrame then continue end
		
		
		cFrameHistory[player][serverTime] = hrpCFrame
		
		latestCFrames[player.UserId] = hrpCFrame
	end
	
	
	
	CFrameBroadcast:FireAllClients(latestCFrames, serverTime)
end)




-- constantly discard old stored positions
RunService.Heartbeat:Connect(function()
	-- remove old CFrames
	local serverTime = workspace:GetServerTimeNow()
	for _, player in pairs(Players:GetPlayers()) do
		
		if not cFrameHistory[player] then continue end
		
		for time, _ in pairs(cFrameHistory[player]) do
			if serverTime - time > MAX_HISTORY_SECS then
				cFrameHistory[player][time] = nil
			end
		end
		
	end
end)



return HistoryModule
