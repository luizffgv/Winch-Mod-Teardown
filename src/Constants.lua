_module "Constants"

---@class Constants
---@field TOOLID string
---@field PLAYER_RANGE number
---@field UPDATE_FPS number
Constants = {}

function ConstantsLoader()
    Constants.TOOLID = "Winch"
    Constants.PLAYER_RANGE = 3
    Constants.UPDATE_FPS = 60
end
