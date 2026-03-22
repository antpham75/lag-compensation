local HitboxConfig = {}

local BODY_SIZE = Vector3.new(3, 3, 3)
local HEAD_SIZE = Vector3.new(1.5, 1.5, 1.5)

local BODY_OFFSET = CFrame.new(0, -1, 0)
local HEAD_OFFSET = CFrame.new(0, BODY_SIZE.Y/2 + HEAD_SIZE.Y/2, 0) -- ensures head hitbox lays on top of body

HitboxConfig.body = {
    size = BODY_SIZE,
    offset = BODY_OFFSET
}

HitboxConfig.head = {
    size = HEAD_SIZE,
    offset = HEAD_OFFSET * BODY_OFFSET
}

return HitboxConfig
