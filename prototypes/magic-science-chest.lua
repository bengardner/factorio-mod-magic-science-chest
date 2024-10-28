--[[
This one is based on the infinity chest.
An item is activated when enough of a science pack has been produced.
]]
local constants = require "src.constants"

local name = constants.CHEST_NAME
local source_item_name = "infinity-chest"
local source_prototype = "infinity-container"
local ref_item_name = "iron-chest"
local ref_prototype = "container"

local ref_entity = data.raw[ref_prototype][ref_item_name]

local entity = table.deepcopy(data.raw[source_prototype][source_item_name])
entity.name = name
entity.picture = {
  filename = constants.path_graphics("entity/magic-science-chest.png"),
  size = 64,
  scale = 0.5,
}
entity.minable.result = name
entity.inventory_size = 39
entity.se_allow_in_space = true
entity.erase_contents_when_mined = true
entity.gui_mode = 'none'
entity.enable_inventory_bar = false
entity.inventory_size = 40 -- should be enough, right?
entity.inventory_type = "with_filters_and_bar"
entity.max_health = ref_entity.max_health
entity.resistances = table.deepcopy(ref_entity.resistances)
entity.subgroup = ref_entity.subgroup
entity.allow_copy_paste = false

local ref_item = data.raw["item"][ref_item_name]
local item = table.deepcopy(data.raw["item"][source_item_name])
item.name = name
item.place_result = name
item.icon = constants.path_graphics("icons/magic-science-chest.png")
item.size = 64
item.order = "a[items]-b[" .. name .. "]"
item.subgroup = ref_item.subgroup

local recipe = {
  name = name,
  type = "recipe",
  enabled = true,
  energy_required = 1,
  --ingredients = { { type="item", name = "iron-chest", amount = 1 }},
  ingredients = {}, -- free
  results = { { type="item", name=name, amount=1 } },
}

data:extend({ entity, item, recipe })
