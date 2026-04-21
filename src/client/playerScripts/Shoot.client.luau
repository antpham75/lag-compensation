local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local HitboxConfig = require(ReplicatedStorage:WaitForChild("HitboxConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local WeaponVisuals = require(ReplicatedStorage:WaitForChild("WeaponVisuals"))
local WeaponSounds = require(ReplicatedStorage:WaitForChild("WeaponSounds"))

local ShootRequest = ReplicatedStorage:WaitForChild("ShootRequest")
local camera = Workspace.CurrentCamera
local GunConfig = require(ReplicatedStorage:WaitForChild("GunConfig"))


local localPlayer = Players.LocalPlayer

local DEBUG_MODE = false




local function createClientViewParts(CFrameDict)
	for partType, CFrame in pairs(CFrameDict) do
		local clientViewPart = Instance.new("Part")
		clientViewPart.Size = HitboxConfig[partType].size
		clientViewPart.Anchored = true
		clientViewPart.CanCollide = false
		clientViewPart.Material = Enum.Material.Neon
		clientViewPart.Color = Color3.new(0, 0.482353, 1) -- blue for client
		if partType == "head" then
			clientViewPart.Color = Color3.new(0, 0.227451, 0.47451) -- red for head
		end
		clientViewPart.Transparency = 0.7
		clientViewPart.CFrame = CFrame
		clientViewPart.Parent = Workspace
		game.Debris:AddItem(clientViewPart, 2.5)
	end
end

local function createRayPart(cameraCFrame)
	-- create client ray part
	local rayPart = Instance.new("Part")
	rayPart.Anchored = true
	rayPart.CanCollide = false
	rayPart.Material = Enum.Material.Neon
	rayPart.Transparency = 0.6
	rayPart.Color = Color3.new(0.301961, 0.301961, 0.301961)
	rayPart.Size = Vector3.new(0.1, 0.1, 1000)
	rayPart.CFrame = cameraCFrame * CFrame.new(0, -0.1, -rayPart.Size.Z / 2 - .25) -- OFFSET OF -0.1 AND -.25 TO HELP SEE THE RAYCAST -- NOT ACTUALLY REPRESENTATIVE OF RAYCAST POSITION
	rayPart.Parent = workspace
	game.Debris:AddItem(rayPart, 2.5)
end

local function playMuzzleFlash()
	print("muzzle flash")
end

local function spawnHitboxes()
-- spawn a part at every other player's hitbox position as the client sees it
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer == localPlayer then continue end

		local character = otherPlayer.Character
		if not character then continue end

		local hitbox = character:FindFirstChild("Hitbox")
		local headHitbox = character:FindFirstChild("HeadHitbox")
			
		if not hitbox or not headHitbox then continue end
			
		createClientViewParts({
			["body"] = hitbox.CFrame,
			["head"] = headHitbox.CFrame
		})
	end
end




local lastShotTime = -math.huge

-- SHOOT GUN
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	
	if gameProcessed then return end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	
	local now = workspace:GetServerTimeNow()
    if now - lastShotTime < GunConfig.SHOOT_COOLDOWN_SECS then return end

	lastShotTime = now
	ShootRequest:FireServer(camera.CFrame.LookVector, Workspace:GetServerTimeNow(), camera.CFrame.Position)


	
	playMuzzleFlash()
	WeaponSounds.playGunSound(localPlayer)
	WeaponVisuals.createTracer(camera.CFrame.Position, camera.CFrame.LookVector, localPlayer.Character)

	if DEBUG_MODE then
		spawnHitboxes()
		createRayPart(camera.CFrame)
	end


		
	
end)





