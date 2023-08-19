local constants = require "src.constants"
local Paths = require "src.Paths"

local M = {}

function M.main()
  M.add_research_chest()
end

function M.add_research_chest()
  local name = constants.CHEST_NAME
  local source_item_name = "iron-chest"
  local source_prototype = "container"

  local entity = table.deepcopy(data.raw[source_prototype][source_item_name])
  entity.name = name
  entity.picture = {
    filename = Paths.graphics .. "/entity/research-chest.png",
    size = 64,
    scale = 0.5,
  }
  entity.minable.result = name

  local item = table.deepcopy(data.raw["item"][source_item_name])
  item.name = name
  item.place_result = name
  item.icon = Paths.graphics .. "/icons/research-chest.png"
  item.size = 64

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
end

M.main()
