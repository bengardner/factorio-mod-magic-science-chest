--[[
Constant values that are shared between the stages.
]]
local M = {}

M.MODULE_NAME = "magic-science-chest"
M.MODULE_PATH = "__" .. M.MODULE_NAME .. "__"

M.CHEST_NAME = "magic-science-chest"

M.PATH_GRAPHICS = M.MODULE_PATH .. "/graphics"

function M.path_graphics(bn)
    return string.format("%s/%s", M.PATH_GRAPHICS, bn)
end

return M
