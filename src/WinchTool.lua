_module "WinchTool"
_requires "Actions"
_requires "Winch"

---@class WinchTool
---@field winches Winch[]
WinchTool = {
    winches = {}
}

function WinchToolLoader()
    ---Returns the last created winch
    ---@return Winch # Last created winch
    ---@return integer # Index of the last created winch
    function WinchTool:_LastWinch()
        local index = #self.winches
        return self.winches[index], index
    end

    ---Removes a winch
    ---@param index integer Index of the winch to be removed
    function WinchTool:_RemoveWinch(index)
        table.remove(self.winches, index)
    end

    ---Deletes all winches
    function WinchTool:_DeleteWinches()
        self.winches = {}
    end

    ---Cretes a new winch
    ---@return Winch # Newly created winch
    function WinchTool:_AddWinch()
        local index = #self.winches + 1
        self.winches[index] = Winch:New()
        return self.winches[index]
    end

    ---Executes a function for each winch, passing the winch as an argument
    ---@param fn fun(winch: Winch, ...) Callback function
    ---@param ... any Additional arguments passed to fn, after the winch
    function WinchTool:_ForEach(fn, ...)
        for i = 1, #self.winches do
            fn(self.winches[i], ...)
        end
    end

    ---Gets information about the currently targeted voxel
    ---@return {hit: boolean, info: {body: number, point: table}}
    function WinchTool:_GetTarget()
        local pos = GetCameraTransform().pos
        local dir = UiPixelToWorld(UiCenter(), UiMiddle())
        local hit, dist, normal, shape = QueryRaycast(pos, dir, Constants.PLAYER_RANGE)
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
    function WinchTool:Init()
        RegisterTool("winch", "Winch", "MOD/assets/vox/winch.vox")
        SetBool("game.tool.winch.enabled", true)
    end

    ---Handles input
    ---@param dt number
    function WinchTool:Tick(dt)
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
        else
            -- Clear partial winch when changing tools
            local lw, index = self:_LastWinch()
            if lw and not lw:HasSecondAttachment() then
                self:_RemoveWinch(index)
            end
        end
    end

    ---Executes actions and handles physics
    ---@param dt number
    function WinchTool:Update(dt)
        -- Handle action
        if not Actions:Empty() then
            local action = Actions:Get()

            if action.id == Actions.IDS.ATTACH_BEGIN then
                if action.data.hit then
                    self:_AddWinch():Attach(1, action.data.info)
                end
            elseif action.id == Actions.IDS.ATTACH_END then
                local lw, index = self:_LastWinch()
                if lw and lw:HasFirstAttachment() and not lw:HasSecondAttachment() then
                    if action.data.hit then
                        -- Attach second point at target and set initial desired
                        --  length to the initial line length
                        lw:Attach(2, action.data.info)
                        lw:SetLengthToCurrent()
                    else -- Invalid attachment location (miss), discard winch
                        self:_RemoveWinch(index)
                    end
                end
            elseif action.id == Actions.IDS.SHRINK then
                self:_ForEach(Winch.Shrink, 0.1)
            elseif action.id == Actions.IDS.DELETE then
                self:_DeleteWinches()
            end
        end

        self:_ForEach(Winch.Update, dt)
    end

    ---Draws the winches to the screen
    ---@param dt number
    function WinchTool:Draw(dt)
        self:_ForEach(Winch.Draw, dt)
    end

    WinchTool:_ForEach(Winch.Reload)
end
