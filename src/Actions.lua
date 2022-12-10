_module "Actions"

---@alias action {id: action_id, data: any}

---@class Actions
---@field _queue action[]
Actions = {}

function ActionsLoader()
    Actions._queue = {}

    ---@enum action_id
    Actions.IDS = {
        ATTACH_BEGIN = 1,
        ATTACH_END = 2,
        SHRINK = 3,
        DELETE = 4
    }


    ---Enqueues an action
    ---@param id action_id
    ---@param data any
    function Actions:Enqueue(id, data)
        table.insert(self._queue, { id = id, data = data })
    end

    ---Enqueues an action, overwriting the last action if it has the same id
    ---@param id action_id
    ---@param data any
    function Actions:Squash(id, data)
        local last_action = self._queue[#self._queue]

        if last_action and last_action.id == id then
            last_action.id = id
            last_action.data = data
        else
            self:Enqueue(id, data)
        end
    end

    ---Checks if the action queue is empty
    ---@return boolean true if the queue is empty, false otherwise
    ---@nodiscard
    function Actions:Empty()
        return #self._queue == 0
    end

    ---Peeks the first action in the queue
    ---@return action
    ---@nodiscard
    function Actions:Peek()
        return self._queue[1]
    end

    ---Dequeues the first action in the queue
    ---@return action
    function Actions:Get()
        return table.remove(self._queue, 1)
    end
end
