#include "winch.lua"

---Initializes the mod
function init()
    Winch:Init()
end

---@param dt number
function tick(dt)
    Winch:Tick(dt)
end

---@param dt number
function update(dt)
    Winch:Update(dt)
end

---@param dt number
function draw(dt)
    Winch:Draw(dt)
end
