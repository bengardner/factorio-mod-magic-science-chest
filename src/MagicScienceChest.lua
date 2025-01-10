--[[
Handler for "magic-science-chest".
]]
local GlobalState = require "src.GlobalState"
local constants = require "src.constants"

local lib = {}

--[[
Filter the complete list of science_packs to which ones the force has produced.
This is done once per force per update cycle.
Returns an InfinityInventoryFilter.
]]
local function filter_science_packs(force, science_packs, min_prod)
  local ic_filter = {}

  -- add up the science packs produces on all surfaces
  local science_pack_totals = GlobalState.get_force_prod_count(force, science_packs)

  -- limit to how much has been produced
  local index = 1
  for item_name, stack_size in pairs(science_packs) do
    local prod_count = science_pack_totals[item_name] or 0
    if prod_count >= min_prod then
      table.insert(ic_filter, { name=item_name, count=stack_size, mode="exactly", index=index })
      index = index + 1
    elseif prod_count > 0 then
      GlobalState.log_msg_state(force, item_name, prod_count, min_prod)
    end
  end
  return ic_filter
end

-- Calls update_research_chest() on each valid chest. Removes invalid chests.
local function service_entities(entities)
  for unum, entity in pairs(entities) do
    if entity.valid then
      local ic_filter = GlobalState.force_get_iif(entity.force_index)
      if ic_filter ~= nil then
        entity.infinity_container_filters = ic_filter
        entity.get_output_inventory().set_bar(#ic_filter + 1)
      else
        log("ic_filter is nil")
      end
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
    service_entities({ [entity.unit_number] = entity })
  end
end

local function entity_removed(event)
  local entity = event.entity
  if entity == nil or not entity.valid or entity.unit_number == nil then
    return
  end

  if entity.name == constants.CHEST_NAME then
    GlobalState.entity_unregister(entity.unit_number)
  end
end


lib.events =
{
  [defines.events.on_built_entity] = entity_added,
  [defines.events.on_robot_built_entity] = entity_added,
  [defines.events.on_space_platform_built_entity] = entity_added,
  [defines.events.script_raised_revive] = entity_added,
  [defines.events.script_raised_built] = entity_added,
  [defines.events.on_entity_cloned] = entity_added,
  [defines.events.on_cancelled_deconstruction] = entity_added,

  -- used to forget about entities (save a tiny bit of RAM)
  [defines.events.on_pre_player_mined_item] = entity_removed,
  [defines.events.on_robot_mined_entity] = entity_removed,
  [defines.events.script_raised_destroy] = entity_removed,
  [defines.events.on_entity_died] = entity_removed,
  [defines.events.on_marked_for_deconstruction] = entity_removed,
  [defines.events.on_post_entity_died] = entity_removed,
}

-- this is called at startup when any mod changes
lib.on_configuration_changed = function(event)
  log("Magic Science Chest: rescan")
  GlobalState.get_science_packs(true)
end

--[[
Calculate the InfinityInventoryFilter for each force.
If it changes, then update all entities.
]]
local function service_forces()
  local min_prod = settings.global["magic-scient-chest-production"].value
  local something_changed = false

  local sp = GlobalState.get_science_packs(false)

  for _, force in pairs(game.forces) do
    local ic_filter = filter_science_packs(force, sp, min_prod)
    local changes = GlobalState.force_set_iif(force.index, ic_filter)
    if changes ~= nil then
      log(("force: %s changes %s"):format(force.name, serpent.line(changes)))
      something_changed = true
      for _, name in ipairs(changes) do
        local prot = prototypes.item[name]
        if prot ~= nil then
          force.print({ "", {"magic-science-chest.unlocked_message",
            'item.' .. name, prot.localised_name } })
        end
      end
    end
  end

  if something_changed then
    service_entities(GlobalState.entity_table())
  end
end

lib.on_nth_tick = {
  -- check for unlocks every 5 seconds
  [60*5] = service_forces,
}

return lib
