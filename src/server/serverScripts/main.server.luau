local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Players = game:GetService("Players")


local HistoryModule = require(SS:WaitForChild("HistoryModule"))
local LagCompensationModule = require(SS:WaitForChild("LagCompensationModule"))

local ShootRequest = RS:WaitForChild("ShootRequest")
local ShotEffect = RS:WaitForChild("ShotEffect")

local function onPlayerAdded(player)
	HistoryModule.initPlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	HistoryModule.removePlayer(player)
end)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

ShootRequest.OnServerEvent:Connect(function(shootingPlayer, rayDir, clientTime, clientPos)
	LagCompensationModule.processShot(shootingPlayer, rayDir, clientTime, clientPos)
	
	for _, player in Players:GetPlayers() do
		if player == shootingPlayer then
			continue
		end
		
		ShotEffect:FireClient(player, shootingPlayer, rayDir)
	end
	
end)

