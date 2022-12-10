_include "WinchTool"

function LoadModules()
    Load "WinchTool"
    WinchTool:Init()
end

---Initializes the mod
function init()
    LoadModules()
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

function handleCommand(command)
    if command == "quickload" then
        LoadModules()
    end
end
