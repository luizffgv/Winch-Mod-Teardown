#include "winchtool.lua"

---Initializes the mod
function init()
    WinchTool:Init()
end

---@param dt number
function tick(dt)
    WinchTool:Tick(dt)
end

---@param dt number
function update(dt)
    WinchTool:Update(dt)
end

---@param dt number
function draw(dt)
    WinchTool:Draw(dt)
end
