local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local speed = 30

RunService.Heartbeat:Connect(function(dt)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {character}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(hrp.Position, Vector3.new(0, -4, 0), params)
	if result then
		local hit = result.Instance
		if hit and hit.Name == "Conveyor" then
			local direction = hit.CFrame.LookVector
			hrp.CFrame = hrp.CFrame + direction * speed * dt
		end
	end
end)