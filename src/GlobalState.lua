local M = {}

local util = require("__core__/lualib/util")

------------------------------------------------------------------------------

-- entity_table: key=unit_number, val=entity
function M.entity_table()
  return global.entities or {}
end

function M.entity_register(entity)
  if entity ~= nil and entity.valid then
    local unum = entity.unit_number
    if unum ~= nil then
      if global.entities == nil then
        global.entities = {}
      end
      if global.entities[unum] == nil then
        global.entities[unum] = entity
      end
    end
  end
end

function M.entity_unregister(unit_number)
  if global.entities ~= nil then
    global.entities[unit_number] = nil
  end
end

------------------------------------------------------------------------------
--[[
force_data: key=force.index, val=InfinityInventoryFilter (array of tables)
Example:
  {
    [1] = { -- force index
      iif = {
        { name="automation-science-pack", count=200, mode="exactly", index=1 },
        { name="logistic-science-pack", count=200, mode="exactly", index=2 },
      },
      msg = {
        ...
      }
    }
  }
]]

-- grab the per-force table
function M.force_data(force_index)
  if global.forces == nil then
    global.forces = {}
  end
  local data = global.forces[force_index]
  if data == nil then
    data = {}
    global.forces[force_index] = data
  end
  return data
end

-- grab a subtable from the per-force table
function M.force_data_sub(force_index, subkey)
  local data = M.force_data(force_index)
  local vv = data[subkey]
  if vv == nil then
    vv = {}
    data[subkey] = vv
  end
  return vv
end

------------------------------------------------------------------------------

--[[ force_table: key=force.index, val=InfinityInventoryFilter (array of tables)
Example:
  {
    [1] = {
      iif = {
        { name="automation-science-pack", count=200, mode="exactly", index=1 },
        { name="logistic-science-pack", count=200, mode="exactly", index=2 },
      },
      msg = {
        ...
      }
    }
  }
]]

function M.force_get_iif(force_index)
  -- get without creating
  return M.force_data(force_index).iif or {}
end

-- list new keys (science packs) in icf2
local function diff_ic_filter(icf1, icf2)
  -- change to simple tables
  local function icf_flatten(icf_arr)
    local xx = {}
    for _, ff in ipairs(icf_arr) do
      xx[ff.name] = ff.count
    end
    return xx
  end
  local ic1 = icf_flatten(icf1)
  local ic2 = icf_flatten(icf2)
  local diffs = {}
  for name, _ in pairs(ic2) do
    if ic1[name] == nil then
      table.insert(diffs, name)
    end
  end
  return diffs
end

-- Sets the force infinity chest filter, returns a list of
-- science packs that were added.
function M.force_set_iif(force_index, ic_filter)
  local data = M.force_data(force_index)
  local old_icf = data.iif or {}
  -- table.compare() is a Factorio extension in "__core__/lualib/util"
  if table.compare(old_icf, ic_filter) then
    return nil -- no change
  end
  log(("old=%s new=%s"):format(serpent.line(old_icf), serpent.line(ic_filter)))
  data.iif = ic_filter
  return diff_ic_filter(old_icf, ic_filter)
end

------------------------------------------------------------------------------

function M.log_msg_state(force, item_name, cur_prod, min_prod)
  local prot = game.item_prototypes[item_name]
  if prot == nil then
    return
  end

  local msg = M.force_data_sub(force.index, "msg")
  local last = msg[item_name] or {}
  local last_tick = last.tick or 0
  local last_prod = last.prod or 0

  if cur_prod < min_prod and last_prod ~= cur_prod then
    log(("force: %s: %s %s/%d"):format(force.name, item_name, cur_prod, min_prod))

    -- see if it is time to log this to the console
    local interval = settings.global["magic-scient-chest-progress"].value * 60
    if (game.tick - last_tick) > interval then
      force.print({ "", {"magic-science-chest.progress_message",
        'item.' .. item_name, prot.localised_name, cur_prod, min_prod } })
      last.tick = game.tick
      last.prod = cur_prod
      msg[item_name] = last
    end
  end
end

------------------------------------------------------------------------------

function M.get_science_packs(force_scan)
  -- scan for science-packs by looking at lab_inputs
  local pp = global.science_packs or {}

  if next(pp) == nil or force_scan then
    -- scan lab prototypes and update the list of science packs
    for _, ep in pairs(game.get_filtered_entity_prototypes{{ filter="type", type="lab" }}) do
      for _, item_name in ipairs(ep.lab_inputs) do
        local ip = game.item_prototypes[item_name]
        if ip ~= nil then
          pp[item_name] = ip.stack_size
        end
      end
    end

    global.science_packs = pp
    for name, cnt in pairs(global.science_packs) do
      log(('Magic Science Chest: %s %s'): format(name, cnt))
    end
  end
  return global.science_packs
end

------------------------------------------------------------------------------

function M.get_player_info(player_index)
  local player_info = global.player_info
  if player_info == nil then
    player_info = {}
    global.player_info = player_info
  end

  local info = player_info[player_index]
  if info == nil then
    info = {}
    player_info[player_index] = info
  end
  return info
end

function M.get_ui_state(player_index)
  local info = M.get_player_info(player_index)
  if info.ui == nil then
    info.ui = {}
  end
  return info.ui
end

return M
