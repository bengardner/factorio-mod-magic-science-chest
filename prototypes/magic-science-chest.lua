local constants = require "src.constants"

local name = constants.CHEST_NAME
local source_item_name = "iron-chest"
local source_prototype = "container"


local entity = table.deepcopy(data.raw[source_prototype][source_item_name])
entity.name = name
entity.picture = {
  filename = constants.path_graphics("entity/magic-science-chest.png"),
  size = 64,
  scale = 0.5,
}
entity.minable.result = name
entity.inventory_size = 39


local item = table.deepcopy(data.raw["item"][source_item_name])
item.name = name
item.place_result = name
item.icon = constants.path_graphics("icons/magic-science-chest.png")
item.size = 64
item.order = "a[items]-b[" .. name .. "]"


local recipe = {
  name = name,
  type = "recipe",
  enabled = true,
  energy_required = 10,
  ingredients =  { { "iron-plate", 32} },
  result = name,
  result_count = 1,
}

data:extend({ entity, item, recipe })
