local utils = {}

--[[
Recursive comparison of two tables.
This will hang if there is a loop.
]]
function utils.same_value(value1, value2)
  -- if they are different type or nil => false
  if type(value2) ~= type(value1) or value1 == nil then
    return false
  end

  -- direct comparison; shortcut same table pointers
  if value1 == value2 then
    return true
  end

  -- check table values
  if type(value1) == "table" then
    for k1, v1 in pairs(value1) do
      local v2 = value2[k1]
      if not utils.same_value(v1, v2) then
        return false
      end
    end
    for k2, v2 in pairs(value2) do
      local v1 = value1[k2]
      if not utils.same_value(v1, v2) then
        return false
      end
    end

    -- no difference in tables
    return true
  end

  return false
end

return utils
