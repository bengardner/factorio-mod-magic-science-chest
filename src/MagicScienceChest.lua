local GlobalState = require "src.GlobalState"
local constants = require "src.constants"

local lib = {}

--[[
Filter the complete list of science_packs to which ones the force
has produced.
This is done once per force per update cycle.
Returns an InfinityInventoryFilter.
]]
local function filter_science_packs(force, science_packs)
  local ic_filter = {}
  local ips = force.item_production_statistics

  -- limit to how much has been produced
  local index = 1
  for item_name, stack_size in pairs(science_packs) do
    local count = math.min(stack_size, ips.get_input_count(item_name))
    if count > 0 then
      table.insert(ic_filter, { name=item_name, count=count, mode="at-least", index=index })
      index = index + 1
    end
  end
  return ic_filter
end

-- Calls update_research_chest() on each valid chest. Removes invalid chests.
local function service_entities(entities)
  local sp = GlobalState.get_science_packs(false)

  -- build the research pack list once per force per service
  local force_cache = {} -- key=force, val=array[InfinityInventoryFilter]

  for unum, entity in pairs(entities) do
    if entity.valid then
      local ic_filter = force_cache[entity.force_index]
      if ic_filter == nil then
        ic_filter = filter_science_packs(entity.force, sp)
        force_cache[entity.force_index] = ic_filter
      end
      entity.infinity_container_filters = ic_filter
      entity.get_output_inventory().set_bar(#ic_filter + 1)
    else
      GlobalState.entity_unregister(unum)
    end
  end
end

local function entity_added(event)
  local entity = event.created_entity or event.entity or event.destination
  if entity == nil or not entity.valid then
    return
  end

  if entity.name == constants.CHEST_NAME then
    GlobalState.entity_register(entity)
    -- entity.remove_unfiltered_items = true
    service_entities({ [entity.unit_number] = entity })
  end
end

lib.events =
{
  [defines.events.on_built_entity] = entity_added,
  [defines.events.on_robot_built_entity] = entity_added,
  [defines.events.script_raised_revive] = entity_added,
  [defines.events.script_raised_built] = entity_added,
  [defines.events.on_entity_cloned] = entity_added,
  [defines.events.on_cancelled_deconstruction] = entity_added,
}

-- this is called at startup when any mod changes
lib.on_configuration_changed = function(event)
  log("Magic Science Chest: rescan")
  GlobalState.get_science_packs(true)
end

lib.on_nth_tick = {
  -- update filter every 5 seconds
  [60*5] = function()
    service_entities(GlobalState.entity_table())
  end,
}

return lib
