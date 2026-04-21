local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GunConfig = require(ReplicatedStorage:WaitForChild("GunConfig"))

local WeaponSounds = {}

function WeaponSounds.playGunSound(shootingPlayer)
    local character = shootingPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local sound = Instance.new("Sound")
    sound.SoundId = GunConfig.GUNSHOT_SOUND_ID
    sound.Volume = 0.2
    sound.Parent = hrp
    sound:Play()
    game.Debris:AddItem(sound, 3)
end

return WeaponSounds