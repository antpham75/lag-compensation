local WeaponVisuals = {}

local TweenService = game:GetService("TweenService")
local BULLET_SPEED = 100 -- studs per second

function WeaponVisuals.createTracer(startPos, rayDir, filterCharacter)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = filterCharacter and {filterCharacter} or {}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(startPos, rayDir * 1000, raycastParams)

    local endPos = result and result.Position or (startPos + rayDir * 1000)
    local distance = (endPos - startPos).Magnitude
    local travelTime = distance / BULLET_SPEED

    local bullet = Instance.new("Part")
    bullet.Anchored = true
    bullet.CanCollide = false
    bullet.Material = Enum.Material.Neon
    bullet.Transparency = 0.3
    bullet.Color = Color3.new(1, 1, 0)
    bullet.Size = Vector3.new(0.05, 0.05, 0.5) -- short bullet shape
    bullet.CFrame = CFrame.lookAt(startPos, endPos)
    bullet.Parent = workspace

    local tween = TweenService:Create(bullet, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
        CFrame = CFrame.lookAt(endPos, endPos + rayDir)
    })
    tween:Play()

    game.Debris:AddItem(bullet, travelTime)
end

function WeaponVisuals.createTracerRay(startPos, rayDir, filterCharacter)


   

    local raycastParams = RaycastParams.new()
    -- raycastParams.FilterDescendantsInstances = {filterCharacter}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(startPos, rayDir * 1000, raycastParams)

    local endPos = result and result.Position or (startPos + rayDir * 1000)
    local distance = (endPos - startPos).Magnitude

    local tracer = Instance.new("Part")
    tracer.Anchored = true
    tracer.CanCollide = false
    tracer.Material = Enum.Material.Neon
    tracer.Transparency = 0.5
    tracer.Color = Color3.new(1, 1, 0)
    tracer.Size = Vector3.new(0.05, 0.05, distance)
    tracer.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
    tracer.Parent = workspace
    game.Debris:AddItem(tracer, 0.1)
end
return WeaponVisuals