local HitboxConfig = {}


HitboxConfig.body = {
	size = Vector3.new(3, 3, 3),
	offset = CFrame.new(0, -1, 0) -- offset from HumanoidRootPart
}

HitboxConfig.head = {
	size = Vector3.new(3, 1.5, 3),
	offset = CFrame.new(0, 1.5, 0) -- offset from HumanoidRootPart
}

return HitboxConfig
