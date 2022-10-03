#include "actions.lua"
#include "constants.lua"


---@alias attachment {body: number, point: table}

---@class Winch
---@field _attachments attachment[]
---@field _desired_length number
Winch = {}
Winch.__index = Winch

---Creates a new Winch
---@return Winch
function Winch:New()
    return setmetatable(
        {
            _attachments = { nil, nil },
            _desired_length = 0
        }, self
    )
end

---Detach attached bodies
function Winch:ClearAttachments()
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

---Sets the winch desired length
---@param length number
function Winch:SetLength(length)
    self._desired_length = length
end

---Sets the desired length to the current length
function Winch:SetLengthToCurrent()
    self:SetLength(VecLength(VecSub(self:_GetAttachedWorldPoints())))
end

---Shrinks the desired length of the winch
---@param amount number
function Winch:Shrink(amount)
    self._desired_length = math.max(0, self._desired_length - amount)
end

---Checks if the winch is attached to the first end
---@return boolean # true if attached to the first end
function Winch:HasFirstAttachment()
    return self._attachments[1] ~= nil
end

---Checks if the winch is attached to the second end
---@return boolean # true if attached to the second end
function Winch:HasSecondAttachment()
    return self._attachments[2] ~= nil
end

---Checks if the winch is attached to both ends
---@return boolean # true if attached to both ends
function Winch:HasBothAttachments()
    return self._attachments[1] ~= nil and self._attachments[2] ~= nil
end

---Attaches an end to an attachment point
---@param end_ 1 | 2
---@param attachment attachment
function Winch:Attach(end_, attachment)
    self._attachments[end_] = attachment
end

---Detaches an end
---@param end_ 1 | 2
function Winch:Detach(end_)
    self._attachments[end_] = nil
end

---Updates the winch physics
---@param dt number
function Winch:Update(dt)
    if self:HasBothAttachments() then
        local b1, b2, p1, p2 = self:_GetAttachedBodiesAndWorldPoints()

        local cur_length = VecLength(VecSub(p1, p2))
        local length_delta = cur_length - self._desired_length

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
            self:SetLength(cur_length)
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
