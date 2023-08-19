local M = {}

function M.setup()
  if global.mod == nil then
    global.mod = {
      entities = {},
    }
  end
end

function M.entity_register(entity)
  if global.mod.entities[entity.unit_number] == nil then
    global.mod.entities[entity.unit_number] = entity
  end
end

function M.entity_delete(unit_number)
  global.mod.entities[unit_number] = nil
end

function M.entity_get(unit_number)
  return global.mod.entities[unit_number]
end

function M.entity_table()
  return global.mod.entities
end

return M
