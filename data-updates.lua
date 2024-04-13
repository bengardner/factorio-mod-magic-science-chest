local constants = require "src.constants"

-- enable this cheat with 'Nullius'
if mods["nullius"] then
  local name = constants.CHEST_NAME
  data.raw.item[name].order = "nullius-" .. name
  data.raw.recipe[name].order = "nullius-" .. name
end
