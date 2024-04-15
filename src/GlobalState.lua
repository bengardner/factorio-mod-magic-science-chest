local M = {}

function M.setup()
  if global.entities == nil then
    global.entities = {}
  end
end

function M.entity_register(entity)
  M.setup()
  if global.entities[entity.unit_number] == nil then
    global.entities[entity.unit_number] = entity
  end
end

function M.entity_unregister(unit_number)
  if global.entities ~= nil then
    global.entities[unit_number] = nil
  end
end

function M.entity_table()
  M.setup()
  return global.entities
end

function M.get_science_packs(force_scan)
  -- scan prototypes for science-packs, going backwards from labs

  local pp = global.science_packs or {}
  if next(pp) == nil or force_scan then

    -- scan lab prototypes and update the list of science packs
    for _, ep in pairs(game.get_filtered_entity_prototypes{type="lab"}) do
      for _, item_name in ipairs(ep.lab_inputs) do
        local ip = game.item_prototypes[item_name]
        if ip ~= nil then
          pp[item_name] = ip.stack_size
        end
      end
    end

    global.science_packs = pp
    for name, cnt in pairs(global.science_packs) do
      print(string.format('Magic Science Pack: %s %s', name, cnt))
    end
  end
  return global.science_packs
end

return M
