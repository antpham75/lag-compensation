local HitboxConfig = require(game.ReplicatedStorage:WaitForChild("HitboxConfig"))

local HitboxModule = {}

function HitboxModule.createHitbox(character)
	local hrp = character:WaitForChild("HumanoidRootPart")
	
	hrp:SetNetworkOwner(nil) -- nil means server owns it
	-- Body hitbox
	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Material = Enum.Material.SmoothPlastic

	hitbox.Size = HitboxConfig.body.size
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.Anchored = false
	hitbox.CFrame = hrp.CFrame * HitboxConfig.body.offset -- adjust offset as needed 		TODO: make this not so hard coded
	hitbox.Parent = character

	-- Weld it to HumanoidRootPart so it follows the player
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = character.HumanoidRootPart
	weld.Part1 = hitbox
	weld.Parent = hitbox


	-- Head hitbox
	local headHitbox = Instance.new("Part")
	headHitbox.Name = "HeadHitbox"
	headHitbox.Material = Enum.Material.SmoothPlastic
	headHitbox.Color = Color3.fromRGB(255, 0, 0)
	headHitbox.Size = HitboxConfig.head.size
	headHitbox.Transparency = 1
	headHitbox.CanCollide = false
	headHitbox.Anchored = false
	headHitbox.CFrame = hrp.CFrame * HitboxConfig.head.offset -- adjust Y as needed
	headHitbox.Parent = character

	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = hrp
	headWeld.Part1 = headHitbox
	headWeld.Parent = headHitbox
end



return HitboxModule
