#include "actions.lua"
#include "constants.lua"

Winch = {
    ---@type {body: number, point: table}[]
    _attachments = {},
    ---@type number
    _desired_length = 0
}

---Detach attached bodies
function Winch:_ClearAttachments()
    self._attachments[1] = nil
    self._attachments[2] = nil
end

---Returns handles to the bodies attached to the winch
function Winch:_GetAttachedBodies()
    return self._attachments[1].body, self._attachments[2].body
end

---Returns both attachment world points
function Winch:_GetAttachedWorldPoints()
    local b1, b2 = self:_GetAttachedBodies()
    return TransformToParentPoint(GetBodyTransform(b1), self._attachments[1].point),
        TransformToParentPoint(GetBodyTransform(b2), self._attachments[2].point)
end

---Returns both attachment world points
function Winch:_GetAttachedBodiesAndWorldPoints()
    local b1, b2 = self:_GetAttachedBodies()
    return b1, b2,
        TransformToParentPoint(GetBodyTransform(b1), self._attachments[1].point),
        TransformToParentPoint(GetBodyTransform(b2), self._attachments[2].point)
end

---Checks if the winch is attached to both ends
---@return boolean # true if attached to both ends
function Winch:_HasBothAttachments()
    return self._attachments[1] ~= nil and self._attachments[2] ~= nil
end

---Gets information about the currently targeted voxel
---@return {hit: boolean, info: {body: number, point: table}}
function Winch:_GetTarget()
    local pos = GetCameraTransform().pos
    local dir = UiPixelToWorld(UiCenter(), UiMiddle())
    local hit, dist, normal, shape = QueryRaycast(pos, dir, PLAYER_RANGE)
    local hitpos = VecAdd(
        pos,
        VecScale(UiPixelToWorld(UiCenter(), UiMiddle()), dist)
    )
    return { hit = hit, info = {
        body = GetShapeBody(shape),
        point = TransformToLocalPoint(GetBodyTransform(GetShapeBody(shape)), hitpos)
    } }
end

---Initializes the winch item
function Winch:Init()
    RegisterTool("winch", "Winch", "MOD/vox/winch.vox")
    SetBool("game.tool.winch.enabled", true)
end

---Handles input
---@param dt number
function Winch:Tick(dt)
    if GetString("game.player.tool") == "winch" then
        if InputPressed("usetool") then
            Actions:Enqueue(Actions.IDS.ATTACH_BEGIN, self:_GetTarget())
        elseif InputReleased("usetool") then
            Actions:Enqueue(Actions.IDS.ATTACH_END, self:_GetTarget())
        elseif InputDown("rmb") then
            Actions:Squash(Actions.IDS.SHRINK)
        elseif InputDown("mmb") then
            Actions:Squash(Actions.IDS.DELETE)
        end
    elseif not self._attachments[2] then
        self:_ClearAttachments()
    end
end

---Executes actions and handles physics
---@param dt number
function Winch:Update(dt)
    -- Handle action
    if not Actions:Empty() then
        local action = Actions:Get()

        if action.id == Actions.IDS.ATTACH_BEGIN then
            if action.data.hit then
                self._attachments[1] = action.data.info
                self._attachments[2] = nil
            end
        elseif action.id == Actions.IDS.ATTACH_END then
            if self._attachments[1] and not self._attachments[2] then
                if action.data.hit then
                    -- Attach second point at target and set initial desired
                    --  length to the initial line length
                    self._attachments[2] = action.data.info
                    DesiredLength = VecLength(VecSub(self:_GetAttachedWorldPoints()))
                else
                    self._attachments[1] = nil
                end
            end
        elseif action.id == Actions.IDS.SHRINK then
            DesiredLength = math.max(0, DesiredLength - 0.1)
        elseif action.id == Actions.IDS.DELETE then
            self:_ClearAttachments()
        end
    end

    -- Update physics
    if self:_HasBothAttachments() then
        local b1, b2, p1, p2  = self:_GetAttachedBodiesAndWorldPoints()

        local cur_length = VecLength(VecSub(p1, p2))
        local length_delta = cur_length - DesiredLength

        if length_delta > 0 then
            local m1 = GetBodyMass(b1)
            local m2 = GetBodyMass(b2)

            -- Lesser of the two masses. Is 0 only if both m1 and m2 are 0.
            -- Static objects have 0 mass, so we gotta handle this.
            local m = math.min(m1 ~= 0 and m1 or m2, m2 ~= 0 and m2 or m1)

            local dir = VecNormalize(VecSub(p2, p1))
            local impulse = VecScale(dir, m * 0.25 * UPDATE_FPS * dt)

            -- Drag objects toward each other (simulates shrinking rope)
            ApplyBodyImpulse(b1, p1, impulse)
            ApplyBodyImpulse(b2, p2, VecScale(impulse, -1))
        else
            -- Automatically adjust the desired length to the current length if
            --  the current length is shorter
            DesiredLength = cur_length
        end
    end
end

---Draws the winch to the screen
---@param dt number
function Winch:Draw(dt)
    if self._attachments[1] then
        local b1 = self._attachments[1].body
        local p1 = TransformToParentPoint(GetBodyTransform(b1), self._attachments[1].point)

        if self._attachments[2] then -- Draw line from target 1 to target 2
            local b2 = self._attachments[2].body
            local p2 = TransformToParentPoint(GetBodyTransform(b2), self._attachments[2].point)
            DrawLine(p1, p2, 0, 0, 0)
        else -- Preview line
            local ct = GetCameraTransform()
            local dir = UiPixelToWorld(UiCenter(), UiMiddle())
            local hit, dist = QueryRaycast(ct.pos, dir, PLAYER_RANGE)

            if hit then -- Voxel in range, preview white line
                DrawLine(p1,
                    VecAdd(ct.pos, QuatRotateVec(ct.rot, VecScale({ 0, 0, -1 }, dist))))
            else -- Out of range, preview red line
                DrawLine(p1,
                    VecAdd(ct.pos, QuatRotateVec(ct.rot, { 0, 0, -PLAYER_RANGE }))
                    , 1, 0, 0)
            end

        end
    end
end
