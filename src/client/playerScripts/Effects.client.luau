local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GunConfig = require(ReplicatedStorage:WaitForChild("GunConfig"))
local WeaponVisuals = require(ReplicatedStorage:WaitForChild("WeaponVisuals"))
local WeaponSounds = require(ReplicatedStorage:WaitForChild("WeaponSounds"))

local ShotEffect = ReplicatedStorage:WaitForChild("ShotEffect")




ShotEffect.OnClientEvent:Connect(function(shootingPlayer, rayDir)
   

    local character = shootingPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local startPos = hrp.Position

    WeaponSounds.playGunSound(shootingPlayer)
    WeaponVisuals.createTracer(startPos, rayDir, character)
end)