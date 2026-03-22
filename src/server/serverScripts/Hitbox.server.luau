local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local HitboxModule = require(SS:WaitForChild("HitboxModule"))
local HistoryModule = require(SS:WaitForChild("HistoryModule"))
local LagCompensationModule = require(SS:WaitForChild("LagCompensationModule"))

local ShootRequest = RS:WaitForChild("ShootRequest")

local function onCharacterAdded(character)
	HitboxModule.createHitbox(character)
end

local function onPlayerAdded(player)
	HistoryModule.initPlayer(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	HistoryModule.removePlayer(player)
end)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

ShootRequest.OnServerEvent:Connect(function(player, rayDir, clientTime, clientPos)
	LagCompensationModule.processShot(player, rayDir, clientTime, clientPos)
	
	
end)

