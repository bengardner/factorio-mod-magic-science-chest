local GlobalState = require "src.GlobalState"
local constants = require "src.constants"

local M = {}

local function generic_create_handler(event)
  local entity = event.created_entity
  if entity == nil then
    entity = event.entity
  end
  if entity.name == constants.CHEST_NAME then
    GlobalState.entity_register(entity)
  end
end

function M.on_built_entity(event)
  generic_create_handler(event)
end

function M.script_raised_built(event)
  generic_create_handler(event)
end

function M.on_entity_cloned(event)
  if event.source.name == constants.CHEST_NAME and event.destination.name == constants.CHEST_NAME then
    GlobalState.entity_register(event.destination)
  end
end

function M.on_robot_built_entity(event)
  generic_create_handler(event)
end

function M.script_raised_revive(event)
  generic_create_handler(event)
end

function M.generic_destroy_handler(event, opts)
  if opts == nil then
    opts = {}
  end

  local entity = event.entity
  if entity.name == constants.CHEST_NAME then
    if not opts.do_not_delete_entity then
      GlobalState.entity_delete(entity.unit_number)
    end
  end
end

function M.on_player_mined_entity(event)
  M.generic_destroy_handler(event)
end

function M.on_pre_player_mined_item(event)
  M.generic_destroy_handler(event)
end

function M.on_robot_mined_entity(event)
  M.generic_destroy_handler(event)
end

function M.script_raised_destroy(event)
  M.generic_destroy_handler(event)
end

function M.on_entity_died(event)
  M.generic_destroy_handler(event, { do_not_delete_entity = true })
end

function M.on_post_entity_died(event)
  if event.unit_number ~= nil then
    GlobalState.entity_delete(event.unit_number)
  end
end

local function update_research_chest(entity)
  local inv = entity.get_output_inventory()
  local contents = inv.get_contents()
  local force = entity.force

  for item_name, item_count in pairs(constants.SCIENCE_PACKS) do
    local tech = force.technologies[item_name]
    if tech == nil or tech.researched then
      local cur_count = contents[item_name] or 0
      if cur_count < item_count then
        inv.insert({
          name = item_name,
          count = item_count - cur_count,
        })
      end
    end
  end
end

function M.onTick()
  GlobalState.setup()

  for _, entity in pairs(GlobalState.entity_table()) do
    if entity.valid then
      update_research_chest(entity)
    end
  end
end

return M
