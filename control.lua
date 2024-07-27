if script.active_mods["gvv"] then require("__gvv__.gvv")() end

-- event_handler is "__core__/lualib/event_handler.lua"
local event_handler = require("event_handler")

event_handler.add_lib(require("src.MagicScienceChest"))
event_handler.add_lib(require("src.MagicScienceChestGui"))
