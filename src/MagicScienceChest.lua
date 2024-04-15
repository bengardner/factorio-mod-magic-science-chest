local GlobalState = require "src.GlobalState"
local constants = require "src.constants"

local lib = {}

local function entity_added(event)
  local entity = event.created_entity or event.entity or event.destination
  if entity == nil or not entity.valid then
    return
  end

  if entity.name == constants.CHEST_NAME then
    GlobalState.entity_register(entity)
  end
end

local function entity_removed(event)
  local entity = event.entity
  if entity == nil or not entity.valid or entity.unit_number == nil then
    return
  end

  if entity.name == constants.CHEST_NAME then
    entity.get_output_inventory().clear()
    GlobalState.entity_unregister(entity.unit_number)
  end
end

--[[
Add the science packs to the chest.
]]
local function update_research_chest(entity, science_packs)
  local inv = entity.get_output_inventory()

  -- don't add items if marked for deconstruction
  if entity.to_be_deconstructed() then
    inv.clear()
    return
  end

  local contents = inv.get_contents()
  for item_name, item_count in pairs(science_packs) do
    local cur_count = contents[item_name] or 0
    if cur_count < item_count then
      inv.insert({
        name = item_name,
        count = item_count - cur_count,
      })
    end
  end
end

--[[
Filter the complete list of science_packs to which ones the force
has produced.
This is done once per force per update cycle.
]]
local function filter_science_packs(force, science_packs)
  local available = {}
  local ips = force.item_production_statistics

  -- limit to how much has been produced
  for item_name, stack_size in pairs(science_packs) do
    available[item_name] = math.min(stack_size, ips.get_input_count(item_name))
  end
  return available
end

-- Calls update_research_chest() on each valid chest. Removes invalid chests.
local function service_entities()
  local sp = GlobalState.get_science_packs(false)

  -- build the research pack list once per force per service
  local force_cache = {} -- key=force, val={researched science packs, amount}

  for unum, entity in pairs(GlobalState.entity_table()) do
    if entity.valid then
      local available = force_cache[entity.force_index]
      if available == nil then
        available = filter_science_packs(entity.force, sp)
        force_cache[entity.force_index] = available
      end
      update_research_chest(entity, available)
    else
      GlobalState.entity_unregister(unum)
    end
  end
end

-- this is called at startup when any mod changes
local function update_configuration(event)
  print("Magic Science Chest: rescan")
  GlobalState.get_science_packs(true)
end

lib.events =
{
  [defines.events.on_built_entity] = entity_added,
  [defines.events.on_robot_built_entity] = entity_added,
  [defines.events.script_raised_revive] = entity_added,
  [defines.events.script_raised_built] = entity_added,
  [defines.events.on_entity_cloned] = entity_added,
  [defines.events.on_cancelled_deconstruction] = entity_added,

  -- need these to discard inventory
  [defines.events.on_pre_player_mined_item] = entity_removed,
  [defines.events.on_robot_mined_entity] = entity_removed,
  [defines.events.script_raised_destroy] = entity_removed,
  [defines.events.on_entity_died] = entity_removed,
  [defines.events.on_marked_for_deconstruction] = entity_removed,
  [defines.events.on_post_entity_died] = entity_removed,
}

lib.on_configuration_changed = update_configuration

lib.on_nth_tick = {
  -- refill chests every 2 seconds
  [120] = service_entities,
}

return lib
