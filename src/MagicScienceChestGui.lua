--[[
Handler for "magic-science-chest".
Replace the entity GUI with a window listing science packs.

]]
local GlobalState = require "src.GlobalState"
local constants = require "src.constants"
local util = require "util" -- "__core__/lualib/util"

local GUI_NAME_WINDOW = "magic-science-chest-entity-gui"
local GUI_NAME_CLOSE = "magic-science-chest-entity-gui-close"
local GUI_NAME_TABLE = "magic-science-chest-entity-gui-table"

local lib = {}
local M = {}

local function gui_get(player_index)
  local ui = GlobalState.get_ui_state(player_index)
  return ui.net_view, ui
end

local function gui_set(player_index, value)
  GlobalState.get_ui_state(player_index).net_view = value
end

local function create_window(player, title, entity)
  local elems = {}

  -- create the main window
  local main_window = player.gui.screen.add({
    type = "frame",
    name = GUI_NAME_WINDOW,
    style = "inset_frame_container_frame",
    tags = { unit_number = entity.unit_number },
  })
  main_window.auto_center = true
  main_window.style.horizontally_stretchable = true
  main_window.style.vertically_stretchable = true
  elems.main_window = main_window

  -- create a vertical flow to cover the entire window body
  local vert_flow = main_window.add({
    type = "flow",
    direction = "vertical",
  })
  vert_flow.style.horizontally_stretchable = true
  vert_flow.style.vertically_stretchable = true

  -- add the header/toolbar flow
  local title_flow = vert_flow.add({
    type = "flow",
    direction = "horizontal",
  })
  title_flow.drag_target = main_window
  elems.title_flow = title_flow

  -- add the window title
  title_flow.add {
    type = "label",
    caption = title,
    style = "frame_title",
    ignored_by_interaction = true,
  }

  -- add the drag space
  local header_drag = title_flow.add {
    type = "empty-widget",
    style = "draggable_space_header",
    ignored_by_interaction = true,
  }
  header_drag.style.horizontally_stretchable = true
  header_drag.style.vertically_stretchable = true
  header_drag.style.height = 24

  elems.close_button = title_flow.add {
    name = GUI_NAME_CLOSE,
    type = "sprite-button",
    sprite = "utility/close_white",
    hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black",
    style = "close_button",
    tags = { event = GUI_NAME_CLOSE },
  }

  -- create the window body flow
  elems.body = vert_flow.add({
    type = "flow",
    direction = "vertical",
  })

  -- give focus to the window (make optional?)
  player.opened = main_window

  -- start the UI data
  local inst = {
    elems = elems,
    player = player,
    player_index = player.index,
    entity = entity,
    -- children = nil,
  }

  return inst
end

function M.on_gui_open(player, entity)
  local inst = gui_get(player.index)
  if inst ~= nil then
    M.destroy(inst)
  end

  -- create the main window
  inst = create_window(player, "Magic Science Chest", entity)
  local elems = inst.elems

  local frame_flow = elems.body.add({ type = "flow", direction = "horizontal" })
  local inner_frame = frame_flow.add({ type = "frame", style = "inside_shallow_frame_with_padding" })

  local side_flow = inner_frame.add({ type = "flow", direction = "horizontal" })

  local preview_frame = side_flow.add({
    type = "frame",
    style = "deep_frame_in_shallow_frame",
  })
  local entity_preview = preview_frame.add({
    type = "entity-preview",
    style = "wide_entity_button",
  })
  entity_preview.style.horizontally_stretchable = false
  entity_preview.style.minimal_width = 100
  entity_preview.style.natural_height = 100
  entity_preview.style.height = 100
  entity_preview.entity = entity

  local right_flow = side_flow.add({ type = "flow", direction = "vertical" })
  local main_flow = right_flow.add({ type = "flow", direction = "vertical" })

  local tt = main_flow.add{
    name = GUI_NAME_TABLE,
    type = "table",
    column_count = 3, -- icon, name, progress
  }
  elems.item_table = tt

  M.rebuild_table(inst, M.get_data(inst))

  gui_set(player.index, inst)
end

function M.on_gui_closed(player, entity)
  print("on_gui_closed")
  M.destroy(gui_get(player.index))
end

function M.destroy(inst)
  if inst ~= nil then
    local player = inst.player
    if player ~= nil and player.valid then
      local frame = player.gui.screen[GUI_NAME_WINDOW]
      if frame ~= nil then
        frame.destroy()
      end
    end
    gui_set(inst.player_index, nil)
  end
end

--[[
Get the list of items and strings.
]]
function M.get_data(inst)
  -- key=item name, val=progress string
  local items = {}
  local ips = inst.player.force.item_production_statistics
  local min_prod = settings.global["magic-scient-chest-production"].value

  local packs = GlobalState.get_science_packs(false)
  for item, _ in pairs(packs) do
    local count = ips.get_input_count(item)
    if count > 0 or min_prod == 0 then
      local caption = "[color=green]unlocked[/color]"
      if count < min_prod then
        caption = string.format("%s / %s", count, min_prod)
      end
      items[item] = caption
    end
  end
  return items
end

function M.rebuild_table(inst, items)
  local elems = inst.elems
  local tt = elems.item_table
  tt.clear()

  for item, caption in pairs(items) do
    local prot = game.item_prototypes[item]
    tt.add{
      type = "sprite-button",
      sprite = "item/" .. item,
    }
    tt.add{
      type = "label",
      caption = { "", "[font=default-bold]", prot.localised_name, "[/font]" },
    }
    elems[item] = tt.add{ type = "label", caption = caption }
  end
  inst.items = items
end

function M.gui_refresh(inst)
  local new_items = M.get_data(inst)
  if table_size(new_items) == table_size(inst.items) then
    if util.table.compare(new_items, inst.items) then
      return
    end
    for item, caption in pairs(new_items) do
      inst.elems[item].caption = caption
    end
    inst.items = new_items
    return
  end
  local tt = inst.elems.item_table
  M.rebuild_table(inst, new_items)
end

local function on_gui_opened(event)
  if event.gui_type == defines.gui_type.entity then
    local entity = event.entity
    if entity ~= nil and entity.valid and entity.name == constants.CHEST_NAME then
      local player = game.players[event.player_index]
      if player ~= nil and player.valid then
        M.on_gui_open(player, entity)
      end
    end
  end
end

local function on_gui_closed(event)
  if event.gui_type == defines.gui_type.entity then
    local entity = event.entity
    if entity ~= nil and entity.valid and entity.name == constants.CHEST_NAME then
      local player = game.players[event.player_index]
      if player ~= nil and player.valid then
        M.on_gui_closed(player, entity)
      end
    end
  end
end

local function on_gui_click(event)
  local player = game.players[event.player_index]
  local element = event.element
  if player ~= nil and player.valid then
    local tags = element.tags or {}
    if tags.event == GUI_NAME_CLOSE then
      M.destroy(gui_get(player.index))
    end
  end
end

local function on_timer(event)
  for _, player in pairs(game.players) do
    local inst = gui_get(player.index)
    if inst ~= nil then
      if inst.entity.valid and inst.elems.main_window.valid then
        M.gui_refresh(inst)
      else
        M.destroy(inst)
      end
    end
  end
end

-------------------------------------------------------------------------------

lib.events =
{
  [defines.events.on_gui_opened] = on_gui_opened,
  [defines.events.on_gui_closed] = on_gui_closed,
  [defines.events.on_gui_click] = on_gui_click,
  [defines.events.on_gui_confirmed] = on_gui_closed,
}

lib.on_nth_tick = {
  [60] = on_timer,
}

return lib
